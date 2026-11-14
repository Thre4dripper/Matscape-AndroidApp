// Step-by-step solutions: replays an expression one operation at a time and,
// for each operation, the working a student would write out by hand.
part of 'evaluator.dart';

enum WorkKind { text, math, matrix, ops }

/// One line of working.
///
/// [text] and [label] may use the tiny markup of the maths views: `<i>`,
/// `<sub>` and `<sup>`.
class Work {
  /// A sentence.
  const Work.text(String this.text, {this.indent = 0})
    : kind = WorkKind.text,
      mat = null,
      label = null,
      aug = null,
      ops = const [];

  /// A line of maths, such as `c₁₁ = 4·1 + 1·4 = 8`.
  const Work.math(String this.text, {this.indent = 0})
    : kind = WorkKind.math,
      mat = null,
      label = null,
      aug = null,
      ops = const [];

  /// A matrix with a caption above it.
  const Work.matrix(Mat this.mat, {this.label, this.aug, this.indent = 0})
    : kind = WorkKind.matrix,
      text = null,
      ops = const [];

  /// Row operations and the matrix they give.
  const Work.ops(this.ops, Mat this.mat, {this.aug, this.indent = 0})
    : kind = WorkKind.ops,
      text = null,
      label = null;

  const Work._(
    this.kind,
    this.text,
    this.mat,
    this.label,
    this.aug,
    this.ops,
    this.indent,
  );

  final WorkKind kind;
  final String? text;
  final Mat? mat;
  final String? label;

  /// Column where an augmented half starts.
  final int? aug;
  final List<String> ops;

  /// How deep inside other working this line sits: the working of a minor
  /// is one level in from the determinant that needs it.
  final int indent;

  /// The same line, [by] levels further in.
  Work indented(int by) =>
      by == 0 ? this : Work._(kind, text, mat, label, aug, ops, indent + by);
}

/// One way of working a step out. The working is only built when asked for.
class StepMethod {
  StepMethod(this.name, this._build, {this.weight = 0});
  final String name;
  final List<Work> Function() _build;

  /// Roughly how many numbers the working has to produce. A large value
  /// tells the app to work it out away from the screen, behind a loader.
  final int weight;
  late final List<Work> work = _build();
}

/// One operation of a solution.
class SolveStep {
  SolveStep(
    this.title,
    this.expr,
    this.value, {
    this.note,
    this.methods = const [],
  });

  /// What is done, in words: "Matrix product".
  final String title;

  /// What is being worked out, as text: "A·Bᵀ".
  final String expr;

  /// What it comes to: a `double`, [Mat], [ListVal], [MultiVal], [PolyVal]
  /// or [TextVal].
  final Object value;

  /// The rule being applied, in a sentence.
  final String? note;
  final List<StepMethod> methods;
}

class Solution {
  Solution(this.expr, this.value, this.steps, this.assign);

  /// The whole expression, tidied.
  final String expr;

  final Object value;
  final List<SolveStep> steps;
  final String? assign;
}

/// Works [text] out step by step, or returns null when it has no answer.
/// [fmt] writes numbers the way the user has chosen to see them.
Solution? explain(
  String text, {
  Map<String, Object> vars = const {},
  bool degrees = false,
  bool exact = true,
  int precision = 4,
  String Function(double)? fmt,
}) {
  final ctx = _Ctx(vars, degrees)..vals = Map<_Node, Object>.identity();
  fmt ??= (x) => plain(x, exact: exact, precision: precision);
  try {
    final a = splitAssignment(text);
    final body = a?.body ?? text;
    if (body.trim().isEmpty) return null;
    final root = _Parser(body, ctx.vars).parse();
    final v = _eval(root, ctx);
    if (v is Eye) return null;
    final ex = _Explainer(ctx, fmt);
    ex.walk(root, top: true);
    return Solution(ex.show(root), _tidy(v), ex.steps, a?.name);
  } on MathError {
    return null;
  } catch (_) {
    return null;
  }
}

/// The working of one method of one step of [text], from scratch. It takes
/// only plain values, so it can run on another isolate while the app shows
/// a loader.
List<Work> workFor(
  String text,
  int step,
  int method, {
  Map<String, Object> vars = const {},
  bool degrees = false,
  bool exact = true,
  int precision = 4,
}) {
  final s = explain(
    text,
    vars: vars,
    degrees: degrees,
    exact: exact,
    precision: precision,
  );
  if (s == null || step >= s.steps.length) return const [];
  final methods = s.steps[step].methods;
  return method < methods.length ? methods[method].work : const [];
}

/// Whether [text] has anything to work out: false for a value on its own,
/// such as `A` or `5`, and for anything that doesn't parse.
bool hasSteps(String text, {Map<String, Object> vars = const {}}) {
  try {
    final body = splitAssignment(text)?.body ?? text;
    if (body.trim().isEmpty) return false;
    final root = _Parser(body, vars).parse();
    return !_Explainer(_Ctx(vars, false), plain)._atom(root);
  } catch (_) {
    return false;
  }
}

Object _tidy(Object v) =>
    v is Mat ? cleanM(v) : (v is double ? cleanNum(v) : v);

const _supDigit = {
  '0': '⁰',
  '1': '¹',
  '2': '²',
  '3': '³',
  '4': '⁴',
  '5': '⁵',
  '6': '⁶',
  '7': '⁷',
  '8': '⁸',
  '9': '⁹',
  '-': '⁻',
};

String _supInt(int k) => '$k'.split('').map((c) => _supDigit[c]!).join();

const _trig = {
  'sin', 'cos', 'tan', 'sec', 'csc', 'cot', //
  'asin', 'arcsin', 'acos', 'arccos', 'atan', 'arctan',
};

const _fnTitle = {
  'det': 'Determinant',
  'tr': 'Trace',
  'trace': 'Trace',
  'rank': 'Rank',
  'inv': 'Inverse',
  'transpose': 'Transpose',
  'adj': 'Adjugate',
  'adjoint': 'Adjugate',
  'cof': 'Cofactor matrix',
  'cofactors': 'Cofactor matrix',
  'minors': 'Matrix of minors',
  'rref': 'Reduced row echelon form',
  'null': 'Null space',
  'nullspace': 'Null space',
  'colsp': 'Column space',
  'colspace': 'Column space',
  'eig': 'Eigenvalues',
  'eigvals': 'Eigenvalues',
  'eigvec': 'Eigenvectors',
  'eigvecs': 'Eigenvectors',
  'charpoly': 'Characteristic polynomial',
  'lu': 'LU decomposition',
  'qr': 'QR decomposition',
  'chol': 'Cholesky decomposition',
  'cholesky': 'Cholesky decomposition',
  'svd': 'Singular value decomposition',
  'pinv': 'Pseudo-inverse',
  'norm': 'Frobenius norm',
  'norm1': '1-norm',
  'norm2': '2-norm',
  'norminf': '∞-norm',
  'cond': 'Condition number',
  'expm': 'Matrix exponential',
  'sinm': 'Matrix sine',
  'cosm': 'Matrix cosine',
  'sqrtm': 'Matrix square root',
  'dot': 'Dot product',
  'cross': 'Cross product',
  'kron': 'Kronecker product',
  'hadamard': 'Entrywise product',
  'solve': 'Solve the system',
  'aug': 'Join side by side',
  'sub': 'Remove a row and a column',
  'row': 'Take a row',
  'column': 'Take a column',
  'diag': 'Diagonal',
  'zeros': 'Build the matrix',
  'ones': 'Build the matrix',
  'I': 'Identity matrix',
  'eye': 'Identity matrix',
};

const _fnNote = {
  'transpose': 'Rows become columns.',
  'pinv': 'From the SVD: A⁺ = V·Σ⁺·Uᵀ, where Σ⁺ turns each non-zero singular value σ into 1/σ.',
  'norm2': 'The largest singular value.',
  'expm': 'The series I + A + A²/2! + A³/3! + …, summed by scaling the matrix down, using a Padé approximation and squaring back up.',
  'sinm': 'The series A − A³/3! + A⁵/5! − …',
  'cosm': 'The series I − A²/2! + A⁴/4! − …',
  'sqrtm': 'The matrix X with X·X equal to this one, found by iteration.',
  'kron': 'Every entry of the left matrix is replaced by that entry times the right matrix.',
  'hadamard': 'Entries in the same position are multiplied.',
  'aug': 'The second matrix is written to the right of the first.',
};

class _Explainer {
  _Explainer(this.ctx, this.fmt);
  final _Ctx ctx;
  final String Function(double) fmt;
  final steps = <SolveStep>[];

  /// Largest determinant whose cofactor expansion is written out all the
  /// way down. The work grows as n!: an 8×8 already has 20 160 2×2
  /// determinants, and a 10×10 would have 1.8 million.
  static const _fullExpansion = 8;

  /// Largest matrix whose minors each get their own row reduction when
  /// they are too big to expand.
  static const _minorRows = 12;

  static int _fact(int k) => k <= 1 ? 1 : k * _fact(k - 1);

  /// A rough size for working that touches every entry a few times.
  static int _cube(Mat m) => m.rows * m.cols * math.max(m.rows, m.cols);

  Object? val(_Node? n) => n == null ? null : ctx.vals![n];

  /* ---------- numbers as text ---------- */

  String n(double x) => fmt(cleanNum(x));

  /// A number as a term of a sum: negatives get brackets.
  String a(double x) {
    final t = n(x);
    return t.startsWith('−') || t.startsWith('-') ? '($t)' : t;
  }

  /// A number as a factor of a product: negatives and fractions get brackets.
  String f(double x) {
    final t = n(x);
    return t.startsWith('−') || t.startsWith('-') || t.contains('/')
        ? '($t)'
        : t;
  }

  String ix(int i, [int? j]) {
    final s = j == null
        ? '${i + 1}'
        : (i > 8 || j > 8 ? '${i + 1},${j + 1}' : '${i + 1}${j + 1}');
    return '<sub>$s</sub>';
  }

  String cx(Object z) {
    if (z is double) return n(z);
    final c = z as Complex;
    if (c.im.abs() < 1e-12) return n(c.re);
    final im = n(c.im.abs());
    final re = c.re.abs() < 1e-12 ? '' : n(c.re);
    final sign = c.im < 0 ? '−' : (re.isEmpty ? '' : '+');
    return re.isEmpty
        ? '$sign${im == '1' ? '' : im}i'
        : '$re $sign ${im == '1' ? '' : im}i';
  }

  String poly(List<double> cf) {
    final deg = cf.length - 1, b = StringBuffer();
    for (var k = 0; k <= deg; k++) {
      final c = cleanNum(cf[k]), p = deg - k;
      if (c.abs() < 1e-12) continue;
      final mag = n(c.abs());
      b.write(b.isEmpty ? (c < 0 ? '−' : '') : (c < 0 ? ' − ' : ' + '));
      if (p == 0 || mag != '1') b.write(mag);
      if (p >= 1) b.write('<i>λ</i>');
      if (p >= 2) b.write(_supInt(p));
    }
    return b.isEmpty ? '0' : b.toString();
  }

  /* ---------- the expression as text ---------- */

  int _prec(_Node x) => switch (x.k) {
    'bin' => x.s == '+' || x.s == '-' ? 1 : 2,
    'neg' => 3,
    'pow' || 'post' => 4,
    _ => 5,
  };

  String _in(_Node x, int min) => _prec(x) < min ? '(${show(x)})' : show(x);

  String show(_Node x) {
    switch (x.k) {
      case 'num':
        return n(x.v);
      case 'id':
        return x.s;
      case 'neg':
        return '−${_in(x.a!, 3)}';
      case 'bin':
        final (sym, left, right) = switch (x.s) {
          '+' => (' + ', 1, 2),
          '-' => (' − ', 1, 2),
          '*' => ('·', 2, 2),
          '/' => (' ÷ ', 2, 3),
          _ => (' ∘ ', 2, 3),
        };
        // A number in front of a name is written as a coefficient: 2I, 3Aᵀ.
        final coef = x.s == '*' && x.a!.k == 'num' && _named(x.b!);
        return '${_in(x.a!, left)}${coef ? '' : sym}${_in(x.b!, right)}';
      case 'pow':
        final e = x.b!, base = _in(x.a!, 5);
        if (e.k == 'id' && e.s == 'T' && !ctx.vars.containsKey('T')) {
          return '$baseᵀ';
        }
        final k = _wholeLiteral(e);
        return k != null ? '$base${_supInt(k)}' : '$base^${_in(e, 5)}';
      case 'post':
        const marks = {
          'T': 'ᵀ',
          'inv': '⁻¹',
          'sq': '²',
          'cube': '³',
          'deg': '°',
          'fact': '!',
        };
        return '${_in(x.a!, 4)}${marks[x.s]}';
      case 'lit':
        return '[${x.rows!.map((r) => r.map(show).join(', ')).join('; ')}]';
      case 'bars':
        return '|${show(x.a!)}|';
      case 'call':
        final args = x.args!;
        if (x.s == 'sqrt' && args.length == 1) return '√${_in(args[0], 5)}';
        if (x.s == 'cbrt' && args.length == 1) return '∛${_in(args[0], 5)}';
        return '${x.s}(${args.map(show).join(', ')})';
      default:
        return '?';
    }
  }

  /// A name, possibly with a power or transpose mark on it.
  bool _named(_Node x) =>
      x.k == 'id' || ((x.k == 'post' || x.k == 'pow') && x.a!.k == 'id');

  /// The whole number a literal exponent stands for, if it is one.
  int? _wholeLiteral(_Node e) {
    final neg = e.k == 'neg', lit = neg ? e.a! : e;
    if (lit.k != 'num' || lit.v != lit.v.roundToDouble()) return null;
    if (lit.v.abs() > 99) return null;
    return neg ? -lit.v.round() : lit.v.round();
  }

  /* ---------- walking the expression ---------- */

  /// Something already known, which needs no step of its own. A typed
  /// matrix counts when its entries are plain numbers or arithmetic.
  bool _atom(_Node x) =>
      x.k == 'num' ||
      x.k == 'id' ||
      (x.k == 'lit' && x.rows!.every((r) => r.every(_arith))) ||
      (x.k == 'neg' && x.a!.k == 'num') ||
      (x.k == 'post' && x.s == 'deg' && _atom(x.a!));

  final _arithMemo = <_Node, bool>{};

  /// True when this part of the expression is arithmetic on numbers only:
  /// no matrix, and nothing worked out from one.
  bool _arith(_Node x) => _arithMemo[x] ??= switch (x.k) {
    'num' => true,
    'id' => x.s != 'I' && ctx.vars[x.s] is! Mat && ctx.vars[x.s] is! InvalidVal,
    'neg' || 'post' || 'bars' => _arith(x.a!),
    'bin' || 'pow' => _arith(x.a!) && _arith(x.b!),
    'call' => !_fnTitle.containsKey(x.s) && x.args!.every(_arith),
    _ => false,
  };

  List<_Node> _kids(_Node x) => [
    if (x.a != null) x.a!,
    // The T of Aᵀ is not a value.
    if (x.b != null && val(x.b) != null) x.b!,
    ...?x.args,
    // Entries of a typed matrix that are worked out from other matrices.
    if (x.rows != null)
      for (final r in x.rows!)
        for (final e in r)
          if (!_arith(e)) e,
  ];

  void walk(_Node x, {bool top = false, bool inNumbers = false}) {
    if (_atom(x)) return;
    final v = val(x);
    if (v == null) return;
    // Plain arithmetic inside a matrix expression is one step, not many.
    final numbers = _arith(x);
    if (numbers && !top && !inNumbers) {
      steps.add(SolveStep('Work out the number', show(x), _tidy(v)));
      return;
    }
    for (final k in _kids(x)) {
      walk(k, inNumbers: numbers);
    }
    if (v is Eye) return;
    final s = _step(x, v);
    if (s != null) steps.add(s);
  }

  SolveStep? _step(_Node x, Object v) {
    final expr = show(x), out = _tidy(v);
    SolveStep make(String title, {String? note, List<StepMethod>? methods}) =>
        SolveStep(title, expr, out, note: note, methods: methods ?? const []);
    switch (x.k) {
      case 'neg':
        return make(
          v is Mat ? 'Change every sign' : 'Change the sign',
          note: v is Mat ? 'Every entry is multiplied by −1.' : null,
        );
      case 'bin':
        return _binary(x, v, make);
      case 'pow':
        final e = x.b!;
        if (e.k == 'id' && e.s == 'T' && !ctx.vars.containsKey('T')) {
          return _unary('transpose', val(x.a)!, x.a!, v, make);
        }
        final base = val(x.a), k = val(e);
        if (base is Mat && k is double) {
          if ((k - 0.5).abs() < 1e-12) {
            return make('Matrix square root', note: _fnNote['sqrtm']);
          }
          return _power(base, k.round(), _in(x.a!, 5), make);
        }
        return make('Raise to the power');
      case 'post':
        final arg = val(x.a)!;
        switch (x.s) {
          case 'T':
            return _unary('transpose', arg, x.a!, v, make);
          case 'inv':
            return arg is Mat
                ? _unary('inv', arg, x.a!, v, make)
                : make('Take the reciprocal');
          case 'sq':
          case 'cube':
            final k = x.s == 'sq' ? 2 : 3;
            return arg is Mat
                ? _power(arg, k, _in(x.a!, 5), make)
                : make(k == 2 ? 'Square it' : 'Cube it');
          case 'fact':
            return make('Factorial');
          default:
            return null;
        }
      case 'bars':
        final arg = val(x.a)!;
        return arg is Mat
            ? _unary('det', arg, x.a!, v, make)
            : make('Absolute value');
      case 'lit':
        return make(
          'Put the results in a matrix',
          note: 'Each entry has been worked out in the steps above.',
        );
      case 'call':
        return _call(x, v, make);
      default:
        return null;
    }
  }

  SolveStep _binary(
    _Node x,
    Object v,
    SolveStep Function(String, {String? note, List<StepMethod>? methods}) make,
  ) {
    final l = val(x.a)!, r = val(x.b)!;
    final plus = x.s == '+';
    switch (x.s) {
      case '+' || '-':
        if (l is Mat && r is Mat) {
          return make(
            plus ? 'Add the matrices' : 'Subtract the matrices',
            note:
                'Entries in the same position are ${plus ? 'added' : 'subtracted'}.',
            methods: [
              StepMethod(
                'Entry by entry',
                () => _entries(
                  v as Mat,
                  (i, j) =>
                      '${n(l.data[i][j])} ${plus ? '+' : '−'} ${a(r.data[i][j])}',
                ),
              ),
            ],
          );
        }
        if (l is Eye || r is Eye) {
          final k = l is Eye ? l.s : (r as Eye).s;
          final what = k == 1 ? 'I' : '${n(k)}I';
          final m = l is Mat ? l : r as Mat, out = v as Mat;
          return make(
            plus ? 'Add $what' : 'Subtract $what',
            note:
                '$what is ${n(k)} down the diagonal and 0 elsewhere, so only the diagonal entries change.',
            methods: [
              StepMethod(
                'Down the diagonal',
                () => [
                  for (var i = 0; i < m.rows; i++)
                    Work.math(
                      '<i>c</i>${ix(i, i)} = ${l is Mat ? n(m.data[i][i]) : n(k)} ${plus ? '+' : '−'} ${a(l is Mat ? k : m.data[i][i])} = ${n(out.data[i][i])}',
                    ),
                ],
              ),
            ],
          );
        }
        return make(plus ? 'Add' : 'Subtract');
      case '*':
        if (l is Mat && r is Mat) {
          return make(
            'Multiply the matrices',
            note: 'Entry (i, j) is row i of the left matrix times column j of the right one.',
            methods: [
              StepMethod(
                'Entry by entry',
                () => _mulWork(l, r),
                weight: l.rows * r.cols * l.cols,
              ),
            ],
          );
        }
        if (l is Mat || r is Mat) {
          final k = l is Mat ? r : l;
          final kt = k is Eye ? n(k.s) : n(k as double);
          return make(
            'Multiply every entry by $kt',
            note: k is Eye && k.s == 1
                ? 'Multiplying by I leaves a matrix unchanged.'
                : null,
          );
        }
        return make('Multiply');
      case '/':
        if (r is Mat) {
          return make(
            'Divide by a matrix',
            note: 'Dividing by a matrix means multiplying by its inverse on the right.',
            methods: [
              StepMethod('Working', () {
                final inv = cleanM(inverse(r));
                return [
                  Work.matrix(inv, label: 'The inverse of the divisor'),
                  if (l is Mat)
                    const Work.text(
                      'Then multiply the left matrix by this inverse.',
                    )
                  else
                    const Work.text('Then multiply every entry by the number.'),
                ];
              }),
            ],
          );
        }
        if (l is Mat) return make('Divide every entry by ${n(r as double)}');
        return make('Divide');
      default:
        return make(
          'Multiply entry by entry',
          note: l is Mat && r is Mat ? _fnNote['hadamard'] : null,
        );
    }
  }

  /// One line for every entry of [c].
  List<Work> _entries(Mat c, String Function(int i, int j) sum) => [
    for (var i = 0; i < c.rows; i++)
      for (var j = 0; j < c.cols; j++)
        Work.math('<i>c</i>${ix(i, j)} = ${sum(i, j)} = ${n(c.data[i][j])}'),
  ];

  List<Work> _mulWork(Mat l, Mat r) {
    final c = cleanM(mulM(l, r));
    return [
      const Work.text(
        'Go along a row of the left matrix and down a column of the right one, multiply in pairs and add.',
      ),
      ..._entries(
        c,
        (i, j) => [
          for (var k = 0; k < l.cols; k++)
            '${f(l.data[i][k])}·${f(r.data[k][j])}',
        ].join(' + '),
      ),
    ];
  }

  SolveStep _power(
    Mat base,
    int k,
    String name,
    SolveStep Function(String, {String? note, List<StepMethod>? methods}) make,
  ) {
    if (k == 0) {
      return make(
        'Raise to the power 0',
        note: 'Any square matrix to the power 0 is the identity.',
      );
    }
    final neg = k < 0, p = k.abs();
    // The matrix that gets multiplied, after inverting for a negative power.
    (Mat, String, List<Work>) start() {
      if (!neg) return (base, name, <Work>[]);
      final inv = cleanM(inverse(base));
      return (
        inv,
        '$name⁻¹',
        [Work.matrix(inv, label: 'First the inverse, $name⁻¹')],
      );
    }

    String pow(String b, int e) => e == 1 ? b : '$b${_supInt(e)}';
    final each = _cube(base);
    return make(
      p == 1 ? 'Inverse' : 'Raise to the power $k',
      note: neg
          ? (p == 1
                ? null
                : 'A negative power means the inverse raised to the power $p.')
          : 'The matrix multiplied by itself $p times.',
      methods: [
        if (p == 1) ..._inverseMethods(base),
        if (p == 2 && !neg)
          StepMethod(
            'Entry by entry',
            () => _mulWork(base, base),
            weight: each,
          ),
        if ((p > 2 || (neg && p > 1)) && p <= 64)
          StepMethod('One multiplication at a time', () {
            final (b, bn, w) = start();
            var acc = b;
            for (var q = 2; q <= p; q++) {
              acc = cleanM(mulM(acc, b));
              w.add(
                Work.matrix(
                  acc,
                  label: '${pow(bn, q)} = ${pow(bn, q - 1)}·$bn',
                ),
              );
            }
            return w;
          }, weight: each * p),
        if (p >= 4)
          StepMethod('Repeated squaring', () {
            final (b, bn, w) = start();
            final bits = [
              for (var e = 1; e <= p; e *= 2)
                if (p & e != 0) e,
            ];
            w.add(
              Work.text(
                bits.length == 1
                    ? '$p is a power of two, so squaring ${bits[0].bitLength - 1} times gets there.'
                    : '$p = ${bits.reversed.join(' + ')}. Square repeatedly, then multiply together the squares that add up to $p.',
              ),
            );
            final squares = {1: b};
            var cur = b;
            for (var e = 2; e <= p; e *= 2) {
              cur = cleanM(mulM(cur, cur));
              squares[e] = cur;
              w.add(
                Work.matrix(
                  cur,
                  label:
                      '${pow(bn, e)} = ${pow(bn, e ~/ 2)}·${pow(bn, e ~/ 2)}',
                ),
              );
            }
            var acc = squares[bits.last]!, have = bits.last;
            for (final e in bits.reversed.skip(1)) {
              acc = cleanM(mulM(acc, squares[e]!));
              w.add(
                Work.matrix(
                  acc,
                  label:
                      '${pow(bn, have + e)} = ${pow(bn, have)}·${pow(bn, e)}',
                ),
              );
              have += e;
            }
            return w;
          }, weight: each * 14),
      ],
    );
  }

  /* ---------- functions ---------- */

  SolveStep _call(
    _Node x,
    Object v,
    SolveStep Function(String, {String? note, List<StepMethod>? methods}) make,
  ) {
    final args = [for (final k in x.args!) val(k)!];
    final first = args.isEmpty ? null : args[0];
    final name = x.s, title = _fnTitle[name];
    if (title == null) {
      // A scalar function such as sin or sqrt.
      final onMatrix = first is Mat;
      return make(
        onMatrix ? 'Apply $name to every entry' : 'Work out $name',
        note: _trig.contains(name)
            ? 'Angles are in ${ctx.deg ? 'degrees' : 'radians'}.'
            : null,
      );
    }
    if (args.length == 1 && first is Mat) {
      return _unary(name, first, x.args![0], v, make);
    }
    final m0 = first is Mat ? first : null;
    final m1 = args.length > 1 && args[1] is Mat ? args[1] as Mat : null;
    switch (name) {
      case 'solve':
        return make(
          title,
          note: 'Find x with A·x = b.',
          methods: m0 == null || m1 == null ? null : _solveMethods(m0, m1),
        );
      case 'dot':
        if (m0 == null || m1 == null) return make(title);
        final u = _vec(m0), w = _vec(m1);
        return make(
          title,
          note: 'Multiply matching entries and add them up.',
          methods: [
            StepMethod(
              'Working',
              () => [
                Work.math(
                  '${[for (var i = 0; i < u.length; i++) '${f(u[i])}·${f(w[i])}'].join(' + ')} = ${n(v as double)}',
                ),
              ],
            ),
          ],
        );
      case 'cross':
        if (m0 == null || m1 == null) return make(title);
        final u = _vec(m0), w = _vec(m1), c = _vec(v as Mat);
        String part(int p, int q) =>
            '${f(u[p])}·${f(w[q])} − ${f(u[q])}·${f(w[p])}';
        return make(
          title,
          note: 'A vector at right angles to both.',
          methods: u.length != 3
              ? null
              : [
                  StepMethod(
                    'Working',
                    () => [
                      Work.math(
                        '<i>x</i> = <i>a</i><sub>2</sub><i>b</i><sub>3</sub> − <i>a</i><sub>3</sub><i>b</i><sub>2</sub> = ${part(1, 2)} = ${n(c[0])}',
                      ),
                      Work.math(
                        '<i>y</i> = <i>a</i><sub>3</sub><i>b</i><sub>1</sub> − <i>a</i><sub>1</sub><i>b</i><sub>3</sub> = ${part(2, 0)} = ${n(c[1])}',
                      ),
                      Work.math(
                        '<i>z</i> = <i>a</i><sub>1</sub><i>b</i><sub>2</sub> − <i>a</i><sub>2</sub><i>b</i><sub>1</sub> = ${part(0, 1)} = ${n(c[2])}',
                      ),
                    ],
                  ),
                ],
        );
      default:
        return make(title, note: _fnNote[name]);
    }
  }

  List<double> _vec(Mat m) =>
      m.rows == 1 ? m.data[0] : [for (final r in m.data) r[0]];

  /// A function of one matrix.
  SolveStep _unary(
    String name,
    Object arg,
    _Node argNode,
    Object v,
    SolveStep Function(String, {String? note, List<StepMethod>? methods}) make,
  ) {
    final title = _fnTitle[name] ?? name;
    if (arg is! Mat) return make(title);
    final m = arg, sq = m.rows == m.cols, size = m.rows;
    switch (name) {
      case 'transpose':
        return make(title, note: _fnNote[name]);
      case 'det':
        return make(title, methods: sq ? _detMethods(m) : null);
      case 'inv':
        return make(title, methods: sq ? _inverseMethods(m) : null);
      case 'tr' || 'trace':
        return make(
          title,
          note: 'The sum of the diagonal entries.',
          methods: [
            StepMethod(
              'Working',
              () => [
                Work.math(
                  '${[for (var i = 0; i < size; i++) a(m.data[i][i])].join(' + ')} = ${n(v as double)}',
                ),
              ],
            ),
          ],
        );
      case 'rank':
        return make(
          title,
          note: 'The number of rows that are not all zero once it is row-reduced.',
          methods: [StepMethod('Row reduction', () => _rows(stepsRref(m)))],
        );
      case 'rref':
        return make(
          title,
          note: 'Row operations until every pivot is 1 with zeros above and below it.',
          methods: [StepMethod('Row reduction', () => _rows(stepsRref(m)))],
        );
      case 'null' || 'nullspace':
        return make(
          title,
          note: 'Every x with A·x = 0.',
          methods: [
            StepMethod(
              'Row reduction',
              () => [
                ..._rows(stepsRref(m)),
                const Work.text(
                  'Columns without a pivot are free. Setting one free variable to 1 and the others to 0, then reading off the rest, gives one basis vector each.',
                ),
              ],
            ),
          ],
        );
      case 'colsp' || 'colspace':
        return make(
          title,
          note: 'Everything the columns can add up to.',
          methods: [
            StepMethod('Row reduction', () {
              final r = rrefCore(m, hand: true);
              final cols = [for (final p in r.pivots) '${p + 1}'].join(', ');
              return [
                ..._rows(stepsRref(m)),
                Work.text(
                  r.pivots.isEmpty
                      ? 'There are no pivots.'
                      : 'The pivots are in column${r.pivots.length > 1 ? 's' : ''} $cols. Those columns of the original matrix form a basis.',
                ),
              ];
            }),
          ],
        );
      case 'adj' || 'adjoint' || 'cof' || 'cofactors' || 'minors':
        final adj = name.startsWith('adj'), minors = name == 'minors';
        return make(
          title,
          note: minors
              ? 'Each entry is the determinant of what is left when that entry’s row and column are removed.'
              : adj
              ? 'The transpose of the cofactor matrix.'
              : 'Each minor with its sign: + where row + column is even, − where it is odd.',
          methods: !sq || size < 2
              ? null
              : [
                  StepMethod('Working', () {
                    return [
                      ..._minorLines(m, signed: !minors),
                      if (adj) ...[
                        Work.matrix(
                          cleanM(cofactorM(m)),
                          label: 'The cofactor matrix',
                        ),
                        const Work.text('Its transpose is the adjugate.'),
                      ],
                    ];
                  }, weight: _minorWeight(m)),
                ],
        );
      case 'eig' || 'eigvals':
        return make(
          title,
          note: 'The numbers λ with A·v = λv for some non-zero v.',
          methods: !sq || size < 2
              ? null
              : [
                  StepMethod('Characteristic equation', () {
                    final vals = (v as ListVal).items;
                    final cp = charpoly(m);
                    return [
                      const Work.text(
                        'The eigenvalues are the roots of det(A − λI) = 0.',
                      ),
                      if (size == 2) ...[
                        Work.math(
                          'trace = ${a(m.data[0][0])} + ${a(m.data[1][1])} = ${n(traceOf(m))}',
                        ),
                        Work.math('det = ${_det2(m)} = ${n(det(m))}'),
                        const Work.math(
                          '<i>λ</i>² − (trace)<i>λ</i> + det = 0',
                        ),
                      ],
                      Work.math('${poly(cp)} = 0'),
                      if (size > 2)
                        const Work.text(
                          'The Characteristic polynomial step shows how these coefficients are found. Its roots are then found numerically.',
                        ),
                      Work.math('<i>λ</i> = ${vals.map(cx).join(',  ')}'),
                    ];
                  }, weight: _cube(m) * size),
                ],
        );
      case 'charpoly':
        return make(
          title,
          note: 'det(λI − A), written as a polynomial in λ.',
          methods: !sq || size < 2
              ? null
              : [
                  if (size <= 3)
                    StepMethod('From trace and det', () {
                      final w = <Work>[];
                      if (size == 2) {
                        w.add(
                          const Work.math(
                            '<i>p</i>(<i>λ</i>) = <i>λ</i>² − (trace)<i>λ</i> + det',
                          ),
                        );
                      } else {
                        w.add(
                          const Work.math(
                            '<i>p</i>(<i>λ</i>) = <i>λ</i>³ − (trace)<i>λ</i>² + (sum of the 2×2 minors on the diagonal)<i>λ</i> − det',
                          ),
                        );
                      }
                      w.add(
                        Work.math(
                          'trace = ${[for (var i = 0; i < size; i++) a(m.data[i][i])].join(' + ')} = ${n(traceOf(m))}',
                        ),
                      );
                      if (size == 3) {
                        final ms = [
                          for (var i = 0; i < 3; i++) det(_minorMat(m, i, i)),
                        ];
                        w.add(
                          Work.math(
                            'minors = ${ms.map(a).join(' + ')} = ${n(ms[0] + ms[1] + ms[2])}',
                          ),
                        );
                      }
                      w.add(Work.math('det = ${n(det(m))}'));
                      w.add(
                        Work.math(
                          '<i>p</i>(<i>λ</i>) = ${poly((v as PolyVal).coeffs)}',
                        ),
                      );
                      return w;
                    }),
                  // Works at any size, and is how the app itself does it.
                  StepMethod('Faddeev–LeVerrier', () {
                    final w = <Work>[
                      const Work.text(
                        'Find the coefficients one at a time. Start from M<sub>1</sub> = I. Each coefficient is c<sub>k</sub> = −trace(A·M<sub>k</sub>) ÷ k, and the next matrix is M<sub>k+1</sub> = A·M<sub>k</sub> + c<sub>k</sub>·I.',
                      ),
                    ];
                    final id = eye(size), coeffs = <double>[1];
                    var mk = zeros(size, size), c = 1.0;
                    for (var k = 1; k <= size; k++) {
                      mk = addM(mulM(m, mk), scaleM(id, c));
                      final t = traceOf(mulM(m, mk));
                      w.add(
                        Work.matrix(
                          cleanM(mk),
                          label: k == 1
                              ? '<i>M</i><sub>1</sub> = I'
                              : '<i>M</i><sub>$k</sub> = A·<i>M</i><sub>${k - 1}</sub> + ${f(c)}·I',
                        ),
                      );
                      c = -t / k;
                      coeffs.add(c);
                      w.add(
                        Work.math(
                          '<i>c</i><sub>$k</sub> = −trace(A·<i>M</i><sub>$k</sub>) ÷ $k = −${a(t)} ÷ $k = ${n(c)}',
                        ),
                      );
                    }
                    w.add(Work.math('<i>p</i>(<i>λ</i>) = ${poly(coeffs)}'));
                    return w;
                  }, weight: _cube(m) * size),
                ],
        );
      case 'eigvec' || 'eigvecs':
        return make(
          title,
          note:
              'For each eigenvalue λ, the non-zero solutions of (A − λI)v = 0.',
          methods: !sq
              ? null
              : [
                  StepMethod('One eigenvalue at a time', () {
                    final w = <Work>[];
                    final seen = <double>[];
                    final tol = 1e-7 * math.max(1.0, maxAbs(m));
                    for (final z in eigenvalues(m)) {
                      if (z is! double) continue;
                      if (seen.any((s) => (s - z).abs() < tol)) continue;
                      seen.add(z);
                      final shifted = cleanM(addM(m, scaleM(eye(size), z), -1));
                      w
                        ..add(
                          Work.matrix(
                            shifted,
                            label: 'For <i>λ</i> = ${n(z)}:  A − <i>λ</i>I',
                          ),
                        )
                        ..add(
                          Work.matrix(
                            rrefCore(shifted, tol: tol).r,
                            label: 'Row-reduced',
                          ),
                        );
                    }
                    w.add(
                      const Work.text(
                        'Each reduced matrix gives the equations its eigenvectors satisfy. They are then scaled to length 1.',
                      ),
                    );
                    return w;
                  }, weight: _cube(m) * size),
                ],
        );
      case 'lu':
        return make(
          title,
          note: 'A lower-triangular L and an upper-triangular U with PA = LU.',
          methods: !sq
              ? null
              : [
                  StepMethod('Elimination', () {
                    final r = rrefCore(m, upperOnly: true);
                    return [
                      const Work.text(
                        'Clear the entries below each pivot. What is left is U; the multipliers used go into L, and any row swaps into P.',
                      ),
                      Work.matrix(m, label: 'Start'),
                      for (final s in r.steps) Work.ops(s.ops, s.m),
                      if (r.steps.isEmpty)
                        const Work.text(
                          'It is already upper triangular, so L is the identity.',
                        ),
                    ];
                  }),
                ],
        );
      case 'chol' || 'cholesky':
        return make(
          title,
          note: 'A lower-triangular L with A = L·Lᵀ.',
          methods: [
            StepMethod('Entry by entry', () => _cholWork(m), weight: _cube(m)),
          ],
        );
      case 'qr':
        return make(
          title,
          note: 'An orthogonal Q and an upper-triangular R with A = QR.',
          methods: [
            StepMethod('Gram–Schmidt', () => _qrWork(m), weight: _cube(m)),
          ],
        );
      case 'svd':
        return make(
          title,
          note: 'A = UΣVᵀ, with the singular values on the diagonal of Σ and orthogonal U and V.',
          methods: [
            StepMethod('Working', () => _svdWork(m), weight: _cube(m) * 4),
          ],
        );
      case 'norm':
        return make(
          title,
          note: 'The square root of the sum of every entry squared.',
          methods: [
            StepMethod('Working', () {
              final all = [for (final r in m.data) ...r];
              final ss = all.fold(0.0, (s, x) => s + x * x);
              return [
                Work.math(
                  '√(${all.map((x) => '${f(x)}²').join(' + ')}) = √${f(ss)} = ${n(v as double)}',
                ),
              ];
            }),
          ],
        );
      case 'norm1' || 'norminf':
        final byCol = name == 'norm1';
        return make(
          title,
          note:
              'The largest ${byCol ? 'column' : 'row'} sum of absolute values.',
          methods: [
            StepMethod('Working', () {
              final lines = byCol ? transpose(m).data : m.data;
              return [
                for (var i = 0; i < lines.length; i++)
                  Work.math(
                    '${byCol ? 'column' : 'row'} ${i + 1}:  ${lines[i].map((x) => '|${n(x)}|').join(' + ')} = ${n(lines[i].fold(0.0, (s, x) => s + x.abs()))}',
                  ),
                Work.math('largest = ${n(v as double)}'),
              ];
            }),
          ],
        );
      case 'cond':
        return make(
          title,
          note: 'The largest singular value divided by the smallest. Large values mean small changes in the input can change the answer a lot.',
          methods: [
            StepMethod('Working', () {
              final sig = svd(m).sigma;
              final hi = sig.reduce(math.max), lo = sig.reduce(math.min);
              return [
                Work.math('<i>σ</i> = ${sig.map(n).join(',  ')}'),
                if (lo > 0) Work.math('${n(hi)} ÷ ${n(lo)} = ${n(hi / lo)}'),
              ];
            }),
          ],
        );
      default:
        return make(title, note: _fnNote[name]);
    }
  }

  /* ---------- worked methods ---------- */

  Mat _minorMat(Mat m, int r, int c) => Mat([
    for (var i = 0; i < m.rows; i++)
      if (i != r)
        [
          for (var j = 0; j < m.cols; j++)
            if (j != c) m.data[i][j],
        ],
  ]);

  /// ad − bc for a 2×2, written out.
  String _det2(Mat m) =>
      '${f(m.data[0][0])}·${f(m.data[1][1])} − ${f(m.data[0][1])}·${f(m.data[1][0])}';

  /// Row operations as working, ending with what they show.
  List<Work> _rows(StepsResult r, {String? intro}) => [
    if (intro != null) Work.text(intro),
    Work.matrix(r.start, label: 'Start', aug: r.aug),
    for (final s in r.steps) Work.ops(s.ops, s.m, aug: r.aug),
    if (r.steps.isEmpty)
      const Work.text('No row operations are needed: it is already reduced.'),
    if (r.summary.contains('=')) Work.math(r.summary) else Work.text(r.summary),
    if (r.note != null) Work.text(r.note!),
  ];

  List<StepMethod> _detMethods(Mat m) {
    final size = m.rows;
    if (size == 1) return const [];
    final cofactors = StepMethod(
      'Cofactor expansion',
      () => _cofactorWork(m),
      weight: size <= _fullExpansion ? _fact(size) : _cube(m),
    );
    final rows = StepMethod(
      'Row reduction',
      () => _rows(
        stepsDet(m),
        intro: 'Reduce to a triangle. The determinant is then the product of the diagonal.',
      ),
      weight: _cube(m),
    );
    return [
      if (size == 2)
        StepMethod(
          'Formula',
          () => [
            const Work.text(
              'For a 2×2 matrix: the product of the main diagonal minus the product of the other diagonal.',
            ),
            Work.math('det = ${_det2(m)} = ${n(det(m))}'),
          ],
        ),
      // Expansion first while it is short; row reduction first once it
      // is the quicker way.
      if (size == 3 || size == 4) ...[cofactors, rows],
      if (size == 2) rows,
      if (size > 4) ...[rows, cofactors],
    ];
  }

  static const _minorLetters = ['M', 'N', 'P', 'Q', 'R', 'S', 'T'];

  /// The row with the most zeros: the fewest minors to work out.
  (int, int) _bestRow(Mat m) {
    var row = 0, best = -1;
    for (var i = 0; i < m.rows; i++) {
      final z = m.data[i].where((x) => x == 0).length;
      if (z > best) {
        best = z;
        row = i;
      }
    }
    return (row, best);
  }

  List<Work> _cofactorWork(Mat m) {
    final w = <Work>[];
    if (m.rows > _fullExpansion) {
      // One level only: see [_fullExpansion].
      final (row, zeros) = _bestRow(m);
      w.add(
        Work.text(
          'Expand along row ${row + 1}${zeros > 0 ? ', which has the most zeros' : ''}. Expanding every minor in turn would take ${m.rows}! ÷ 2 two-by-two determinants, far too many to write out, so each minor’s determinant is given here. Row reduction has the complete working at this size.',
        ),
      );
      final terms = StringBuffer();
      var total = 0.0;
      for (var j = 0; j < m.cols; j++) {
        final e = m.data[row][j];
        if (e == 0) continue;
        final minor = _minorMat(m, row, j), mv = cleanNum(det(minor));
        w.add(
          Work.matrix(
            minor,
            label:
                '<i>M</i>${ix(row, j)}: remove row ${row + 1} and column ${j + 1}. Its determinant is ${n(mv)}.',
          ),
        );
        final plus = (row + j).isEven;
        terms
          ..write(terms.isEmpty ? (plus ? '' : '−') : (plus ? ' + ' : ' − '))
          ..write('${f(e)}·${f(mv)}');
        total += (plus ? 1 : -1) * e * mv;
      }
      w.add(
        terms.isEmpty
            ? Work.text('Row ${row + 1} is all zeros, so the determinant is 0.')
            : Work.math('det = $terms = ${n(total)}'),
      );
      return w;
    }
    _expand(m, 'det', 0, w);
    return w;
  }

  /// Expands the determinant of [m] along its best row, and every minor in
  /// turn, down to 2×2. Adds the lines to [w], each level one step further
  /// in, and returns the value. [name] is what this determinant is called.
  double _expand(Mat m, String name, int depth, List<Work> w) {
    final size = m.rows;
    if (size == 1) {
      w.add(Work.math('$name = ${n(m.data[0][0])}', indent: depth));
      return m.data[0][0];
    }
    if (size == 2) {
      final d = m.data[0][0] * m.data[1][1] - m.data[0][1] * m.data[1][0];
      w.add(Work.math('$name = ${_det2(m)} = ${n(d)}', indent: depth));
      return d;
    }
    final (row, zeros) = _bestRow(m);
    final most = zeros > 0 ? ', which has the most zeros' : '';
    w.add(
      Work.text(
        depth == 0
            ? 'Expand along row ${row + 1}$most: each entry times the determinant of what is left when its row and column are removed, with signs + − + …'
            : 'Expand $name along its row ${row + 1}$most.',
        indent: depth,
      ),
    );
    final letter = _minorLetters[math.min(depth, _minorLetters.length - 1)];
    final terms = StringBuffer();
    var total = 0.0;
    for (var j = 0; j < size; j++) {
      final e = m.data[row][j];
      if (e == 0) continue;
      final minor = _minorMat(m, row, j);
      final minorName = '<i>$letter</i>${ix(row, j)}';
      final double mv;
      if (size == 3) {
        // 2×2 minors are one line each, alongside the expansion.
        mv = _expand(minor, minorName, depth, w);
      } else {
        w.add(
          Work.matrix(
            minor,
            label: '$minorName: remove row ${row + 1} and column ${j + 1}',
            indent: depth,
          ),
        );
        mv = _expand(minor, minorName, depth + 1, w);
      }
      final plus = (row + j).isEven;
      terms
        ..write(terms.isEmpty ? (plus ? '' : '−') : (plus ? ' + ' : ' − '))
        ..write('${f(e)}·${f(mv)}');
      total += (plus ? 1 : -1) * e * mv;
    }
    if (terms.isEmpty) {
      w.add(
        Work.text(
          'Row ${row + 1} is all zeros, so ${depth == 0 ? 'the determinant' : name} is 0.',
          indent: depth,
        ),
      );
      return 0;
    }
    w.add(Work.math('$name = $terms = ${n(total)}', indent: depth));
    return total;
  }

  /// How much working [_minorLines] produces for a matrix this size.
  int _minorWeight(Mat m) {
    final size = m.rows, each = size - 1;
    return size *
        size *
        (each <= 4 ? _fact(each) : (size <= _minorRows ? each * each : 1));
  }

  /// Every minor (or cofactor) of [m], with how it is found.
  List<Work> _minorLines(Mat m, {required bool signed}) {
    final size = m.rows;
    final w = <Work>[];
    if (size > _minorRows) {
      w.add(
        const Work.text(
          'Each determinant below is found by row reduction, as in a Determinant step.',
        ),
      );
    }
    for (var i = 0; i < size; i++) {
      for (var j = 0; j < size; j++) {
        final minor = _minorMat(m, i, j);
        final neg = signed && (i + j).isOdd;
        final sym = signed ? 'C' : 'M';
        final name = '<i>$sym</i>${ix(i, j)}';
        if (size == 2) {
          // The minor of a 2×2 is the one entry left over.
          final e = minor.data[0][0];
          w.add(
            Work.math(
              !signed
                  ? '$name = ${n(e)}'
                  : neg
                  ? '$name = −${a(e)}${e < 0 ? ' = ${n(-e)}' : ''}'
                  : '$name = ${n(e)}',
            ),
          );
          continue;
        }
        if (size == 3) {
          final mv = cleanNum(det(minor)), body = _det2(minor);
          final shown = !signed ? body : (neg ? '−($body)' : body);
          w.add(Work.math('$name = $shown = ${n(neg ? -mv : mv)}'));
          continue;
        }
        // Bigger minors: the matrix, then its determinant worked out one
        // level in.
        final minorName = '<i>M</i>${ix(i, j)}';
        w.add(
          Work.matrix(
            minor,
            label: '$minorName: remove row ${i + 1} and column ${j + 1}',
          ),
        );
        final double mv;
        if (size - 1 <= 4) {
          mv = cleanNum(_expand(minor, minorName, 1, w));
        } else {
          mv = cleanNum(det(minor));
          if (size <= _minorRows) {
            final r = stepsDet(minor);
            w.addAll([
              for (final s in r.steps) Work.ops(s.ops, s.m, indent: 1),
              Work.math('$minorName = ${n(mv)}', indent: 1),
            ]);
          } else {
            w.add(Work.math('$minorName = ${n(mv)}', indent: 1));
          }
        }
        if (signed) {
          w.add(
            Work.math(
              '$name = ${neg ? '−' : ''}$minorName = ${n(neg ? -mv : mv)}',
            ),
          );
        }
      }
    }
    return w;
  }

  List<StepMethod> _inverseMethods(Mat m) {
    final size = m.rows;
    if (size == 1) return const [];
    final d = cleanNum(det(m));
    return [
      if (size == 2)
        StepMethod(
          'Formula',
          () => [
            const Work.text(
              'For a 2×2 matrix: swap the diagonal entries, change the sign of the other two, and divide by the determinant.',
            ),
            Work.math('det = ${_det2(m)} = ${n(d)}'),
            Work.matrix(
              Mat([
                [m.data[1][1], -m.data[0][1]],
                [-m.data[1][0], m.data[0][0]],
              ]),
              label: 'Swapped and sign-changed',
            ),
            Work.matrix(cleanM(inverse(m)), label: 'Divided by ${n(d)}'),
          ],
        ),
      StepMethod(
        'Gauss–Jordan',
        () => _rows(
          stepsInverse(m),
          intro: 'Write the matrix beside I, then row-reduce until the left half is I.',
        ),
      ),
      StepMethod(
        'Adjugate',
        () => [
          const Work.text(
            'The inverse is the adjugate divided by the determinant.',
          ),
          Work.math('det = ${n(d)}'),
          ..._minorLines(m, signed: true),
          Work.matrix(cleanM(cofactorM(m)), label: 'The cofactor matrix'),
          Work.matrix(
            cleanM(adjugate(m)),
            label: 'Its transpose, the adjugate',
          ),
          Work.matrix(cleanM(inverse(m)), label: 'Divided by ${n(d)}'),
        ],
        weight: _minorWeight(m),
      ),
    ];
  }

  List<StepMethod> _solveMethods(Mat am, Mat b) {
    final rows = am.rows, cols = am.cols;
    if (rows != b.rows) return const [];
    final sq = rows == cols;
    final d = sq ? cleanNum(det(am)) : 0.0;
    final unique = sq && d.abs() > tolFor(am, 1e-10);
    return [
      StepMethod('Elimination', () {
        final aug = Mat([
          for (var i = 0; i < rows; i++) [...am.data[i], ...b.data[i]],
        ]);
        final r = rrefCore(aug, hand: true, augAt: cols);
        return [
          const Work.text(
            'Write A and b side by side, then row-reduce the left half.',
          ),
          Work.matrix(aug, label: 'Start', aug: cols),
          for (final s in r.steps) Work.ops(s.ops, s.m, aug: cols),
          if (unique && b.cols == 1)
            for (var i = 0; i < cols; i++)
              Work.math('<i>x</i>${ix(i)} = ${n(r.r.data[i][cols])}')
          else
            const Work.text(
              'Each pivot row now gives one unknown in terms of the right-hand side.',
            ),
        ];
      }),
      if (unique && b.cols == 1)
        StepMethod('Cramer’s rule', () {
          final w = <Work>[
            const Work.text(
              'Each unknown is a ratio of determinants: replace one column of A with b, and divide by det(A).',
            ),
            Work.math('<i>D</i> = det(A) = ${n(d)}'),
          ];
          for (var j = 0; j < cols; j++) {
            final swapped = Mat([
              for (var i = 0; i < rows; i++)
                [
                  for (var k = 0; k < cols; k++)
                    k == j ? b.data[i][0] : am.data[i][k],
                ],
            ]);
            final dj = cleanNum(det(swapped));
            w
              ..add(
                Work.matrix(
                  swapped,
                  label:
                      '<i>D</i>${ix(j)}: column ${j + 1} replaced by b. Its determinant is ${n(dj)}.',
                ),
              )
              ..add(
                Work.math(
                  '<i>x</i>${ix(j)} = <i>D</i>${ix(j)} ÷ <i>D</i> = ${a(dj)} ÷ ${a(d)} = ${n(dj / d)}',
                ),
              );
          }
          return w;
        }),
      if (unique)
        StepMethod(
          'Inverse',
          () => [
            const Work.text('Multiply both sides by A⁻¹: x = A⁻¹·b.'),
            Work.matrix(cleanM(inverse(am)), label: 'A⁻¹'),
            Work.matrix(cleanM(mulM(inverse(am), b)), label: 'A⁻¹·b'),
          ],
        ),
    ];
  }

  Mat _column(List<double> v) => Mat([
    for (final x in v) [x],
  ]);

  /// Gram–Schmidt, written from the Q and R the app returns so that every
  /// number shown is one of theirs.
  List<Work> _qrWork(Mat m) {
    final res = qr(m), q = res.q.data, r = res.r.data;
    final rows = m.rows, cols = m.cols, k = math.min(rows, cols);
    final tol = 1e-10 * math.max(1.0, maxAbs(m));
    final w = <Work>[
      const Work.text(
        'Take the columns a<sub>1</sub>, a<sub>2</sub>, … one at a time. From each, take away its part along every q found so far. What is left, scaled to length 1, is the next q. The amounts taken away, and the lengths, are the entries of R.',
      ),
    ];
    for (var c = 0; c < k; c++) {
      final col = [for (var i = 0; i < rows; i++) m.data[i][c]];
      final u = List<double>.of(col);
      for (var p = 0; p < c; p++) {
        final qp = [for (var i = 0; i < rows; i++) q[i][p]];
        w.add(
          Work.math(
            '<i>r</i>${ix(p, c)} = <i>q</i>${ix(p)}·<i>a</i>${ix(c)} = ${[for (var i = 0; i < rows; i++) '${f(qp[i])}·${f(col[i])}'].join(' + ')} = ${n(r[p][c])}',
          ),
        );
        for (var i = 0; i < rows; i++) {
          u[i] -= r[p][c] * qp[i];
        }
      }
      final taken = [
        for (var p = 0; p < c; p++) '<i>r</i>${ix(p, c)}·<i>q</i>${ix(p)}',
      ];
      w.add(
        Work.matrix(
          cleanM(_column(u)),
          label:
              '<i>u</i>${ix(c)} = ${['<i>a</i>${ix(c)}', ...taken].join(' − ')}',
        ),
      );
      final clean = cleanM(_column(u)).data;
      w.add(
        Work.math(
          '<i>r</i>${ix(c, c)} = ‖<i>u</i>${ix(c)}‖ = √(${[for (final x in clean) '${f(x[0])}²'].join(' + ')}) = ${n(r[c][c])}',
        ),
      );
      if (r[c][c].abs() > tol) {
        w.add(
          Work.matrix(
            _column([for (var i = 0; i < rows; i++) q[i][c]]),
            label: '<i>q</i>${ix(c)} = <i>u</i>${ix(c)} ÷ <i>r</i>${ix(c, c)}',
          ),
        );
      } else {
        w.add(
          Work.matrix(
            _column([for (var i = 0; i < rows; i++) q[i][c]]),
            label:
                '<i>u</i>${ix(c)} is zero: this column depends on the earlier ones. Any unit vector at right angles to the others can be <i>q</i>${ix(c)}; this one is used.',
          ),
        );
      }
    }
    if (cols > k) {
      w.add(
        Work.text(
          'Columns ${k + 1} to $cols have no new direction left to give: their entries in R are their parts along each q, r<sub>ij</sub> = q<sub>i</sub>·a<sub>j</sub>.',
        ),
      );
    }
    if (rows > k) {
      w.add(
        Work.text(
          'Q is square, so ${rows - k} more unit vector${rows - k > 1 ? 's at right angles to these complete' : ' at right angles to these completes'} it. The matching rows of R are zero.',
        ),
      );
    }
    return w;
  }

  /// The singular value decomposition from AᵀA, using the U, Σ and V the
  /// app returns.
  List<Work> _svdWork(Mat m) {
    final res = svd(m), sig = res.sigma;
    final ata = cleanM(mulM(transpose(m), m)), size = ata.rows;
    final tol = 1e-10 * math.max(1.0, sig.isEmpty ? 0.0 : sig[0]);
    final w = <Work>[
      Work.matrix(ata, label: 'Start with AᵀA'),
      const Work.text(
        'Its eigenvalues are the squares of the singular values, so solve det(AᵀA − λI) = 0.',
      ),
      Work.math('${poly(charpoly(ata))} = 0'),
    ];
    for (var i = 0; i < sig.length; i++) {
      final lam = cleanNum(sig[i] * sig[i]);
      w.add(
        Work.math(
          '<i>λ</i>${ix(i)} = ${n(lam)},  <i>σ</i>${ix(i)} = √${f(lam)} = ${n(sig[i])}',
        ),
      );
    }
    w.add(
      const Work.text(
        'The columns of V are the eigenvectors of AᵀA, each scaled to length 1.',
      ),
    );
    final reduceTol = 1e-7 * math.max(1.0, maxAbs(ata));
    for (var i = 0; i < sig.length; i++) {
      final lam = sig[i] * sig[i];
      final repeat = i > 0 && (lam - sig[i - 1] * sig[i - 1]).abs() < reduceTol;
      if (!repeat) {
        final shifted = cleanM(addM(ata, scaleM(eye(size), lam), -1));
        w
          ..add(
            Work.matrix(
              shifted,
              label: 'For <i>λ</i>${ix(i)} = ${n(lam)}:  AᵀA − <i>λ</i>I',
            ),
          )
          ..add(
            Work.matrix(
              rrefCore(shifted, tol: reduceTol).r,
              label: 'Row-reduced',
              indent: 1,
            ),
          );
      }
      w.add(
        Work.matrix(
          _column(res.vt.data[i]),
          label: repeat
              ? '<i>v</i>${ix(i)}, a second solution for the same <i>λ</i>, at right angles to the first'
              : '<i>v</i>${ix(i)}, the solution of length 1',
          indent: 1,
        ),
      );
    }
    w.add(
      const Work.text(
        'Each column of U is A times a column of V, divided by its σ.',
      ),
    );
    for (var i = 0; i < sig.length; i++) {
      final ui = _column([for (final r in res.u.data) r[i]]);
      if (sig[i] > tol) {
        w
          ..add(
            Work.matrix(
              cleanM(mulM(m, _column(res.vt.data[i]))),
              label: 'A·<i>v</i>${ix(i)}',
            ),
          )
          ..add(
            Work.matrix(
              ui,
              label: '<i>u</i>${ix(i)} = A·<i>v</i>${ix(i)} ÷ ${n(sig[i])}',
              indent: 1,
            ),
          );
      } else {
        w.add(
          Work.matrix(
            ui,
            label:
                '<i>σ</i>${ix(i)} is 0, so <i>u</i>${ix(i)} is chosen as a unit vector at right angles to the others',
          ),
        );
      }
    }
    w.add(
      const Work.text(
        'Σ has the σ down its diagonal, U has the u as its columns and Vᵀ has the v as its rows.',
      ),
    );
    return w;
  }

  List<Work> _cholWork(Mat m) {
    final size = m.rows, l = cholesky(m).data;
    final w = <Work>[
      const Work.text(
        'Work along each row of L. A diagonal entry is a square root; the others are divided by the diagonal entry above them.',
      ),
    ];
    for (var i = 0; i < size; i++) {
      for (var j = 0; j <= i; j++) {
        final taken = [
          for (var k = 0; k < j; k++)
            i == j ? '${f(l[i][k])}²' : '${f(l[i][k])}·${f(l[j][k])}',
        ];
        final inner = [n(m.data[i][j]), ...taken].join(' − ');
        final name = '<i>l</i>${ix(i, j)}';
        w.add(
          Work.math(
            // Brackets only where something is taken away first.
            i == j
                ? '$name = √${taken.isEmpty ? f(m.data[i][j]) : '($inner)'} = ${n(l[i][j])}'
                : '$name = ${taken.isEmpty ? f(m.data[i][j]) : '($inner)'} ÷ ${f(l[j][j])} = ${n(l[i][j])}',
          ),
        );
      }
    }
    return w;
  }
}
