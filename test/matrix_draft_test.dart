// The matrix editor's working copy: changed or not, undo and redo.
import 'package:flutter_test/flutter_test.dart';
import 'package:matscape/app/matrix_draft.dart';

void main() {
  Cells grid() => [
    ['1', '2'],
    ['3', '4'],
  ];

  test('typing into one entry is one step to undo', () {
    final d = MatrixDraft(grid());
    d.setCell(0, 0, '5');
    d.setCell(0, 0, '56');
    expect(d.changed, isTrue);
    d.undo();
    expect(d.cells[0][0], '1');
    expect(d.canUndo, isFalse);
    expect(d.changed, isFalse);
  });

  test('another entry, or ending typing, starts a new step', () {
    final d = MatrixDraft(grid())
      ..setCell(0, 0, '5')
      ..setCell(0, 1, '6')
      ..endTyping()
      ..setCell(0, 1, '7');
    d.undo();
    expect(d.cells[0], ['5', '6']);
    d.undo();
    expect(d.cells[0], ['5', '2']);
    d.undo();
    expect(d.cells[0], ['1', '2']);
  });

  test('redo brings undone steps back, until something new is done', () {
    final d = MatrixDraft(grid())
      ..setCell(0, 0, '5')
      ..replace([
        ['0'],
      ]);
    d
      ..undo()
      ..undo();
    expect(d.canRedo, isTrue);
    d.redo();
    expect(d.cells[0][0], '5');
    d.redo();
    expect(d.cells, [
      ['0'],
    ]);
    d
      ..undo()
      ..setCell(1, 1, '9');
    expect(d.canRedo, isFalse);
  });

  test('a change that changes nothing is not a step', () {
    final d = MatrixDraft(grid())
      ..setCell(0, 0, '1')
      ..replace(grid());
    expect(d.canUndo, isFalse);
    expect(d.changed, isFalse);
  });

  test('saving makes the current cells the unchanged state', () {
    final d = MatrixDraft(grid())..setCell(0, 0, '5');
    d.markSaved();
    expect(d.changed, isFalse);
    d.undo();
    expect(d.changed, isTrue);
  });

  test('the draft never shares lists with what it was given', () {
    final saved = grid();
    final d = MatrixDraft(saved)..setCell(0, 0, '5');
    expect(saved[0][0], '1');
    d.undo();
    d.redo();
    expect(saved[0][0], '1');
  });
}
