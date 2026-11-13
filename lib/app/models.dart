import 'dart:math';

final _rng = Random();

String uid() =>
    _rng.nextInt(1 << 32).toRadixString(36) +
    _rng.nextInt(1 << 32).toRadixString(36);

/// A user matrix. Cells hold the text the user typed, so entries can be
/// expressions like `sin(π/6)`.
class MatrixModel {
  MatrixModel({String? id, required this.name, required this.cells})
    : id = id ?? uid();

  factory MatrixModel.of(String name, List<List<Object>> rows) => MatrixModel(
    name: name,
    cells: [
      for (final r in rows) [for (final x in r) '$x'],
    ],
  );

  factory MatrixModel.fromJson(Map<String, dynamic> j) => MatrixModel(
    id: j['id'] as String?,
    name: j['name'] as String,
    cells: [
      for (final r in j['cells'] as List) [for (final x in r as List) '$x'],
    ],
  );

  final String id;
  String name;
  List<List<String>> cells;

  int get rows => cells.length;
  int get cols => cells[0].length;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'cells': cells};
}

class LineModel {
  LineModel(this.text, {String? id}) : id = id ?? uid();

  factory LineModel.fromJson(Map<String, dynamic> j) =>
      LineModel(j['text'] as String, id: j['id'] as String?);

  final String id;
  String text;

  Map<String, dynamic> toJson() => {'id': id, 'text': text};
}

class Workspace {
  Workspace({
    String? id,
    required this.name,
    required this.updated,
    required this.matrices,
    required this.lines,
  }) : id = id ?? uid();

  factory Workspace.fromJson(Map<String, dynamic> j) => Workspace(
    id: j['id'] as String?,
    name: j['name'] as String,
    updated: j['updated'] as int,
    matrices: [
      for (final m in j['matrices'] as List)
        MatrixModel.fromJson(m as Map<String, dynamic>),
    ],
    lines: [
      for (final l in j['lines'] as List)
        LineModel.fromJson(l as Map<String, dynamic>),
    ],
  );

  final String id;
  String name;

  /// Last change, milliseconds since epoch.
  int updated;
  List<MatrixModel> matrices;
  List<LineModel> lines;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'updated': updated,
    'matrices': matrices,
    'lines': lines,
  };
}

class HistoryItem {
  HistoryItem(this.text, this.summary, this.ts);

  factory HistoryItem.fromJson(Map<String, dynamic> j) =>
      HistoryItem(j['text'] as String, j['summary'] as String, j['ts'] as int);

  final String text;
  final String summary;
  final int ts;

  Map<String, dynamic> toJson() => {'text': text, 'summary': summary, 'ts': ts};
}

class Settings {
  /// 'system', 'light' or 'dark'.
  String theme = 'system';
  bool degrees = false;

  /// Show fractions, roots and π where possible instead of decimals.
  bool exact = true;
  int precision = 4;
  int defRows = 3;
  int defCols = 3;
  bool defIdentity = false;

  void load(Map<String, dynamic> j) {
    theme = j['theme'] as String? ?? theme;
    degrees = j['degrees'] as bool? ?? degrees;
    exact = j['exact'] as bool? ?? exact;
    precision = j['precision'] as int? ?? precision;
    defRows = j['defRows'] as int? ?? defRows;
    defCols = j['defCols'] as int? ?? defCols;
    defIdentity = j['defIdentity'] as bool? ?? defIdentity;
  }

  Map<String, dynamic> toJson() => {
    'theme': theme,
    'degrees': degrees,
    'exact': exact,
    'precision': precision,
    'defRows': defRows,
    'defCols': defCols,
    'defIdentity': defIdentity,
  };
}

/// Starter workspaces shown on first launch.
List<Workspace> seedWorkspaces() {
  final now = DateTime.now().millisecondsSinceEpoch;
  const day = 86400000;
  List<LineModel> lines(List<String> t) => [for (final s in t) LineModel(s)];
  return [
    Workspace(
      name: 'Rotations & eigenvalues',
      updated: now,
      matrices: [
        MatrixModel.of('A', [
          [4, 1, 2],
          [1, 3, 0],
          [2, 0, 5],
        ]),
        MatrixModel.of('B', [
          [1, 2, 3],
          [4, 5, 6],
        ]),
        MatrixModel.of('C', [
          [2, 0, 1],
          [1, 3, 2],
          [1, 1, 2],
        ]),
        MatrixModel.of('R', [
          ['cos(π/4)', '−sin(π/4)'],
          ['sin(π/4)', 'cos(π/4)'],
        ]),
      ],
      lines: lines([
        'det(A)',
        'C⁻¹',
        'BA',
        'R²',
        'eig(A)',
        'sin(Bπ/6)',
        'M = BBᵀ',
        'A + B',
      ]),
    ),
    Workspace(
      name: 'Linear systems — HW 4',
      updated: now - day * 2,
      matrices: [
        MatrixModel.of('A', [
          [2, 1, -1],
          [-3, -1, 2],
          [-2, 1, 2],
        ]),
        MatrixModel.of('B', [
          [8],
          [-11],
          [-3],
        ]),
      ],
      lines: lines([
        'solve(A, B)',
        'rref(aug(A, B))',
        'lu(A)',
        'N = [1, 2; 2, 4]',
        'null(N)',
        'rank(N)',
      ]),
    ),
    Workspace(
      name: 'Trig inside matrices',
      updated: now - day * 6,
      matrices: [
        MatrixModel.of('T', [
          ['cos(30°)', '−sin(30°)', '0'],
          ['sin(30°)', 'cos(30°)', '0'],
          ['0', '0', '1'],
        ]),
        MatrixModel.of('S', [
          [0, -1],
          [1, 0],
        ]),
      ],
      lines: lines(['TᵀT', 'det(T)', 'expm(π/2·S)', 'sinm(S)', 'svd(T)']),
    ),
  ];
}
