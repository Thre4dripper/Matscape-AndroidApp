// The adaptive layouts: which one each device gets, and that each one
// shows the right panes. Device sizes are the ones on the design's board.
import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:matscape/app/app_state.dart';
import 'package:matscape/app/storage.dart';
import 'package:matscape/main.dart';
import 'package:matscape/ui/glance.dart';
import 'package:matscape/ui/inspector_screen.dart';
import 'package:matscape/ui/keypad.dart';
import 'package:matscape/ui/layout.dart';
import 'package:matscape/ui/side_pane.dart';

DisplayFeature _fold(
  double w,
  double h, {
  required bool vertical,
  bool half = false,
  double thickness = 0,
}) => DisplayFeature(
  bounds: vertical
      ? Rect.fromLTWH((w - thickness) / 2, 0, thickness, h)
      : Rect.fromLTWH(0, (h - thickness) / 2, w, thickness),
  type: thickness > 0 ? DisplayFeatureType.hinge : DisplayFeatureType.fold,
  state: half
      ? DisplayFeatureState.postureHalfOpened
      : DisplayFeatureState.postureFlat,
);

AppLayout _layout(
  double w,
  double h, {
  List<DisplayFeature> features = const [],
  Size? display,
}) => LayoutInfo.compute(
  size: Size(w, h),
  features: features,
  displaySize: display ?? const Size(1400, 1400),
).layout;

/// Launches the app in a window of [w]×[h] logical pixels.
Future<AppState> _launch(
  WidgetTester tester,
  double w,
  double h, {
  List<DisplayFeature> features = const [],
  bool cover = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(w, h);
  tester.view.displayFeatures = features;
  tester.view.display.size = cover ? Size(w, h) : const Size(3000, 3000);
  addTearDown(tester.view.reset);
  final state = AppState(MemoryStorage());
  await state.load();
  addTearDown(state.flush);
  await tester.pumpWidget(MatscapeApp(key: UniqueKey(), state: state));
  await tester.pumpAndSettle();
  return state;
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  group('choosing a layout', () {
    test('phones and closed foldables are compact', () {
      expect(_layout(402, 874), AppLayout.compact); // iPhone
      expect(_layout(412, 915), AppLayout.compact); // Android phone
      expect(_layout(375, 812), AppLayout.compact); // iPhone Duo, closed
      expect(_layout(368, 850), AppLayout.compact); // book foldable, closed
      expect(_layout(360, 640), AppLayout.compact);
    });

    test('tablets get a sidebar, large ones an inspector too', () {
      expect(_layout(744, 1133), AppLayout.medium); // iPad mini
      expect(_layout(800, 1280), AppLayout.medium); // Android tablet
      expect(_layout(1180, 820), AppLayout.expanded); // iPad 11″
      expect(_layout(1376, 1032), AppLayout.expanded); // iPad 13″
      expect(_layout(1032, 1376), AppLayout.expanded); // iPad 13″, portrait
    });

    test('a foldable opened flat is a book', () {
      final f = [_fold(744, 840, vertical: true)];
      final info = LayoutInfo.compute(size: const Size(744, 840), features: f);
      expect(info.layout, AppLayout.book);
      // A seamless fold still gets a 24px strip kept clear.
      expect(info.fold.width, minHinge);
      expect(info.fold.center.dx, 372);
      expect(
        _layout(870, 652, features: [_fold(870, 652, vertical: true)]),
        AppLayout.book,
      );
    });

    test('half-folded on a desk is tabletop; flat it is a normal phone', () {
      expect(
        _layout(
          412,
          915,
          features: [_fold(412, 915, vertical: false, half: true)],
        ),
        AppLayout.tabletop,
      );
      expect(
        _layout(412, 915, features: [_fold(412, 915, vertical: false)]),
        AppLayout.compact,
      );
      expect(
        _layout(
          840,
          744,
          features: [_fold(840, 744, vertical: false, half: true)],
        ),
        AppLayout.tabletop,
      );
      // A physical hinge always splits the screen, even when flat.
      expect(
        _layout(
          540,
          1400,
          features: [_fold(540, 1400, vertical: false, thickness: 30)],
        ),
        AppLayout.tabletop,
      );
    });

    test('only a tiny screen is a glance, not a small window', () {
      expect(
        _layout(300, 340, display: const Size(300, 340)),
        AppLayout.glance,
      );
      // Same window size in split-screen on a normal phone stays usable.
      expect(
        _layout(360, 380, display: const Size(360, 800)),
        AppLayout.compact,
      );
    });

    test('a phone on its side puts the keypad beside the content', () {
      expect(_layout(874, 402), AppLayout.landscape);
      expect(_layout(915, 412), AppLayout.landscape);
      // A tablet in landscape is tall enough for the normal layouts.
      expect(_layout(1133, 744), AppLayout.expanded);
    });

    test('overlays stay on one side of a fold', () {
      const size = Size(744, 840);
      final book = LayoutInfo.compute(
        size: size,
        features: [_fold(744, 840, vertical: true)],
      );
      expect(book.overlayRect(size), const Rect.fromLTRB(0, 0, 360, 840));
      const flat = LayoutInfo(AppLayout.compact);
      expect(flat.overlayRect(size), Offset.zero & size);
    });
  });

  group('what each layout shows', () {
    testWidgets('medium: sidebar; screens replace the workspace column', (
      tester,
    ) async {
      await _launch(tester, 744, 1133);
      expect(find.byType(SidePane), findsOneWidget);
      expect(find.byType(InspectorScreen), findsNothing);
      expect(find.bySemanticsLabel('Open menu'), findsNothing);
      expect(find.text('123'), findsOneWidget);

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Number format'), findsOneWidget);
      expect(find.byType(SidePane), findsOneWidget);
      expect(find.byType(Keypad), findsNothing);

      await tester.tap(find.bySemanticsLabel('Back to workspace'));
      await tester.pumpAndSettle();
      expect(find.byType(Keypad), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _settle(tester);
    });

    testWidgets('expanded: inspector follows the workspace', (tester) async {
      final state = await _launch(tester, 1180, 820);
      expect(find.byType(SidePane), findsOneWidget);
      // Line 1 is a number, so the inspector shows the latest matrix result.
      expect(find.text('Inspector · Line 7'), findsOneWidget);

      // A screen opens in the detail pane, beside the workspace.
      await tester.tap(find.text('Operations library'));
      await tester.pumpAndSettle();
      expect(find.text('Search operations'), findsOneWidget);
      expect(find.byType(Keypad), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Close panel'));
      await tester.pumpAndSettle();
      expect(find.text('Inspector · Line 7'), findsOneWidget);

      // With no matrix results it falls back to the first matrix.
      for (final l in state.ws.lines) {
        state.setLineText(l.id, '');
      }
      await tester.pumpAndSettle();
      expect(find.text('Inspector · Matrix A'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _settle(tester);
    });

    testWidgets('expanded and wide: number pad stays beside a second page', (
      tester,
    ) async {
      await _launch(tester, 1376, 1032);
      // The 123 tab is gone because the number pad is always visible.
      expect(find.text('123'), findsNothing);
      Finder key(String label) =>
          find.descendant(of: find.byType(Keypad), matching: find.text(label));
      expect(key('7'), findsOneWidget);
      expect(key('det'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _settle(tester);
    });

    testWidgets('book: workspace left of the fold, inspector right of it', (
      tester,
    ) async {
      await _launch(
        tester,
        744,
        840,
        features: [_fold(744, 840, vertical: true)],
      );
      expect(find.byType(SidePane), findsNothing);
      expect(find.bySemanticsLabel('Open menu'), findsOneWidget);
      expect(find.byType(InspectorScreen), findsOneWidget);
      // Nothing is placed across the fold.
      expect(tester.getRect(find.byType(Keypad)).right, lessThanOrEqualTo(360));
      expect(
        tester.getRect(find.byType(InspectorScreen)).left,
        greaterThanOrEqualTo(384),
      );
      expect(tester.takeException(), isNull);
      await _settle(tester);
    });

    testWidgets('tabletop: keypad fills the lower half and stays put', (
      tester,
    ) async {
      await _launch(
        tester,
        412,
        915,
        features: [_fold(412, 915, vertical: false, half: true)],
      );
      final keypad = tester.getRect(find.byType(Keypad));
      expect(keypad.top, greaterThanOrEqualTo(915 / 2));
      expect(keypad.bottom, 915);
      expect(find.bySemanticsLabel('Hide keypad'), findsNothing);

      // A screen takes the upper half; the keypad stays below the fold.
      await tester.tap(find.bySemanticsLabel('Operations library'));
      await tester.pumpAndSettle();
      expect(find.text('Search operations'), findsOneWidget);
      expect(find.byType(Keypad), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _settle(tester);
    });

    testWidgets('glance: read-only latest results', (tester) async {
      await _launch(tester, 300, 340, cover: true);
      expect(find.byType(GlanceView), findsOneWidget);
      expect(find.text('Open the phone to edit'), findsOneWidget);
      expect(find.byType(Keypad), findsNothing);
      expect(find.text('M = BBᵀ'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _settle(tester);
    });

    testWidgets('landscape phone: keypad on the right', (tester) async {
      await _launch(tester, 874, 402);
      final keypad = tester.getRect(find.byType(Keypad));
      expect(keypad.left, greaterThan(874 / 2 - 1));
      expect(keypad.height, 402);
      expect(find.bySemanticsLabel('Hide keypad'), findsNothing);
      expect(tester.takeException(), isNull);
      await _settle(tester);
    });
  });

  group('changing layout', () {
    testWidgets('the matrix editor opens in every layout', (tester) async {
      final cases = <(double, double, List<DisplayFeature>)>[
        (402, 874, const []),
        (874, 402, const []),
        (744, 1133, const []),
        (1376, 1032, const []),
        (744, 840, [_fold(744, 840, vertical: true)]),
        (840, 744, [_fold(840, 744, vertical: false, half: true)]),
        (412, 915, [_fold(412, 915, vertical: false, half: true)]),
      ];
      for (final (w, h, features) in cases) {
        final state = await _launch(tester, w, h, features: features);
        await tester.tap(
          find.bySemanticsLabel(RegExp('^Matrix A, 3 by 3')).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('5').last);
        await tester.pump();
        expect(state.ws.matrices.first.cells[0][0], '5', reason: '$w×$h');
        expect(tester.takeException(), isNull, reason: '$w×$h');
        await tester.tap(find.text('Done').last);
        await _settle(tester);
      }
    });

    testWidgets('unfolding with a screen open keeps the app consistent', (
      tester,
    ) async {
      await _launch(tester, 368, 850);
      await tester.tap(find.bySemanticsLabel('Open menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Help & tips').last);
      await tester.pumpAndSettle();
      expect(find.text('Try these'.toUpperCase()), findsOneWidget);

      // Open the foldable: the pushed screen closes, panes appear.
      tester.view.physicalSize = const Size(744, 840);
      tester.view.displayFeatures = [_fold(744, 840, vertical: true)];
      await tester.pumpAndSettle();
      expect(find.byType(InspectorScreen), findsOneWidget);
      expect(find.text('Try these'.toUpperCase()), findsNothing);

      // Fold it again: back to a single column, nothing left over.
      tester.view.physicalSize = const Size(368, 850);
      tester.view.displayFeatures = const [];
      await tester.pumpAndSettle();
      expect(find.byType(InspectorScreen), findsNothing);
      expect(find.byType(Keypad), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _settle(tester);
    });

    testWidgets('rotating a phone keeps what was typed', (tester) async {
      final state = await _launch(tester, 402, 874);
      state.setLineText(state.ws.lines.first.id, 'tr(A)');
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(874, 402);
      await tester.pumpAndSettle();
      expect(state.ws.lines.first.text, 'tr(A)');
      expect(state.lineResults[state.ws.lines.first.id]!.value, 12);
      expect(find.text('tr(A)'), findsOneWidget);
      expect(find.byType(Keypad), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _settle(tester);
    });
  });
}
