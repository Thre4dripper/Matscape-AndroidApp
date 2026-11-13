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

