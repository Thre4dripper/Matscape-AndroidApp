// The first-launch tour, the library's pages, the samples and reordering.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:matscape/app/app_state.dart';
import 'package:matscape/app/storage.dart';
import 'package:matscape/engine/engine.dart';
import 'package:matscape/main.dart';
import 'package:matscape/ui/library_data.dart';

Future<AppState> _launch(
  WidgetTester tester, {
  MemoryStorage? storage,
  bool seen = true,
  Size size = const Size(412, 915),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.view.display.size = const Size(3000, 3000);
  addTearDown(tester.view.reset);
  final state = AppState(storage ?? MemoryStorage());
  await state.load();
  if (seen) state.tutorialSeen = true;
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
  group('the tour', () {
    testWidgets('opens on first launch and walks to the end', (tester) async {
      final storage = MemoryStorage();
      final state = await _launch(tester, storage: storage, seen: false);
      expect(find.text('Welcome to Matscape'), findsOneWidget);
      expect(state.tutorialSeen, isFalse);

      var pages = 1;
      while (find.text('Get started').evaluate().isEmpty) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'page ${pages + 1}');
        pages++;
      }
      expect(pages, 9);
      expect(find.text('The rest is in the menu'), findsOneWidget);

      await tester.tap(find.text('Get started'));
      await _settle(tester);
      expect(find.text('Welcome to Matscape'), findsNothing);
      expect(find.text('Rotations & eigenvalues'), findsOneWidget);
      expect(state.tutorialSeen, isTrue);

      // It doesn't come back on the next launch.
      await state.flush();
      final again = AppState(MemoryStorage(storage.data));
      await again.load();
      expect(again.tutorialSeen, isTrue);
    });

    testWidgets('can be skipped, and replayed from Help', (tester) async {
      final state = await _launch(tester, seen: false);
      await tester.tap(find.text('Skip'));
      await _settle(tester);
      expect(state.tutorialSeen, isTrue);
      expect(find.text('Welcome to Matscape'), findsNothing);

      await tester.tap(find.bySemanticsLabel('Open menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Help & tips').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Take the tour again'));
      await tester.pumpAndSettle();
      expect(find.text('Welcome to Matscape'), findsOneWidget);
      await tester.tap(find.text('Skip'));
      await _settle(tester);
    });

    testWidgets('fits a small phone, a phone on its side and a tablet', (
      tester,
    ) async {
      for (final size in const [
        Size(320, 568),
        Size(844, 390),
        Size(1280, 800),
      ]) {
        await _launch(tester, seen: false, size: size);
        for (var i = 0; i < 8; i++) {
          await tester.tap(find.text('Next'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$size, page $i');
        }
        await tester.tap(find.text('Get started'));
        await _settle(tester);
        expect(tester.takeException(), isNull, reason: '$size');
      }
    });
  });

  group('the operations library', () {
    test('every example works, in radians and in degrees', () {
      final problems = <String>[];
      for (final deg in [false, true]) {
        for (final op in ops) {
          final vars = <String, Object>{};
          for (final e in op.examples) {
            final r = evaluate(
              e,
              vars: vars,
              degrees: deg,
              matrixNames: const {},
            );
            if (!r.ok) problems.add('${op.title}: $e → ${r.error}');
            final v = r.value;
            if (r.ok && r.assign != null && (v is Mat || v is double)) {
              vars[r.assign!] = v!;
            }
          }
        }
      }
      expect(problems, isEmpty);
    });

    test('every entry has a page worth reading and a sample to open', () async {
      final state = AppState(MemoryStorage());
      await state.load();
      final samples = {for (final w in state.workspaces) w.name};
      for (final op in ops) {
        expect(op.about.length, greaterThan(60), reason: op.title);
        expect(op.examples, isNotEmpty, reason: op.title);
        expect(samples, contains(op.sampleName), reason: op.title);
      }
      expect({for (final o in ops) o.title}.length, ops.length);
    });

    testWidgets('an entry opens its page; Try it out adds the examples', (
      tester,
    ) async {
      final state = await _launch(tester);
      final before = state.ws.lines.length;
      await tester.tap(find.bySemanticsLabel('Operations library'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Inverse of a square, non-singular matrix'));
      await tester.pumpAndSettle();

      // The page explains the operation and shows worked examples.
      expect(find.text('Inverse'), findsOneWidget);
      expect(find.text('How to write it'), findsOneWidget);
      expect(find.text('[4, 7; 2, 6]⁻¹'), findsOneWidget);
      // Shown with a named, properly drawn matrix as well as in one line.
      expect(find.text('A⁻¹'), findsWidgets);
      expect(find.text('Typed in one line'), findsWidgets);
      expect(find.text('For a 2×2 matrix'), findsOneWidget);
      // Nothing was typed into the workspace just by opening it.
      expect(state.ws.lines.length, before);

      // Back returns to the list, not to the workspace.
      await tester.tap(find.bySemanticsLabel('Back to operations'));
      await tester.pumpAndSettle();
      expect(find.text('Search operations'), findsOneWidget);
      expect(find.text('How to write it'), findsNothing);

      await tester.tap(find.text('Inverse of a square, non-singular matrix'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Try it out'));
      await _settle(tester);
      expect(state.ws.lines.length, before + 2);
      expect(state.ws.lines[before].text, '[4, 7; 2, 6]⁻¹');
      expect(state.lineResults[state.ws.lines.last.id]!.ok, isTrue);
      expect(tester.takeException(), isNull);
      // Let the "examples added" message go away.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      // The list has scrolled down to the new lines, and they are in
      // History.
      final view = tester.getRect(find.byType(CustomScrollView).first);
      final last = tester.getRect(
        find.bySemanticsLabel('Line ${state.ws.lines.length}. Drag to reorder'),
      );
      expect(last.bottom, lessThanOrEqualTo(view.bottom + 1));
      expect(last.top, greaterThanOrEqualTo(view.top - 1));
      expect(
        state.history.map((h) => h.text),
        containsAll(['[4, 7; 2, 6]⁻¹', '[4, 7; 2, 6]·[4, 7; 2, 6]⁻¹']),
      );
    });

    testWidgets('Insert types the operation into the active line', (
      tester,
    ) async {
      final state = await _launch(tester);
      // Scroll the active line (line 1) well out of view first.
      await tester.drag(
        find.byType(CustomScrollView).first,
        const Offset(0, -900),
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Line 1. Drag to reorder'), findsNothing);
      await tester.tap(find.bySemanticsLabel('Operations library'));
      await tester.pumpAndSettle();
      final row = find.text('Trace — sum of the diagonal');
      await tester.dragUntilVisible(
        row,
        find.byType(ListView).first,
        const Offset(0, -300),
      );
      await tester.pump();
      await tester.tap(row);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Insert tr( )'));
      await _settle(tester);
      expect(state.ws.lines.first.text, 'det(A)tr()');
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      // The list scrolled back so the line that was typed into is visible.
      final view = tester.getRect(find.byType(CustomScrollView).first);
      final line = tester.getRect(
        find.bySemanticsLabel('Line 1. Drag to reorder'),
      );
      expect(line.top, greaterThanOrEqualTo(view.top - 1));
      expect(line.bottom, lessThanOrEqualTo(view.bottom + 1));
    });

    testWidgets('every page opens without errors', (tester) async {
      final state = await _launch(tester, size: const Size(360, 640));
      await tester.tap(find.bySemanticsLabel('Operations library'));
      await tester.pumpAndSettle();
      for (final op in ops) {
        final row = find.bySemanticsLabel('${op.title}. ${op.desc}. Open');
        await tester.dragUntilVisible(
          row,
          find.byType(ListView).first,
          const Offset(0, -300),
        );
        await tester.pump();
        await tester.tap(row);
        await tester.pumpAndSettle();
        expect(find.text('How to write it'), findsOneWidget, reason: op.title);
        expect(tester.takeException(), isNull, reason: op.title);
        await tester.tap(find.bySemanticsLabel('Back to operations'));
        await tester.pumpAndSettle();
      }
      expect(state.ws.lines.first.text, 'det(A)');
    });
  });

  group('samples', () {
    test('deleted samples can be restored', () async {
      final state = AppState(MemoryStorage());
      await state.load();
      final total = state.workspaces.length;
      state.deleteWorkspace(state.workspaces[3].id);
      state.deleteWorkspace(state.workspaces[5].id);
      state.newWorkspace();
      expect(state.restoreSamples(), 2);
      expect(state.workspaces.length, total + 1);
      expect(state.restoreSamples(), 0);
      await state.flush();
    });
  });

  group('history', () {
    testWidgets('keeps a line once you move on from it', (tester) async {
      final state = await _launch(tester);
      expect(state.history, isEmpty);
      await tester.tap(find.text('C⁻¹'));
      await tester.pumpAndSettle();
      expect(state.history.map((h) => h.text), ['det(A)']);
      await tester.tap(find.text('det(A)'));
      await tester.pumpAndSettle();
      expect(state.history.map((h) => h.text), ['C⁻¹', 'det(A)']);
      // Going back and forth doesn't pile up copies.
      await tester.tap(find.text('C⁻¹'));
      await tester.pumpAndSettle();
      expect(state.history.map((h) => h.text), ['det(A)', 'C⁻¹']);
      await _settle(tester);
    });

    testWidgets('has the line you were on when you open it', (tester) async {
      final state = await _launch(tester);
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      expect(state.history.single.text, 'det(A)');
      expect(find.text('No history yet'), findsNothing);
      await _settle(tester);
    });
  });

  group('the matrix editor', () {
    testWidgets('stays the same height when rows are added or removed', (
      tester,
    ) async {
      final state = await _launch(tester);
      await tester.tap(find.bySemanticsLabel(RegExp('^Matrix A, 3 by 3')));
      await tester.pumpAndSettle();
      final done = tester.getTopLeft(find.text('Done'));
      final enter = tester.getTopLeft(find.text('Next'));
      for (var i = 0; i < 5; i++) {
        await tester.tap(find.bySemanticsLabel('Increase rows'));
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(find.text('Done')), done);
      }
      expect(state.ws.matrices.first.rows, 8);
      for (var i = 0; i < 7; i++) {
        await tester.tap(find.bySemanticsLabel('Decrease rows'));
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(find.text('Done')), done);
      }
      expect(state.ws.matrices.first.rows, 1);
      expect(tester.getTopLeft(find.text('Next')), enter);
      expect(tester.takeException(), isNull);
      await _settle(tester);
    });
  });

  group('reordering', () {
    test('lines and matrices move without changing any result', () async {
      final state = AppState(MemoryStorage());
      await state.load();
      final ws = state.ws;
      final first = ws.lines.first, det = state.lineResults[first.id]!.value;
      state.moveLine(0, 3);
      expect(ws.lines[3].id, first.id);
      expect(ws.lines.first.text, 'C⁻¹');
      expect(state.lineResults[first.id]!.value, det);

      state.moveMatrix(3, 0);
      expect(ws.matrices.map((m) => m.name), ['R', 'A', 'B', 'C']);
      expect(state.lineResults[first.id]!.value, det);

      // Out-of-range targets are clamped rather than thrown.
      state.moveLine(1, 99);
      expect(ws.lines.last.text, 'BA');
      await state.flush();
    });

    testWidgets('dragging the numbered strip moves a line', (tester) async {
      final state = await _launch(tester);
      final first = state.ws.lines.first.id;
      final handle = find.bySemanticsLabel('Line 1. Drag to reorder');
      final g = await tester.startGesture(tester.getCenter(handle));
      await tester.pump(const Duration(milliseconds: 50));
      // Down past line 2, a finger's pace at a time.
      for (var i = 0; i < 14; i++) {
        await g.moveBy(const Offset(0, 20));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await _settle(tester);
      expect(state.ws.lines.first.text, 'C⁻¹');
      expect(state.ws.lines.indexWhere((l) => l.id == first), greaterThan(0));
      expect(tester.takeException(), isNull);
    });

    testWidgets('holding a matrix card and dragging moves it', (tester) async {
      final state = await _launch(tester);
      final card = find.bySemanticsLabel(RegExp('^Matrix A, 3 by 3'));
      final g = await tester.startGesture(tester.getCenter(card));
      await tester.pump(const Duration(milliseconds: 700));
      for (var i = 0; i < 12; i++) {
        await g.moveBy(const Offset(10, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await _settle(tester);
      expect(state.ws.matrices.first.name, 'B');
      expect(state.ws.matrices[1].name, 'A');
      expect(state.ws.matrices.map((m) => m.name).toSet(), {
        'A',
        'B',
        'C',
        'R',
      });
      expect(tester.takeException(), isNull);
    });

    testWidgets('a card moves at once when dragged by its handle', (
      tester,
    ) async {
      final state = await _launch(tester);
      final handle = find.bySemanticsLabel('Drag to reorder matrix A');
      final g = await tester.startGesture(tester.getCenter(handle));
      await tester.pump(const Duration(milliseconds: 50));
      for (var i = 0; i < 12; i++) {
        await g.moveBy(const Offset(10, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await _settle(tester);
      expect(state.ws.matrices.map((m) => m.name).take(2), ['B', 'A']);
      // Touching the handle doesn't open the editor.
      expect(find.text('Done'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('in the sidebar grid, the handle drags a card too', (
      tester,
    ) async {
      final state = await _launch(tester, size: const Size(820, 1180));
      final target = tester.getCenter(
        find.bySemanticsLabel(RegExp('^Matrix C, 3 by 3')),
      );
      final g = await tester.startGesture(
        tester.getCenter(find.bySemanticsLabel('Drag to reorder matrix A')),
      );
      await tester.pump(const Duration(milliseconds: 50));
      await g.moveBy(const Offset(-30, 30));
      await tester.pump();
      await g.moveTo(target - const Offset(10, 10));
      await tester.pump();
      await g.moveTo(target);
      await tester.pump();
      await g.up();
      await _settle(tester);
      // A took C's place, in the second row of the grid.
      expect(state.ws.matrices.map((m) => m.name), ['B', 'C', 'A', 'R']);
      expect(tester.takeException(), isNull);
    });

    testWidgets('in the sidebar, a held card swaps with the one under it', (
      tester,
    ) async {
      final state = await _launch(tester, size: const Size(820, 1180));
      final a = find.bySemanticsLabel(RegExp('^Matrix A, 3 by 3'));
      final b = find.bySemanticsLabel(RegExp('^Matrix B, 2 by 3'));
      final target = tester.getCenter(b);
      final g = await tester.startGesture(tester.getCenter(a));
      await tester.pump(const Duration(milliseconds: 500));
      await g.moveTo(target - const Offset(20, 0));
      await tester.pump();
      await g.moveTo(target);
      await tester.pump();
      await g.up();
      await _settle(tester);
      expect(state.ws.matrices.map((m) => m.name).take(2), ['B', 'A']);
      expect(tester.takeException(), isNull);
    });
  });
}
