// The Backup & sync card in Settings, driven like a user would.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:matscape/app/app_state.dart';
import 'package:matscape/app/storage.dart';
import 'package:matscape/app/sync.dart';
import 'package:matscape/app/sync_merge.dart';
import 'package:matscape/main.dart';

import 'support/fake_sync.dart';

Future<(AppState, SyncController, FakeCloud)> _launch(
  WidgetTester tester, {
  bool available = true,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(402, 1400);
  tester.view.display.size = const Size(3000, 3000);
  addTearDown(tester.view.reset);
  final state = AppState(MemoryStorage());
  await state.load();
  state.tutorialSeen = true;
  final cloud = FakeCloud();
  final sync = SyncController(
    state: state,
    account: FakeAccount(),
    local: MemoryStorage(),
    store: (_) => cloud,
    deviceName: () async => 'Pixel',
    debounce: const Duration(hours: 1),
    poll: null,
    available: available,
  );
  addTearDown(state.flush);
  await tester.pumpWidget(
    MatscapeApp(key: UniqueKey(), state: state, sync: sync),
  );
  await tester.runAsync(sync.start);
  await tester.pumpAndSettle();
  return (state, sync, cloud);
}

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('Open menu'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Settings').last);
  await tester.pumpAndSettle();
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('connect, sync now and disconnect from Settings', (tester) async {
    final (_, sync, cloud) = await _launch(tester);
    await _openSettings(tester);
    expect(find.text('BACKUP & SYNC'), findsOneWidget);
    expect(find.text('Back up and sync'), findsOneWidget);

    await tester.tap(find.text('Connect Google Drive'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(sync.status, SyncStatus.ready);
    expect(find.text('user@example.com'), findsOneWidget);
    expect(find.text('Synced just now'), findsOneWidget);
    expect(find.text('Backed up to Google Drive'), findsOneWidget);
    expect(cloud.files, hasLength(1));
    await _settle(tester);

    await tester.tap(find.text('Sync now'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(sync.status, SyncStatus.ready);

    await tester.tap(find.text('Disconnect'));
    await tester.pumpAndSettle();
    expect(find.text('Disconnect Google Drive?'), findsOneWidget);
    await tester.tap(find.text('Disconnect').last);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(sync.status, SyncStatus.off);
    expect(find.text('Connect Google Drive'), findsOneWidget);
    // The copy in Drive stays, for connecting again later.
    expect(cloud.files, hasLength(1));
    expect(tester.takeException(), isNull);
    await _settle(tester);
  });

  testWidgets('a failed sync says the work is safe', (tester) async {
    final (_, sync, cloud) = await _launch(tester);
    await _openSettings(tester);
    await tester.tap(find.text('Connect Google Drive'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    await _settle(tester);

    cloud.offline = true;
    await tester.tap(find.text('Sync now'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(sync.status, SyncStatus.failed);
    expect(find.textContaining('Your work is safe'), findsOneWidget);
    await _settle(tester);
  });

  testWidgets('Live is off until chosen, and says what it does', (
    tester,
  ) async {
    final (_, sync, _) = await _launch(tester);
    await _openSettings(tester);
    // Only offered once connected.
    expect(find.text('Changes from your other devices'), findsNothing);
    await tester.tap(find.text('Connect Google Drive'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    await _settle(tester);

    expect(find.text('Changes from your other devices'), findsOneWidget);
    expect(sync.live, isFalse);
    expect(
      find.textContaining('so nothing changes while you work'),
      findsOneWidget,
    );
    await tester.tap(find.text('Live'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(sync.live, isTrue);
    expect(find.textContaining('every 30 seconds'), findsOneWidget);
    await _settle(tester);
  });

  testWidgets('a workspace deleted on another device can be undone', (
    tester,
  ) async {
    final (state, sync, cloud) = await _launch(tester);
    await _openSettings(tester);
    await tester.tap(find.text('Connect Google Drive'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    await _settle(tester);

    // Another device deleted the open workspace.
    final open = state.ws;
    final mine = state.toSyncDoc(
      device: 'ipad',
      deviceName: 'iPad',
      savedAt: 0,
    );
    final theirs = SyncDoc(
      device: 'ipad',
      deviceName: 'iPad',
      savedAt: 0,
      workspaces: [
        for (final w in mine.workspaces)
          if (w.id != open.id) w,
      ],
      deleted: {open.id: open.updated},
      history: mine.history,
      historyClearedAt: 0,
      settings: mine.settings,
      settingsUpdated: mine.settingsUpdated,
    );
    await tester.runAsync(
      () => cloud.upload('sync-ipad.json', jsonEncode(theirs)),
    );

    await tester.tap(find.text('Sync now'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(state.workspaces.any((w) => w.id == open.id), isFalse);
    expect(
      find.text('“${open.name}” was deleted on another device'),
      findsOneWidget,
    );

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(state.currentId, open.id);
    expect(find.text('Undo'), findsNothing);
    expect(tester.takeException(), isNull);
    // Leaving the app sends the restore at once.
    final before = cloud.uploads;
    await tester.runAsync(() async {
      sync.paused();
      await Future<void>.delayed(Duration.zero);
    });
    expect(cloud.uploads, before + 1);
    await _settle(tester);
  });

  testWidgets('a build without Google ids says so and offers nothing', (
    tester,
  ) async {
    await _launch(tester, available: false);
    await _openSettings(tester);
    expect(find.text('Not available in this build.'), findsOneWidget);
    expect(find.text('Connect Google Drive'), findsNothing);
    await _settle(tester);
  });
}
