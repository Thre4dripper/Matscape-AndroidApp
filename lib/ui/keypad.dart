import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'icons.dart';
import 'math_view.dart';
import 'theme.dart';
import 'widgets.dart';

enum KeyKind { digit, op, fn, fnMath, util, enter }

/// One key: what it shows and what it types.
class KeyDef {
  const KeyDef(
    this.label,
    this.ins, {
    this.kind = KeyKind.digit,
    this.back = 0,
    this.aria,
  });

  /// Label markup (see [markup]).
  final String label;

  /// Text inserted at the caret.
  final String ins;
  final KeyKind kind;

  /// Characters to step back after inserting, to land inside brackets.
  final int back;
  final String? aria;
}

KeyDef _d(String n) => KeyDef(n, n);
KeyDef _op(String l, [String? ins, String? aria]) =>
    KeyDef(l, ins ?? l, kind: KeyKind.op, aria: aria);
KeyDef _fn(String l, [String? aria]) =>
    KeyDef(l, '$l()', kind: KeyKind.fn, back: 1, aria: aria);
KeyDef _mk(String l, String ins, String aria, [int back = 0]) =>
    KeyDef(l, ins, kind: KeyKind.fnMath, back: back, aria: aria);

/// Marks the slot on the f(x) page taken by the RAD/DEG switch.
const angleToggle = KeyDef('', '', kind: KeyKind.util);

class KeypadPage {
  const KeypadPage(this.id, this.label, this.rows);
  final String id, label;
  final List<List<KeyDef>> rows;
}

final keypadPages = <KeypadPage>[
  KeypadPage('num', '123', [
    [_d('7'), _d('8'), _d('9'), _op('÷', '÷', 'Divide'), _op('('), _op(')')],
    [
      _d('4'),
      _d('5'),
      _d('6'),
      _op('×', '·', 'Multiply'),
      _op('[', '[', 'Open matrix bracket'),
      _op(']', ']', 'Close matrix bracket'),
    ],
    [
      _d('1'),
      _d('2'),
      _d('3'),
      _op('−', '−', 'Minus'),
      _op('x<sup>□</sup>', '^', 'Power'),
      _op(',', ', ', 'Comma — next entry'),
    ],
    [
      _d('0'),
      _d('.'),
      _op('π'),
      _op('+', '+', 'Plus'),
      _op(';', '; ', 'Semicolon — next row'),
      _op('√', '√', 'Square root'),
    ],
  ]),
  KeypadPage('mat', 'Matrix', [
    [
      _fn('det', 'Determinant'),
      _fn('tr', 'Trace'),
      _fn('rank', 'Rank'),
      _mk('<i>A</i><sup>T</sup>', 'ᵀ', 'Transpose'),
      _mk('<i>A</i><sup>−1</sup>', '⁻¹', 'Inverse'),
      _mk('<i>A</i><sup>2</sup>', '²', 'Squared'),
    ],
    [
      _fn('adj', 'Adjugate'),
      _fn('cof', 'Cofactor matrix'),
      _fn('minors', 'Matrix of minors'),
      _fn('rref', 'Reduced row echelon form'),
      _fn('null', 'Null space'),
      _fn('colsp', 'Column space'),
    ],
    [
      _mk('I(<i>n</i>)', 'I()', 'Identity matrix', 1),
      _fn('diag', 'Diagonal'),
      _fn('zeros', 'Zero matrix'),
      _fn('ones', 'Matrix of ones'),
      _fn('aug', 'Augment side by side'),
      _fn('sub', 'Submatrix without row i, column j'),
    ],
    [
      _fn('dot', 'Dot product'),
      _fn('cross', 'Cross product'),
      _fn('kron', 'Kronecker product'),
      _mk('∘', '∘', 'Entrywise product'),
      _fn('solve', 'Solve A x = b'),
      _fn('norm', 'Frobenius norm'),
    ],
  ]),
  KeypadPage('fx', 'f(x)', [
    [_fn('sin'), _fn('cos'), _fn('tan'), _fn('sec'), _fn('csc'), _fn('cot')],
    [
      const KeyDef(
        'sin<sup>−1</sup>',
        'asin()',
        kind: KeyKind.fn,
        back: 1,
        aria: 'Inverse sine',
      ),
      const KeyDef(
        'cos<sup>−1</sup>',
        'acos()',
        kind: KeyKind.fn,
        back: 1,
        aria: 'Inverse cosine',
      ),
      const KeyDef(
        'tan<sup>−1</sup>',
        'atan()',
        kind: KeyKind.fn,
        back: 1,
        aria: 'Inverse tangent',
      ),
      _fn('sinh'),
      _fn('cosh'),
      _fn('tanh'),
    ],
    [
      _fn('ln', 'Natural log'),
      _fn('log', 'Log base 10'),
      _mk('<i>e</i><sup>x</sup>', 'exp()', 'e to the power', 1),
      _mk('√', '√', 'Square root'),
      _mk('∛', '∛', 'Cube root'),
      _mk('<i>n</i>!', '!', 'Factorial'),
    ],
    [
      _mk('π', 'π', 'Pi'),
      _mk('<i>e</i>', 'e', 'Euler’s number'),
      _mk('°', '°', 'Degrees'),
      _mk('=', ' = ', 'Name a value'),
      angleToggle,
    ],
  ]),
  KeypadPage('adv', 'More', [
    [
      _fn('eig', 'Eigenvalues'),
      _fn('eigvec', 'Eigenvectors'),
      _mk('<i>p</i>(<i>λ</i>)', 'charpoly()', 'Characteristic polynomial', 1),
      _fn('lu', 'LU decomposition'),
      _fn('qr', 'QR decomposition'),
      _fn('chol', 'Cholesky decomposition'),
    ],
    [
      _fn('svd', 'Singular value decomposition'),
      _fn('pinv', 'Pseudo-inverse'),
      _fn('cond', 'Condition number'),
      _mk('<i>e</i><sup><i>A</i></sup>', 'expm()', 'Matrix exponential', 1),
      _fn('sinm', 'Matrix sine'),
      _fn('cosm', 'Matrix cosine'),
    ],
    [
      _fn('sqrtm', 'Matrix square root'),
      _mk('‖·‖<sub>1</sub>', 'norm1()', '1-norm', 1),
      _mk('‖·‖<sub>2</sub>', 'norm2()', 'Spectral norm', 1),
      _mk('‖·‖<sub>∞</sub>', 'norminf()', 'Infinity norm', 1),
      _mk('|<i>x</i>|', '||', 'Absolute value or determinant bars', 1),
      const KeyDef('mod', 'mod(, )', kind: KeyKind.fn, back: 3, aria: 'Modulo'),
    ],
    [
      _fn('round'),
      _fn('floor'),
      _fn('ceil'),
      _fn('row', 'Row i of a matrix'),
      _fn('column', 'Column j of a matrix'),
      _fn('abs', 'Absolute value of each entry'),
    ],
  ]),
];

/// A single keycap.
class KeyCap extends StatelessWidget {
  const KeyCap({
    super.key,
    required this.onTap,
    required this.child,
    this.kind = KeyKind.digit,
    this.label,
    this.radius = 10,
  });

  /// Keycap for a [KeyDef], with its label typeset.
  factory KeyCap.def(KeyDef k, {required VoidCallback onTap}) => KeyCap(
    onTap: onTap,
    kind: k.kind,
    label: k.aria,
    child: KeyLabel(k.label, k.kind),
  );

  final VoidCallback? onTap;
  final Widget child;
  final KeyKind kind;
  final String? label;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final bg = switch (kind) {
      KeyKind.digit => pal.key,
      KeyKind.op || KeyKind.util => pal.keyOp,
      KeyKind.fn || KeyKind.fnMath => pal.keyFn,
      KeyKind.enter => pal.accent,
    };
    final pressed = kind == KeyKind.enter ? pal.accentInk : pal.keyPress;
    return Pressable(
      onTap: onTap,
      label: label,
      scale: .96,
      builder: (_, down) => AnimatedContainer(
        duration: Motion.fast,
        curve: Motion.easeOut,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: down ? pressed : bg,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(color: pal.keyShadow, offset: const Offset(0, 1)),
          ],
        ),
        child: IconTheme(
          data: IconThemeData(
            size: 22,
            color: kind == KeyKind.enter ? pal.onAccent : pal.ink,
          ),
          child: child,
        ),
      ),
    );
  }
}

class KeyLabel extends StatelessWidget {
  const KeyLabel(this.text, this.kind, {super.key, this.size});
  final String text;
  final KeyKind kind;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final style = switch (kind) {
      KeyKind.fn => TextStyle(
        fontSize: size ?? 14,
        fontWeight: FontWeight.w500,
        letterSpacing: -.14,
        height: 1,
        color: pal.ink,
      ),
      KeyKind.fnMath => mathStyle(
        context,
        size: size ?? 17,
        height: 1,
        color: pal.ink,
      ),
      _ => mathStyle(context, size: size ?? 20, height: 1, color: pal.ink),
    };
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text.rich(
        TextSpan(children: markup(text, style), style: style),
        softWrap: false,
      ),
    );
  }
}

/// The workspace keypad: page tabs, matrix-name rail and the key grid.
class Keypad extends StatelessWidget {
  const Keypad({
    super.key,
    required this.page,
    required this.collapsed,
    required this.degrees,
    required this.names,
    required this.onPage,
    required this.onToggleCollapsed,
    required this.onInsert,
    required this.onBackspace,
    required this.onMove,
    required this.onEnter,
    required this.onAngle,
    required this.onNewMatrix,
    this.fill = false,
    this.dual = false,
    this.collapsible = true,
    this.topBorder = true,
    this.hPad = 8,
    this.rowHeight = 44,
    this.topInset = 0,
  });

  final String page;
  final bool collapsed, degrees;
  final List<String> names;
  final ValueChanged<String> onPage;
  final VoidCallback onToggleCollapsed;
  final void Function(String text, int back) onInsert;
  final VoidCallback onBackspace, onEnter, onAngle, onNewMatrix;
  final ValueChanged<int> onMove;

  /// Stretch the key rows to use all the height on offer (tabletop, landscape).
  final bool fill;

  /// Show the number pad and one function page side by side.
  final bool dual;

  /// Whether the keypad can be hidden.
  final bool collapsible;
  final bool topBorder;
  final double hPad, rowHeight;

  /// Extra space above the keys, for when the keypad reaches the top of
  /// the screen (status bar).
  final double topInset;

  static const _gap = 6.0, _minRow = 36.0;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final showKeys = !collapsed || !collapsible;
    // With two pages on screen the number pad is always there, so its tab
    // goes away and the second slot shows one of the other pages.
    final shown = dual && page == 'num' ? 'mat' : page;
    return Container(
      padding: EdgeInsets.fromLTRB(
        hPad,
        (fill ? 8 : 4) + topInset,
        hPad,
        8 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: pal.surface2,
        border: topBorder ? Border(top: BorderSide(color: pal.line)) : null,
      ),
      child: Column(
        mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Row(
            children: [
              // Tabs keep their natural size; they only shrink on very
              // narrow screens.
              Expanded(
                child: showKeys
                    ? FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: _tabs(context, shown),
                      )
                    : const SizedBox.shrink(),
              ),
              if (collapsible)
                collapsed
                    ? TextBtn(
                        'Show keypad',
                        icon: MIcon.up,
                        onTap: onToggleCollapsed,
                      )
                    : IconBtn(
                        MIcon.down,
                        label: 'Hide keypad',
                        onTap: onToggleCollapsed,
                      ),
            ],
          ),
          if (showKeys) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: _namesRow(context),
            ),
            if (fill)
              Expanded(child: _keys(context, shown))
            else
              _keys(context, shown),
          ],
        ],
      ),
    );
  }

  Widget _tabs(BuildContext context, String shown) {
    final pal = context.pal;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: pal.surface3,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final p in keypadPages)
            if (!(dual && p.id == 'num'))
              Pressable(
                onTap: () => onPage(p.id),
                selected: p.id == shown,
                builder: (_, _) {
                  final on = p.id == shown;
                  return AnimatedContainer(
                    duration: Motion.fast,
                    height: 34,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: on ? pal.surface : null,
                      borderRadius: BorderRadius.circular(9),
                      boxShadow: on
                          ? [
                              BoxShadow(
                                color: pal.keyShadow,
                                offset: const Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      p.label,
                      style: TextStyle(
                        fontSize: Fs.sm,
                        fontWeight: FontWeight.w600,
                        color: on ? pal.ink : pal.ink2,
                      ),
                    ),
                  );
                },
              ),
        ],
      ),
    );
  }

  Widget _namesRow(BuildContext context) {
    final pal = context.pal;
    Widget pill({
      required Widget child,
      required VoidCallback onTap,
      String? label,
    }) => Pressable(
      onTap: onTap,
      label: label,
      builder: (_, down) => Container(
        height: 40,
        constraints: const BoxConstraints(minWidth: 44),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: down ? pal.keyPress : pal.surface,
          border: Border.all(color: pal.lineStrong),
          borderRadius: BorderRadius.circular(999),
        ),
        child: child,
      ),
    );
    Widget arrow(MIcon icon, String label, int delta) => SizedBox(
      width: 48,
      height: 40,
      child: KeyCap(
        kind: KeyKind.util,
        label: label,
        onTap: () => onMove(delta),
        child: Ico(icon),
      ),
    );
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: names.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                if (i == names.length) {
                  return pill(
                    onTap: onNewMatrix,
                    label: 'New matrix',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Ico(MIcon.plus, size: 16, color: pal.accentInk),
                        const SizedBox(width: 4),
                        Text(
                          'New',
                          style: TextStyle(
                            fontSize: Fs.sm,
                            fontWeight: FontWeight.w500,
                            color: pal.accentInk,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return pill(
                  onTap: () => onInsert(names[i], 0),
                  label: 'Insert matrix ${names[i]}',
                  child: Text(
                    names[i],
                    style: mathStyle(
                      context,
                      size: Fs.lg,
                      weight: FontWeight.w600,
                      italic: true,
                      height: 1.1,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 4),
        arrow(MIcon.left, 'Move cursor left', -1),
        const SizedBox(width: 4),
        arrow(MIcon.right, 'Move cursor right', 1),
      ],
    );
  }

  Widget _angleKey(BuildContext context) {
    final pal = context.pal;
    TextSpan part(String t, bool on) => TextSpan(
      text: t,
      style: TextStyle(
        color: on ? pal.accentInk : pal.ink3,
        fontWeight: on ? FontWeight.w600 : FontWeight.w500,
      ),
    );
    return KeyCap(
      kind: KeyKind.util,
      label:
          'Angle unit: ${degrees ? 'degrees' : 'radians'}. Switch to ${degrees ? 'radians' : 'degrees'}',
      onTap: onAngle,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text.rich(
          TextSpan(
            style: const TextStyle(fontSize: 13, height: 1),
            children: [
              part('RAD', !degrees),
              TextSpan(
                text: ' · ',
                style: TextStyle(color: pal.ink3),
              ),
              part('DEG', degrees),
            ],
          ),
        ),
      ),
    );
  }

  List<List<KeyDef>> _rows(String id) =>
      keypadPages.firstWhere((p) => p.id == id).rows;

  Widget _keys(BuildContext context, String shown) {
    return LayoutBuilder(
      builder: (context, c) {
        final rowH = fill && c.maxHeight.isFinite
            ? math.max(_minRow, (c.maxHeight - 3 * _gap) / 4)
            : rowHeight;
        final Widget grid = dual
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: Semantics(
                      container: true,
                      label: 'Numbers',
                      child: _grid(context, _rows('num'), rowH, util: false),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 7,
                    child: _grid(context, _rows(shown), rowH, util: true),
                  ),
                ],
              )
            : _grid(context, _rows(shown), rowH, util: true);
        // On a very short screen the rows stop shrinking at their minimum
        // and the grid is clipped rather than overflowing.
        return fill
            ? SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: grid,
              )
            : grid;
      },
    );
  }

  /// One page of keys; [util] adds the backspace / enter column.
  Widget _grid(
    BuildContext context,
    List<List<KeyDef>> rows,
    double rowH, {
    required bool util,
  }) {
    Widget tall(Widget child) =>
        SizedBox(height: rowH * 2 + _gap, child: child);
    return LayoutBuilder(
      builder: (context, c) {
        final w = util
            ? (c.maxWidth - 6 * _gap) / 7
            : (c.maxWidth - 5 * _gap) / 6;
        final keys = Column(
          children: [
            for (var r = 0; r < rows.length; r++) ...[
              if (r > 0) const SizedBox(height: _gap),
              SizedBox(
                height: rowH,
                child: Row(
                  children: [
                    for (var k = 0; k < rows[r].length; k++) ...[
                      if (k > 0) const SizedBox(width: _gap),
                      if (identical(rows[r][k], angleToggle))
                        SizedBox(width: w * 2 + _gap, child: _angleKey(context))
                      else
                        SizedBox(
                          width: w,
                          child: KeyCap.def(
                            rows[r][k],
                            onTap: () =>
                                onInsert(rows[r][k].ins, rows[r][k].back),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
        if (!util) return keys;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: keys),
            const SizedBox(width: _gap),
            SizedBox(
              width: w,
              child: Column(
                children: [
                  tall(
                    KeyCap(
                      kind: KeyKind.util,
                      label: 'Delete',
                      onTap: onBackspace,
                      child: const Ico(MIcon.backspace),
                    ),
                  ),
                  const SizedBox(height: _gap),
                  tall(
                    KeyCap(
                      kind: KeyKind.enter,
                      label: 'Enter — next line',
                      onTap: onEnter,
                      child: const Ico(MIcon.enter),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
