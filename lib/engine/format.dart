/// Exact-looking number display: integers, fractions, surds, multiples of π.
library;

import 'dart:math' as math;

enum NumKind { special, integer, frac, surd, pi, dec }

/// How a number should be shown. Which fields are set depends on [kind]:
/// integer → [text]; frac → n/d; surd → n√k/d; pi → nπ/d;
/// dec → [text], or [mant]×10^[exp] for very large or small values.
class NumDesc {
  const NumDesc(
    this.kind, {
    this.neg = false,
    this.n = 0,
    this.d = 1,
    this.k = 0,
    this.text,
    this.mant,
    this.exp = 0,
  });
  final NumKind kind;
  final bool neg;
  final int n;
  final int d;
  final int k;
  final String? text;
  final String? mant;
  final int exp;
}

/// Shortest text for a double, without a trailing ".0".
String numStr(double v) {
  if (v == v.roundToDouble() && v.abs() < 1e21) return v.toStringAsFixed(0);
  return v.toString();
}

/// Best rational approximation h/k of [x] with k ≤ [maxDen], or null.
(int, int)? fraction(double x, int maxDen) {
  double h1 = 1, h0 = 0, k1 = 0, k0 = 1, b = x;
  bool ok() => k1 > 0 && (x - h1 / k1).abs() < 1e-9 * math.max(1.0, x.abs());
  for (var i = 0; i < 24; i++) {
    final a = b.floorToDouble();
    final h2 = a * h1 + h0, k2 = a * k1 + k0;
    if (k2 > maxDen) break;
    h0 = h1;
    h1 = h2;
    k0 = k1;
    k1 = k2;
    if (ok()) return (h1.round(), k1.round());
    final fr = b - a;
    if (fr < 1e-12) break;
    b = 1 / fr;
  }
  return ok() ? (h1.round(), k1.round()) : null;
}

NumDesc _decimal(double ax, int p, bool neg) {
  if (ax != 0 && (ax >= 1e9 || ax < 1e-4)) {
    final parts = ax.toStringAsExponential(math.max(1, p - 1)).split('e');
    return NumDesc(
      NumKind.dec,
      neg: neg,
      mant: numStr(double.parse(parts[0])),
      exp: int.parse(parts[1]),
    );
  }
  final text = numStr(double.parse(ax.toStringAsFixed(p)));
  if (text == '0') return const NumDesc(NumKind.integer, text: '0');
  return NumDesc(NumKind.dec, neg: neg, text: text);
}

NumDesc describe(double x, {bool exact = true, int precision = 4}) {
  if (!x.isFinite) {
    return NumDesc(
      NumKind.special,
      text: x.isNaN ? 'undefined' : (x > 0 ? '∞' : '−∞'),
    );
  }
  if (x.abs() < 1e-11) x = 0;
  final neg = x < 0, ax = x.abs();
  if (exact) {
    final r = ax.roundToDouble();
    if ((ax - r).abs() < 1e-9 * math.max(1.0, ax)) {
      return NumDesc(NumKind.integer, neg: neg && r != 0, text: numStr(r));
    }
    if (ax < 1e7) {
      final f = fraction(ax, 200);
      if (f != null) return NumDesc(NumKind.frac, neg: neg, n: f.$1, d: f.$2);
      for (final k in const [2, 3, 5, 6, 7, 10]) {
        final s = fraction(ax / math.sqrt(k), 60);
        if (s != null && s.$1 <= 60) {
          return NumDesc(NumKind.surd, neg: neg, n: s.$1, d: s.$2, k: k);
        }
      }
      final fp = fraction(ax / math.pi, 12);
      if (fp != null && fp.$1 <= 24) {
        return NumDesc(NumKind.pi, neg: neg, n: fp.$1, d: fp.$2);
      }
    }
  }
  return _decimal(ax, precision, neg);
}

/// One-line text form, used for copying, history and step descriptions.
String plain(double x, {bool exact = true, int precision = 4}) {
  final d = describe(x, exact: exact, precision: precision);
  final s = d.neg ? '−' : '';
  switch (d.kind) {
    case NumKind.special:
      return d.text!;
    case NumKind.integer:
      return s + d.text!;
    case NumKind.frac:
      return '$s${d.n}/${d.d}';
    case NumKind.surd:
      return '$s${d.n == 1 ? '' : d.n}√${d.k}${d.d == 1 ? '' : '/${d.d}'}';
    case NumKind.pi:
      return '$s${d.n == 1 ? '' : d.n}π${d.d == 1 ? '' : '/${d.d}'}';
    case NumKind.dec:
      return s + (d.text ?? '${d.mant}×10^${d.exp}');
  }
}

final _needsParens = RegExp(r'[/√π]');

/// Coefficient text for row operations: "" for 1, "(1/2)" for fractions.
String coefTxt(double f) {
  if ((f - 1).abs() < 1e-12) return '';
  final p = plain(f);
  return _needsParens.hasMatch(p) ? '($p)' : p;
}

String divTxt(double f) {
  final p = plain(f);
  return f < 0 || _needsParens.hasMatch(p) ? '($p)' : p;
}
