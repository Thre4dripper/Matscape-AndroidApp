import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../app/app_state.dart';
import '../app/models.dart';
import '../engine/engine.dart';
import 'icons.dart';
import 'layout.dart';
import 'math_view.dart';
import 'matrix_card.dart';
import 'scope.dart';
import 'theme.dart';
import 'widgets.dart';

/// One page of the tour.
class _Step {
  const _Step(this.title, this.body, this.points, this.figure);
  final String title, body;
  final List<String> points;
  final Widget Function(BuildContext context) figure;
}

/// The tour shown the first time the app is opened, and again from Help.
/// It walks through every part of the app and points to the sample
/// workspaces.
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  /// Opens the tour over everything else. Completes when it is closed.
  static Future<void> show(BuildContext context) =>
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => const TutorialScreen(),
        ),
      );

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final _pages = PageController();
  int _index = 0;

  static final _steps = <_Step>[
    _Step(
      'Welcome to Matscape',
      'A matrix calculator that works like a page of notes. Keep your '
          'matrices at the top, write expressions underneath, and every '
          'answer updates as you type.',
      [
        'This short tour shows where everything is. It takes about a minute.',
        'You can open it again any time from Help & tips in the menu.',
      ],
      _figWelcome,
    ),
    _Step(
      'Matrices live at the top',
      'Each card is a matrix with a one-letter name. Tap a card to edit it, '
          'or tap New to add one.',
      [
        'In the editor you can change the size, rename, duplicate or delete '
            'the matrix, and fill it with zeros, an identity, random '
            'numbers and more.',
        'An entry can be an expression, such as 1/2, √3 or sin(30°).',
        'Drag a card by the dots in its corner to change the order.',
      ],
      _figMatrices,
    ),
    _Step(
      'Write expressions underneath',
      'Tap a line and type with the keypad — det(A), A⁻¹, AB + 2C. The '
          'answer appears under the line and recalculates whenever a matrix '
          'changes.',
      [
        'Enter starts a new line. ✕ removes one.',
        'Drag the numbered strip on the left to move a line up or down.',
        'If something can’t be worked out, the line says why and how to '
            'fix it.',
      ],
      _figLine,
    ),
    _Step(
      'A keypad made for matrices',
      'The keypad has four pages: 123 for numbers and brackets, Matrix for '
          'determinant, inverse and transpose, f(x) for trig and logs, and '
          'More for everything else.',
      [
        'Your matrix names sit in a row above the keys, one tap away.',
        'RAD / DEG on the f(x) page switches the angle unit.',
        'The arrow at the top right hides the keypad to give results more '
            'room.',
      ],
      _figKeypad,
    ),
    _Step(
      'Exact answers you can reuse',
      'Results stay exact where they can — fractions, square roots and '
          'multiples of π instead of long decimals.',
      [
        'Name a result with “=”, for example M = A·B, then use M in any '
            'other line.',
        'Under a matrix result, Save as matrix keeps it as a new card and '
            'Copy puts it on the clipboard.',
        'Prefer decimals? Change the number format in Settings.',
      ],
      _figExact,
    ),
    _Step(
      'Look inside any matrix',
      'Tap Inspect under a matrix result to see everything about it on one '
          'page.',
      [
        'Properties: square, symmetric, invertible, rank, determinant, '
            'trace.',
        'Eigenvalues, norms and the condition number.',
        'Row reduction, the determinant and the inverse worked out step by '
            'step, and the LU, QR, Cholesky and SVD decompositions.',
      ],
      _figInspect,
    ),
    _Step(
      'Every operation, explained',
      'The book at the top right opens the operations library: everything '
          'Matscape can calculate, grouped by topic and searchable.',
      [
        'Each operation has its own page with what it means, how to write '
            'it, and worked examples.',
        'Try it out puts the examples in your workspace so you can change '
            'them.',
      ],
      _figLibrary,
    ),
    _Step(
      'Sample workspaces to learn from',
      'A workspace is one page of matrices and expressions. Matscape comes '
          'with a sample workspace for every topic, from basic arithmetic '
          'to eigenvalues and decompositions.',
      [
        'Open the menu and choose Workspaces to switch between them.',
        'Change anything you like — or start your own with New workspace.',
        'Deleted a sample? Restore samples brings it back.',
      ],
      _figSamples,
    ),
    _Step(
      'The rest is in the menu',
      'History, settings and help are behind the menu button at the top '
          'left. On a tablet they are always visible in the sidebar.',
      [
        'History keeps the expressions you entered. Tap one to use it '
            'again.',
        'Settings has the theme, radians or degrees, exact or decimal '
            'results, and the size of new matrices.',
        'Help & tips has examples to try, and this tour.',
      ],
      _figMenu,
    ),
  ];

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int i) =>
      _pages.animateToPage(i, duration: Motion.slow, curve: Motion.easeOut);

  void _close() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final pal = context.pal, size = MediaQuery.sizeOf(context);
    // Stay on one side of a fold, like every other overlay.
    final area = LayoutInfo.of(context).overlayRect(size);
    final last = _index == _steps.length - 1;
    return Scaffold(
      backgroundColor: pal.bg,
      body: Padding(
        padding: EdgeInsets.only(
          right: size.width - area.right,
          bottom: size.height - area.bottom,
        ),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 52,
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        '${_index + 1} of ${_steps.length}',
                        style: TextStyle(fontSize: 13, color: pal.ink3),
                      ),
                    ),
                    if (!last) TextBtn('Skip', onTap: _close),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pages,
                  itemCount: _steps.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) => _StepPage(_steps[i]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 12),
                child: ExcludeSemantics(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _steps.length; i++)
                        AnimatedContainer(
                          duration: Motion.base,
                          width: i == _index ? 18 : 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: i == _index ? pal.accent : pal.lineStrong,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Row(
                      children: [
                        if (_index > 0) ...[
                          Btn('Back', onTap: () => _go(_index - 1)),
                          const SizedBox(width: 8),
                        ],
                        Btn(
                          last ? 'Get started' : 'Next',
                          kind: BtnKind.primary,
                          onTap: last ? _close : () => _go(_index + 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepPage extends StatelessWidget {
  const _StepPage(this.step);
  final _Step step;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final body = TextStyle(fontSize: 15, height: 1.55, color: pal.ink2);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The picture: a small piece of the real interface.
              ExcludeSemantics(
                child: IgnorePointer(
                  child: Container(
                    height: 176,
                    padding: const EdgeInsets.all(16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: pal.surface2,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: step.figure(context),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Semantics(
                header: true,
                child: Text(
                  step.title,
                  style: mathStyle(
                    context,
                    size: 26,
                    weight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(step.body, style: body),
              const SizedBox(height: 14),
              for (final p in step.points)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 3, right: 10),
                        child: Ico(MIcon.check, size: 16, color: pal.accent),
                      ),
                      Expanded(
                        child: Text(p, style: body.copyWith(fontSize: 14)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ---------- the pictures ---------- */

const _fmt = NumFmt();

Widget _panel(BuildContext context, Widget child, {EdgeInsets? padding}) {
  final pal = context.pal;
  return Container(
    padding:
        padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: pal.surface,
      border: Border.all(color: pal.line),
      borderRadius: BorderRadius.circular(14),
    ),
    child: child,
  );
}

Widget _pill(BuildContext context, String text, {bool on = false}) {
  final pal = context.pal;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: on ? pal.accentSoft : pal.surface,
      border: Border.all(color: on ? pal.accentSoft : pal.line),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: on ? pal.accentInk : pal.ink2,
      ),
    ),
  );
}

Widget _figWelcome(BuildContext context) => Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    const Wordmark(size: 44),
    const SizedBox(height: 6),
    Text(
      'Matrix calculator',
      style: TextStyle(fontSize: Fs.sm, color: context.pal.ink3),
    ),
  ],
);

Widget _figMatrices(BuildContext context) {
  Widget card(String name, List<List<double>> rows) => MatrixCard(
    model: MatrixModel.of(name, rows),
    eval: MatEval.ok(Mat(rows)),
    fmt: _fmt,
    onTap: () {},
    handle: const Grip(),
  );
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      card('A', [
        [4, 1, 2],
        [1, 3, 0],
        [2, 0, 5],
      ]),
      const SizedBox(width: 10),
      card('B', [
        [1, 2, 3],
        [4, 5, 6],
      ]),
      const SizedBox(width: 10),
      NewMatrixCard(onTap: () {}),
    ],
  );
}

Widget _figLine(BuildContext context) {
  final pal = context.pal;
  Widget line(int n, String text, Widget result, {bool active = false}) =>
      Container(
        width: 280,
        decoration: BoxDecoration(
          color: pal.surface,
          border: Border(bottom: BorderSide(color: pal.line)),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 36,
                padding: const EdgeInsets.only(top: 10),
                alignment: Alignment.topCenter,
                color: active ? pal.accent : pal.surface2,
                child: Text(
                  '$n',
                  style: TextStyle(
                    fontSize: Fs.cap,
                    fontWeight: FontWeight.w600,
                    color: active ? pal.onAccent : pal.ink3,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(text, style: mathStyle(context, size: Fs.lg)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '=  ',
                          style: mathStyle(
                            context,
                            size: Fs.lg,
                            color: pal.ink3,
                          ),
                        ),
                        result,
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  final st = mathStyle(context, size: Fs.lg);
  return ClipRRect(
    borderRadius: BorderRadius.circular(14),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        line(1, 'det(A)', Text('43', style: st), active: true),
        line(2, 'tr(A) / 3', const NumText(4, _fmt)),
      ],
    ),
  );
}

Widget _figKeypad(BuildContext context) => Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    SizedBox(
      width: 300,
      child: Seg<String>(
        options: const [
          ('num', '123'),
          ('mat', 'Matrix'),
          ('fn', 'f(x)'),
          ('more', 'More'),
        ],
        value: 'mat',
        onChanged: (_) {},
      ),
    ),
    const SizedBox(height: 12),
    Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final k in const [
          'det',
          '<i>A</i><sup>−1</sup>',
          '<i>A</i><sup>T</sup>',
          'rref',
          'eig',
        ])
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: _panel(
              context,
              Text.rich(
                TextSpan(
                  children: markup(
                    k,
                    mathStyle(context, size: Fs.body, height: 1.2),
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
      ],
    ),
  ],
);

Widget _figExact(BuildContext context) {
  final st = mathStyle(context, size: Fs.lg);
  Widget row(String text, double value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$text  =  ', style: st),
        NumText(value, _fmt, style: st),
      ],
    ),
  );
  return _panel(
    context,
    Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row('1/3 + 1/6', 1 / 2),
        row('√8', math.sqrt(8)),
        row('asin(1/2)', math.pi / 6),
      ],
    ),
  );
}

Widget _figInspect(BuildContext context) => SizedBox(
  width: 300,
  child: Wrap(
    spacing: 8,
    runSpacing: 8,
    alignment: WrapAlignment.center,
    children: [
      _pill(context, 'Symmetric', on: true),
      _pill(context, 'Invertible', on: true),
      _pill(context, 'Rank 3'),
      _pill(context, 'det = 43'),
      _pill(context, 'Eigenvalues'),
      _pill(context, 'Steps'),
      _pill(context, 'LU · QR · SVD'),
    ],
  ),
);

Widget _figLibrary(BuildContext context) {
  final pal = context.pal;
  return _panel(
    context,
    SizedBox(
      width: 260,
      child: Row(
        children: [
          Ico(MIcon.book, size: 26, color: pal.accent),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('det(A)  or  |A|', style: mathStyle(context, size: Fs.lg)),
                Text(
                  'Determinant of a square matrix',
                  style: TextStyle(fontSize: 13, color: pal.ink2),
                ),
                const SizedBox(height: 8),
                _pill(context, 'Try it out', on: true),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _figSamples(BuildContext context) {
  final pal = context.pal;
  final names = [for (final w in AppScope.read(context).workspaces) w.name];
  const shown = 3;
  return _panel(
    context,
    SizedBox(
      width: 280,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final n in names.take(shown))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Ico(MIcon.folder, size: 18, color: pal.ink3),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      n,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: Fs.sm,
                        fontWeight: FontWeight.w600,
                        color: pal.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (names.length > shown)
            Padding(
              padding: const EdgeInsets.only(left: 28, top: 4),
              child: Text(
                'and ${names.length - shown} more',
                style: TextStyle(fontSize: 13, color: pal.ink3),
              ),
            ),
        ],
      ),
    ),
  );
}

Widget _figMenu(BuildContext context) {
  final pal = context.pal;
  Widget item(MIcon icon, String label) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Ico(icon, size: 18, color: pal.ink2),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: Fs.sm,
            fontWeight: FontWeight.w500,
            color: pal.ink,
          ),
        ),
      ],
    ),
  );
  return _panel(
    context,
    Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        item(MIcon.clock, 'History'),
        item(MIcon.sliders, 'Settings'),
        item(MIcon.help, 'Help & tips'),
      ],
    ),
  );
}
