// Renders the real app, screen by screen and device by device, into
// design/reference/. The designer works from these pictures, so the design
// follows the app instead of a description of it.
//
// Run with tool/screenshots.sh. It is a test only because that is how
// Flutter draws widgets without a device; it is not part of `flutter test`.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:matscape/app/app_state.dart';
import 'package:matscape/app/storage.dart';
import 'package:matscape/app/sync.dart';
import 'package:matscape/app/sync_merge.dart';
import 'package:matscape/main.dart';

import '../../test/support/fake_sync.dart';

const _out = 'design/reference';

/// The text face for labels and buttons. The app uses each platform's own;
/// here the Mac's system face stands in for it. Maths is always the app's
/// bundled STIX, so matrices look exactly as they do on a device.
const _systemFace = '/System/Library/Fonts/SFNS.ttf';

class Device {
  const Device(this.name, this.w, this.h, {this.pad = FakeViewPadding.zero});
  final String name;
  final double w, h;

  /// The safe-area insets the device reports (notch, home bar, side strip).
  final FakeViewPadding pad;
}

const iphone = Device(
  'iphone',
  402,
  874,
  pad: FakeViewPadding(top: 62, bottom: 34),
);
const androidSmall = Device(
  'android-small',
  360,
  800,
  pad: FakeViewPadding(top: 28, bottom: 16),
);
const iphoneLandscape = Device(
  'iphone-landscape',
  874,
  402,
  pad: FakeViewPadding(left: 62, right: 62, bottom: 21),
);
// The outer screen keeps an 84pt strip down one side for the camera.
const duoClosed = Device(
  'iphone-duo-closed',
  466,
  678,
  pad: FakeViewPadding(right: 84, bottom: 34),
);
const duoClosedLandscape = Device(
  'iphone-duo-closed-landscape',
  678,
  466,
  pad: FakeViewPadding(left: 84, bottom: 34),
);
const duoOpen = Device(
  'iphone-duo-open',
  669,
  951,
  pad: FakeViewPadding(top: 24, bottom: 20),
);
const ipadMini = Device(
  'ipad-mini',
  744,
  1133,
  pad: FakeViewPadding(top: 24, bottom: 20),
);
const ipad11 = Device(
  'ipad-11',
  1180,
  820,
  pad: FakeViewPadding(top: 24, bottom: 20),
);
// A phone-width page with no bottom, for a whole solution in one picture.
const tall = Device('iphone-full-page', 402, 3200);

typedef Act = Future<void> Function(WidgetTester t, AppState s);

class Scene {
  const Scene(
    this.name,
    this.act, {
    this.tour = false,
    this.line,
    this.synced = false,
    this.deletedElsewhere = false,
  });
  final String name;
  final Act act;

  /// Connect Google Drive (a stand-in) before the picture.
  final bool synced;

  /// Then have another device delete the open workspace, and sync: the
  /// picture shows the notice with Undo.
  final bool deletedElsewhere;

  /// Start on the first-launch tour instead of the workspace.
  final bool tour;

  /// Text to put in the first expression before anything else.
  final String? line;
}

/// A chain from matrix to number to matrix: ten steps.
const _long = 'det(A − tr(A)·I)·(A·Aᵀ + rank(A)·I)⁻¹·[1; 2; 3]';

Future<void> _none(WidgetTester t, AppState s) async {}

Future<void> _tap(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  await t.tap(f);
  await t.pumpAndSettle();
}

Future<void> _hideKeypad(WidgetTester t, AppState s) =>
    _tap(t, find.bySemanticsLabel('Hide keypad'));

Future<void> _steps(WidgetTester t, AppState s) =>
    _tap(t, find.text('Steps').first);

/// Opens a menu destination: from the drawer on a phone, the sidebar on a
/// tablet.
Act _menu(String label) => (t, s) async {
  final drawer = find.bySemanticsLabel('Open menu');
  if (drawer.evaluate().isNotEmpty) await _tap(t, drawer);
  await _tap(t, find.text(label).last);
};

final _phoneScenes = <Scene>[
  const Scene('01-workspace', _none),
  const Scene('02-results', _hideKeypad),
  const Scene('03-steps-determinant-cofactors', _steps),
  Scene('04-steps-determinant-row-reduction', (t, s) async {
    await _steps(t, s);
    await _tap(t, find.text('Row reduction'));
  }),
  const Scene('05-steps-ten-steps', _steps, line: _long),
  Scene('06-steps-working-open', (t, s) async {
    await _steps(t, s);
    await _tap(t, find.text('Show the working').first);
  }, line: 'C⁻¹·[1; 2; 3]'),
  Scene('07-inspector', (t, s) async {
    await _hideKeypad(t, s);
    await _tap(t, find.text('Inspect').first);
  }),
  Scene(
    '08-matrix-editor',
    (t, s) => _tap(t, find.bySemanticsLabel(RegExp('^Matrix A,')).first),
  ),
  Scene(
    '09-library',
    (t, s) => _tap(t, find.bySemanticsLabel('Operations library').first),
  ),
  Scene('10-library-operation', (t, s) async {
    await _tap(t, find.bySemanticsLabel('Operations library').first);
    await _tap(t, find.textContaining('Add or subtract'));
  }),
  Scene('11-menu', (t, s) => _tap(t, find.bySemanticsLabel('Open menu'))),
  Scene('12-history', _menu('History')),
  Scene('13-workspaces', _menu('Workspaces')),
  Scene('14-settings', _menu('Settings')),
  Scene('14b-settings-synced', _menu('Settings'), synced: true),
  const Scene(
    '14c-deleted-on-another-device',
    _hideKeypad,
    synced: true,
    deletedElsewhere: true,
  ),
  Scene('15-help', _menu('Help & tips')),
  const Scene('16-tour-welcome', _none, tour: true),
  Scene('17-tour-steps-and-inspector', (t, s) async {
    for (var i = 0; i < 5; i++) {
      await _tap(t, find.text('Next'));
    }
  }, tour: true),
];

/// Every picture to make: (device, dark?, scene).
final _shots = <(Device, bool, Scene)>[
  for (final sc in _phoneScenes) (iphone, false, sc),
  for (final sc in _phoneScenes.take(4)) (iphone, true, sc),
  for (final sc in _phoneScenes.take(4)) (androidSmall, false, sc),
  // A whole solution, top to bottom, with one step's working open.
  (
    tall,
    false,
    Scene('01-steps-ten-steps-full', (t, s) async {
      await _steps(t, s);
      await _tap(t, find.text('Show the working').at(1));
    }, line: _long),
  ),
  (iphoneLandscape, false, const Scene('01-workspace', _none)),
  (
    iphoneLandscape,
    false,
    Scene(
      '02-matrix-editor',
      (t, s) => _tap(t, find.bySemanticsLabel(RegExp('^Matrix A,')).first),
    ),
  ),
  (duoClosed, false, const Scene('01-workspace', _none)),
  (duoClosed, false, const Scene('02-steps-determinant', _steps)),
  (duoClosedLandscape, false, const Scene('01-workspace', _none)),
  (duoOpen, false, const Scene('01-workspace', _none)),
  (ipadMini, false, const Scene('01-workspace', _none)),
  (ipadMini, false, const Scene('02-steps', _steps)),
  (ipadMini, false, Scene('03-settings', _menu('Settings'))),
  (
    ipadMini,
    false,
    Scene('04-settings-synced', _menu('Settings'), synced: true),
  ),
  (ipad11, false, const Scene('01-workspace-inspector-no-matrix', _none)),
  (
    ipad11,
    false,
    Scene(
      '02-inspect-makes-expression-active',
      (t, s) => _tap(t, find.text('Inspect').first),
    ),
  ),
  (ipad11, false, const Scene('03-steps-in-side-pane', _steps)),
  (ipad11, false, const Scene('04-steps-ten-steps', _steps, line: _long)),
  (ipad11, false, Scene('05-library', _menu('Operations library'))),
  (ipad11, true, const Scene('01-workspace-inspector-no-matrix', _none)),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    Future<void> font(String family, List<String> files) async {
      final loader = FontLoader(family);
      for (final f in files) {
        loader.addFont(
          Future.value(ByteData.view(File(f).readAsBytesSync().buffer)),
        );
      }
      await loader.load();
    }

    await font('STIXTwoText', [
      'assets/fonts/STIXTwoText.ttf',
      'assets/fonts/STIXTwoText-Italic.ttf',
    ]);
    await font('STIXTwoMath', ['assets/fonts/STIXTwoMath-Symbols.otf']);
    await font('NotoSerifSuperscripts', [
      'assets/fonts/NotoSerif-Superscripts.ttf',
    ]);
    if (File(_systemFace).existsSync()) {
      await font('Roboto', [_systemFace]);
    } else {
      // ignore: avoid_print
      print('No system text face at $_systemFace: labels will be boxes.');
    }
    final dir = Directory(_out);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  for (final (device, dark, scene) in _shots) {
    final folder = '${device.name}${dark ? '-dark' : ''}';
    testWidgets('$folder/${scene.name}', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(device.w, device.h);
      tester.view.padding = device.pad;
      tester.view.viewPadding = device.pad;
      tester.view.display.size = const Size(4000, 4000);
      addTearDown(tester.view.reset);

      final state = AppState(MemoryStorage());
      await state.load();
      state.tutorialSeen = !scene.tour;
      state.settings.theme = dark ? 'dark' : 'light';
      if (scene.line != null) {
        state.setLineText(state.ws.lines.first.id, scene.line!);
      }
      final cloud = FakeCloud();
      final sync = SyncController(
        state: state,
        account: FakeAccount(),
        local: MemoryStorage(),
        store: (_) => cloud,
        deviceName: () async => 'iPhone',
        debounce: const Duration(hours: 1),
        poll: null,
        available: true,
      );
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MatscapeApp(key: UniqueKey(), state: state, sync: sync),
        ),
      );
      await tester.runAsync(sync.start);
      if (scene.synced) await tester.runAsync(sync.connect);
      await tester.pumpAndSettle();
      await scene.act(tester, state);
      await tester.pumpAndSettle();
      if (scene.deletedElsewhere) {
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
        await tester.runAsync(sync.sync);
        await tester.pumpAndSettle();
      }

      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(key),
      );
      final image = await tester.runAsync(
        () => boundary.toImage(pixelRatio: 2),
      );
      final bytes = await tester.runAsync(
        () => image!.toByteData(format: ui.ImageByteFormat.png),
      );
      final file = File('$_out/$folder/${scene.name}.png');
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(bytes!.buffer.asUint8List());

      expect(tester.takeException(), isNull);
      sync.dispose();
      state.flush();
      // Let any toast go before the next picture.
      await tester.pump(const Duration(seconds: 11));
    });
  }
}
