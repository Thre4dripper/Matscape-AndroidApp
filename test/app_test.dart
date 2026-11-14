import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:matscape/app/app_state.dart';
import 'package:matscape/app/storage.dart';
import 'package:matscape/main.dart';

Future<AppState> _launch(WidgetTester tester, [MemoryStorage? storage]) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
  final state = AppState(storage ?? MemoryStorage());
  await state.load();
  // The first-launch tour has its own tests (tour_test.dart).
  state.tutorialSeen = true;
  await tester.pumpWidget(MatscapeApp(state: state));
  await tester.pumpAndSettle();
  // Let the debounced save finish before the test ends.
  addTearDown(state.flush);
  return state;
}

/// Taps a keypad key by its visible label.
Future<void> _key(WidgetTester tester, String label) async {
  await tester.tap(find.text(label).last);
  await tester.pump();
}

void main() {
  testWidgets('first launch shows the starter workspace with live results', (
    tester,
  ) async {
    final state = await _launch(tester);
    expect(find.text('Rotations & eigenvalues'), findsOneWidget);
    expect(state.ws.matrices.map((m) => m.name), ['A', 'B', 'C', 'R']);
    // det(A) on line 1 evaluates to 43.
    expect(
      state.lineResults[state.ws.lines.first.id]!.value,
      closeTo(43, 1e-9),
    );
    expect(find.text('43'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('the keypad types into a new line and Enter records history', (
    tester,
  ) async {
    final state = await _launch(tester);
    final before = state.ws.lines.length;

    // Enter on line 1 opens a fresh line 2 and focuses it.
    await tester.tap(find.bySemanticsLabel('Enter — next line'));
    await tester.pumpAndSettle();
    expect(state.ws.lines.length, before + 1);
    expect(state.history.first.text, 'det(A)');

    for (final k in ['2', '+', '3']) {
      await _key(tester, k);
    }
    final line = state.ws.lines[1];
    expect(line.text, '2+3');
    expect(state.lineResults[line.id]!.value, 5);

    // Function keys land the caret inside their brackets.
    await tester.tap(find.bySemanticsLabel('Delete'));
    await tester.tap(find.bySemanticsLabel('Delete'));
    await tester.tap(find.bySemanticsLabel('Delete'));
    await tester.tap(find.text('Matrix'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Determinant'));
    await tester.tap(find.bySemanticsLabel('Insert matrix C'));
    await tester.pump();
    expect(line.text, 'det(C)');
    expect(state.lineResults[line.id]!.value, closeTo(6, 1e-9));
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('a matrix edit is saved only by Done', (tester) async {
    final state = await _launch(tester);
    await tester.tap(find.bySemanticsLabel(RegExp('^Matrix A, 3 by 3')));
    await tester.pumpAndSettle();
    expect(find.text('Matrix'), findsWidgets);

    // The first entry is selected; typing replaces it, in the editor only.
    await _key(tester, '5');
    expect(state.ws.matrices.first.cells[0][0], '4');
    expect(
      find.text('Not saved yet · Done saves your changes'),
      findsOneWidget,
    );
    expect(
      state.lineResults[state.ws.lines.first.id]!.value,
      closeTo(43, 1e-9),
    );

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(state.ws.matrices.first.cells[0][0], '5');
    expect(find.text('58'), findsOneWidget); // det with a11 = 5
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('leaving the editor with changes asks first', (tester) async {
    final state = await _launch(tester);
    Future<void> open() async {
      await tester.tap(find.bySemanticsLabel(RegExp('^Matrix A, 3 by 3')));
      await tester.pumpAndSettle();
      await _key(tester, '5');
      // The system back gesture.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Save changes to A?'), findsOneWidget);
    }

    // Discard: nothing changes.
    await open();
    await tester.tap(find.text('Discard changes'));
    await tester.pumpAndSettle();
    expect(find.text('Save changes to A?'), findsNothing);
    expect(find.text('Done'), findsNothing);
    expect(state.ws.matrices.first.cells[0][0], '4');

    // Dismissing the question keeps the editor open with the change.
    await open();
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    expect(find.text('Done'), findsOneWidget);
    expect(state.ws.matrices.first.cells[0][0], '4');

    // Save: kept.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(find.text('Done'), findsNothing);
    expect(state.ws.matrices.first.cells[0][0], '5');

    // Without changes it just closes.
    await tester.tap(find.bySemanticsLabel(RegExp('^Matrix A, 3 by 3')));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Done'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('undo and redo step through the editor session', (tester) async {
    final state = await _launch(tester);
    await tester.tap(find.bySemanticsLabel(RegExp('^Matrix A, 3 by 3')));
    await tester.pumpAndSettle();
    String cell(int i, int j) {
      final grid = find.bySemanticsLabel(
        RegExp('^Row ${i + 1}, column ${j + 1}: '),
      );
      return tester.getSemantics(grid).label.split(': ').last.split(',').first;
    }

    await _key(tester, '5');
    await _key(tester, '6');
    await tester.tap(find.bySemanticsLabel('Next entry'));
    await tester.pumpAndSettle();
    await _key(tester, '7');
    expect([cell(0, 0), cell(0, 1)], ['56', '7']);

    // A fill is one step too.
    await tester.tap(find.text('Fill'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Identity'));
    await tester.pumpAndSettle();
    expect([cell(0, 0), cell(0, 1)], ['1', '0']);

    await tester.tap(find.bySemanticsLabel('Undo'));
    await tester.pumpAndSettle();
    expect([cell(0, 0), cell(0, 1)], ['56', '7']);
    await tester.tap(find.bySemanticsLabel('Undo'));
    await tester.tap(find.bySemanticsLabel('Undo'));
    await tester.pumpAndSettle();
    expect([cell(0, 0), cell(0, 1)], ['4', '1']);
    expect(find.text('Not saved yet · Done saves your changes'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Redo'));
    await tester.pumpAndSettle();
    expect(cell(0, 0), '56');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(state.ws.matrices.first.cells[0].take(2), ['56', '1']);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('back closes the menu first, whatever the keypad is doing', (
    tester,
  ) async {
    await _launch(tester);
    Future<void> back() async {
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
    }

    Future<void> openMenu() async {
      await tester.tap(find.bySemanticsLabel('Open menu'));
      await tester.pumpAndSettle();
      expect(find.text('Help & tips'), findsOneWidget);
    }

    // Keypad up: the menu closes, the keypad stays.
    await openMenu();
    await back();
    expect(find.text('Help & tips'), findsNothing);
    expect(find.text('Show keypad'), findsNothing);

    // Keypad down: the menu closes, and the app stays open.
    await back();
    expect(find.text('Show keypad'), findsOneWidget);
    await openMenu();
    await back();
    expect(find.text('Help & tips'), findsNothing);
    expect(find.text('Show keypad'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('back puts the keypad away before leaving the app', (
    tester,
  ) async {
    await _launch(tester);
    expect(find.text('Show keypad'), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Show keypad'), findsOneWidget);
    expect(find.text('Rotations & eigenvalues'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('changes are saved and restored on the next launch', (
    tester,
  ) async {
    final storage = MemoryStorage();
    final state = await _launch(tester, storage);
    state.setLineText(state.ws.lines.first.id, 'tr(A)');
    state.updateSettings((s) => s.degrees = true);
    await state.flush();

    final saved = jsonDecode(storage.data!) as Map<String, dynamic>;
    expect(saved['settings']['degrees'], isTrue);

    final again = AppState(MemoryStorage(storage.data));
    await again.load();
    expect(again.ws.lines.first.text, 'tr(A)');
    expect(again.settings.degrees, isTrue);
    expect(again.lineResults[again.ws.lines.first.id]!.value, 12);
  });

  testWidgets('every menu screen opens without errors', (tester) async {
    await _launch(tester);
    for (final (item, title) in const [
      ('Workspaces', 'Workspaces'),
      ('History', 'History'),
      ('Operations library', 'Operations'),
      ('Settings', 'Settings'),
      ('Help & tips', 'Help & tips'),
    ]) {
      await tester.tap(find.bySemanticsLabel('Open menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(item).last);
      await tester.pumpAndSettle();
      expect(find.text(title), findsWidgets, reason: item);
      expect(tester.takeException(), isNull, reason: item);
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
    }
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('the inspector opens from a matrix result', (tester) async {
    final state = await _launch(tester);
    // Line 2 (C⁻¹) is a matrix result with an Inspect action.
    await tester.dragUntilVisible(
      find.text('Inspect').first,
      find.byType(CustomScrollView).first,
      const Offset(0, -200),
    );
    await tester.pump();
    await tester.tap(find.text('Inspect').first);
    await tester.pumpAndSettle();
    expect(find.text('Expression 2'), findsOneWidget);
    expect(find.text('PROPERTIES'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(state.ws.lines[1].text, 'C⁻¹');
  });
}
