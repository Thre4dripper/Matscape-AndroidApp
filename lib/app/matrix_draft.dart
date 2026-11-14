/// The matrix editor's working copy: what the user is changing before they
/// press Done, with undo and redo for the time the editor is open.
library;

typedef Cells = List<List<String>>;

Cells copyCells(Cells c) => [for (final r in c) List.of(r)];

bool sameCells(Cells a, Cells b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i].length != b[i].length) return false;
    for (var j = 0; j < a[i].length; j++) {
      if (a[i][j] != b[i][j]) return false;
    }
  }
  return true;
}

class MatrixDraft {
  MatrixDraft(Cells saved)
    : _saved = copyCells(saved),
      _cells = copyCells(saved);

  Cells _saved;
  Cells _cells;
  final _undo = <Cells>[], _redo = <Cells>[];

  /// The entry being typed into. Typing into one entry is one step to undo,
  /// however many keys it took.
  (int, int)? _typing;

  /// The cells as they are now. Read only: change them through the methods.
  Cells get cells => _cells;
  int get rows => _cells.length;
  int get cols => _cells[0].length;

  /// Whether the cells differ from what was saved.
  bool get changed => !sameCells(_cells, _saved);
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  /// Sets one entry. Consecutive changes to the same entry undo together.
  void setCell(int i, int j, String text) {
    if (_cells[i][j] == text) return;
    if (_typing != (i, j)) {
      _push();
      _typing = (i, j);
    }
    _cells[i][j] = text;
  }

  /// Replaces every entry at once (a resize, a fill), as one step.
  void replace(Cells next) {
    if (sameCells(next, _cells)) return;
    _push();
    _cells = copyCells(next);
  }

  /// The next change starts a new step, even in the same entry.
  void endTyping() => _typing = null;

  void undo() {
    if (_undo.isEmpty) return;
    _redo.add(_cells);
    _cells = _undo.removeLast();
    _typing = null;
  }

  void redo() {
    if (_redo.isEmpty) return;
    _undo.add(_cells);
    _cells = _redo.removeLast();
    _typing = null;
  }

  /// What is here now has been saved.
  void markSaved() => _saved = copyCells(_cells);

  void _push() {
    _undo.add(copyCells(_cells));
    _redo.clear();
    _typing = null;
  }
}
