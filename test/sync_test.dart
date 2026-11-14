// Sync between simulated devices that share one fake Google Drive.
import 'package:flutter_test/flutter_test.dart';
import 'package:matscape/app/app_state.dart';
import 'package:matscape/app/storage.dart';
import 'package:matscape/app/sync.dart';

import 'support/fake_sync.dart';

/// One device: its app data, its own sync bookkeeping, its controller.
class _Device {
  _Device(this.name, this.cloud, {MemoryStorage? data, MemoryStorage? local})
    : data = data ?? MemoryStorage(),
      local = local ?? MemoryStorage();

  final String name;
  final FakeCloud cloud;
  final MemoryStorage data, local;
  final account = FakeAccount();
  late AppState state;
  late SyncController sync;
  var clock = 1800000000000;

  Future<_Device> open({Duration? poll}) async {
    state = AppState(data);
    await state.load();
    sync = SyncController(
      state: state,
      account: account,
      local: local,
      store: (_) => cloud,
      deviceName: () async => name,
      debounce: const Duration(milliseconds: 20),
      poll: poll,
      now: () => clock += 1000,
    );
    await sync.start();
    return this;
  }

  List<String> get names => [for (final w in state.workspaces) w.name]..sort();

  Future<void> close() async {
    sync.dispose();
    await state.flush();
  }
}

void main() {
  late FakeCloud cloud;
  setUp(() => cloud = FakeCloud());

  test('a second device gets the first device\'s work', () async {
    final a = await _Device('Pixel', cloud).open();
    a.state.renameWorkspace('Homework');
    await a.sync.connect();
    expect(a.sync.status, SyncStatus.ready);
    expect(cloud.files, hasLength(1));

    final b = await _Device('iPad', cloud).open();
    final report = await b.sync.connect();
    expect(b.names, contains('Homework'));
    // The samples are the same everywhere: none were doubled.
    expect(b.state.workspaces, hasLength(a.state.workspaces.length));
    expect(report!.conflicts, 0);
  });

  test('edits travel both ways', () async {
    final a = await _Device('Pixel', cloud).open();
    final b = await _Device('iPad', cloud).open();
    await a.sync.connect();
    await b.sync.connect();

    a.state.setLineText(a.state.ws.lines.first.id, 'det(A) + 1');
    await a.sync.sync();
    await b.sync.sync();
    final id = a.state.currentId;
    expect(
      b.state.workspaces.firstWhere((w) => w.id == id).lines.first.text,
      'det(A) + 1',
    );

    b.state.openWorkspace(id);
    b.state.setLineText(b.state.ws.lines.first.id, 'det(A) + 2');
    await b.sync.sync();
    await a.sync.sync();
    expect(a.state.ws.lines.first.text, 'det(A) + 2');
    // Ordinary back-and-forth makes no copies.
    expect(a.state.workspaces, hasLength(b.state.workspaces.length));
  });

  test('the same workspace edited on two devices keeps both', () async {
    final a = await _Device('Pixel', cloud).open();
    final b = await _Device('iPad', cloud).open();
    await a.sync.connect();
    await b.sync.connect();
    final id = a.state.currentId;
    b.state.openWorkspace(id);

    a.state.setLineText(a.state.ws.lines.first.id, 'from the Pixel');
    b.state.setLineText(b.state.ws.lines.first.id, 'from the iPad');
    await a.sync.sync();
    await b.sync.sync();
    await a.sync.sync();

    String texts(_Device d) =>
        (d.state.workspaces
                .where((w) => w.id == id || w.id.startsWith('copy-$id'))
                .map((w) => '${w.name}: ${w.lines.first.text}')
                .toList()
              ..sort())
            .join(' / ');
    expect(texts(a), contains('from the Pixel'));
    expect(texts(a), contains('from the iPad'));
    expect(texts(a), texts(b));
  });

  test('a deletion reaches the other device', () async {
    final a = await _Device('Pixel', cloud).open();
    final b = await _Device('iPad', cloud).open();
    await a.sync.connect();
    await b.sync.connect();
    final gone = a.state.workspaces.last.id;
    a.state.deleteWorkspace(gone);
    await a.sync.sync();
    await b.sync.sync();
    expect(b.state.workspaces.any((w) => w.id == gone), isFalse);
  });

  test('an edit syncs by itself once the user pauses', () async {
    final a = await _Device('Pixel', cloud).open();
    await a.sync.connect();
    final before = cloud.uploads;
    a.state.renameWorkspace('Typed a name');
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(cloud.uploads, before + 1);
    // Nothing changed since: nothing more is sent.
    await a.sync.sync();
    expect(cloud.uploads, before + 1);
  });

  test('by default an open app doesn\'t change until it is reopened', () async {
    const poll = Duration(milliseconds: 30);
    final a = await _Device('Pixel', cloud).open(poll: poll);
    final b = await _Device('iPad', cloud).open(poll: poll);
    await a.sync.connect();
    await b.sync.connect();

    a.state.renameWorkspace('Renamed on the Pixel');
    await Future<void>.delayed(const Duration(milliseconds: 100));
    // The Pixel sent it, and the iPad, busy in another workspace, sends its
    // own edit…
    b.state.openWorkspace(b.state.workspaces.last.id);
    b.state.setLineText(b.state.ws.lines.first.id, 'typing on the iPad');
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(cloud.files, hasLength(2));
    // …but nothing from the Pixel lands on the iPad's screen meanwhile.
    expect(b.names, isNot(contains('Renamed on the Pixel')));
    expect(b.state.ws.lines.first.text, 'typing on the iPad');

    // Coming back to the app brings it in.
    b.sync.paused();
    b.sync.resumed();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(b.names, contains('Renamed on the Pixel'));
    await a.close();
    await b.close();
  });

  test('with Live on, another device\'s edit arrives while the app sits '
      'open', () async {
    const poll = Duration(milliseconds: 30);
    final a = await _Device('Pixel', cloud).open(poll: poll);
    final b = await _Device('iPad', cloud).open(poll: poll);
    await a.sync.connect();
    await b.sync.connect();
    await b.sync.setLive(true);

    a.state.renameWorkspace('Renamed on the Pixel');
    // No edit, tap or reopen on the iPad: its regular look picks it up.
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(b.names, contains('Renamed on the Pixel'));
    await a.close();
    await b.close();
  });

  test('nothing is checked while the app is in the background', () async {
    final a = await _Device(
      'Pixel',
      cloud,
    ).open(poll: const Duration(milliseconds: 20));
    await a.sync.connect();
    await a.sync.setLive(true);
    a.sync.paused();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final lists = cloud.lists;
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(cloud.lists, lists);

    // Back in front: it syncs at once and keeps looking.
    a.sync.resumed();
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(cloud.lists, greaterThan(lists + 1));
    await a.close();
  });

  test(
    'an edit waiting to be sent goes out when the app is backgrounded',
    () async {
      final a = await _Device('Pixel', cloud).open();
      await a.sync.connect();
      final before = cloud.uploads;
      a.state.renameWorkspace('Then left the app');
      a.sync.paused();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(cloud.uploads, before + 1);
      await a.close();
    },
  );

  test('Live is this device\'s choice and survives a restart', () async {
    final a = await _Device('Pixel', cloud).open();
    final b = await _Device('iPad', cloud).open();
    await a.sync.connect();
    await b.sync.connect();
    await a.sync.setLive(true);
    await a.sync.sync();
    await b.sync.sync();
    expect(b.sync.live, isFalse);

    await a.close();
    final again = await _Device(
      'Pixel',
      cloud,
      data: a.data,
      local: a.local,
    ).open();
    expect(again.sync.live, isTrue);
    await again.close();
    await b.close();
  });

  test('an edit the deleting device never saw survives the delete', () async {
    final a = await _Device('Pixel', cloud).open();
    final b = await _Device('iPad', cloud).open();
    await a.sync.connect();
    await b.sync.connect();
    final id = a.state.currentId;

    // The Pixel edits; before that reaches Drive, the iPad deletes the
    // version it has.
    a.state.setLineText(a.state.ws.lines.first.id, 'work not sent yet');
    expect(b.state.deleteWorkspace(id), isTrue);
    await b.sync.sync();
    await a.sync.sync();
    expect(a.state.currentId, id);
    expect(a.state.ws.lines.first.text, 'work not sent yet');

    // And the iPad gets it back rather than losing it.
    await b.sync.sync();
    final back = b.state.workspaces.where((w) => w.id == id);
    expect(back.single.lines.first.text, 'work not sent yet');
    await a.close();
    await b.close();
  });

  test('a delete from elsewhere is reported, and Undo brings it back '
      'everywhere', () async {
    final a = await _Device('Pixel', cloud).open();
    final b = await _Device('iPad', cloud).open();
    await a.sync.connect();
    await b.sync.connect();
    final id = a.state.currentId, name = a.state.ws.name;

    final notices = <SyncNotice>[];
    final sub = a.sync.notices.listen(notices.add);
    expect(b.state.deleteWorkspace(id), isTrue);
    await b.sync.sync();
    await a.sync.sync();
    expect(a.state.workspaces.any((w) => w.id == id), isFalse);
    expect(notices.single.removed.single.name, name);
    expect(notices.single.openId, id);

    a.state.restoreWorkspaces(
      notices.single.removed,
      open: notices.single.openId,
    );
    expect(a.state.currentId, id);
    await a.sync.sync();
    await b.sync.sync();
    expect(b.state.workspaces.any((w) => w.id == id), isTrue);
    // Restoring isn't itself reported as a change on the other device.
    await sub.cancel();
    await a.close();
    await b.close();
  });

  test('two devices editing one workspace hear about the copy', () async {
    final a = await _Device('Pixel', cloud).open();
    final b = await _Device('iPad', cloud).open();
    await a.sync.connect();
    await b.sync.connect();
    final id = a.state.currentId;
    b.state.openWorkspace(id);
    final notices = <SyncNotice>[];
    final subA = a.sync.notices.listen(notices.add);
    final subB = b.sync.notices.listen(notices.add);

    a.state.setLineText(a.state.ws.lines.first.id, 'from the Pixel');
    b.state.setLineText(b.state.ws.lines.first.id, 'from the iPad');
    await a.sync.sync();
    await b.sync.sync();
    await a.sync.sync();
    expect(notices.expand((n) => n.copies), isNotEmpty);
    expect(notices.expand((n) => n.copies).first, contains('(from '));
    await subA.cancel();
    await subB.cancel();
    await a.close();
    await b.close();
  });

  test('a merge only rewrites what changed: no upload loop', () async {
    final a = await _Device('Pixel', cloud).open();
    final b = await _Device('iPad', cloud).open();
    await a.sync.connect();
    await b.sync.connect();
    a.state.setLineText(a.state.ws.lines.first.id, 'one edit');
    await a.sync.sync();
    await b.sync.sync();
    await a.sync.sync();
    final settled = cloud.uploads;
    await a.sync.sync();
    await b.sync.sync();
    expect(cloud.uploads, settled);
    await a.close();
    await b.close();
  });

  test('offline: nothing is lost, and it works once back', () async {
    final a = await _Device('Pixel', cloud).open();
    await a.sync.connect();
    cloud.offline = true;
    a.state.renameWorkspace('Written offline');
    await a.sync.sync();
    expect(a.sync.status, SyncStatus.failed);
    expect(a.sync.error, 'No connection');
    expect(a.names, contains('Written offline'));

    cloud.offline = false;
    await a.sync.sync();
    expect(a.sync.status, SyncStatus.ready);
    final b = await _Device('iPad', cloud).open();
    await b.sync.connect();
    expect(b.names, contains('Written offline'));
  });

  test('withdrawn access asks the user to connect again', () async {
    final a = await _Device('Pixel', cloud).open();
    await a.sync.connect();
    cloud.revoked = true;
    await a.sync.sync();
    expect(a.sync.status, SyncStatus.reconnect);
    // Edits don't keep retrying while access is gone.
    final before = cloud.uploads;
    a.state.renameWorkspace('x');
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(cloud.uploads, before);

    cloud.revoked = false;
    await a.sync.connect();
    expect(a.sync.status, SyncStatus.ready);
  });

  test('closing the sign-in leaves sync off without an error', () async {
    final a = await _Device('Pixel', cloud).open();
    a.account.cancel = true;
    expect(await a.sync.connect(), isNull);
    expect(a.sync.status, SyncStatus.off);
    expect(a.sync.error, isNull);
    expect(cloud.files, isEmpty);
  });

  test('connection and device id survive a restart', () async {
    final a = await _Device('Pixel', cloud).open();
    await a.sync.connect();
    final file = a.sync.fileName;
    await a.close();

    // Google still remembers the account.
    final again = _Device('Pixel', cloud, data: a.data, local: a.local);
    again.account.connected = true;
    await again.open();
    // start() reconnects silently and syncs into the same file.
    expect(again.sync.status, SyncStatus.ready);
    expect(again.sync.fileName, file);
    expect(cloud.files, hasLength(1));
  });

  test('a phone restored from a backup is a new device', () async {
    final a = await _Device('Pixel', cloud).open();
    a.state.renameWorkspace('Thesis');
    await a.sync.connect();
    await a.close();

    // The app data comes back from the backup; the sync folder does not.
    final restored = await _Device(
      'New Pixel',
      cloud,
      data: MemoryStorage(a.data.data),
    ).open();
    expect(restored.sync.connected, isFalse);
    await restored.sync.connect();
    expect(restored.sync.fileName, isNot(a.sync.fileName));
    expect(cloud.files, hasLength(2));
    // Same data on both: no copies.
    expect(restored.names.where((n) => n.startsWith('Thesis')), ['Thesis']);
  });

  test('disconnecting can remove this device\'s copy from Drive', () async {
    final a = await _Device('Pixel', cloud).open();
    final b = await _Device('iPad', cloud).open();
    await a.sync.connect();
    await b.sync.connect();
    await a.sync.disconnect(deleteCloudCopy: true);
    expect(a.sync.status, SyncStatus.off);
    expect(cloud.files.values.map((f) => f.$1), [b.sync.fileName]);
    // The data on the device stays.
    expect(a.state.workspaces, isNotEmpty);
  });

  test('three devices end up the same', () async {
    final ds = [
      await _Device('Pixel', cloud).open(),
      await _Device('iPad', cloud).open(),
      await _Device('Tab', cloud).open(),
    ];
    for (final d in ds) {
      await d.sync.connect();
    }
    ds[0].state.renameWorkspace('From Pixel');
    ds[1].state.newWorkspace();
    ds[1].state.renameWorkspace('From iPad');
    ds[2].state.clearHistory();
    ds[2].state.updateSettings((s) => s.copyLatex = true);
    for (var round = 0; round < 2; round++) {
      for (final d in ds) {
        await d.sync.sync();
      }
    }
    final first = ds[0].names;
    for (final d in ds) {
      expect(d.names, first);
      expect(d.state.settings.copyLatex, isTrue);
      expect(d.state.history, isEmpty);
    }
    expect(first, containsAll(['From Pixel', 'From iPad']));
  });
}
