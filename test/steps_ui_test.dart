// The Steps button under a result and the screen it opens.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:matscape/app/app_state.dart';
import 'package:matscape/app/storage.dart';
import 'package:matscape/main.dart';
import 'package:matscape/ui/steps_screen.dart';

Future<AppState> _launch(
  WidgetTester tester, {
  Size size = const Size(402, 874),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.view.display.size = const Size(3000, 3000);
  addTearDown(tester.view.reset);
  final state = AppState(MemoryStorage());
  await state.load();
  state.tutorialSeen = true;
  addTearDown(state.flush);
  await tester.pumpWidget(MatscapeApp(key: UniqueKey(), state: state));
  await tester.pumpAndSettle();
  return state;
}

/// Picks a method. The names scroll sideways when they don't all fit.
Future<void> _pick(WidgetTester tester, String method) async {
  final tab = find.text(method).first;
  await tester.ensureVisible(tab);
  await tester.pumpAndSettle();
  await tester.tap(tab);
  await tester.pumpAndSettle();
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('Steps opens the working for a result', (tester) async {
    await _launch(tester);
    // Line 1 is det(A): a number, with one step.
    await tester.tap(find.text('Steps').first);
    await tester.pumpAndSettle();
    expect(find.text('Steps · Expression 1'), findsOneWidget);
    expect(find.text('Determinant'), findsOneWidget);
    // A single step starts with its working open, on the first method.
    expect(find.text('Hide the working'), findsOneWidget);
    expect(find.text('Cofactor expansion'), findsOneWidget);
    expect(find.textContaining('Expand along row 2'), findsOneWidget);

    // The other method shows the row operations instead.
    await _pick(tester, 'Row reduction');
    expect(find.textContaining('Expand along row 2'), findsNothing);
    expect(find.text('Start'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Copy the steps'));
    await tester.pump();
    expect(find.text('Steps copied'), findsOneWidget);
    expect(tester.takeException(), isNull);
    // Let the toast go away.
    await tester.pump(const Duration(seconds: 3));
    await _settle(tester);
  });

  testWidgets('a longer expression lists every operation', (tester) async {
    final state = await _launch(tester);
    state.setLineText(state.ws.lines.first.id, 'det(A·Aᵀ − 2I)');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Steps').first);
    await tester.pumpAndSettle();
    expect(find.text('4 STEPS'), findsOneWidget);
    expect(find.text('Transpose'), findsOneWidget);
    expect(find.text('Multiply the matrices'), findsOneWidget);
    expect(find.text('Subtract 2I'), findsOneWidget);
    // Working stays closed until asked for.
    expect(find.text('Hide the working'), findsNothing);
    await tester.tap(find.text('Show the working').first);
    await tester.pumpAndSettle();
    expect(find.text('Hide the working'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _settle(tester);
  });

  testWidgets('a value on its own has no Steps button', (tester) async {
    final state = await _launch(tester);
    final before = find.text('Steps').evaluate().length;
    state.setLineText(state.ws.lines.first.id, 'A');
    await tester.pumpAndSettle();
    expect(find.text('Steps').evaluate().length, before - 1);
    await _settle(tester);
  });

  testWidgets('Save keeps its full name for screen readers', (tester) async {
    await _launch(tester, size: const Size(375, 812));
    expect(find.text('Save'), findsWidgets);
    expect(find.bySemanticsLabel('Save as matrix'), findsWidgets);
    expect(tester.takeException(), isNull);
    await _settle(tester);
  });

  testWidgets('on a tablet the steps open beside the workspace', (
    tester,
  ) async {
    await _launch(tester, size: const Size(1180, 820));
    await tester.tap(find.text('Steps').first);
    await tester.pumpAndSettle();
    expect(find.text('Steps · Expression 1'), findsOneWidget);
    expect(find.text('EXPRESSIONS'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Close panel'));
    await tester.pumpAndSettle();
    expect(find.text('Inspector · Expression 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _settle(tester);
  });

  testWidgets('a long chain through numbers and matrices draws on a phone', (
    tester,
  ) async {
    // A small phone, and tall enough that every step is built.
    final state = await _launch(tester, size: const Size(360, 20000));
    final id = state.ws.lines.first.id;
    for (final text in const [
      'tr(inv(det(A)·C − tr(C)·A)·Aᵀ)·(B·Bᵀ − det(B·Bᵀ)·I)⁻¹·B',
      '[det(A), tr(A); rank(A), norm1(A)]·[1, 2; 3, 4]⁻¹ + dot(row(A, 1), row(C, 2))·I(2)',
      'solve(det(C)·A + rank(A)·I, tr(A)·[1; 2; 3] − A·[1; 2; 3])',
      'det(kron(B·Bᵀ, [2, 1; 1, 3]))·adj(A)·A⁻¹ ÷ det(A)^2',
    ]) {
      state.setLineText(id, text);
      await tester.pumpAndSettle();
      expect(state.lineResults[id]!.ok, isTrue, reason: text);
      final sol = state.solutionFor(id)!;
      expect(sol.steps.length, greaterThan(5), reason: text);

      await tester.tap(find.text('Steps').first);
      await tester.pumpAndSettle();
      expect(
        find.text('${sol.steps.length} STEPS'),
        findsOneWidget,
        reason: text,
      );
      expect(find.text('ANSWER'), findsOneWidget);
      while (find.text('Show the working').evaluate().isNotEmpty) {
        await tester.tap(find.text('Show the working').first);
        await tester.pumpAndSettle();
      }
      for (final st in sol.steps) {
        for (final m in st.methods.skip(1)) {
          await _pick(tester, m.name);
        }
      }
      expect(tester.takeException(), isNull, reason: text);
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
    }
    await _settle(tester);
  });

  testWidgets('long working shows a loader, then every line of it', (
    tester,
  ) async {
    // Tall enough that every step is built.
    final state = await _launch(tester, size: const Size(402, 6000));
    final id = state.ws.lines.first.id;
    // An 8×8 determinant: its cofactor expansion runs to thousands of lines.
    state.setLineText(
      id,
      'det(kron([2, 1; 1, 3], [2, 1, 0, 1; 1, 3, 1, 0; 0, 1, 4, 1; 1, 0, 1, 5]) + I(8))',
    );
    await tester.pumpAndSettle();
    final sol = state.solutionFor(id)!;
    final det = sol.steps.length - 1;
    expect(sol.steps[det].methods.map((m) => m.name), [
      'Row reduction',
      'Cofactor expansion',
    ]);

    await tester.tap(find.text('Steps').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show the working').last);
    await tester.pumpAndSettle();
    // Row reduction is quick and appears at once.
    expect(find.text('Working out the full solution…'), findsNothing);

    // The expansion is built away from the screen, behind a loader. (The
    // loader keeps animating, so this can't wait for the screen to settle.)
    await tester.ensureVisible(find.text('Cofactor expansion'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cofactor expansion'));
    await tester.pump();
    expect(find.text('Working out the full solution…'), findsOneWidget);
    final lines = await tester.runAsync(() => state.workOffThread(id, det, 1));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 400)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Working out the full solution…'), findsNothing);
    expect(lines!.length, greaterThan(3000));
    // Only what is on screen is laid out, however long the working is.
    expect(find.textContaining('Expand along row'), findsWidgets);
    expect(tester.takeException(), isNull);
    await _settle(tester);
  });

  testWidgets('every sample line draws its steps and all its working', (
    tester,
  ) async {
    // Tall enough that a whole solution is built at once.
    final state = await _launch(tester, size: const Size(402, 12000));
    final nav = Navigator.of(tester.element(find.text('EXPRESSIONS')));
    var shown = 0;
    for (final ws in [...state.workspaces]) {
      state.openWorkspace(ws.id);
      await tester.pumpAndSettle();
      for (final l in [...state.ws.lines]) {
        if (!state.hasSteps(l.id)) continue;
        nav.push(
          MaterialPageRoute<void>(builder: (_) => StepsScreen(lineId: l.id)),
        );
        await tester.pumpAndSettle();
        // Open every step, then walk through each of its methods.
        while (find.text('Show the working').evaluate().isNotEmpty) {
          await tester.ensureVisible(find.text('Show the working').first);
          await tester.tap(find.text('Show the working').first);
          await tester.pumpAndSettle();
        }
        final sol = state.solutionFor(l.id)!;
        for (final st in sol.steps) {
          for (final m in st.methods.skip(1)) {
            await _pick(tester, m.name);
          }
        }
        expect(tester.takeException(), isNull, reason: '${ws.name}: ${l.text}');
        shown++;
        nav.pop();
        await tester.pumpAndSettle();
      }
    }
    expect(shown, greaterThan(50));
    await _settle(tester);
  });
}
