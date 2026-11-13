/// Matscape math engine — value types and basic matrix helpers.
/// Pure Dart: no Flutter imports, shared as-is by Android and iOS.
library;

import 'dart:math' as math;

class MathError implements Exception {
  MathError(this.message, [this.hint = '', this.unknown]);
  final String message;
  final String hint;

  /// Set when the error is an undefined name (lets callers retry later).
  final String? unknown;

  @override
  String toString() => message;
}

final _singleCap = RegExp(r'^[A-Z]$');

MathError unknownName(String name) => MathError(
  'Unknown name “$name”',
  _singleCap.hasMatch(name)
      ? 'Create matrix $name with the + button, or define it in a line like $name = [1, 2; 3, 4].'
      : 'Define it first in its own line, like $name = 2.',
  name,
);

/// Real-valued dense matrix.
class Mat {
  Mat(this.data, {this.label}) : rows = data.length, cols = data[0].length;
  final List<List<double>> data;
  final int rows;
  final int cols;

  /// Name of the user matrix this came from, used in error messages.
  String? label;
}

/// A size-less identity scaled by [s]; adapts to its neighbour (A − 2I).
class Eye {
  const Eye(this.s);
  final double s;
}

class Complex {
  const Complex(this.re, [this.im = 0]);
  final double re;
  final double im;
}

/// Several scalars, e.g. eigenvalues. Items are `double` or [Complex].
class ListVal {
  ListVal(this.sym, this.items);
  final String sym;
  final List<Object> items;
}

class Part {
  Part(this.label, this.value);
  final String label;
  final Mat value;
}

/// Several labelled matrices, e.g. a decomposition.
class MultiVal {
  MultiVal(this.parts, {this.relation});
  final String? relation;
  final List<Part> parts;
}

/// Polynomial coefficients, highest power first.
class PolyVal {
  PolyVal(this.coeffs);
  final List<double> coeffs;
}

class TextVal {
  TextVal(this.text);
  final String text;
}

/// A user matrix with an entry that failed to evaluate.
class InvalidVal {
  InvalidVal(this.name, this.where);
  final String name;
  final String where;
}

/* ---------- matrix basics ---------- */

Mat zeros(int r, int c) =>
    Mat(List.generate(r, (_) => List<double>.filled(c, 0)));

Mat eye(int n) {
  final m = zeros(n, n);
  for (var i = 0; i < n; i++) {
    m.data[i][i] = 1;
  }
  return m;
}

List<List<double>> copyData(Mat a) => [
  for (final r in a.data) List<double>.of(r),
];

String dims(Mat a) => '${a.rows}×${a.cols}';

String desc(Mat a) =>
    a.label != null ? '${a.label} (${dims(a)})' : 'a ${dims(a)} matrix';

Mat mapM(Mat a, double Function(double x, int i, int j) f) => Mat([
  for (var i = 0; i < a.rows; i++)
    [for (var j = 0; j < a.cols; j++) f(a.data[i][j], i, j)],
]);

Mat transpose(Mat a) => Mat([
  for (var j = 0; j < a.cols; j++)
    [for (var i = 0; i < a.rows; i++) a.data[i][j]],
]);

/// a + s·b
Mat addM(Mat a, Mat b, [double s = 1]) =>
    mapM(a, (x, i, j) => x + s * b.data[i][j]);

Mat scaleM(Mat a, double k) => mapM(a, (x, _, _) => x * k);

Mat mulM(Mat a, Mat b) {
  final r = zeros(a.rows, b.cols);
  for (var i = 0; i < a.rows; i++) {
    final ri = r.data[i];
    for (var k = 0; k < a.cols; k++) {
      final x = a.data[i][k];
      if (x == 0) continue;
      final bk = b.data[k];
      for (var j = 0; j < b.cols; j++) {
        ri[j] += x * bk[j];
      }
    }
  }
  return r;
}

double traceOf(Mat a) {
  var s = 0.0;
  for (var i = 0; i < math.min(a.rows, a.cols); i++) {
    s += a.data[i][i];
  }
  return s;
}

double maxAbs(Mat a) {
  var m = 0.0;
  for (final r in a.data) {
    for (final x in r) {
      if (x.abs() > m) m = x.abs();
    }
  }
  return m;
}

double tolFor(Mat a, [double k = 1e-10]) => k * math.max(1.0, maxAbs(a));

double cleanNum(double x, [double s = 1]) =>
    x.abs() < 1e-11 * math.max(1.0, s) ? 0 : x;

Mat cleanM(Mat a) {
  final s = maxAbs(a);
  return mapM(a, (x, _, _) => cleanNum(x, s));
}

bool approxEq(Mat a, Mat b, double t) {
  if (a.rows != b.rows || a.cols != b.cols) return false;
  for (var i = 0; i < a.rows; i++) {
    for (var j = 0; j < a.cols; j++) {
      // Written so NaN compares unequal, like the reference engine.
      if (!((a.data[i][j] - b.data[i][j]).abs() <= t)) return false;
    }
  }
  return true;
}

List<double> col(Mat a, int j) => [for (final r in a.data) r[j]];

Mat fromCols(List<List<double>> cols) => Mat([
  for (var i = 0; i < cols[0].length; i++) [for (final c in cols) c[i]],
]);

double vnorm(List<double> v) {
  var s = 0.0;
  for (final x in v) {
    s += x * x;
  }
  return math.sqrt(s);
}

void needSquare(Mat a, String what) {
  if (a.rows != a.cols) {
    throw MathError(
      '$what needs a square matrix',
      '${a.label ?? 'This matrix'} is ${dims(a)}.',
    );
  }
}
