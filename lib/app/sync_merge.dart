/// Merging the copies of a user's data that live on their devices.
///
/// Each device keeps one [SyncDoc] in the user's Google Drive. A sync merges
/// this device's doc with every other device's, so all of them end up with
/// the same workspaces, history and settings. The rules:
///
/// - A workspace is taken from whichever device changed it last.
/// - If two devices changed the same workspace without seeing each other's
///   change, the older change is kept as a copy instead of being lost.
/// - A delete removes the version the deleting device had. Changes it never
///   saw (made on another device before or after the delete) survive it, so
///   a delete never throws away work nobody looked at.
/// - History is the union of every device's, without anything older than the
///   last time it was cleared.
/// - Settings come from whichever device changed them last.
///
/// [merge] depends only on the docs it is given, never on which device runs
/// it or in what order the docs arrive, so every device reaches the same
/// result.
library;

import 'dart:convert';

import 'models.dart';

/// Everything that syncs, as one device last saved it.
class SyncDoc {
  SyncDoc({
    required this.device,
    required this.deviceName,
    required this.savedAt,
    required this.workspaces,
    required this.deleted,
    required this.history,
    required this.historyClearedAt,
    required this.settings,
    required this.settingsUpdated,
  });

  factory SyncDoc.fromJson(Map<String, dynamic> j) => SyncDoc(
    device: j['device'] as String? ?? '',
    deviceName: j['deviceName'] as String? ?? 'another device',
    savedAt: j['savedAt'] as int? ?? 0,
    workspaces: [
      for (final w in j['workspaces'] as List? ?? const [])
        Workspace.fromJson(w as Map<String, dynamic>),
    ],
    deleted: {
      for (final e in (j['deleted'] as Map? ?? const {}).entries)
        e.key as String: e.value as int,
    },
    history: [
      for (final h in j['history'] as List? ?? const [])
        HistoryItem.fromJson(h as Map<String, dynamic>),
    ],
    historyClearedAt: j['historyClearedAt'] as int? ?? 0,
    settings: Map<String, dynamic>.of(
      j['settings'] as Map<String, dynamic>? ?? const {},
    ),
    settingsUpdated: j['settingsUpdated'] as int? ?? 0,
  );

  /// The device's sync id, and the name it shows to people.
  final String device;
  final String deviceName;

  /// When the device wrote this doc.
  final int savedAt;

  final List<Workspace> workspaces;

  /// Deleted workspace ids, each with the version that was deleted (that
  /// workspace's `updated`). Older files hold the time of the delete, which
  /// is never earlier, so they read the same way.
  final Map<String, int> deleted;
  final List<HistoryItem> history;
  final int historyClearedAt;
  final Map<String, dynamic> settings;
  final int settingsUpdated;

  Map<String, dynamic> toJson() => {
    'schema': 1,
    'device': device,
    'deviceName': deviceName,
    'savedAt': savedAt,
    'workspaces': workspaces,
    'deleted': deleted,
    'history': history,
    'historyClearedAt': historyClearedAt,
    'settings': settings,
    'settingsUpdated': settingsUpdated,
  };

  /// The synced content alone, without who saved it or when: two docs with
  /// the same fingerprint need no upload.
  String get fingerprint {
    final j = toJson()
      ..remove('device')
      ..remove('deviceName')
      ..remove('savedAt');
    return jsonEncode(j);
  }
}

/// What a merge changed on this device, for telling the user.
class MergeReport {
  int added = 0;
  int updated = 0;
  int removed = 0;

  /// Copies kept because two devices changed the same workspace.
  int conflicts = 0;

  bool get changed => added + updated + removed + conflicts > 0;
}

/// Most history items kept, as on a single device.
const historyLimit = 60;

/// Merges [local] (this device's doc) with [remotes] (other devices' docs).
///
/// The result keeps [local]'s device, name and save time; the caller stamps
/// a new save time before uploading it.
(SyncDoc, MergeReport) merge(SyncDoc local, List<SyncDoc> remotes) {
  final docs = [local, ...remotes];
  final report = MergeReport();

  // Deletions: the latest version of each id deleted on any device.
  final deleted = <String, int>{};
  for (final d in docs) {
    d.deleted.forEach((id, t) {
      if (t > (deleted[id] ?? 0)) deleted[id] = t;
    });
  }

  // Every version of every workspace, with the device that holds it.
  final versions = <String, List<(Workspace, SyncDoc)>>{};
  for (final d in docs) {
    for (final w in d.workspaces) {
      (versions[w.id] ??= []).add((w, d));
    }
  }

  final out = <Workspace>[];
  final copies = <String, Workspace>{};
  final localById = {for (final w in local.workspaces) w.id: w};
  for (final vs in versions.values) {
    vs.sort((a, b) => _compare(b, a));
    var (winner, _) = vs.first;

    // The version the winner was edited from. Devices that only received
    // the winner hold the same base; older files may hold a later one, so
    // the earliest is taken: that keeps a copy rather than losing an edit.
    for (final (w, _) in vs) {
      if (w.updated == winner.updated &&
          w.contentKey == winner.contentKey &&
          w.base < winner.base) {
        winner = w;
      }
    }

    // Changes the winner never saw (made after the version it was edited
    // from) are kept as copies rather than dropped.
    final seen = <String>{winner.contentKey};
    for (final (loser, from) in vs) {
      if (identical(loser, winner) || loser.updated <= winner.base) continue;
      if (!seen.add(loser.contentKey)) continue;
      final copy = loser.copyWith(
        id: 'copy-${loser.id}-${loser.updated.toRadixString(36)}',
        name: '${loser.name} (from ${from.deviceName})',
        base: loser.updated,
      );
      copies.putIfAbsent(copy.id, () => copy);
    }

    if (_isDeleted(winner, deleted)) {
      if (localById.containsKey(winner.id)) report.removed++;
      continue;
    }
    // Taken as it is: its base belongs to the version, and each device sets
    // the base of its own next edit (see AppState).
    final merged = winner.copyWith();
    out.add(merged);
    final mine = localById[winner.id];
    if (mine == null) {
      report.added++;
    } else if (mine.contentKey != merged.contentKey) {
      report.updated++;
    }
  }

  // A copy that some device already made is in the docs and was merged
  // above; only new ones are added here, and the same ones on every device.
  for (final copy in copies.values) {
    if (versions.containsKey(copy.id) || _isDeleted(copy, deleted)) continue;
    out.add(copy);
    report.conflicts++;
  }

  // Newest first, as the workspace list shows them.
  out.sort((a, b) {
    final t = b.updated.compareTo(a.updated);
    return t != 0 ? t : a.id.compareTo(b.id);
  });

  // History: newest use of each expression, nothing from before a clear.
  final cleared = docs.map((d) => d.historyClearedAt).reduce(_max);
  final byText = <String, HistoryItem>{};
  for (final d in docs) {
    for (final h in d.history) {
      if (h.ts <= cleared) continue;
      final have = byText[h.text];
      if (have == null ||
          h.ts > have.ts ||
          (h.ts == have.ts && h.summary.compareTo(have.summary) > 0)) {
        byText[h.text] = h;
      }
    }
  }
  final history = byText.values.toList()
    ..sort((a, b) {
      final t = b.ts.compareTo(a.ts);
      return t != 0 ? t : a.text.compareTo(b.text);
    });
  if (history.length > historyLimit) {
    history.removeRange(historyLimit, history.length);
  }

  // Settings: from the device that changed them last.
  final settingsFrom = docs.reduce((a, b) {
    if (a.settingsUpdated != b.settingsUpdated) {
      return a.settingsUpdated > b.settingsUpdated ? a : b;
    }
    return a.device.compareTo(b.device) >= 0 ? a : b;
  });

  return (
    SyncDoc(
      device: local.device,
      deviceName: local.deviceName,
      savedAt: local.savedAt,
      workspaces: out,
      deleted: deleted,
      history: history,
      historyClearedAt: cleared,
      settings: Map.of(settingsFrom.settings),
      settingsUpdated: settingsFrom.settingsUpdated,
    ),
    report,
  );
}

int _max(int a, int b) => a > b ? a : b;

bool _isDeleted(Workspace w, Map<String, int> deleted) =>
    (deleted[w.id] ?? -1) >= w.updated;

/// Orders two versions of a workspace: earlier change first, and the same
/// order on every device when the times are equal.
int _compare((Workspace, SyncDoc) a, (Workspace, SyncDoc) b) {
  final t = a.$1.updated.compareTo(b.$1.updated);
  if (t != 0) return t;
  final c = a.$1.contentKey.compareTo(b.$1.contentKey);
  if (c != 0) return c;
  return a.$2.device.compareTo(b.$2.device);
}
