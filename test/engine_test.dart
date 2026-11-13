import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:matscape/engine/engine.dart';

Mat m(List<List<num>> rows) => Mat([
  for (final r in rows) [for (final x in r) x.toDouble()],
]);

void expectMat(Object? actual, List<List<num>> want, [double tol = 1e-9]) {
  expect(actual, isA<Mat>());
  final a = actual! as Mat;
  expect(a.rows, want.length, reason: 'rows');
  expect(a.cols, want[0].length, reason: 'cols');
  for (var i = 0; i < a.rows; i++) {
    for (var j = 0; j < a.cols; j++) {
      expect(a.data[i][j], closeTo(want[i][j], tol), reason: 'entry $i,$j');
    }
  }
}

void main() {
  final a = m([
    [4, 1, 2],
    [1, 3, 0],
    [2, 0, 5],
  ])..label = 'A';
  final b = m([
    [1, 2, 3],
    [4, 5, 6],
  ])..label = 'B';
  final vars = <String, Object>{'A': a, 'B': b, 'k': 3.0};

  Object? ev(String s, {bool degrees = false}) {
    final r = evaluate(s, vars: vars, degrees: degrees);
    expect(r.ok, isTrue, reason: '$s → ${r.error} ${r.hint}');
    return r.value;
  }

  EvalResult err(String s) {
    final r = evaluate(s, vars: vars);
    expect(r.ok, isFalse, reason: '$s should fail');
    return r;
  }

  group('scalars', () {
    test('arithmetic and precedence', () {
      expect(ev('1 + 2·3'), 7);
      expect(ev('2^3^2'), 512);
      expect(ev('−2^2'), -4);
      expect(ev('(1 + 2)(3 + 4)'), 21);
      expect(ev('2π'), closeTo(2 * math.pi, 1e-12));
      expect(ev('7 ÷ 2'), 3.5);
      expect(ev('5!'), 120);
      expect(ev('|−3|'), 3);
      expect(ev('mod(−1, 3)'), 2);
    });

    test('roots and functions', () {
      expect(ev('√16'), 4);
      expect(ev('2√9'), 6);
      expect(ev('∛27'), closeTo(3, 1e-12));
      expect(ev('ln(e)'), closeTo(1, 1e-12));
      expect(ev('log(1000)'), closeTo(3, 1e-12));
      expect(ev('round(2.5)'), 3);
      expect(ev('round(−2.5)'), -2);
    });

    test('angles', () {
      expect(ev('sin(30°)'), closeTo(0.5, 1e-12));
      expect(ev('sin(π/6)'), closeTo(0.5, 1e-12));
      expect(ev('sin(30)', degrees: true), closeTo(0.5, 1e-12));
      expect(ev('asin(1/2)', degrees: true), closeTo(30, 1e-9));
      expect(err('tan(π/2)').error, contains('undefined'));
    });

    test('named values', () {
      expect(ev('2k'), 6);
      final r = evaluate('x = 2k + 1', vars: vars);
      expect(r.assign, 'x');
      expect(r.value, 7);
      expect(evaluate('x =', vars: vars).empty, isTrue);
      expect(err('sin = 2').error, contains('built-in'));
      expect(err('AB = 2').error, contains('one capital'));
    });
  });

  group('matrices', () {
    test('determinant, trace, rank', () {
      expect(ev('det(A)'), closeTo(43, 1e-9));
      expect(ev('|A|'), closeTo(43, 1e-9));
      expect(ev('tr(A)'), 12);
      expect(ev('rank(A)'), 3);
      expect(ev('rank([1, 2; 2, 4])'), 1);
    });

    test('products and implicit multiplication', () {
      expectMat(ev('BA'), [
        [12, 7, 17],
        [33, 19, 38],
      ]);
      expectMat(ev('BBᵀ'), [
        [14, 32],
        [32, 77],
      ]);
      expectMat(ev('2[1, 2; 3, 4]'), [
        [2, 4],
        [6, 8],
      ]);
      expect(err('A + B').error, contains('Can’t add'));
      expect(err('AB').error, contains('Can’t multiply'));
    });

    test('inverse, powers, transpose', () {
      expectMat(ev('[1, 2; 3, 4]⁻¹'), [
        [-2, 1],
        [1.5, -0.5],
      ]);
      expectMat(ev('[1, 1; 0, 1]^3'), [
        [1, 3],
        [0, 1],
      ]);
      expectMat(ev('[1, 2; 3, 4]^T'), [
        [1, 3],
        [2, 4],
      ]);
      expectMat(ev("B'"), [
        [1, 4],
        [2, 5],
        [3, 6],
      ]);
      expect(err('[1, 2; 2, 4]⁻¹').error, contains('singular'));
    });

    test('bare I adapts to its neighbour', () {
      expect(ev('det([2, 1; 1, 3] − 2I)'), closeTo(-1, 1e-12));
      expectMat(ev('sin(30°)·I(2)'), [
        [0.5, 0],
        [0, 0.5],
      ]);
      expect(err('I').error, contains('needs a size'));
    });

    test('builders', () {
      expectMat(ev('aug([1; 2], [3; 4])'), [
        [1, 3],
        [2, 4],
      ]);
      expectMat(ev('sub(A, 1, 1)'), [
        [3, 0],
        [0, 5],
      ]);
      expectMat(ev('diag([1, 2])'), [
        [1, 0],
        [0, 2],
      ]);
      expectMat(ev('zeros(2, 3)'), [
        [0, 0, 0],
        [0, 0, 0],
      ]);
      expect(ev('dot([1, 2, 3], [4, 5, 6])'), 32);
      expectMat(ev('cross([1, 0, 0], [0, 1, 0])'), [
        [0, 0, 1],
      ]);
      expect(err('zeros(5000)').error, contains('too large'));
    });

    test('systems', () {
      final s = <String, Object>{
        'A': m([
          [2, 1, -1],
          [-3, -1, 2],
          [-2, 1, 2],
        ]),
        'B': m([
          [8],
          [-11],
          [-3],
        ]),
      };
      expectMat(evaluate('solve(A, B)', vars: s).value, [
        [2],
        [3],
        [-1],
      ]);
      expectMat(evaluate('rref(aug(A, B))', vars: s).value, [
        [1, 0, 0, 2],
        [0, 1, 0, 3],
        [0, 0, 1, -1],
      ]);
      expectMat(ev('null([1, 2; 2, 4])'), [
        [-2],
        [1],
      ]);
      expect(err('solve([1, 1; 1, 1], [1; 2])').error, contains('no solution'));
    });
  });

  group('eigen and decompositions', () {
    test('eigenvalues', () {
      final sym = ev('eig([2, 1; 1, 2])')! as ListVal;
      expect(sym.items[0], closeTo(3, 1e-9));
      expect(sym.items[1], closeTo(1, 1e-9));
      final rot = ev('eig([0, −1; 1, 0])')! as ListVal;
      final z = rot.items[0] as Complex;
      expect(z.re, closeTo(0, 1e-9));
      expect(z.im.abs(), closeTo(1, 1e-9));
      final gen = ev('eig([2, 0, 0; 1, 3, 0; 4, 5, 6])')! as ListVal;
      expect(gen.items, [6, 3, 2]);
    });

    test('characteristic polynomial', () {
      final p = ev('charpoly([2, 1; 1, 2])')! as PolyVal;
      expect(p.coeffs[0], 1);
      expect(p.coeffs[1], closeTo(-4, 1e-12));
      expect(p.coeffs[2], closeTo(3, 1e-12));
    });

    Mat part(Object? v, String label) =>
        (v! as MultiVal).parts.firstWhere((p) => p.label == label).value;

    test('LU reconstructs PA', () {
      final v = ev('lu(A)');
      final pa = mulM(part(v, 'P'), a), lu = mulM(part(v, 'L'), part(v, 'U'));
      expect(approxEq(pa, lu, 1e-9), isTrue);
    });

    test('QR reconstructs A with orthogonal Q', () {
      final v = ev('qr(B)');
      final q = part(v, 'Q');
      expect(approxEq(mulM(q, part(v, 'R')), b, 1e-9), isTrue);
      expect(approxEq(mulM(transpose(q), q), eye(2), 1e-9), isTrue);
    });

    test('SVD reconstructs A', () {
      final v = ev('svd(B)');
      final back = mulM(mulM(part(v, 'U'), part(v, 'Σ')), part(v, 'Vᵀ'));
      expect(approxEq(back, b, 1e-8), isTrue);
    });

    test('Cholesky', () {
      final l = part(ev('chol(A)'), 'L');
      expect(approxEq(mulM(l, transpose(l)), a, 1e-9), isTrue);
      expect(err('chol([1, 2; 3, 4])').error, contains('symmetric'));
    });

    test('matrix functions', () {
      expectMat(ev('expm([0, −π; π, 0])'), [
        [-1, 0],
        [0, -1],
      ], 1e-8);
      expectMat(ev('sqrtm([4, 0; 0, 9])'), [
        [2, 0],
        [0, 3],
      ], 1e-8);
      expectMat(ev('pinv([1, 2; 3, 4])'), [
        [-2, 1],
        [1.5, -0.5],
      ], 1e-8);
    });
  });

  group('number display', () {
    test('exact forms', () {
      expect(plain(0.5), '1/2');
      expect(plain(-1 / 3), '−1/3');
      expect(plain(math.sqrt(2) / 2), '√2/2');
      expect(plain(2 * math.sqrt(3)), '2√3');
      expect(plain(3 * math.pi / 4), '3π/4');
      expect(plain(43), '43');
      expect(plain(double.nan), 'undefined');
    });

    test('decimal forms', () {
      expect(plain(0.5, exact: false), '0.5');
      expect(plain(1 / 3, exact: false, precision: 4), '0.3333');
      expect(plain(0.012345), '0.0123');
      expect(plain(1.23456e-7), '1.235×10^-7');
      expect(plain(3, exact: false), '3');
    });
  });

  group('step by step', () {
    test('determinant by elimination', () {
      final s = stepsDet(a);
      expect(s.summary, endsWith('= 43'));
      expect(s.steps, isNotEmpty);
    });

    test('inverse by Gauss–Jordan', () {
      final s = stepsInverse(
        m([
          [1, 2],
          [3, 4],
        ]),
      );
      expect(s.aug, 2);
      expectMat(s.result, [
        [1, 0, -2, 1],
        [0, 1, 1.5, -0.5],
      ]);
    });

    test('properties', () {
      final p = {for (final x in properties(a)) x.key: x.value};
      expect(p['symmetric'], isTrue);
      expect(p['posdef'], isTrue);
      expect(p['orthogonal'], isFalse);
    });
  });

  group('errors read like sentences', () {
    test('syntax', () {
      expect(err('2 +').error, 'This expression ends too early');
      expect(err('(1 + 2').error, 'A bracket is missing its “)”');
      expect(err('1..2').error, 'Check the decimal point');
      expect(err('Z + 1').unknown, 'Z');
      expect(err('det(B)').error, 'The determinant needs a square matrix');
      expect(
        err('lu(A) + 1').error,
        'This result can’t be used inside a calculation',
      );
    });
  });
}
