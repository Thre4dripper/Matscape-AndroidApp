/// Core linear algebra: elimination, decompositions, eigen-analysis,
/// matrix functions and step-by-step row reduction.
library;

import 'dart:math' as math;

import 'format.dart';
import 'types.dart';

/* ---------- elimination ---------- */

class LuResult {
  LuResult(this.l, this.u, this.p, this.swaps, this.singular);
  final Mat l, u, p;
  final int swaps;
  final bool singular;
}

LuResult lu(Mat a) {
  needSquare(a, 'LU decomposition');
  final n = a.rows, u = copyData(a), l = eye(n).data;
  final perm = List<int>.generate(n, (i) => i);
  final tol = tolFor(a, 1e-12);
  var swaps = 0, singular = false;
  for (var k = 0; k < n; k++) {
    var p = k;
    for (var i = k + 1; i < n; i++) {
      if (u[i][k].abs() > u[p][k].abs()) p = i;
    }
    if (u[p][k].abs() <= tol) {
      singular = true;
      for (var i = k; i < n; i++) {
        u[i][k] = 0;
      }
      continue;
    }
    if (p != k) {
      final tr = u[p];
      u[p] = u[k];
      u[k] = tr;
      final tp = perm[p];
      perm[p] = perm[k];
      perm[k] = tp;
      for (var j = 0; j < k; j++) {
        final t = l[p][j];
        l[p][j] = l[k][j];
        l[k][j] = t;
      }
      swaps++;
    }
    for (var i = k + 1; i < n; i++) {
      final f = u[i][k] / u[k][k];
      l[i][k] = f;
      u[i][k] = 0;
      for (var j = k + 1; j < n; j++) {
        u[i][j] -= f * u[k][j];
      }
    }
  }
  final pm = zeros(n, n);
  for (var i = 0; i < n; i++) {
    pm.data[i][perm[i]] = 1;
  }
  return LuResult(Mat(l), Mat(u), pm, swaps, singular);
}

double det(Mat a) {
  needSquare(a, 'The determinant');
  final n = a.rows, d = a.data;
  if (n == 1) return d[0][0];
  if (n == 2) return d[0][0] * d[1][1] - d[0][1] * d[1][0];
  final r = lu(a);
  if (r.singular) return 0;
  var out = r.swaps.isOdd ? -1.0 : 1.0;
  for (var i = 0; i < n; i++) {
    out *= r.u.data[i][i];
  }
  return out;
}

Mat inverse(Mat a) {
  needSquare(a, 'The inverse');
  final n = a.rows, id = eye(n).data, tol = tolFor(a);
  final m = [
    for (var i = 0; i < n; i++) [...a.data[i], ...id[i]],
  ];
  for (var c = 0; c < n; c++) {
    var p = c;
    for (var i = c + 1; i < n; i++) {
      if (m[i][c].abs() > m[p][c].abs()) p = i;
    }
    if (m[p][c].abs() <= tol) {
      throw MathError(
        '${a.label ?? 'This matrix'} is singular, so it has no inverse',
        'Its determinant is 0. Try pinv(${a.label ?? 'A'}) for the pseudo-inverse.',
      );
    }
    final t = m[p];
    m[p] = m[c];
    m[c] = t;
    final pv = m[c][c];
    for (var j = 0; j < 2 * n; j++) {
      m[c][j] /= pv;
    }
    for (var i = 0; i < n; i++) {
      if (i == c) continue;
      final f = m[i][c];
      if (f != 0) {
        for (var j = 0; j < 2 * n; j++) {
          m[i][j] -= f * m[c][j];
        }
      }
    }
  }
  return Mat([for (final r in m) r.sublist(n)]);
}

class RowStep {
  RowStep(this.ops, this.m);
  final List<String> ops;
  final Mat m;
}

class RrefResult {
  RrefResult(this.r, this.pivots, this.steps, this.swaps);
  final Mat r;
  final List<int> pivots;
  final List<RowStep> steps;
  final int swaps;
}

/// Gauss–Jordan elimination. [hand] picks the first usable pivot (as you
/// would on paper) instead of the largest; [upperOnly] stops at echelon form.
RrefResult rrefCore(
  Mat a, {
  int? augAt,
  double? tol,
  bool hand = false,
  bool upperOnly = false,
}) {
  final r = copyData(a), m = a.rows, n = a.cols, lim = augAt ?? n;
  final t = tol ?? tolFor(a, 1e-10);
  final steps = <RowStep>[], pivots = <int>[];
  var row = 0, swaps = 0;
  Mat snap() => Mat([
    for (final rr in r) [for (final x in rr) x.abs() <= t ? 0.0 : x],
  ]);
  for (var c = 0; c < lim && row < m; c++) {
    var p = row;
    if (hand) {
      while (p < m && r[p][c].abs() <= t) {
        p++;
      }
      if (p == m) p = row;
    } else {
      for (var i = row + 1; i < m; i++) {
        if (r[i][c].abs() > r[p][c].abs()) p = i;
      }
    }
    if (r[p][c].abs() <= t) {
      for (var i = row; i < m; i++) {
        r[i][c] = 0;
      }
      continue;
    }
    if (p != row) {
      final tmp = r[p];
      r[p] = r[row];
      r[row] = tmp;
      swaps++;
      steps.add(RowStep(['R${row + 1} ↔ R${p + 1}'], snap()));
    }
    if (!upperOnly) {
      final pv = r[row][c];
      if ((pv - 1).abs() > t) {
        for (var j = 0; j < n; j++) {
          r[row][j] /= pv;
        }
        r[row][c] = 1;
        steps.add(
          RowStep(['R${row + 1} → R${row + 1} ÷ ${divTxt(pv)}'], snap()),
        );
      }
    }
    final ops = <String>[];
    for (var i = upperOnly ? row + 1 : 0; i < m; i++) {
      if (i == row) continue;
      final f = r[i][c] / r[row][c];
      if (r[i][c].abs() <= t) {
        r[i][c] = 0;
        continue;
      }
      for (var j = 0; j < n; j++) {
        r[i][j] -= f * r[row][j];
      }
      r[i][c] = 0;
      ops.add(
        f > 0
            ? 'R${i + 1} → R${i + 1} − ${coefTxt(f)}R${row + 1}'
            : 'R${i + 1} → R${i + 1} + ${coefTxt(-f)}R${row + 1}',
      );
    }
    if (ops.isNotEmpty) steps.add(RowStep(ops, snap()));
    pivots.add(c);
    row++;
  }
  return RrefResult(snap(), pivots, steps, swaps);
}

Mat rref(Mat a) => rrefCore(a).r;

int rank(Mat a) => rrefCore(a).pivots.length;

Mat? nullspace(Mat a, [double? tol]) {
  final res = rrefCore(a, tol: tol);
  final free = [
    for (var c = 0; c < a.cols; c++)
      if (!res.pivots.contains(c)) c,
  ];
  if (free.isEmpty) return null;
  final b = zeros(a.cols, free.length);
  for (var k = 0; k < free.length; k++) {
    final f = free[k];
    b.data[f][k] = 1;
    for (var row = 0; row < res.pivots.length; row++) {
      b.data[res.pivots[row]][k] = -res.r.data[row][f];
    }
  }
  return b;
}

Mat? colspace(Mat a) {
  final pivots = rrefCore(a).pivots;
  if (pivots.isEmpty) return null;
  return fromCols([for (final j in pivots) col(a, j)]);
}

double _minorOf(Mat a, int r, int c) {
  final rows = [
    for (var i = 0; i < a.rows; i++)
      if (i != r)
        [
          for (var j = 0; j < a.cols; j++)
            if (j != c) a.data[i][j],
        ],
  ];
  return rows.isEmpty ? 1 : det(Mat(rows));
}

Mat minorsM(Mat a) {
  needSquare(a, 'The minor matrix');
  if (a.rows < 2) throw MathError('Minors need at least a 2×2 matrix');
  return mapM(a, (_, i, j) => _minorOf(a, i, j));
}

Mat cofactorM(Mat a) {
  needSquare(a, 'The cofactor matrix');
  if (a.rows < 2) throw MathError('Cofactors need at least a 2×2 matrix');
  return mapM(a, (_, i, j) => ((i + j).isOdd ? -1 : 1) * _minorOf(a, i, j));
}

Mat adjugate(Mat a) {
  needSquare(a, 'The adjugate');
  if (a.rows == 1) {
    return Mat([
      [1.0],
    ]);
  }
  return transpose(cofactorM(a));
}

/* ---------- decompositions ---------- */

class QrResult {
  QrResult(this.q, this.r);
  final Mat q, r;
}

/// Householder QR with a non-negative diagonal on R.
QrResult qr(Mat a) {
  final m = a.rows, n = a.cols, r = copyData(a), q = eye(m).data;
  for (var k = 0; k < math.min(m - 1, n); k++) {
    final x = [for (var i = k; i < m; i++) r[i][k]];
    final nx = vnorm(x);
    if (nx < 1e-14) continue;
    final alpha = -(x[0] >= 0 ? 1 : -1) * nx;
    final v = List<double>.of(x);
    v[0] -= alpha;
    final nv = vnorm(v);
    if (nv < 1e-14) continue;
    for (var i = 0; i < v.length; i++) {
      v[i] /= nv;
    }
    for (var j = 0; j < n; j++) {
      var s = 0.0;
      for (var i = 0; i < v.length; i++) {
        s += v[i] * r[k + i][j];
      }
      for (var i = 0; i < v.length; i++) {
        r[k + i][j] -= 2 * v[i] * s;
      }
    }
    for (var i = 0; i < m; i++) {
      var s = 0.0;
      for (var t = 0; t < v.length; t++) {
        s += q[i][k + t] * v[t];
      }
      for (var t = 0; t < v.length; t++) {
        q[i][k + t] -= 2 * s * v[t];
      }
    }
  }
  for (var k = 0; k < math.min(m, n); k++) {
    if (r[k][k] < 0) {
      for (var j = 0; j < n; j++) {
        r[k][j] = -r[k][j];
      }
      for (var i = 0; i < m; i++) {
        q[i][k] = -q[i][k];
      }
    }
  }
  for (var i = 0; i < m; i++) {
    for (var j = 0; j < math.min(i, n); j++) {
      r[i][j] = 0;
    }
  }
  return QrResult(cleanM(Mat(q)), cleanM(Mat(r)));
}

bool isSymmetric(Mat a) =>
    a.rows == a.cols && approxEq(a, transpose(a), tolFor(a, 1e-9));

Mat cholesky(Mat a) {
  needSquare(a, 'Cholesky');
  if (!isSymmetric(a)) {
    throw MathError(
      'Cholesky needs a symmetric matrix',
      '${a.label ?? 'This matrix'} isn’t symmetric. Try lu(…) or qr(…) instead.',
    );
  }
  final n = a.rows, l = zeros(n, n).data, tol = tolFor(a, 1e-12);
  for (var i = 0; i < n; i++) {
    for (var j = 0; j <= i; j++) {
      var s = a.data[i][j];
      for (var k = 0; k < j; k++) {
        s -= l[i][k] * l[j][k];
      }
      if (i == j) {
        if (s <= tol) {
          throw MathError(
            'Cholesky needs a positive definite matrix',
            'At least one eigenvalue is zero or negative.',
          );
        }
        l[i][i] = math.sqrt(s);
      } else {
        l[i][j] = s / l[j][j];
      }
    }
  }
  return Mat(l);
}

/* ---------- eigen-analysis ---------- */

class JacobiResult {
  JacobiResult(this.values, this.vectors);
  final List<double> values;
  final Mat vectors;
}

/// Eigen-decomposition of a symmetric matrix (cyclic Jacobi), largest first.
JacobiResult jacobi(Mat s) {
  final n = s.rows, a = copyData(s), v = eye(n).data;
  for (var sweep = 0; sweep < 100; sweep++) {
    var off = 0.0;
    for (var p = 0; p < n; p++) {
      for (var q = p + 1; q < n; q++) {
        off += a[p][q] * a[p][q];
      }
    }
    if (off < 1e-26) break;
    for (var p = 0; p < n; p++) {
      for (var q = p + 1; q < n; q++) {
        if (a[p][q].abs() < 1e-300) continue;
        final theta = (a[q][q] - a[p][p]) / (2 * a[p][q]);
        final t =
            (theta >= 0 ? 1 : -1) /
            (theta.abs() + math.sqrt(theta * theta + 1));
        final c = 1 / math.sqrt(t * t + 1), sn = t * c;
        for (var k = 0; k < n; k++) {
          final x = a[k][p], y = a[k][q];
          a[k][p] = c * x - sn * y;
          a[k][q] = sn * x + c * y;
        }
        for (var k = 0; k < n; k++) {
          final x = a[p][k], y = a[q][k];
          a[p][k] = c * x - sn * y;
          a[q][k] = sn * x + c * y;
        }
        for (var k = 0; k < n; k++) {
          final x = v[k][p], y = v[k][q];
          v[k][p] = c * x - sn * y;
          v[k][q] = sn * x + c * y;
        }
      }
    }
  }
  final order = List<int>.generate(n, (i) => i)
    ..sort((x, y) => a[y][y].compareTo(a[x][x]));
  final values = [for (final i in order) a[i][i]];
  final vecs = [
    for (final i in order)
      () {
        final vec = [for (final r in v) r[i]];
        var big = 0;
        for (var k = 0; k < vec.length; k++) {
          if (vec[k].abs() > vec[big].abs() + 1e-12) big = k;
        }
        return vec[big] < 0 ? [for (final x in vec) -x] : vec;
      }(),
  ];
  return JacobiResult(values, fromCols(vecs));
}

/// Characteristic polynomial (Faddeev–LeVerrier): [1, c_{n-1}, …, c_0].
List<double> charpoly(Mat a) {
  needSquare(a, 'The characteristic polynomial');
  final n = a.rows, id = eye(n), coeffs = <double>[1];
  var mk = zeros(n, n);
  var cPrev = 1.0;
  for (var k = 1; k <= n; k++) {
    mk = addM(mulM(a, mk), scaleM(id, cPrev));
    cPrev = -traceOf(mulM(a, mk)) / k;
    coeffs.add(cPrev);
  }
  return coeffs;
}

Complex _cadd(Complex a, Complex b) => Complex(a.re + b.re, a.im + b.im);
Complex _csub(Complex a, Complex b) => Complex(a.re - b.re, a.im - b.im);
Complex _cmul(Complex a, Complex b) =>
    Complex(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re);
Complex _cdiv(Complex a, Complex b) {
  var d = b.re * b.re + b.im * b.im;
  if (d == 0) d = 1e-300;
  return Complex(
    (a.re * b.re + a.im * b.im) / d,
    (a.im * b.re - a.re * b.im) / d,
  );
}

double _cabs(Complex a) => math.sqrt(a.re * a.re + a.im * a.im);

Complex _polyEval(List<double> cf, Complex z) {
  var acc = const Complex(0);
  for (final c in cf) {
    acc = _cadd(_cmul(acc, z), Complex(c));
  }
  return acc;
}

/// All roots of a monic polynomial (Durand–Kerner), snapped to simple
/// fractions when those are true roots.
List<Complex> polyRoots(List<double> cf) {
  final n = cf.length - 1;
  if (n < 1) return [];
  var big = 0.0;
  for (var i = 1; i < cf.length; i++) {
    big = math.max(big, cf[i].abs());
  }
  final bound = 1 + big;
  var z = const Complex(1);
  const seed = Complex(0.4, 0.9);
  final roots = <Complex>[];
  for (var k = 0; k < n; k++) {
    roots.add(Complex(z.re * bound * 0.5, z.im * bound * 0.5));
    z = _cmul(z, seed);
  }
  for (var it = 0; it < 2000; it++) {
    var maxD = 0.0;
    for (var i = 0; i < n; i++) {
      var den = const Complex(1);
      for (var j = 0; j < n; j++) {
        if (j != i) den = _cmul(den, _csub(roots[i], roots[j]));
      }
      final d = _cdiv(_polyEval(cf, roots[i]), den);
      roots[i] = _csub(roots[i], d);
      maxD = math.max(maxD, _cabs(d));
    }
    if (maxD < 1e-15 * bound) break;
  }
  var scale = 1.0;
  for (final c in cf) {
    scale = math.max(scale, c.abs());
  }
  double? snapTo(double x) {
    final f = fraction(x.abs(), 12);
    return f == null ? null : x.sign * f.$1 / f.$2;
  }

  return [
    for (var r in roots)
      () {
        if (r.im.abs() < 1e-7 * (1 + r.re.abs())) r = Complex(r.re, 0);
        final re = snapTo(r.re), im = r.im != 0 ? snapTo(r.im) : 0.0;
        if (re != null &&
            im != null &&
            (re - r.re).abs() < 1e-6 &&
            (im - r.im).abs() < 1e-6 &&
            _cabs(_polyEval(cf, Complex(re, im))) < 1e-8 * scale) {
          return Complex(re, im);
        }
        return r;
      }(),
  ];
}

({bool up, bool low}) isTriangular(Mat a) {
  final t = tolFor(a, 1e-12);
  var up = true, low = true;
  for (var i = 0; i < a.rows; i++) {
    for (var j = 0; j < a.cols; j++) {
      if (i > j && a.data[i][j].abs() > t) up = false;
      if (i < j && a.data[i][j].abs() > t) low = false;
    }
  }
  return (up: up, low: low);
}

/// Eigenvalues as `double`, or [Complex] for non-real ones.
List<Object> eigenvalues(Mat a) {
  needSquare(a, 'Eigenvalues');
  if (isSymmetric(a)) {
    final s = maxAbs(a);
    return [for (final x in jacobi(a).values) cleanNum(x, s)];
  }
  final tri = isTriangular(a);
  if (tri.up || tri.low) {
    final diag = [for (var i = 0; i < a.rows; i++) a.data[i][i]]
      ..sort((x, y) => y.compareTo(x));
    return diag;
  }
  final roots = polyRoots(charpoly(a));
  roots.sort((x, y) {
    final cx = x.im.abs() > 0 ? 1 : 0, cy = y.im.abs() > 0 ? 1 : 0;
    if (cx != cy) return cx - cy;
    if (x.re != y.re) return y.re.compareTo(x.re);
    return y.im.compareTo(x.im);
  });
  return [for (final r in roots) r.im == 0 ? r.re : r];
}

List<double> _gaussSolve(Mat a, List<double> b) {
  final n = a.rows;
  final m = [
    for (var i = 0; i < n; i++) [...a.data[i], b[i]],
  ];
  for (var c = 0; c < n; c++) {
    var p = c;
    for (var i = c + 1; i < n; i++) {
      if (m[i][c].abs() > m[p][c].abs()) p = i;
    }
    final t = m[p];
    m[p] = m[c];
    m[c] = t;
    if (m[c][c].abs() < 1e-300) m[c][c] = 1e-300;
    for (var i = c + 1; i < n; i++) {
      final f = m[i][c] / m[c][c];
      for (var j = c; j <= n; j++) {
        m[i][j] -= f * m[c][j];
      }
    }
  }
  final x = List<double>.filled(n, 0);
  for (var i = n - 1; i >= 0; i--) {
    var s = m[i][n];
    for (var j = i + 1; j < n; j++) {
      s -= m[i][j] * x[j];
    }
    x[i] = s / m[i][i];
  }
  return x;
}

class EigvecResult {
  EigvecResult(this.parts, this.notes);
  final List<Part> parts;
  final List<String> notes;
}

EigvecResult eigenvectors(Mat a) {
  needSquare(a, 'Eigenvectors');
  final scale = math.max(1.0, maxAbs(a)), n = a.rows;
  final parts = <Part>[], notes = <String>[];
  if (isSymmetric(a)) {
    final jr = jacobi(a);
    final groups = <({double l, List<int> idx})>[];
    for (var i = 0; i < jr.values.length; i++) {
      final v = jr.values[i];
      final at = groups.indexWhere((g) => (g.l - v).abs() < 1e-8 * scale);
      if (at >= 0) {
        groups[at].idx.add(i);
      } else {
        groups.add((l: v, idx: [i]));
      }
    }
    for (final g in groups) {
      parts.add(
        Part(
          'λ = ${plain(cleanNum(g.l, scale))}',
          cleanM(fromCols([for (final i in g.idx) col(jr.vectors, i)])),
        ),
      );
    }
    return EigvecResult(parts, [
      'Unit-length eigenvectors (A is symmetric, so they’re orthogonal).',
    ]);
  }
  final vals = eigenvalues(a), seen = <double>[];
  var complexCount = 0;
  for (final l in vals) {
    if (l is! double) {
      complexCount++;
      continue;
    }
    if (seen.any((s) => (s - l).abs() < 1e-7 * scale)) continue;
    seen.add(l);
    final ash = addM(a, eye(n), -l);
    var ns = nullspace(ash, 1e-7 * scale);
    if (ns == null) {
      // Inverse iteration when the shifted matrix is numerically regular.
      var x = List<double>.filled(n, 1);
      final bm = addM(ash, eye(n), -1e-9 * scale);
      for (var k = 0; k < 30; k++) {
        x = _gaussSolve(bm, x);
        var nx = vnorm(x);
        if (nx == 0) nx = 1;
        x = [for (final v in x) v / nx];
      }
      ns = fromCols([x]);
    }
    parts.add(Part('λ = ${plain(l)}', cleanM(ns)));
  }
  if (complexCount > 0) {
    notes.add(
      '$complexCount complex eigenvalue${complexCount > 1 ? 's' : ''} — their eigenvectors are complex and aren’t shown.',
    );
  }
  if (parts.isEmpty) {
    throw MathError(
      'No real eigenvalues',
      'All eigenvalues are complex. Use eig(…) to see them.',
    );
  }
  return EigvecResult(parts, notes);
}

class SvdResult {
  SvdResult(this.u, this.s, this.vt, this.sigma);
  final Mat u, s, vt;
  final List<double> sigma;
}

SvdResult svd(Mat a) {
  final m = a.rows, n = a.cols, r = math.min(m, n);
  final jr = jacobi(mulM(transpose(a), a));
  final sig = [
    for (var i = 0; i < r; i++) math.sqrt(math.max(jr.values[i], 0.0)),
  ];
  final tol = 1e-10 * math.max(1.0, sig.isEmpty ? 0.0 : sig[0]);
  final vc = [for (var k = 0; k < r; k++) col(jr.vectors, k)];
  final uc = List<List<double>?>.filled(r, null);
  for (var k = 0; k < r; k++) {
    if (sig[k] > tol) {
      final av = mulM(a, fromCols([vc[k]]));
      uc[k] = [for (final x in av.data) x[0] / sig[k]];
    }
  }
  // Complete U with unit vectors orthogonal to the ones already found.
  for (var k = 0; k < r; k++) {
    if (uc[k] != null) continue;
    for (var e = 0; e < m; e++) {
      var v = List<double>.filled(m, 0);
      v[e] = 1;
      for (final u in uc) {
        if (u == null) continue;
        var d = 0.0;
        for (var i = 0; i < m; i++) {
          d += u[i] * v[i];
        }
        v = [for (var i = 0; i < m; i++) v[i] - d * u[i]];
      }
      final nv = vnorm(v);
      if (nv > 1e-6) {
        uc[k] = [for (final x in v) x / nv];
        break;
      }
    }
  }
  final s = zeros(r, r);
  for (var i = 0; i < r; i++) {
    s.data[i][i] = sig[i];
  }
  return SvdResult(
    cleanM(fromCols([for (final u in uc) u!])),
    cleanM(s),
    cleanM(transpose(fromCols(vc))),
    sig,
  );
}

Mat pinv(Mat a) {
  final r = svd(a);
  final tol = 1e-10 * math.max(1.0, r.sigma.isEmpty ? 0.0 : r.sigma[0]);
  final sp = mapM(r.s, (x, i, j) => i == j && x > tol ? 1 / x : 0);
  return cleanM(mulM(mulM(transpose(r.vt), sp), transpose(r.u)));
}

