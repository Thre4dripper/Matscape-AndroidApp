import 'dart:convert';
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
    this.base = 0,
  }) : id = id ?? uid();

  factory Workspace.fromJson(Map<String, dynamic> j) => Workspace(
    id: j['id'] as String?,
    name: j['name'] as String,
    updated: j['updated'] as int,
    base: j['base'] as int? ?? 0,
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

  /// The [updated] time of the version this one was edited from. It is set
  /// by the device that edits, on its first edit since its last full sync,
  /// and merging never changes it. A version whose [base] is older than
  /// another version's [updated] never saw that version's edits, which is
  /// how sync tells a conflict from an ordinary later edit.
  int base;
  List<MatrixModel> matrices;
  List<LineModel> lines;

  /// A sample as it was shipped, never edited.
  bool get isPristineSample =>
      id.startsWith(samplePrefix) && updated <= sampleEpoch;

  /// What the user sees, for telling whether two versions differ. Internal
  /// ids are left out: the same text on two devices is the same content.
  String get contentKey => jsonEncode([
    name,
    [
      for (final m in matrices) [m.name, m.cells],
    ],
    [for (final l in lines) l.text],
  ]);

  Workspace copyWith({String? id, String? name, int? updated, int? base}) =>
      Workspace.fromJson({
        ...jsonDecode(jsonEncode(this)) as Map<String, dynamic>,
        'id': ?id,
        'name': ?name,
        'updated': ?updated,
        'base': ?base,
      });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'updated': updated,
    'base': base,
    'matrices': matrices,
    'lines': lines,
  };
}

/// Ids of the shipped samples start with this, so every device has the same
/// ids for them and sync doesn't duplicate them.
const samplePrefix = 'sample-';

/// The shipped samples are dated just before this, 1 January 2025, so any
/// edit a user makes is newer than a pristine copy from another device.
const sampleEpoch = 1735689600000;

String sampleId(String name) =>
    samplePrefix +
    name
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');

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

  /// Copy results and steps as LaTeX instead of plain text.
  bool copyLatex = false;

  void load(Map<String, dynamic> j) {
    theme = j['theme'] as String? ?? theme;
    degrees = j['degrees'] as bool? ?? degrees;
    exact = j['exact'] as bool? ?? exact;
    precision = j['precision'] as int? ?? precision;
    defRows = j['defRows'] as int? ?? defRows;
    defCols = j['defCols'] as int? ?? defCols;
    defIdentity = j['defIdentity'] as bool? ?? defIdentity;
    copyLatex = j['copyLatex'] as bool? ?? copyLatex;
  }

  Map<String, dynamic> toJson() => {
    'theme': theme,
    'degrees': degrees,
    'exact': exact,
    'precision': precision,
    'defRows': defRows,
    'defCols': defCols,
    'defIdentity': defIdentity,
    'copyLatex': copyLatex,
  };
}

/// Sample workspaces shown on first launch: a showcase first, then one per
/// topic, in the order someone would learn them. Every operation in the
/// library appears in at least one of them.
List<Workspace> seedWorkspaces() {
  var n = 0;
  Workspace ws(String name, List<MatrixModel> matrices, List<String> lines) {
    // A second apart, so sorting by date keeps this order.
    final t = sampleEpoch - 1000 * n++;
    return Workspace(
      id: sampleId(name),
      name: name,
      updated: t,
      base: t,
      // Fixed ids inside too, so the same sample is identical everywhere.
      matrices: [
        for (final (i, m) in matrices.indexed)
          MatrixModel(
            id: '${sampleId(name)}-m$i',
            name: m.name,
            cells: m.cells,
          ),
      ],
      lines: [
        for (final (i, s) in lines.indexed)
          LineModel(s, id: '${sampleId(name)}-l$i'),
      ],
    );
  }

  const m = MatrixModel.of;
  return [
    ws(
      'Rotations & eigenvalues',
      [
        m('A', [
          [4, 1, 2],
          [1, 3, 0],
          [2, 0, 5],
        ]),
        m('B', [
          [1, 2, 3],
          [4, 5, 6],
        ]),
        m('C', [
          [2, 0, 1],
          [1, 3, 2],
          [1, 1, 2],
        ]),
        m('R', [
          ['cos(π/4)', '−sin(π/4)'],
          ['sin(π/4)', 'cos(π/4)'],
        ]),
      ],
      ['det(A)', 'C⁻¹', 'BA', 'R²', 'eig(A)', 'sin(Bπ/6)', 'M = BBᵀ', 'A + B'],
    ),
    ws(
      'Basics — add, multiply, transpose',
      [
        m('A', [
          [1, 2],
          [3, 4],
        ]),
        m('B', [
          [2, 0],
          [1, 3],
        ]),
        m('C', [
          [1, 2, 3],
          [4, 5, 6],
        ]),
      ],
      [
        'A + B',
        'A − B',
        '3A',
        'AB',
        'BA',
        'AC',
        'Cᵀ',
        'A⁻¹',
        'A²',
        'A ∘ B',
        'A / B',
        'k = 2',
        'k·A + I',
      ],
    ),
    ws(
      'Determinant, trace, rank & norms',
      [
        m('A', [
          [2, -1, 0],
          [-1, 2, -1],
          [0, -1, 2],
        ]),
        m('S', [
          [1, 2],
          [2, 4],
        ]),
      ],
      [
        'det(A)',
        '|A|',
        'tr(A)',
        'rank(A)',
        'det(S)',
        'rank(S)',
        'norm(A)',
        'norm1(A)',
        'norminf(A)',
        'norm2(A)',
        'cond(A)',
      ],
    ),
    ws(
      'Building matrices',
      [
        m('A', [
          [1, 2, 3],
          [4, 5, 6],
          [7, 8, 10],
        ]),
        m('B', [
          [1],
          [2],
          [3],
        ]),
      ],
      [
        '[1, 2; 3, 4]',
        'I(3)',
        'A − 2I',
        'zeros(2, 3)',
        'ones(2, 2)',
        'diag([1, 2, 3])',
        'diag(A)',
        'aug(A, B)',
        'sub(A, 1, 1)',
        'row(A, 2)',
        'column(A, 3)',
        'kron([1, 2; 3, 4], I(2))',
      ],
    ),
    ws(
      'Minors, cofactors & adjugate',
      [
        m('A', [
          [1, 2, 3],
          [0, 1, 4],
          [5, 6, 0],
        ]),
      ],
      ['minors(A)', 'cof(A)', 'adj(A)', 'det(A)', 'adj(A) / det(A)', 'A⁻¹'],
    ),
    ws(
      'Linear systems',
      [
        m('A', [
          [2, 1, -1],
          [-3, -1, 2],
          [-2, 1, 2],
        ]),
        m('B', [
          [8],
          [-11],
          [-3],
        ]),
      ],
      [
        'solve(A, B)',
        'rref(aug(A, B))',
        'A⁻¹B',
        'N = [1, 2; 2, 4]',
        'rank(N)',
        'null(N)',
        'colsp(N)',
        'pinv(N)',
        'solve(N, [3; 6])',
      ],
    ),
    ws(
      'Vectors — dot and cross',
      [
        m('U', [
          [1],
          [2],
          [3],
        ]),
        m('V', [
          [4],
          [5],
          [6],
        ]),
      ],
      [
        'dot(U, V)',
        'cross(U, V)',
        'UᵀV',
        'UVᵀ',
        'norm(U)',
        'U / norm(U)',
        'dot(U, cross(U, V))',
      ],
    ),
    ws(
      'Decompositions — LU, QR, Cholesky, SVD',
      [
        m('A', [
          [4, 12, -16],
          [12, 37, -43],
          [-16, -43, 98],
        ]),
        m('B', [
          [1, 2],
          [3, 4],
          [5, 6],
        ]),
      ],
      ['lu(A)', 'qr(A)', 'chol(A)', 'svd(B)', 'qr(B)'],
    ),
    ws(
      'Eigenvalues & eigenvectors',
      [
        m('A', [
          [4, 1],
          [2, 3],
        ]),
        m('S', [
          [2, 1, 0],
          [1, 2, 1],
          [0, 1, 2],
        ]),
        m('R', [
          [0, -1],
          [1, 0],
        ]),
      ],
      [
        'eig(A)',
        'eigvec(A)',
        'charpoly(A)',
        'det(A − 5I)',
        'eig(S)',
        'eig(R)',
        'tr(A)',
        'det(A)',
      ],
    ),
    ws(
      'Matrix functions — expm, sinm, sqrtm',
      [
        m('D', [
          [1, 0],
          [0, 2],
        ]),
        m('S', [
          [0, -1],
          [1, 0],
        ]),
        m('P', [
          [5, 4],
          [4, 5],
        ]),
      ],
      [
        'expm(D)',
        'expm(π/2·S)',
        'sinm(S)',
        'cosm(S)',
        'sqrtm(P)',
        'P^0.5',
        'sqrtm(P)²',
      ],
    ),
    ws(
      'Trig inside matrices',
      [
        m('T', [
          ['cos(30°)', '−sin(30°)', '0'],
          ['sin(30°)', 'cos(30°)', '0'],
          ['0', '0', '1'],
        ]),
        m('S', [
          [0, -1],
          [1, 0],
        ]),
      ],
      ['TᵀT', 'det(T)', 'sin(T)', 'expm(π/2·S)', 'sinm(S)', 'svd(T)'],
    ),
    ws(
      'Numbers, fractions & exact results',
      [
        m('A', [
          ['1/2', '1/3'],
          ['√2', 'π'],
        ]),
      ],
      [
        '1/3 + 1/6',
        '√8',
        '∛27',
        'sin(π/6)',
        'cos(45°)',
        'asin(1/2)',
        'ln(e)',
        'log(1000)',
        '5!',
        'mod(17, 5)',
        'abs(−3.5)',
        'round(2.6)',
        'x = 2√3',
        'x²',
        '2A',
      ],
    ),
  ];
}
