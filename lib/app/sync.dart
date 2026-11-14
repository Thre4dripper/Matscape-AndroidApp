/// Keeps this device's data in step with the user's other devices through
/// their Google Drive.
///
/// Each device writes only its own file, `sync-<device id>.json`, to the
/// Drive app-data folder, and reads everyone else's. See `sync_merge.dart`
/// for how the copies are combined.
///
/// Other devices' changes are brought in when the app opens, when it comes
/// back to the foreground and on Sync now, so the screen never changes under
/// someone mid-task. This device's own edits are sent on their own, a few
/// seconds after the user pauses and when the app goes to the background:
/// sending never changes the screen, and it keeps the Drive copy current.
/// With [SyncController.live] on, changes are also brought in every
/// [SyncController.poll] while the app is open.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'app_state.dart';
import 'drive_store.dart';
import 'google_account.dart';
import 'google_config.dart';
import 'models.dart';
import 'storage.dart';
import 'sync_merge.dart';

/// What a sync changed that the user didn't do here, to tell them.
class SyncNotice {
  SyncNotice({required this.removed, required this.copies, this.openId});

  /// Workspaces deleted on another device, as they were here.
  final List<Workspace> removed;

  /// Names of copies kept because two devices changed the same workspace.
  final List<String> copies;

  /// The open workspace, when it was one of [removed].
  final String? openId;
}

enum SyncStatus {
  /// Not connected to Google Drive.
  off,

  /// Waiting for the user to pick an account.
  connecting,
  syncing,

  /// Connected; the last sync worked.
  ready,

  /// Connected, but the last sync failed. It is tried again later.
  failed,

  /// Drive access was withdrawn or expired: the user must connect again.
  reconnect,
}

class SyncController extends ChangeNotifier {
  SyncController({
    required this.state,
    required this.account,
    required this.local,
    CloudStore Function(DriveAccount account)? store,
    Future<String> Function()? deviceName,
    Future<void> Function(Future<void> Function() work)? whileLeaving,
    this.debounce = const Duration(seconds: 10),
    this.poll = const Duration(seconds: 30),
    int Function()? now,
    bool? available,
  }) : available = available ?? googleConfigured,
       _storeFor = store ?? ((a) => DriveStore(a.token)),
       _deviceName = deviceName ?? FileStorage.deviceName,
       _whileLeaving = whileLeaving ?? FileStorage.whileLeaving,
       _now = now ?? (() => DateTime.now().millisecondsSinceEpoch);

  final AppState state;
  final DriveAccount account;

  /// Whether this build can reach Google Drive (its client ids are set).
  final bool available;

  /// This device's own bookkeeping, in a folder that is never backed up.
  final Storage local;
  final Duration debounce;

  /// How often [live] looks for other devices' changes while the app is
  /// open. Each look is one small request; files are only downloaded or
  /// uploaded when something changed. Null turns looking off altogether.
  final Duration? poll;

  /// Whether other devices' changes are brought in while the app is open,
  /// rather than only when it opens. This device's choice: never synced.
  bool get live => _live;
  final CloudStore Function(DriveAccount) _storeFor;
  final Future<String> Function() _deviceName;
  final Future<void> Function(Future<void> Function()) _whileLeaving;
  final int Function() _now;

  static const prefix = 'sync-';

  SyncStatus status = SyncStatus.off;

  /// The connected Google account.
  String? email;

  /// When the last sync worked, milliseconds since epoch.
  int? lastSynced;

  /// What went wrong last time, for the user.
  String? error;

  bool get connected => _connected;

  /// What syncs changed that came from elsewhere: deletions, conflicts.
  Stream<SyncNotice> get notices => _notices.stream;
  final _notices = StreamController<SyncNotice>.broadcast();

  String _device = '';
  String _name = 'another device';
  bool _connected = false;
  bool _live = false;

  /// This device's file in Drive, once known.
  CloudFile? _mine;

  /// Each other device's file, as of when it was last merged here.
  Map<String, String> _seen = {};

  /// What was last uploaded, so an unchanged doc isn't sent again.
  String? _uploaded;

  /// What the app's data looked like after the last sync, to notice edits.
  String? _settled;

  /// Something worth telling the user even though the sync worked.
  String? _warning;

  CloudStore? _store;
  Timer? _timer, _poller;
  bool _foreground = true;
  bool _running = false;

  /// What to run once the current run ends: a full sync (true) or a send
  /// (false).
  bool? _queued;

  String get fileName => '$prefix$_device.json';

  /// Loads this device's id and, if Drive was connected, syncs.
  Future<void> start() async {
    await _load();
    _name = await _deviceName();
    state.addListener(_onState);
    if (!_connected) return;
    final who = await _guard(account.restore);
    if (who == null) {
      _set(SyncStatus.reconnect, 'Connect Google Drive again to keep syncing.');
      return;
    }
    // An empty answer: still connected, keep the email saved here.
    if (who.isNotEmpty) email = who;
    _startPolling();
    await sync();
  }

  /// Asks the user for Drive access, then syncs. Returns what the first sync
  /// changed on this device, or null if it didn't happen.
  Future<MergeReport?> connect() async {
    _set(SyncStatus.connecting);
    try {
      email = await account.connect();
    } on AccountException catch (e) {
      _set(
        _connected ? SyncStatus.reconnect : SyncStatus.off,
        e.canceled ? null : e.message,
      );
      return null;
    }
    _connected = true;
    await _save();
    _startPolling();
    return sync();
  }

  /// Stops syncing. With [deleteCloudCopy], this device's file is removed
  /// from Drive first. The data on this device stays.
  Future<void> disconnect({bool deleteCloudCopy = false}) async {
    _timer?.cancel();
    _poller?.cancel();
    if (deleteCloudCopy) {
      try {
        final store = _store ??= _storeFor(account);
        for (final f in await store.list(fileName)) {
          if (f.name == fileName) await store.delete(f);
        }
      } on Exception {
        // Best effort: the account is disconnected either way.
      }
    }
    await _guard(account.disconnect);
    _connected = false;
    email = null;
    _seen = {};
    _uploaded = null;
    _store = null;
    _mine = null;
    await _save();
    _set(SyncStatus.off);
  }

  /// The app came back to the foreground.
  void resumed() {
    _foreground = true;
    if (_connected && status != SyncStatus.reconnect) {
      _startPolling();
      sync();
    }
  }

  /// The app went to the background: stop looking until it's back. Edits
  /// not yet sent are sent now, while the app can still run.
  void paused() {
    _foreground = false;
    _poller?.cancel();
    _timer?.cancel();
    if (_connected && status != SyncStatus.reconnect) {
      unawaited(_whileLeaving(push));
    }
  }

  /// Turns [live] on or off for this device.
  Future<void> setLive(bool on) async {
    if (_live == on) return;
    _live = on;
    _startPolling();
    notifyListeners();
    await _save();
  }

  void _startPolling() {
    final every = poll;
    _poller?.cancel();
    if (every == null || !_live || !_foreground || !_connected) return;
    _poller = Timer.periodic(every, (_) {
      if (_connected && !_running && status != SyncStatus.reconnect) sync();
    });
  }

  /// Brings in other devices' changes and sends this device's. Only one
  /// run happens at a time; asking during one runs another straight after.
  Future<MergeReport?> sync() => _run(full: true);

  /// Sends this device's data without bringing anything in, so nothing on
  /// screen changes. Does nothing when Drive already has it.
  Future<void> push() => _run(full: false);

  Future<MergeReport?> _run({required bool full}) async {
    if (!_connected) return null;
    if (_running) {
      _queued = full || (_queued ?? false);
      return null;
    }
    _running = true;
    _timer?.cancel();
    if (full) _set(SyncStatus.syncing);
    MergeReport? report;
    try {
      if (full) {
        _warning = null;
        report = await _syncOnce();
        lastSynced = _now();
        _set(SyncStatus.ready, _warning);
      } else if (await _pushOnce()) {
        lastSynced = _now();
        // Keep a warning from the last full sync; clear a failure.
        _set(SyncStatus.ready, status == SyncStatus.ready ? error : null);
      }
    } on CloudException catch (e) {
      _set(
        e.signedOut ? SyncStatus.reconnect : SyncStatus.failed,
        e.signedOut ? 'Connect Google Drive again to keep syncing.' : e.message,
      );
    } on Exception catch (e) {
      _set(SyncStatus.failed, '$e');
    } finally {
      _running = false;
      await _save();
    }
    final next = _queued;
    _queued = null;
    if (next != null) unawaited(_run(full: next));
    return report;
  }

  /// Uploads this device's data if Drive doesn't have it yet. Returns
  /// whether anything was sent.
  Future<bool> _pushOnce() async {
    final store = _store ??= _storeFor(account);
    final doc = state.toSyncDoc(
      device: _device,
      deviceName: _name,
      savedAt: _now(),
    );
    _settled = doc.fingerprint;
    if (doc.fingerprint == _uploaded) return false;
    _mine ??= await _findMine(store);
    try {
      _mine = await store.upload(fileName, jsonEncode(doc), existing: _mine);
    } on CloudException catch (e) {
      // The file went away (removed from another device, say): make it again.
      if (e.status != 404) rethrow;
      _mine = await _findMine(store);
      _mine = await store.upload(fileName, jsonEncode(doc), existing: _mine);
    }
    _uploaded = doc.fingerprint;
    return true;
  }

  Future<CloudFile?> _findMine(CloudStore store) async {
    for (final f in await store.list(fileName)) {
      if (f.name == fileName) return f;
    }
    return null;
  }

  Future<MergeReport> _syncOnce() async {
    final store = _store ??= _storeFor(account);
    final files = await store.list(prefix);
    CloudFile? mine;
    final remotes = <SyncDoc>[];
    final read = <String, String>{};
    for (final f in files) {
      if (f.name == fileName) {
        mine = f;
        continue;
      }
      final stamp = f.modified.toIso8601String();
      if (_seen[f.name] == stamp) continue;
      try {
        final j = jsonDecode(await store.download(f)) as Map<String, dynamic>;
        if ((j['schema'] as int? ?? 1) > 1) {
          _warning = 'Another device has a newer Matscape. Update this one to sync with it.';
          continue;
        }
        remotes.add(SyncDoc.fromJson(j));
        read[f.name] = stamp;
      } on FormatException {
        // A broken file: skip it rather than lose this sync.
        continue;
      }
    }

    final here = state.toSyncDoc(
      device: _device,
      deviceName: _name,
      savedAt: _now(),
    );
    final (merged, report) = merge(here, remotes);
    final notice = _noticeFor(here, merged);
    // No awaits between taking [here] and these: an edit can't slip between.
    if (merged.fingerprint != here.fingerprint) state.applySyncDoc(merged);
    state.markSynced();
    _settled = _fingerprint();
    if (notice != null) _notices.add(notice);

    _mine = mine;
    if (mine == null || merged.fingerprint != _uploaded) {
      _mine = await store.upload(
        fileName,
        jsonEncode(
          SyncDoc(
            device: _device,
            deviceName: _name,
            savedAt: _now(),
            workspaces: merged.workspaces,
            deleted: merged.deleted,
            history: merged.history,
            historyClearedAt: merged.historyClearedAt,
            settings: merged.settings,
            settingsUpdated: merged.settingsUpdated,
          ),
        ),
        existing: mine,
      );
      _uploaded = merged.fingerprint;
    }
    _seen.addAll(read);
    return report;
  }

  /// What [merged] takes away or copies, compared with [here].
  SyncNotice? _noticeFor(SyncDoc here, SyncDoc merged) {
    final before = {for (final w in here.workspaces) w.id};
    final after = {for (final w in merged.workspaces) w.id};
    final removed = [
      for (final w in here.workspaces)
        if (!after.contains(w.id)) w,
    ];
    final copies = [
      for (final w in merged.workspaces)
        if (w.id.startsWith('copy-') && !before.contains(w.id)) w.name,
    ];
    if (removed.isEmpty && copies.isEmpty) return null;
    final open = state.currentId;
    return SyncNotice(
      removed: removed,
      copies: copies,
      openId: removed.any((w) => w.id == open) ? open : null,
    );
  }

  String _fingerprint() => state
      .toSyncDoc(device: _device, deviceName: _name, savedAt: 0)
      .fingerprint;

  /// An edit: send it once the user pauses. With [live] on, other devices'
  /// changes come in at the same time.
  void _onState() {
    if (!_connected || status == SyncStatus.reconnect) return;
    if (_fingerprint() == _settled) return;
    _timer?.cancel();
    _timer = Timer(debounce, _live ? sync : push);
  }

  void _set(SyncStatus s, [String? message]) {
    status = s;
    error = message;
    notifyListeners();
  }

  Future<T?> _guard<T>(Future<T> Function() f) async {
    try {
      return await f();
    } on Exception {
      return null;
    }
  }

  Future<void> _load() async {
    try {
      final raw = await local.read();
      if (raw != null) {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        _device = j['device'] as String? ?? '';
        _connected = j['connected'] as bool? ?? false;
        _live = j['live'] as bool? ?? false;
        email = j['email'] as String?;
        lastSynced = j['lastSynced'] as int?;
        _uploaded = j['uploaded'] as String?;
        _seen = {
          for (final e in (j['seen'] as Map? ?? const {}).entries)
            e.key as String: e.value as String,
        };
      }
    } catch (_) {
      // Unreadable: start as a new device.
    }
    if (_device.isEmpty) {
      _device = uid();
      await _save();
    }
  }

  Future<void> _save() async {
    try {
      await local.write(
        jsonEncode({
          'device': _device,
          'connected': _connected,
          'live': _live,
          'email': email,
          'lastSynced': lastSynced,
          'uploaded': _uploaded,
          'seen': _seen,
        }),
      );
    } catch (_) {
      // The next sync saves again.
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _poller?.cancel();
    _notices.close();
    state.removeListener(_onState);
    super.dispose();
  }
}
