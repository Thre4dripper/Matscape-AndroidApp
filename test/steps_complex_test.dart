// Long, nested expressions on larger matrices: every step must come to
// what the engine itself gives for that sub-expression, and every line of
// arithmetic written in the working must be true.
import 'package:flutter_test/flutter_test.dart';
import 'package:matscape/engine/engine.dart';

Mat _m(List<List<double>> d) => Mat(d);

final _vars = <String, Object>{
  'A': _m([
    [4, 1, 2],
    [1, 3, 0],
    [2, 0, 5],
  ]),
  'B': _m([
    [2, 1],
    [5, 3],
  ]),
  // 4×4 and 5×5, invertible, with a few zeros and negatives.
  'C': _m([
    [2, 0, 1, -1],
    [1, 3, 0, 2],
    [0, -2, 4, 1],
    [3, 1, 0, 5],
  ]),
  'D': _m([
    [3, 1, 0, 2, -1],
    [1, 4, 1, 0, 2],
    [0, 1, 5, 1, 0],
    [2, 0, 1, 6, 1],
    [-1, 2, 0, 1, 7],
  ]),
  // Symmetric positive definite.
  'S': _m([
    [4, 2, 0],
    [2, 5, 1],
    [0, 1, 3],
  ]),
  // Singular: row 3 = row 1 + row 2.
  'Z': _m([
    [1, 2, 3],
    [4, 5, 6],
    [5, 7, 9],
  ]),
  // Rotation by 90°: complex eigenvalues.
  'R': _m([
    [0, -1],
    [1, 0],
  ]),
  'W': _m([
    [1, 2, 3, 4],
    [5, 6, 7, 8],
  ]),
  'v': _m([
    [1],
    [2],
    [3],
  ]),
  'k': 2.5,
};

const _cases = [
  // Long chains mixing everything.
  '(A·Aᵀ − 2I)⁻¹·v + det(A)·Aᵀ·v',
  'tr((A + Aᵀ)^3) ÷ det(A − 2I)',
  'solve(AᵀA + 3I, Aᵀv)',
  'det(A⁻¹·S·A) − det(S)',
  '(A + I)(A − I) − A² + I',
  '−(2A − 3S)ᵀ·(A ÷ 2 + k·S)',
  'M = inv(S)·(A − k·I)^2·v',
  'norm(A⁻¹)·norm(A) − cond(S)',
  'adj(A)·A − det(A)·I(3)',
  'rank(Z) + rank(A) + tr(Z·Zᵀ)',
  '|A|·|B| − |S|^2 + |−3|',
  'kron(B, B)⁻¹·C',
  'det(kron(B, B))^(1/2)',
  'cross(Aᵀ·v, S·v)',
  'dot(row(A, 1), column(S, 2))·A',
  '(2B)^-2 + B⁻¹·Bᵀ ÷ det(B)',
  'A∘S − hadamard(A, Aᵀ)',
  'aug(A, v)',
  'rref(aug(A·S, A·v))',
  // Matrix → number → matrix, several times over.
  'det(A)·A⁻¹ − adj(A)',
  '(tr(A)·I − A)·v ÷ det(A)',
  'A^(rank(Z))',
  'norm(A·v)·S − dot(v, S·v)·I(3)',
  '(A − tr(A) ÷ 3·I)⁻¹',
  'det(A − det(B)·I)·B',
  'inv(det(S)·A + tr(A·S)·I)·(norm(v)^2·v)',
  '[det(A), tr(A); rank(A), norm1(A)]·B',
  'det([tr(A), det(B); rank(Z), dot(v, v)])·[1, 2; 3, 4]⁻¹',
  'solve(det(B)·S + rank(A)·I, tr(S)·v − A·v)',
  'tr(inv(det(A)·S − tr(S)·A)·Aᵀ)·(B^(rank(B)) − det(B)·Bᵀ)',
  'kron(det(B)·B, [tr(B), 0; 0, rank(Z)])⁻¹',
  'det(det(A)·B − det(B)·I)·det(S)^-1·C',
  // Larger matrices.
  'det(C)',
  'C⁻¹',
  'det(D)',
  'D⁻¹·[1; 2; 3; 4; 5]',
  'C·Cᵀ − 2C + I',
  'W·Wᵀ',
  'Wᵀ·W',
  'rank(Wᵀ·W)',
  'adj(C)',
  'cof(C)',
  'minors(A)',
  'solve(C, [1; 0; 2; −1])',
  'solve(D, D·[1; 1; 1; 1; 1])',
  'C^5',
  'A^-3',
  'tr(D²)',
  // Decompositions and spectra.
  'lu(C)',
  'lu(A·S − 2I)',
  'chol(S)',
  'chol(Sᵀ·S + I)',
  'qr(A)',
  'svd(W)',
  'eig(A)',
  'eig(R)',
  'eig(C)',
  'eigvec(S)',
  'charpoly(A·S)',
  'null(Z)',
  'colsp(Z)',
  'pinv(W)',
  'expm(A − Aᵀ)',
  'sqrtm(S)',
  // Singular and awkward ones.
  'det(Z)',
  'solve(Z, [1; 2; 3])',
  'rref(Z)',
  'Z·null(Z)',
  'norm1(C) + norminf(C) + norm2(S) + norm(W)',
  // Pure arithmetic.
  '(1 + √5) ÷ 2',
  'sin(π/6)^2 + cos(π/6)^2',
  '3! + 2^10 − |−7|·(4 − 9)',
  'k^2 − 4·k + ∛27',
  '2^(1/2)·3^(1/2) − √6',
];

/// Numbers written in full, so the working can be checked exactly.
String _full(double x) {
  if (x == x.roundToDouble() && x.abs() < 1e15) return x.toStringAsFixed(0);
  return x.toStringAsFixed(12);
}

const _sup = {
  '⁰': '0',
  '¹': '1',
  '²': '2',
  '³': '3',
  '⁴': '4',
  '⁵': '5',
  '⁶': '6',
  '⁷': '7',
  '⁸': '8',
  '⁹': '9',
  '⁻': '-',
};
final _supRun = RegExp('[⁰¹²³⁴⁵⁶⁷⁸⁹⁻]+');
final _tags = RegExp('<[^>]+>');

/// The displayed text of an expression, as something the parser reads.
String _typed(String shown) => shown.replaceAllMapped(_supRun, (m) {
  final t = m[0]!;
  if (t == '²' || t == '³' || t == '⁻¹') return t;
  return '^(${t.split('').map((c) => _sup[c]).join()})';
});

bool _close(double a, double b) =>
    (a - b).abs() <= 1e-6 * (1 + a.abs().clamp(0, 1e12) + b.abs());

void _same(Object got, Object want, String why) {
  if (want is double) {
    expect(got, isA<double>(), reason: why);
    expect(_close(got as double, want), isTrue, reason: '$why: $got vs $want');
  } else if (want is Mat) {
    expect(got, isA<Mat>(), reason: why);
    final g = got as Mat;
    expect((g.rows, g.cols), (want.rows, want.cols), reason: why);
    for (var i = 0; i < want.rows; i++) {
      for (var j = 0; j < want.cols; j++) {
        expect(
          _close(g.data[i][j], want.data[i][j]),
          isTrue,
          reason: '$why at ($i, $j): ${g.data[i][j]} vs ${want.data[i][j]}',
        );
      }
    }
  } else {
    expect(got.runtimeType, want.runtimeType, reason: why);
  }
}

void main() {
  test('every step of a complex expression comes to the right value', () {
    for (final e in _cases) {
      final direct = evaluate(e, vars: _vars);
      expect(direct.ok, isTrue, reason: '$e: ${direct.error}');
      final s = explain(e, vars: _vars, fmt: _full);
      expect(s, isNotNull, reason: e);
      expect(s!.steps, isNotEmpty, reason: e);
      _same(s.value, direct.value!, e);
      _same(s.steps.last.value, direct.value!, '$e (last step)');
      for (final st in s.steps) {
        // What the step says it is working out, typed back in.
        final again = evaluate(_typed(st.expr), vars: _vars);
        expect(again.ok, isTrue, reason: '$e → ${st.expr}: ${again.error}');
        _same(st.value, again.value!, '$e → ${st.expr}');
      }
    }
  });

  test('every line of arithmetic in the working is true', () {
    var checked = 0;
    for (final e in _cases) {
      final s = explain(e, vars: _vars, fmt: _full)!;
      for (final st in s.steps) {
        for (final m in st.methods) {
          expect(m.work, isNotEmpty, reason: '$e → ${m.name}');
          for (final w in m.work) {
            if (w.kind != WorkKind.math) continue;
            // "c11 = 2·2 + 1·5 = 9": every side that is plain arithmetic
            // must be the same number.
            final sides = w.text!.replaceAll(_tags, '').split(' = ');
            final nums = <double>[];
            for (final side in sides) {
              final r = evaluate(_typed(side.trim()));
              if (r.ok && r.value is double) nums.add(r.value! as double);
            }
            for (final x in nums.skip(1)) {
              // Row-operation summaries round a long pivot to 4 places.
              final ok = m.name == 'Row reduction'
                  ? (x - nums.first).abs() <= 2e-3 * (1 + nums.first.abs())
                  : _close(x, nums.first);
              expect(
                ok,
                isTrue,
                reason: '$e → ${st.expr} → ${m.name}: ${w.text}',
              );
              checked++;
            }
          }
        }
      }
    }
    expect(checked, greaterThan(250));
  });

  test('the same holds in degrees and with decimals shown', () {
    final s = explain(
      'sin(30°)·A + cos(60)·S',
      vars: _vars,
      degrees: true,
      fmt: (x) => plain(x, exact: false, precision: 3),
    )!;
    final direct = evaluate(
      'sin(30°)·A + cos(60)·S',
      vars: _vars,
      degrees: true,
    );
    _same(s.value, direct.value!, 'degrees');
    expect(s.steps.map((st) => st.expr), [
      'sin(30°)',
      'sin(30°)·A',
      'cos(60)',
      'cos(60)·S',
      'sin(30°)·A + cos(60)·S',
    ]);
  });

  test(
    'matrix to number to matrix: each kind of step is named for what it is',
    () {
      final s = explain('det(A − det(B)·I)·B', vars: _vars)!;
      expect(
        [for (final st in s.steps) '${st.title} | ${st.expr}'],
        [
          'Determinant | det(B)',
          'Subtract I | A − det(B)·I',
          'Determinant | det(A − det(B)·I)',
          'Multiply every entry by 12 | det(A − det(B)·I)·B',
        ],
      );
      // Numbers worked out inside a typed matrix get their own steps first.
      final t = explain('[det(A), tr(A); rank(A), 1/2]·B', vars: _vars)!;
      expect(
        [for (final st in t.steps) st.title],
        [
          'Determinant',
          'Trace',
          'Rank',
          'Put the results in a matrix',
          'Multiply the matrices',
        ],
      );
      // A typed matrix of plain numbers needs no steps of its own.
      expect(hasSteps('[1/2, √3; 2^3, −1]'), isFalse);
      expect(hasSteps('[det(A), 1]', vars: _vars), isTrue);
    },
  );

  group('nothing is cut short', () {
    // Deterministic matrices of any size, with a few zeros.
    Mat grid(int size) => Mat([
      for (var i = 0; i < size; i++)
        [
          for (var j = 0; j < size; j++)
            i == j
                ? (size + i + 2).toDouble()
                : ((i * 3 + j * 5) % 7 == 0 ? 0.0 : ((i + 2 * j) % 5 - 2.0)),
        ],
    ]);
    final big = <String, Object>{
      ..._vars,
      'E': grid(6),
      'F': grid(7),
      'G': grid(8),
      'H': grid(9),
      'K': grid(12),
    };
    Solution solve(String e) => explain(e, vars: big, fmt: _full)!;
    StepMethod method(String e, String name) =>
        solve(e).steps.last.methods.firstWhere((m) => m.name == name);

    /// The last number on a line such as "det = … = 863".
    double answer(Work w) =>
        evaluate(w.text!.replaceAll(_tags, '').split(' = ').last).value!
            as double;

    test('a product lists every entry, whatever the size', () {
      final w = method('D·D', 'Entry by entry').work;
      expect(w.where((x) => x.kind == WorkKind.math), hasLength(25));
      final wide = method('K·K', 'Entry by entry').work;
      expect(wide.where((x) => x.kind == WorkKind.math), hasLength(144));
      expect(wide.map((x) => x.text).join(), isNot(contains('same way')));
    });

    test('cofactor expansion goes all the way down, minor inside minor', () {
      expect(solve('det(D)').steps.single.methods.map((m) => m.name), [
        'Row reduction',
        'Cofactor expansion',
      ]);
      for (final (name, depth) in [('D', 2), ('E', 3), ('F', 4)]) {
        final w = method('det($name)', 'Cofactor expansion').work;
        // Each level of minors sits one step further in.
        expect(w.map((x) => x.indent).reduce((a, b) => a > b ? a : b), depth);
        final want = evaluate('det($name)', vars: big).value! as double;
        expect(_close(answer(w.last), want), isTrue, reason: name);
        // Every line of the expansion is true, at every depth.
        for (final line in w.where((x) => x.kind == WorkKind.math)) {
          final sides = line.text!.replaceAll(_tags, '').split(' = ');
          final nums = [
            for (final side in sides)
              if (evaluate(_typed(side)) case final r
                  when r.ok && r.value is double)
                r.value! as double,
          ];
          for (final x in nums.skip(1)) {
            expect(_close(x, nums.first), isTrue, reason: line.text);
          }
        }
      }
    });

    test('an 8×8 expansion is complete: thousands of lines, right answer', () {
      final m = method('det(G)', 'Cofactor expansion');
      // Heavy enough that the app works it out behind a loader.
      expect(m.weight, greaterThan(20000));
      final w = m.work;
      expect(w.length, greaterThan(3000));
      expect(w.map((x) => x.indent).reduce((a, b) => a > b ? a : b), 5);
      final want = evaluate('det(G)', vars: big).value! as double;
      expect(_close(answer(w.last), want), isTrue);
    });

    test('past 8×8 the expansion says why it stops at one level', () {
      final w = method('det(H)', 'Cofactor expansion').work;
      expect(w.first.text, contains('far too many to write out'));
      expect(w.where((x) => x.kind == WorkKind.matrix).length, greaterThan(2));
      final want = evaluate('det(H)', vars: big).value! as double;
      expect(_close(answer(w.last), want), isTrue);
      // Row reduction is still complete.
      expect(method('det(H)', 'Row reduction').work.length, greaterThan(8));
    });

    test('every minor of a large matrix is shown with its working', () {
      final w = method('adj(E)', 'Working').work;
      final labels = w.map((x) => x.label ?? '').join('\n');
      for (var i = 1; i <= 6; i++) {
        for (var j = 1; j <= 6; j++) {
          expect(labels, contains('<sub>$i$j</sub>: remove row $i'));
        }
      }
      // 5×5 minors are found by row operations, one level in.
      expect(
        w.where((x) => x.kind == WorkKind.ops && x.indent == 1),
        isNotEmpty,
      );
      expect(
        w.where((x) => (x.text ?? '').startsWith('<i>C</i>')),
        hasLength(36),
      );
      // The inverse by the adjugate works at this size too.
      expect(
        solve('E⁻¹').steps.single.methods.map((m) => m.name),
        contains('Adjugate'),
      );
    });

    test('Cramer’s rule, Cholesky and eigenvalues have no size limit', () {
      final cramer = method(
        'solve(E, [1; 2; 3; 4; 5; 6])',
        'Cramer’s rule',
      ).work;
      expect(
        cramer.where((x) => (x.text ?? '').startsWith('<i>x</i>')),
        hasLength(6),
      );
      final chol = method('chol(Eᵀ·E)', 'Entry by entry').work;
      expect(chol.where((x) => x.kind == WorkKind.math), hasLength(21));
      expect(
        solve('eig(E + Eᵀ)').steps.last.methods.single.name,
        'Characteristic equation',
      );
      expect(solve('eigvec(E + Eᵀ)').steps.last.methods, isNotEmpty);
      expect(
        solve('charpoly(F)').steps.single.methods.single.name,
        'Faddeev–LeVerrier',
      );
    });

    test('a high power is shown both ways, to the end', () {
      final each = method('B^13', 'One multiplication at a time').work;
      expect(each, hasLength(12));
      expect(each.last.label, 'B¹³ = B¹²·B');
      final sq = method('B^13', 'Repeated squaring').work;
      expect(sq.first.text, startsWith('13 = 8 + 4 + 1'));
      expect(sq.last.label, 'B¹³ = B¹²·B');
      final want = evaluate('B^13', vars: _vars).value! as Mat;
      _same(each.last.mat!, want, 'chain');
      _same(sq.last.mat!, want, 'squaring');
      // Beyond 64 only squaring is offered; it is still complete.
      final many = solve('B^100').steps.single.methods;
      expect(many.single.name, 'Repeated squaring');
      _same(
        many.single.work.last.mat!,
        evaluate('B^100', vars: _vars).value!,
        'B^100',
      );
    });

    test('QR is worked by Gram–Schmidt and gives the Q and R shown', () {
      for (final e in ['qr(A)', 'qr(W)', 'qr(Wᵀ)', 'qr(Z)']) {
        final s = solve(e);
        final res = s.value as MultiVal;
        final q = res.parts[0].value, r = res.parts[1].value;
        final w = s.steps.last.methods.single.work;
        // Each q written in the working is a column of Q.
        final qs = w
            .where((x) => (x.label ?? '').startsWith('<i>q</i>'))
            .toList();
        for (var c = 0; c < qs.length; c++) {
          for (var i = 0; i < q.rows; i++) {
            expect(
              _close(qs[c].mat!.data[i][0], q.data[i][c]),
              isTrue,
              reason: e,
            );
          }
        }
        // Each r written out is an entry of R.
        for (final line in w.where((x) => x.kind == WorkKind.math)) {
          final t = line.text!.replaceAll(_tags, '');
          final idx = RegExp(r'^r(\d)(\d) = ').firstMatch(t)!;
          final want = r.data[int.parse(idx[1]!) - 1][int.parse(idx[2]!) - 1];
          expect(_close(answer(line), want), isTrue, reason: '$e: $t');
        }
      }
    });

    test('SVD is worked from AᵀA and gives the U, Σ and V shown', () {
      for (final e in ['svd(W)', 'svd(A)', 'svd(Z)', 'svd(Wᵀ)']) {
        final s = solve(e);
        final res = s.value as MultiVal;
        final u = res.parts[0].value, sig = res.parts[1].value;
        final w = s.steps.last.methods.single.work;
        final us = w
            .where(
              (x) =>
                  (x.label ?? '').startsWith('<i>u</i>') ||
                  (x.label ?? '').contains('is 0, so <i>u</i>'),
            )
            .toList();
        expect(us, hasLength(sig.rows), reason: e);
        for (var c = 0; c < us.length; c++) {
          for (var i = 0; i < u.rows; i++) {
            expect(
              _close(us[c].mat!.data[i][0], u.data[i][c]),
              isTrue,
              reason: e,
            );
          }
        }
        final sigmas = w
            .where((x) => (x.text ?? '').contains('<i>σ</i>'))
            .toList();
        expect(sigmas, hasLength(sig.rows), reason: e);
        for (var c = 0; c < sigmas.length; c++) {
          expect(_close(answer(sigmas[c]), sig.data[c][c]), isTrue, reason: e);
        }
      }
    });

    test('working fetched by index is the same working', () {
      final direct = explain('det(C)', vars: big)!.steps.single.methods[0].work;
      final byIndex = workFor('det(C)', 0, 0, vars: big);
      expect(
        byIndex.map((w) => w.text ?? w.label),
        direct.map((w) => w.text ?? w.label),
      );
      expect(workFor('det(C)', 5, 0, vars: big), isEmpty);
    });
  });
}
