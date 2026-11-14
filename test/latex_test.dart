// Copy as LaTeX: numbers, matrices, expressions and whole solutions.
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:matscape/app/app_state.dart';
import 'package:matscape/app/storage.dart';
import 'package:matscape/engine/engine.dart';
import 'package:matscape/main.dart';

final _vars = <String, Object>{
  'A': Mat([
    [4, 1, 2],
    [1, 3, 0],
    [2, 0, 5],
  ]),
  'B': Mat([
    [2, 1],
    [5, 3],
  ]),
  'C': Mat([
    [2, 0, 1, -1],
    [1, 3, 0, 2],
    [0, -2, 4, 1],
    [3, 1, 0, 5],
  ]),
  'S': Mat([
    [4, 2, 0],
    [2, 5, 1],
    [0, 1, 3],
  ]),
  'W': Mat([
    [1, 2, 3, 4],
    [5, 6, 7, 8],
  ]),
  'R': Mat([
    [0, -1],
    [1, 0],
  ]),
  'rate': 2.5,
};

String _tex(String e) => explain(e, vars: _vars)!.tex;

final _leftover = RegExp('[·−–÷×λσΣπ‖→↔…∘°ᵀ⁰¹²³⁴⁵⁶⁷⁸⁹⁻⁺√∛<>]');
final _command = RegExp(r'\\([A-Za-z]+)');
const _known = {
  'frac', 'tfrac', 'sqrt', 'pi', 'infty', 'text', 'textbf', 'times', 'cdot',
  'div', 'circ', 'lambda', 'sigma', 'Sigma', 'to', 'leftrightarrow', 'dots',
  'mathsf', 'mathrm', 'operatorname', 'left', 'right', 'begin', 'end', 'quad',
  'det', 'sin', 'cos', 'tan', 'sec', 'csc', 'cot', 'arcsin', 'arccos',
  'arctan', 'sinh', 'cosh', 'tanh', 'ln', 'log', 'exp', 'alpha', 'beta',
  'gamma', 'delta', 'theta', 'mu', 'varphi', 'omega', 'surd', 'ge', 'le', //
};

/// Fails unless [tex] is well formed: braces and environments balance,
/// every command is one LaTeX has, and no symbol was left unconverted.
void _wellFormed(String tex, String from) {
  var depth = 0;
  for (var i = 0; i < tex.length; i++) {
    if (tex[i] == r'\') {
      i++;
      continue;
    }
    if (tex[i] == '{') depth++;
    if (tex[i] == '}') depth--;
    expect(depth, greaterThanOrEqualTo(0), reason: '$from\n$tex');
  }
  expect(depth, 0, reason: 'braces: $from\n$tex');
  expect(
    r'\left'.allMatches(tex.replaceAll(r'\leftrightarrow', '')).length,
    r'\right'.allMatches(tex).length,
    reason: 'left/right: $from\n$tex',
  );
  expect(
    r'\begin{'.allMatches(tex).length,
    r'\end{'.allMatches(tex).length,
    reason: 'environments: $from\n$tex',
  );
  expect(_leftover.hasMatch(tex), isFalse, reason: 'symbol left: $from\n$tex');
  for (final m in _command.allMatches(tex)) {
    expect(_known, contains(m[1]), reason: 'unknown \\${m[1]}: $from\n$tex');
  }
}

void main() {
  test('numbers keep their exact form', () {
    expect(texNum(3), '3');
    expect(texNum(2 / 3), r'\frac{2}{3}');
    expect(texNum(-0.5), r'-\frac{1}{2}');
    expect(texNum(math.sqrt(2)), r'\sqrt{2}');
    expect(texNum(2 * math.sqrt(3)), r'2\sqrt{3}');
    expect(texNum(-math.sqrt(2) / 2), r'-\frac{\sqrt{2}}{2}');
    expect(texNum(math.pi / 6), r'\frac{\pi}{6}');
    expect(texNum(2 / 3, exact: false, precision: 3), '0.667');
    expect(texNum(1.5e12, exact: false), r'1.5 \times 10^{12}');
    expect(texNum(double.infinity), r'\infty');
  });

  test('matrices are bmatrix, with a bar when augmented', () {
    final m = Mat([
      [1, 0.5],
      [-2, 4],
    ]);
    expect(
      texMat(m),
      r'\begin{bmatrix} 1 & \frac{1}{2} \\ -2 & 4 \end{bmatrix}',
    );
    expect(
      texMat(m, aug: 1),
      r'\left[\begin{array}{c|c} 1 & \frac{1}{2} \\ -2 & 4 \end{array}\right]',
    );
  });

  test('every kind of result has a LaTeX form', () {
    Object v(String e) => evaluate(e, vars: _vars).value!;
    expect(texValue(v('det(A)')), '43');
    expect(
      texValue(v('B⁻¹')),
      r'\begin{bmatrix} 3 & -1 \\ -5 & 2 \end{bmatrix}',
    );
    expect(texValue(v('eig(R)')), r'\lambda_{1} = i,\quad \lambda_{2} = -i');
    expect(texValue(v('charpoly(B)')), r'\lambda^{2} - 5\lambda + 1');
    final lu = texValue(v('lu(B)'));
    expect(lu, startsWith(r'P = \begin{bmatrix}'));
    expect(lu, contains(r',\quad L = \begin{bmatrix}'));
    expect(texValue(v('svd(W)')), contains(r'V^{\mathsf{T}} = '));
    for (final e in ['eigvec(S)', 'qr(A)', 'chol(S)', 'null(A)', 'svd(W)']) {
      _wellFormed(texValue(v(e)), e);
    }
  });

  test('expressions are set the way they are written by hand', () {
    expect(
      _tex('det(A·Aᵀ − 2I) + tr(A)'),
      r'\det\left( A A^{\mathsf{T}} - 2I \right) + \operatorname{tr}\left( A \right)',
    );
    expect(_tex('(1 + √5) ÷ 2'), r'\frac{1 + \sqrt{5}}{2}');
    expect(_tex('3·4 + 2^10'), r'3 \cdot 4 + 2^{10}');
    expect(
      _tex('(A + S)⁻¹·[1; 2; 3]'),
      contains(
        r'\left( A + S \right)^{-1} \begin{bmatrix} 1 \\ 2 \\ 3 \end{bmatrix}',
      ),
    );
    expect(_tex('|A|·B²'), r'\left| A \right| B^{2}');
    expect(
      _tex('rate·A − sin(π/6)·S'),
      r'\mathrm{rate} A - \sin\left( \frac{\pi}{6} \right) S',
    );
    expect(_tex('A ÷ 2'), 'A / 2');
    expect(_tex('−A^3'), '-A^{3}');
  });

  test('lines of working convert symbol by symbol', () {
    expect(
      texMath('<i>c</i><sub>11</sub> = 2·2 + 1·5 = 9'),
      r'c_{11} = 2 \cdot 2 + 1 \cdot 5 = 9',
    );
    expect(
      texMath('det = −1·5 + 3·16 = 43'),
      r'\det = -1 \cdot 5 + 3 \cdot 16 = 43',
    );
    expect(
      texMath('R2 → R2 − (1/4)R1'),
      r'R_{2} \to R_{2} - (\tfrac{1}{4})R_{1}',
    );
    expect(texMath('R1 ↔ R3'), r'R_{1} \leftrightarrow R_{3}');
    expect(
      texMath('√(4² + 1²) = √17 = 4.1231'),
      r'\sqrt{4^{2} + 1^{2}} = \sqrt{17} = 4.1231',
    );
    expect(
      texMath('<i>λ</i>² − 5<i>λ</i> + 6 = 0'),
      r'\lambda ^{2} - 5\lambda + 6 = 0',
    );
    expect(
      texMath(
        '<i>r</i><sub>22</sub> = ‖<i>u</i><sub>2</sub>‖ = √(1² + (−2)²) = √5',
      ),
      r'r_{22} = \|u_{2}\| = \sqrt{1^{2} + (-2)^{2}} = \sqrt{5}',
    );
    expect(texMath('B¹³ = B¹²·B'), r'B^{13} = B^{12} \cdot B');
    expect(texMath('Vᵀ'), r'V^{\mathsf{T}}');
    expect(
      texProse('M<sub>1</sub> = I: 100% of A & B'),
      r'\text{M$_{1}$ = I: 100\% of A \& B}',
    );
  });

  test('every solution is well-formed LaTeX from top to bottom', () {
    var lines = 0;
    for (final e in const [
      '(A·Aᵀ − 2I)⁻¹·[1; 2; 3] + det(A)·Aᵀ·[1; 2; 3]',
      'tr((A + Aᵀ)^3) ÷ det(A − 2I)',
      'solve(AᵀA + 3I, Aᵀ·[1; 2; 3])',
      '[det(A), tr(A); rank(A), norm1(A)]·B',
      'det(C)',
      'C⁻¹',
      'adj(C)',
      'cof(A)',
      'minors(B)',
      'B^13',
      'A^-3',
      'lu(C)',
      'chol(S)',
      'qr(A)',
      'svd(W)',
      'eig(A)',
      'eig(R)',
      'eigvec(S)',
      'charpoly(C)',
      'null(A)',
      'colsp(W)',
      'rank(W)',
      'rref(aug(A, S))',
      'norm(A) + norm1(A) + norminf(A) + norm2(S) + cond(S)',
      'cross([1, 2, 3], [4, 5, 6])',
      'dot([1, 2, 3], [4, 5, 6])',
      'kron(B, B)',
      'expm(B)',
      'pinv(W)',
      'sqrtm(S)',
      'A∘S',
      'B ÷ B^0',
      'solve(C, [1; 0; 2; −1])',
      'sin(30°)^2 + √2·3! − |−7| + ∛27',
    ]) {
      final s = explain(e, vars: _vars);
      expect(s, isNotNull, reason: e);
      _wellFormed(s!.tex, e);
      for (final st in s.steps) {
        _wellFormed(st.tex, '$e → ${st.expr}');
        _wellFormed(texValue(st.value), '$e → value of ${st.expr}');
        _wellFormed(texProse(st.title), st.title);
        for (final m in st.methods) {
          for (final w in m.work) {
            final from = '$e → ${m.name}: ${w.text ?? w.label ?? w.ops}';
            switch (w.kind) {
              case WorkKind.text:
                _wellFormed(texProse(w.text!), from);
              case WorkKind.math:
                _wellFormed(texMath(w.text!), from);
              case WorkKind.matrix:
                if (w.label != null) _wellFormed(texProse(w.label!), from);
                _wellFormed(texMat(w.mat!, aug: w.aug), from);
              case WorkKind.ops:
                w.ops.map(texMath).forEach((t) => _wellFormed(t, from));
                _wellFormed(texMat(w.mat!, aug: w.aug), from);
            }
            lines++;
          }
        }
      }
    }
    expect(lines, greaterThan(500));
  });

  testWidgets('with LaTeX chosen, the copy buttons give LaTeX', (tester) async {
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(402, 2400);
    tester.view.display.size = const Size(3000, 3000);
    addTearDown(tester.view.reset);
    final state = AppState(MemoryStorage());
    await state.load();
    state.tutorialSeen = true;
    addTearDown(state.flush);
    await tester.pumpWidget(MatscapeApp(key: UniqueKey(), state: state));
    await tester.pumpAndSettle();

    // Plain text by default.
    await tester.tap(find.bySemanticsLabel('Copy matrix').first);
    await tester.pump();
    expect(copied.last, startsWith('['));
    await tester.pump(const Duration(seconds: 3));

    state.updateSettings((s) => s.copyLatex = true);
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Copy matrix').first);
    await tester.pump();
    expect(copied.last, startsWith(r'\begin{bmatrix} \frac{2}{3} & '));
    expect(find.text('Copied as LaTeX'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));

    // A whole solution, with the working that is open.
    await tester.tap(find.text('Steps').first);
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Copy the steps'));
    await tester.pump();
    final tex = copied.last;
    expect(
      tex,
      startsWith('% det(A)\n\\begin{align*}\n& \\textbf{1. Determinant}'),
    );
    expect(tex, contains(r'& \det\left( A \right) = 43'));
    expect(tex, contains(r'& \text{Cofactor expansion:}'));
    expect(tex, contains(r'& M_{21} = 1 \cdot 5 - 2 \cdot 0 = 5'));
    expect(tex, endsWith(r'\end{align*}'));
    _wellFormed(tex.split('\n').skip(1).join('\n'), 'copied steps');
    expect(find.text('Steps copied as LaTeX'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
