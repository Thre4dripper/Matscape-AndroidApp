/// Expression language: tokenizer, parser and evaluator.
///
/// Values are plain Dart objects: `double`, [Mat], [Eye], [ListVal],
/// [MultiVal], [PolyVal] or [TextVal].
library;

import 'dart:math' as math;

import 'format.dart';
import 'linalg.dart';
import 'types.dart';

part 'steps.dart';

/// Largest dimension a generated matrix may have, so a typo like
/// zeros(9999) can't freeze the app.
const int maxGeneratedSize = 64;

/* ---------- tokenizer ---------- */

class _Tok {
  const _Tok(this.t, [this.v]);

  /// 'num', 'id', 'op', 'post', 'end', or a literal bracket/separator.
  final String t;
  final Object? v;
}

const _postfix = {
  'ᵀ': 'T',
  '²': 'sq',
  '³': 'cube',
  '°': 'deg',
  '!': 'fact',
  "'": 'T',
};

final _numRe = RegExp(r'(\d+\.?\d*|\.\d+)');
final _idRe = RegExp(r'([A-Za-z_][A-Za-z0-9_]*|[α-ωΑ-Ω])');
final _capsRun = RegExp(r'^[A-Z]{2,}$');
final _space = RegExp(r'\s');

List<_Tok> _tokenize(String src) {
  final toks = <_Tok>[];
  var i = 0;
  while (i < src.length) {
    final ch = src[i];
    if (_space.hasMatch(ch)) {
      i++;
      continue;
    }
    final num = _numRe.matchAsPrefix(src, i);
    if (num != null) {
      i = num.end;
      if (i < src.length && src[i] == '.') {
        throw MathError(
          'Check the decimal point',
          '“${num[0]}.” has more than one decimal point.',
        );
      }
      toks.add(_Tok('num', double.parse(num[0]!)));
      continue;
    }
    final id = _idRe.matchAsPrefix(src, i);
    if (id != null && id[0] != 'π') {
      final name = id[0]!;
      // Runs of capitals are separate matrices multiplied together: BBᵀ = B·Bᵀ
      if (_capsRun.hasMatch(name)) {
        for (final c in name.split('')) {
          toks.add(_Tok('id', c));
        }
      } else {
        toks.add(_Tok('id', name));
      }
      i = id.end;
      continue;
    }
    if (src.startsWith('⁻¹', i)) {
      toks.add(const _Tok('post', 'inv'));
      i += 2;
      continue;
    }
    if (ch == 'π') {
      toks.add(const _Tok('id', 'π'));
    } else if (_postfix.containsKey(ch)) {
      toks.add(_Tok('post', _postfix[ch]));
    } else if (ch == '+') {
      toks.add(const _Tok('op', '+'));
    } else if ('-−–'.contains(ch)) {
      toks.add(const _Tok('op', '-'));
    } else if ('*·×⋅'.contains(ch)) {
      toks.add(const _Tok('op', '*'));
    } else if ('/÷'.contains(ch)) {
      toks.add(const _Tok('op', '/'));
    } else if (ch == '^') {
      toks.add(const _Tok('op', '^'));
    } else if (ch == '∘') {
      toks.add(const _Tok('op', '∘'));
    } else if ('()[],;|√∛'.contains(ch)) {
      toks.add(_Tok(ch));
    } else if (ch == '=') {
      throw MathError(
        'Use “=” only to name a value',
        'Write it at the start, like k = 3 or M = A·B.',
      );
    } else {
      throw MathError('“$ch” isn’t something Matscape understands');
    }
    i++;
  }
  toks.add(const _Tok('end'));
  return toks;
}

/* ---------- parser ---------- */

/// AST node. [k] is one of: num, id, neg, bin, pow, post, lit, bars, call.
class _Node {
  _Node(
    this.k, {
    this.v = 0,
    this.s = '',
    this.a,
    this.b,
    this.args,
    this.rows,
  });
  final String k;
  final double v;
  final String s;
  final _Node? a, b;
  final List<_Node>? args;
  final List<List<_Node>>? rows;
}

class _Parser {
  _Parser(String src, this.vars) : toks = _tokenize(src);
  final List<_Tok> toks;
  final Map<String, Object> vars;
  var i = 0;

  _Tok get peek => toks[i];
  _Tok next() => toks[i++];
  bool peekOp(String v) => peek.t == 'op' && peek.v == v;

  void expect(String t, String msg) {
    if (peek.t != t) throw MathError(msg);
    i++;
  }

  static const _factorStart = {'num', 'id', '(', '[', '√', '∛'};

  _Node parse() {
    final tree = expr();
    if (peek.t != 'end') {
      throw MathError(
        peek.t == ')'
            ? 'There’s an extra “)”'
            : peek.t == ','
            ? 'Commas only go inside function brackets or [ ]'
            : 'Something here doesn’t fit',
        '',
      );
    }
    return tree;
  }

  _Node expr() {
    var a = term();
    while (peekOp('+') || peekOp('-')) {
      final op = next().v as String;
      a = _Node('bin', s: op, a: a, b: term());
    }
    return a;
  }

  _Node term() {
    var a = unary();
    for (;;) {
      final tk = peek;
      if (tk.t == 'op' && (tk.v == '*' || tk.v == '/' || tk.v == '∘')) {
        next();
        a = _Node('bin', s: tk.v as String, a: a, b: unary());
      } else if (_factorStart.contains(tk.t)) {
        // Implicit multiplication: 2A, AB, 3(1 + 2).
        a = _Node('bin', s: '*', a: a, b: power());
      } else {
        return a;
      }
    }
  }

  _Node unary() {
    if (peekOp('-')) {
      next();
      return _Node('neg', a: unary());
    }
    if (peekOp('+')) {
      next();
      return unary();
    }
    return power();
  }

  _Node power() {
    final base = postfix();
    if (peekOp('^')) {
      next();
      return _Node('pow', a: base, b: unary());
    }
    return base;
  }

  _Node postfix() {
    var n = primary();
    while (peek.t == 'post') {
      n = _Node('post', s: next().v as String, a: n);
    }
    return n;
  }

  _Node primary() {
    final tk = next();
    switch (tk.t) {
      case 'num':
        return _Node('num', v: tk.v as double);
      case '(':
        if (peek.t == ')') {
          throw MathError('Empty brackets', 'Put something between ( and ).');
        }
        final e = expr();
        expect(')', 'A bracket is missing its “)”');
        return e;
      case '[':
        final rows = <List<_Node>>[[]];
        if (peek.t == ']') {
          throw MathError('Empty matrix', 'Write entries like [1, 2; 3, 4].');
        }
        for (;;) {
          rows.last.add(expr());
          final sep = next();
          if (sep.t == ',') continue;
          if (sep.t == ';') {
            rows.add([]);
            continue;
          }
          if (sep.t == ']') break;
          throw MathError(
            'Matrix brackets aren’t closed',
            'Separate entries with “,”, rows with “;”, and finish with “]”.',
          );
        }
        return _Node('lit', rows: rows);
      case '|':
        final e = expr();
        expect('|', 'The closing “|” is missing');
        return _Node('bars', a: e);
      case '√':
        return _Node('call', s: 'sqrt', args: [postfix()]);
      case '∛':
        return _Node('call', s: 'cbrt', args: [postfix()]);
      case 'id':
        final name = tk.v as String;
        final f = vars.containsKey(name) ? null : _funcs[name];
        if (f == null) return _Node('id', s: name);
        if ((name == 'I' || name == 'eye') && peek.t != '(') {
          return _Node('id', s: 'I');
        }
        if (peek.t == '(') {
          next();
          final args = <_Node>[];
          if (peek.t != ')') {
            for (;;) {
              args.add(expr());
              if (peek.t == ',') {
                next();
                continue;
              }
              break;
            }
          }
          expect(')', '$name( is missing its “)”');
          return _Node('call', s: name, args: args);
        }
        // Single-input functions may skip the brackets: det A, sin x.
        if (f.min == 1) return _Node('call', s: name, args: [postfix()]);
        throw MathError('$name needs brackets', 'Write $name(…)');
      case 'end':
        throw MathError(
          'This expression ends too early',
          'Something is missing after the last operator.',
        );
      case ')':
        throw MathError('There’s an extra “)”');
      case ']':
        throw MathError('There’s an extra “]”');
      case 'op':
        throw MathError(
          '“${tk.v == '*' ? '×' : tk.v}” is missing something before it',
        );
      case 'post':
        throw MathError('A power or transpose sign has nothing before it');
      default:
        throw MathError('Unexpected “${tk.t}”');
    }
  }
}

/* ---------- evaluation ---------- */

class _Ctx {
  _Ctx(this.vars, this.deg);
  final Map<String, Object> vars;
  final bool deg;
  final warnings = <String>[];

  /// When set, the value of every part of the expression is kept here so
  /// the steps can be written out afterwards (see `explain`).
  Map<_Node, Object>? vals;
}

MathError _eyeNeedsSize() =>
    MathError('I needs a size here', 'Write I(3) for the 3×3 identity.');

Mat _asMat(Object v, String fname) {
  if (v is double) {
    return Mat([
      [v],
    ]);
  }
  if (v is Mat) return v;
  if (v is Eye) throw _eyeNeedsSize();
  throw MathError('$fname(…) needs a matrix');
}

double _asNum(Object v, String fname) {
  if (v is double) return v;
  if (v is Mat && v.rows == 1 && v.cols == 1) return v.data[0][0];
  throw MathError(
    '$fname needs a number here',
    v is Mat ? 'Got ${desc(v)}.' : '',
  );
}

int _asInt(Object v, String fname, [int min = 1]) {
  final n = _asNum(v, fname);
  if (!n.isFinite || (n - n.roundToDouble()).abs() > 1e-9 || n.round() < min) {
    throw MathError(
      '$fname needs a whole number${min > 0 ? ' of at least $min' : ''}',
    );
  }
  return n.round();
}

int _asSize(Object v, String fname) {
  final n = _asInt(v, fname);
  if (n > maxGeneratedSize) {
    throw MathError(
      'That matrix would be too large',
      'Sizes up to $maxGeneratedSize are supported.',
    );
  }
  return n;
}

Object _elementwise(Object v, double Function(double) f) {
  if (v is Mat) return mapM(v, (x, _, _) => f(x));
  if (v is double) return f(v);
  throw _eyeNeedsSize();
}

Object _add(Object a, Object b, double sign) {
  final verb = sign > 0 ? 'add' : 'subtract';
  if (a is double && b is double) return a + sign * b;
  if (a is Mat && b is Mat) {
    if (a.rows != b.rows || a.cols != b.cols) {
      throw MathError(
        'Can’t $verb ${desc(a)} and ${desc(b)}',
        'Both matrices need the same size.',
      );
    }
    return addM(a, b, sign);
  }
  if (a is Mat && b is Eye) {
    needSquare(a, 'Adding I');
    return addM(a, scaleM(eye(a.rows), b.s), sign);
  }
  if (a is Eye && b is Mat) {
    needSquare(b, 'Adding I');
    return addM(scaleM(eye(b.rows), a.s), b, sign);
  }
  if (a is Eye && b is Eye) return Eye(a.s + sign * b.s);
  throw MathError(
    'Can’t $verb a number and a matrix',
    'To shift the diagonal, use the identity: A − 2I.',
  );
}

Object _mul(Object a, Object b) {
  if (a is double && b is double) return a * b;
  if (a is double && b is Mat) return scaleM(b, a);
  if (a is Mat && b is double) return scaleM(a, b);
  if (a is Mat && b is Mat) {
    if (a.cols != b.rows) {
      throw MathError(
        'Can’t multiply ${desc(a)} by ${desc(b)}',
        'The left matrix’s columns (${a.cols}) must match the right matrix’s rows (${b.rows}).',
      );
    }
    return mulM(a, b);
  }
  if (a is Eye && b is Eye) return Eye(a.s * b.s);
  if (a is Eye) return b is double ? Eye(a.s * b) : scaleM(b as Mat, a.s);
  if (b is Eye) return a is double ? Eye(a * b.s) : scaleM(a as Mat, b.s);
  throw MathError('Can’t multiply these');
}

Object _div(Object a, Object b, _Ctx ctx) {
  if (b is double) {
    if (b == 0) throw MathError('Division by zero');
    if (a is double) return a / b;
    if (a is Mat) return scaleM(a, 1 / b);
    return Eye((a as Eye).s / b);
  }
  if (b is Mat) {
    final inv = inverse(b);
    if (a is Mat) {
      ctx.warnings.add(
        'Matrix division is worked out as ${a.label ?? 'left'}·${b.label ?? 'right'}⁻¹.',
      );
    }
    return _mul(a, inv);
  }
  throw MathError('Can’t divide by I without a size');
}

Object _hadamard(Object a, Object b) {
  if (a is Mat && b is Mat) {
    if (a.rows != b.rows || a.cols != b.cols) {
      throw MathError(
        'The entrywise product needs equal sizes',
        '${desc(a)} vs ${desc(b)}.',
      );
    }
    return mapM(a, (x, i, j) => x * b.data[i][j]);
  }
  return _mul(a, b);
}

double _factorial(double x) {
  if (x < 0 || (x - x.roundToDouble()).abs() > 1e-9) {
    throw MathError('Factorial needs a whole number ≥ 0');
  }
  final n = x.round();
  if (n > 170) return double.infinity;
  var r = 1.0;
  for (var k = 2; k <= n; k++) {
    r *= k;
  }
  return r;
}

double _sinh(double x) => (math.exp(x) - math.exp(-x)) / 2;
double _cosh(double x) => (math.exp(x) + math.exp(-x)) / 2;
double _tanh(double x) {
  if (x > 20) return 1;
  if (x < -20) return -1;
  final e = math.exp(2 * x);
  return (e - 1) / (e + 1);
}

double _cbrt(double x) =>
    x < 0 ? -math.pow(-x, 1 / 3).toDouble() : math.pow(x, 1 / 3).toDouble();

/// Rounds halves up, matching how calculators (and the prototype) round.
double _round(double x) => (x + 0.5).floorToDouble();

/* ---------- function table ---------- */

class _Fn {
  const _Fn(this.min, this.max, this.fn);
  final int min, max;
  final Object Function(List<Object> args, _Ctx ctx) fn;
}

final Map<String, _Fn> _funcs = _makeFuncs();

Map<String, _Fn> _makeFuncs() {
  final f = <String, _Fn>{};
  void def(
    String names,
    int min,
    int max,
    Object Function(List<Object> args, _Ctx ctx) fn,
  ) {
    for (final n in names.split(' ')) {
      f[n] = _Fn(min, max, fn);
    }
  }

  double toRad(double x, _Ctx c) => c.deg ? x * math.pi / 180 : x;
  double fromRad(double x, _Ctx c) => c.deg ? x * 180 / math.pi : x;
  void guard(bool bad, String msg) {
    if (bad) throw MathError(msg);
  }

  // Scalar functions; on a matrix they apply to every entry.
  void sc(
    String names,
    double Function(double x, _Ctx c) fn, [
    String? matHint,
  ]) {
    final first = names.split(' ').first;
    def(names, 1, 1, (args, ctx) {
      final v = args[0];
      if (v is Mat && matHint != null) ctx.warnings.add(matHint);
      if (v is! double && v is! Mat) {
        throw MathError('$first needs a number or matrix');
      }
      return _elementwise(v, (x) => fn(x, ctx));
    });
  }

  sc(
    'sin',
    (x, c) => math.sin(toRad(x, c)),
    'sin is applied to each entry. Use sinm(A) for the true matrix sine.',
  );
  sc(
    'cos',
    (x, c) => math.cos(toRad(x, c)),
    'cos is applied to each entry. Use cosm(A) for the true matrix cosine.',
  );
  sc('tan', (x, c) {
    final r = toRad(x, c);
    guard(math.cos(r).abs() < 1e-12, 'tan is undefined at this angle');
    return math.tan(r);
  });
  sc('sec', (x, c) {
    final r = toRad(x, c);
    guard(math.cos(r).abs() < 1e-12, 'sec is undefined at this angle');
    return 1 / math.cos(r);
  });
  sc('csc', (x, c) {
    final r = toRad(x, c);
    guard(math.sin(r).abs() < 1e-12, 'csc is undefined at this angle');
    return 1 / math.sin(r);
  });
  sc('cot', (x, c) {
    final r = toRad(x, c);
    guard(math.sin(r).abs() < 1e-12, 'cot is undefined at this angle');
    return math.cos(r) / math.sin(r);
  });
  sc('asin arcsin', (x, c) {
    guard(x.abs() > 1 + 1e-12, 'sin⁻¹ only takes values from −1 to 1');
    return fromRad(math.asin(x.clamp(-1.0, 1.0)), c);
  });
  sc('acos arccos', (x, c) {
    guard(x.abs() > 1 + 1e-12, 'cos⁻¹ only takes values from −1 to 1');
    return fromRad(math.acos(x.clamp(-1.0, 1.0)), c);
  });
  sc('atan arctan', (x, c) => fromRad(math.atan(x), c));
  sc('sinh', (x, _) => _sinh(x));
  sc('cosh', (x, _) => _cosh(x));
  sc('tanh', (x, _) => _tanh(x));
  sc('ln', (x, _) {
    guard(x <= 0, 'ln needs a positive number');
    return math.log(x);
  });
  sc('log', (x, _) {
    guard(x <= 0, 'log needs a positive number');
    return math.log(x) / math.ln10;
  });
  sc(
    'exp',
    (x, _) => math.exp(x),
    'exp is applied to each entry. Use expm(A) for the matrix exponential.',
  );
  sc('sqrt', (x, _) {
    guard(x < -1e-15, '√ of a negative number isn’t real');
    return math.sqrt(math.max(0.0, x));
  }, '√ is applied to each entry. Use sqrtm(A) for the matrix square root.');
  sc('cbrt', (x, _) => _cbrt(x));
  sc('abs', (x, _) => x.abs());
  sc('round', (x, _) => _round(x));
  sc('floor', (x, _) => x.floorToDouble());
  sc('ceil', (x, _) => x.ceilToDouble());
  def('mod', 2, 2, (a, _) {
    final x = _asNum(a[0], 'mod'), m = _asNum(a[1], 'mod');
    if (m == 0) throw MathError('mod by zero');
    return (x.remainder(m) + m).remainder(m);
  });

  // One-matrix functions.
  void m1(String names, Object Function(Mat a, _Ctx ctx) fn) {
    final first = names.split(' ').first;
    def(names, 1, 1, (args, ctx) => fn(_asMat(args[0], first), ctx));
  }

  m1('det', (a, _) => det(a));
  m1('tr trace', (a, _) {
    needSquare(a, 'The trace');
    return traceOf(a);
  });
  m1('rank', (a, _) => rank(a).toDouble());
  m1('inv', (a, _) => inverse(a));
  m1('transpose', (a, _) => transpose(a));
  m1('adj adjoint', (a, _) => adjugate(a));
  m1('cof cofactors', (a, _) => cofactorM(a));
  m1('minors', (a, _) => minorsM(a));
  m1('rref', (a, _) => rref(a));
  m1(
    'null nullspace',
    (a, _) =>
        nullspace(a) ??
        TextVal('Only the zero vector — the columns are independent.'),
  );
  m1(
    'colsp colspace',
    (a, _) => colspace(a) ?? TextVal('Only the zero vector.'),
  );
  m1('eig eigvals', (a, _) => ListVal('λ', eigenvalues(a)));
  m1('eigvec eigvecs', (a, ctx) {
    final r = eigenvectors(a);
    ctx.warnings.addAll(r.notes);
    return MultiVal(r.parts);
  });
  m1('charpoly', (a, _) => PolyVal(charpoly(a)));
  m1('lu', (a, ctx) {
    final r = lu(a);
    if (r.singular) {
      ctx.warnings.add(
        'This matrix is singular, so U has a zero on its diagonal.',
      );
    }
    return MultiVal([
      Part('P', r.p),
      Part('L', cleanM(r.l)),
      Part('U', cleanM(r.u)),
    ], relation: 'PA = LU');
  });
  m1('qr', (a, _) {
    final r = qr(a);
    return MultiVal([Part('Q', r.q), Part('R', r.r)], relation: 'A = QR');
  });
  m1(
    'chol cholesky',
    (a, _) => MultiVal([Part('L', cleanM(cholesky(a)))], relation: 'A = LLᵀ'),
  );
  m1('svd', (a, _) {
    final r = svd(a);
    return MultiVal([
      Part('U', r.u),
      Part('Σ', r.s),
      Part('Vᵀ', r.vt),
    ], relation: 'A = UΣVᵀ');
  });
  m1('pinv', (a, _) => pinv(a));
  m1('norm', (a, _) => frob(a));
  m1('norm1', (a, _) => norm1(a));
  m1('norm2', (a, _) => norm2(a));
  m1('norminf', (a, _) => normInf(a));
  m1('cond', (a, _) => cond(a));
  m1('expm', (a, _) => expm(a));
  m1('sinm', (a, _) => sincosm(a).sin);
  m1('cosm', (a, _) => sincosm(a).cos);
  m1('sqrtm', (a, _) => sqrtm(a));

  // Builders and multi-input functions.
  def('I eye', 1, 1, (a, _) => eye(_asSize(a[0], 'I(n)')));
  def('zeros', 1, 2, (a, _) {
    final r = _asSize(a[0], 'zeros');
    return zeros(r, a.length > 1 ? _asSize(a[1], 'zeros') : r);
  });
  def('ones', 1, 2, (a, _) {
    final r = _asSize(a[0], 'ones');
    final c = a.length > 1 ? _asSize(a[1], 'ones') : r;
    return mapM(zeros(r, c), (_, _, _) => 1);
  });
  def('diag', 1, 1, (args, _) {
    final a = _asMat(args[0], 'diag');
    if (a.rows == 1 || a.cols == 1) {
      final d = a.rows == 1 ? a.data[0] : col(a, 0);
      final out = zeros(d.length, d.length);
      for (var i = 0; i < d.length; i++) {
        out.data[i][i] = d[i];
      }
      return out;
    }
    needSquare(a, 'diag');
    return Mat([
      for (var i = 0; i < a.rows; i++) [a.data[i][i]],
    ]);
  });
  def('aug', 2, 2, (args, _) {
    final a = _asMat(args[0], 'aug'), b = _asMat(args[1], 'aug');
    if (a.rows != b.rows) {
      throw MathError('aug needs matching rows', '${desc(a)} vs ${desc(b)}.');
    }
    return Mat([
      for (var i = 0; i < a.rows; i++) [...a.data[i], ...b.data[i]],
    ]);
  });
  def('sub', 3, 3, (args, _) {
    final a = _asMat(args[0], 'sub');
    final i = _asInt(args[1], 'sub'), j = _asInt(args[2], 'sub');
    if (i > a.rows || j > a.cols) {
      throw MathError('That row or column doesn’t exist', '${desc(a)}.');
    }
    if (a.rows < 2 || a.cols < 2) {
      throw MathError('sub needs at least a 2×2 matrix');
    }
    return Mat([
      for (var k = 0; k < a.rows; k++)
        if (k != i - 1)
          [
            for (var l = 0; l < a.cols; l++)
              if (l != j - 1) a.data[k][l],
          ],
    ]);
  });
  def('row', 2, 2, (args, _) {
    final a = _asMat(args[0], 'row'), i = _asInt(args[1], 'row');
    if (i > a.rows) throw MathError('Row $i doesn’t exist', '${desc(a)}.');
    return Mat([List<double>.of(a.data[i - 1])]);
  });
  def('column', 2, 2, (args, _) {
    final a = _asMat(args[0], 'column'), j = _asInt(args[1], 'column');
    if (j > a.cols) throw MathError('Column $j doesn’t exist', '${desc(a)}.');
    return Mat([
      for (final r in a.data) [r[j - 1]],
    ]);
  });
  List<double> vecOf(Object v, String fname) {
    final a = _asMat(v, fname);
    if (a.rows != 1 && a.cols != 1) {
      throw MathError(
        '$fname(…) needs vectors',
        '${desc(a)} is not a single row or column.',
      );
    }
    return a.rows == 1 ? List<double>.of(a.data[0]) : col(a, 0);
  }

  def('dot', 2, 2, (args, _) {
    final u = vecOf(args[0], 'dot'), v = vecOf(args[1], 'dot');
    if (u.length != v.length) {
      throw MathError('dot needs vectors of the same length');
    }
    var s = 0.0;
    for (var i = 0; i < u.length; i++) {
      s += u[i] * v[i];
    }
    return s;
  });
  def('cross', 2, 2, (args, _) {
    final u = vecOf(args[0], 'cross'), v = vecOf(args[1], 'cross');
    if (u.length != 3 || v.length != 3) {
      throw MathError('cross needs two 3-vectors');
    }
    final w = [
      u[1] * v[2] - u[2] * v[1],
      u[2] * v[0] - u[0] * v[2],
      u[0] * v[1] - u[1] * v[0],
    ];
    final a = args[0];
    return a is Mat && a.rows == 1
        ? Mat([w])
        : Mat([
            for (final x in w) [x],
          ]);
  });
  def('kron', 2, 2, (args, _) {
    final a = _asMat(args[0], 'kron'), b = _asMat(args[1], 'kron');
    if (a.rows * b.rows > maxGeneratedSize ||
        a.cols * b.cols > maxGeneratedSize) {
      throw MathError(
        'That matrix would be too large',
        'Sizes up to $maxGeneratedSize are supported.',
      );
    }
    return kron(a, b);
  });
  def(
    'hadamard',
    2,
    2,
    (args, _) =>
        _hadamard(_asMat(args[0], 'hadamard'), _asMat(args[1], 'hadamard')),
  );
  def(
    'solve',
    2,
    2,
    (args, ctx) => solve(
      _asMat(args[0], 'solve'),
      _asMat(args[1], 'solve'),
      ctx.warnings.add,
    ),
  );
  return f;
}

const Map<String, double> _consts = {'π': math.pi, 'pi': math.pi, 'e': math.e};

/// Names a user value can't take.
final Set<String> reservedNames = {..._funcs.keys, ..._consts.keys, 'I', 'T'};

/* ---------- tree walk ---------- */

/// Rejects results that can't take part in further arithmetic.
Object _need(Object v) {
  if (v is double || v is Mat || v is Eye) return v;
  if (v is InvalidVal) {
    throw MathError('Matrix ${v.name} has an entry that needs fixing', v.where);
  }
  throw MathError(
    'This result can’t be used inside a calculation',
    'Functions like eig, lu or svd give several outputs — use them on their own line.',
  );
}

Object _lookup(String name, _Ctx ctx) {
  final v = ctx.vars[name];
  if (v != null) return v;
  final c = _consts[name];
  if (c != null) return c;
  if (name == 'I') return const Eye(1);
  throw unknownName(name);
}

Object _postOp(String op, Object v, _Ctx ctx) {
  switch (op) {
    case 'T':
      return v is Mat ? transpose(v) : v;
    case 'inv':
      if (v is double) {
        if (v == 0) throw MathError('Division by zero');
        return 1 / v;
      }
      return inverse(_asMat(v, 'inverse'));
    case 'sq':
      return v is double ? v * v : matPow(_asMat(v, 'power'), 2);
    case 'cube':
      return v is double ? v * v * v : matPow(_asMat(v, 'power'), 3);
    case 'deg':
      return _elementwise(v, (x) => ctx.deg ? x : x * math.pi / 180);
    case 'fact':
      return _elementwise(v, _factorial);
    default:
      throw MathError('Unknown operator');
  }
}

Object _eval(_Node n, _Ctx ctx) {
  final v = _evalNode(n, ctx);
  ctx.vals?[n] = v;
  return v;
}

Object _evalNode(_Node n, _Ctx ctx) {
  switch (n.k) {
    case 'num':
      return n.v;
    case 'id':
      return _lookup(n.s, ctx);
    case 'neg':
      final v = _eval(n.a!, ctx);
      return v is Eye ? Eye(-v.s) : _mul(-1.0, _need(v));
    case 'bin':
      final a = _need(_eval(n.a!, ctx)), b = _need(_eval(n.b!, ctx));
      switch (n.s) {
        case '+':
          return _add(a, b, 1);
        case '-':
          return _add(a, b, -1);
        case '*':
          return _mul(a, b);
        case '/':
          return _div(a, b, ctx);
        default:
          return _hadamard(a, b);
      }
    case 'pow':
      final e = n.b!;
      // A^T is a transpose unless the user defined a value called T.
      if (e.k == 'id' && e.s == 'T' && !ctx.vars.containsKey('T')) {
        return _postOp('T', _need(_eval(n.a!, ctx)), ctx);
      }
      final a = _need(_eval(n.a!, ctx)), b = _need(_eval(e, ctx));
      if (b is! double) {
        throw MathError(
          'Exponents must be numbers',
          'For example A^3 or 2^0.5.',
        );
      }
      if (a is double) {
        final r = math.pow(a, b).toDouble();
        if (r.isNaN) {
          throw MathError(
            'The result isn’t a real number',
            'A negative number can’t take a fractional power.',
          );
        }
        return r;
      }
      if (a is Eye) return Eye(math.pow(a.s, b).toDouble());
      if ((b - b.roundToDouble()).abs() < 1e-9) {
        return matPow(a as Mat, b.round());
      }
      if ((b - 0.5).abs() < 1e-12) return sqrtm(a as Mat);
      throw MathError(
        'Matrix powers need a whole number',
        'Use sqrtm(A) for a square root.',
      );
    case 'post':
      return _postOp(n.s, _need(_eval(n.a!, ctx)), ctx);
    case 'lit':
      final rows = [
        for (final r in n.rows!)
          [
            for (final e in r)
              () {
                final v = _need(_eval(e, ctx));
                if (v is! double) {
                  throw MathError('Entries inside [ ] must be numbers');
                }
                return v;
              }(),
          ],
      ];
      if (rows.any((r) => r.length != rows[0].length)) {
        throw MathError(
          'Every row needs the same number of entries',
          'Separate entries with “,” and rows with “;”.',
        );
      }
      return Mat(rows);
    case 'bars':
      final v = _need(_eval(n.a!, ctx));
      return v is double ? v.abs() : det(_asMat(v, '|…|'));
    case 'call':
      final f = _funcs[n.s]!, args = n.args!;
      if (args.length < f.min || args.length > f.max) {
        throw MathError(
          '${n.s}(…) takes ${f.min == f.max ? f.min : '${f.min}–${f.max}'} input${f.max > 1 ? 's' : ''}',
          'It got ${args.length}.',
        );
      }
      return f.fn([for (final a in args) _need(_eval(a, ctx))], ctx);
    default:
      throw MathError('Unknown expression');
  }
}

/* ---------- public API ---------- */

class EvalResult {
  EvalResult.success(Object this.value, this.warnings, this.assign)
    : ok = true,
      empty = false,
      error = null,
      hint = '',
      unknown = null;
  EvalResult.failure(
    String this.error, {
    this.hint = '',
    this.unknown,
    this.assign,
  }) : ok = false,
       empty = false,
       value = null,
       warnings = const [];
  EvalResult.empty(this.assign)
    : ok = false,
      empty = true,
      value = null,
      warnings = const [],
      error = null,
      hint = '',
      unknown = null;

  final bool ok;

  /// True for "M =" with nothing after it yet.
  final bool empty;
  final Object? value;
  final List<String> warnings;

  /// Name being assigned, for lines like `M = A·B`.
  final String? assign;
  final String? error;
  final String hint;
  final String? unknown;
}

final _assignRe = RegExp(
  r'^\s*([A-Za-z][A-Za-z0-9_]*|[α-ωΑ-Ω])\s*=(?!=)(.*)$',
  dotAll: true,
);

/// Splits `name = body`, or returns null when the line isn't an assignment.
({String name, String body})? splitAssignment(String text) {
  final m = _assignRe.firstMatch(text);
  return m == null ? null : (name: m[1]!, body: m[2]!);
}

/// Evaluates one line. [vars] holds matrices and named values (`double`,
/// [Mat] or [InvalidVal]); [matrixNames] are names owned by the matrix rail.
EvalResult evaluate(
  String text, {
  Map<String, Object> vars = const {},
  bool degrees = false,
  Set<String> matrixNames = const {},
}) {
  final ctx = _Ctx(vars, degrees);
  var body = text;
  String? assign;
  try {
    final a = splitAssignment(text);
    if (a != null) {
      if (_capsRun.hasMatch(a.name)) {
        throw MathError(
          'Use one capital letter or a lowercase name',
          'Capitals side by side multiply, so AB means A·B.',
        );
      }
      if (reservedNames.contains(a.name)) {
        throw MathError(
          '“${a.name}” is a built-in name',
          'Pick another name for this value.',
        );
      }
      if (matrixNames.contains(a.name)) {
        throw MathError(
          '${a.name} is already a matrix',
          'Pick another name, or edit the matrix directly.',
        );
      }
      assign = a.name;
      body = a.body;
    }
    if (body.trim().isEmpty) return EvalResult.empty(assign);
    var v = _eval(_Parser(body, ctx.vars).parse(), ctx);
    if (v is Eye) {
      throw MathError(
        'I needs a size here',
        'Write I(3), or use it next to a matrix like A − 2I.',
      );
    }
    if (v is Mat) v = cleanM(v);
    if (v is double) v = cleanNum(v);
    return EvalResult.success(v, ctx.warnings, assign);
  } on MathError catch (e) {
    return EvalResult.failure(
      e.message,
      hint: e.hint,
      unknown: e.unknown,
      assign: assign,
    );
  } catch (e) {
    return EvalResult.failure(
      'Something went wrong evaluating this',
      hint: '$e',
      assign: assign,
    );
  }
}

/// Evaluates a single matrix entry, which must come out as one number.
EvalResult evalScalar(String text, {bool degrees = false}) {
  final r = evaluate(text, degrees: degrees);
  if (r.empty) return EvalResult.failure('Empty entry');
  if (r.ok && r.value is! double) {
    return EvalResult.failure('An entry must be a single number');
  }
  return r;
}
