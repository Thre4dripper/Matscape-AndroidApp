// Step-by-step solutions: every expression the app ships with can be
// worked through, and the working says what a textbook would.
import 'package:flutter_test/flutter_test.dart';
import 'package:matscape/app/app_state.dart';
import 'package:matscape/app/storage.dart';
import 'package:matscape/engine/engine.dart';
import 'package:matscape/ui/library_data.dart';

Mat _m(List<List<double>> d) => Mat(d);

final _a = _m([
  [4, 1, 2],
  [1, 3, 0],
  [2, 0, 5],
]);
final _b = _m([
  [2, 1],
  [5, 3],
]);
final _vars = <String, Object>{'A': _a, 'B': _b};

Solution _solve(String text, {bool degrees = false}) =>
    explain(text, vars: _vars, degrees: degrees)!;

/// Every line of working in a step, as text.
List<String> _lines(SolveStep s, [String? method]) => [
  for (final m in s.methods)
    if (method == null || m.name == method)
      for (final w in m.work) ...[?w.text, ?w.label, ...w.ops],
];

void main() {
  test('one step per operation, in the order they are done', () {
    final s = _solve('det(A·Aᵀ − 2I) + tr(A)');
    expect(s.expr, 'det(A·Aᵀ − 2I) + tr(A)');
    expect(
      [for (final st in s.steps) st.expr],
      [
        'Aᵀ',
        'A·Aᵀ',
        'A·Aᵀ − 2I',
        'det(A·Aᵀ − 2I)',
        'tr(A)',
        'det(A·Aᵀ − 2I) + tr(A)',
      ],
    );
    expect(s.steps.first.title, 'Transpose');
    expect(s.steps[1].title, 'Multiply the matrices');
    expect(s.steps[2].title, 'Subtract 2I');
    // The last step is the answer the line itself shows.
    final direct = evaluate('det(A·Aᵀ − 2I) + tr(A)', vars: _vars);
    expect(s.value, direct.value);
    expect(s.steps.last.value, direct.value);
  });

  test('a matrix on its own has nothing to work out', () {
    expect(_solve('A').steps, isEmpty);
    expect(_solve('[1, 2; 3, 4]').steps, isEmpty);
  });

  test('plain arithmetic is worked one operation at a time', () {
    final s = _solve('2 + 3·4');
    expect([for (final st in s.steps) st.expr], ['3·4', '2 + 3·4']);
    expect(s.value, 14);
  });

  test('arithmetic inside a matrix expression is a single step', () {
    final s = _solve('2^(1/2)·B');
    expect([for (final st in s.steps) st.expr], ['2^(1 ÷ 2)', '2^(1 ÷ 2)·B']);
    expect(s.steps.first.title, 'Work out the number');
  });

  test('a named result explains what comes after the =', () {
    final s = _solve('M = B²');
    expect(s.assign, 'M');
    expect(s.steps.single.expr, 'B²');
  });

  test('a 2×2 determinant uses the formula', () {
    final st = _solve('det(B)').steps.single;
    expect(st.methods.map((m) => m.name), ['Formula', 'Row reduction']);
    expect(_lines(st, 'Formula'), contains('det = 2·3 − 1·5 = 1'));
  });

  test('a 3×3 determinant expands along the row with most zeros', () {
    final st = _solve('|A|').steps.single;
    expect(st.title, 'Determinant');
    expect(st.methods.map((m) => m.name), [
      'Cofactor expansion',
      'Row reduction',
    ]);
    final lines = _lines(st, 'Cofactor expansion');
    expect(lines.first, startsWith('Expand along row 2'));
    // Row 2 is 1, 3, 0: two minors, and the signs start with a minus.
    expect(lines, contains('<i>M</i><sub>21</sub> = 1·5 − 2·0 = 5'));
    expect(lines.last, 'det = −1·5 + 3·16 = 43');
    // Row reduction ends on the same number.
    expect(_lines(st, 'Row reduction').join(' '), contains('= 43'));
  });

  test('an inverse can be found three ways', () {
    final st = _solve('B⁻¹').steps.single;
    expect(st.methods.map((m) => m.name), [
      'Formula',
      'Gauss–Jordan',
      'Adjugate',
    ]);
    for (final m in st.methods) {
      expect(m.work, isNotEmpty);
    }
    expect(_solve('A^-1').steps.single.title, 'Inverse');
    expect(_solve('inv(A)').steps.single.methods.map((m) => m.name), [
      'Gauss–Jordan',
      'Adjugate',
    ]);
  });

  test('a product is written out entry by entry', () {
    final st = _solve('B·B').steps.single;
    final lines = _lines(st);
    expect(lines, contains('<i>c</i><sub>11</sub> = 2·2 + 1·5 = 9'));
    expect(lines, contains('<i>c</i><sub>22</sub> = 5·1 + 3·3 = 14'));
  });

  test('a system is solved by elimination, Cramer’s rule or the inverse', () {
    final st = _solve('solve(B, [1; 2])').steps.single;
    expect(st.methods.map((m) => m.name), [
      'Elimination',
      'Cramer’s rule',
      'Inverse',
    ]);
    expect(_lines(st, 'Elimination'), contains('<i>x</i><sub>1</sub> = 1'));
    expect(
      _lines(st, 'Cramer’s rule'),
      contains(
        '<i>x</i><sub>2</sub> = <i>D</i><sub>2</sub> ÷ <i>D</i> = (−1) ÷ 1 = −1',
      ),
    );
  });

  test('eigenvalues come from the characteristic equation', () {
    final st = _solve('eig([2, 0; 0, 3])').steps.single;
    final lines = _lines(st);
    expect(lines, contains('<i>λ</i>² − 5<i>λ</i> + 6 = 0'));
  });

  test('powers are built up one multiplication at a time', () {
    final st = _solve('B^3').steps.single;
    expect(st.title, 'Raise to the power 3');
    expect(_lines(st), ['B² = B·B', 'B³ = B²·B']);
    expect(_solve('B²').steps.single.methods.single.name, 'Entry by entry');
  });

  test('trig says which angle unit is in use', () {
    expect(
      _solve('sin(30°)', degrees: true).steps.single.note,
      'Angles are in degrees.',
    );
    expect(_solve('sin(π/6)').steps.last.note, 'Angles are in radians.');
  });

  test('numbers follow the format that is passed in', () {
    final s = explain(
      'B⁻¹·[1; 1]',
      vars: _vars,
      fmt: (x) => x.toStringAsFixed(2),
    )!;
    expect(_lines(s.steps.last).last, contains('2.00'));
  });

  test('an expression with an error has no steps', () {
    expect(explain('A·B', vars: _vars), isNull);
    expect(explain('det(', vars: _vars), isNull);
    expect(explain('', vars: _vars), isNull);
  });

  test('every sample workspace line can be worked through', () async {
    final state = AppState(MemoryStorage());
    await state.load();
    var lines = 0, withWorking = 0;
    for (final ws in [...state.workspaces]) {
      state.openWorkspace(ws.id);
      for (final l in state.ws.lines) {
        final r = state.lineResults[l.id]!;
        if (!r.ok) continue;
        final s = state.solutionFor(l.id);
        expect(s, isNotNull, reason: '${ws.name}: ${l.text}');
        lines++;
        for (final st in s!.steps) {
          expect(st.title, isNotEmpty);
          for (final m in st.methods) {
            // Building the working must not throw, and must say something.
            expect(m.work, isNotEmpty, reason: '${l.text} → ${m.name}');
            withWorking++;
          }
        }
        if (s.steps.isNotEmpty) {
          expect(
            state.valueText(s.steps.last.value),
            state.valueText(r.value!),
            reason: '${ws.name}: ${l.text}',
          );
        }
      }
    }
    expect(lines, greaterThan(60));
    expect(withWorking, greaterThan(40));
    state.flush();
  });

  test('every library example can be worked through', () {
    var n = 0;
    for (final op in ops) {
      for (final e in op.examples) {
        final r = evaluate(e);
        if (!r.ok) continue;
        final s = explain(e);
        expect(s, isNotNull, reason: e);
        for (final st in s!.steps) {
          for (final m in st.methods) {
            expect(m.work, isNotEmpty, reason: '$e → ${m.name}');
          }
        }
        n++;
      }
    }
    expect(n, greaterThan(40));
  });
}
