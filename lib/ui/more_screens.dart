import 'package:material_ui/material_ui.dart';

import '../app/app_state.dart';
import 'icons.dart';
import 'library_screen.dart' show FieldLabel, InputBox;
import 'scope.dart';
import 'theme.dart';
import 'tutorial_screen.dart';
import 'widgets.dart';

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _shortDate(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  return '${d.day} ${_months[d.month - 1]}';
}

String _ago(int ms) {
  final m = ((DateTime.now().millisecondsSinceEpoch - ms) / 60000).round();
  if (m < 1) return 'just now';
  if (m < 60) return '$m min ago';
  final h = (m / 60).round();
  if (h < 24) return '$h h ago';
  return '${(h / 24).round()} d ago';
}

Widget _rowTitle(BuildContext context, String text) => Text(
  text,
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
  style: TextStyle(
    fontSize: Fs.body,
    fontWeight: FontWeight.w600,
    height: 1.35,
    color: context.pal.ink,
  ),
);

Widget _rowSub(BuildContext context, String text) => Text(
  text,
  style: TextStyle(fontSize: 13, height: 1.4, color: context.pal.ink3),
);

Widget _paragraph(BuildContext context, String text, {double bottom = 12}) =>
    Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Text(
        text,
        style: TextStyle(fontSize: Fs.sm, height: 1.6, color: context.pal.ink2),
      ),
    );

/* ---------- workspaces ---------- */

class WorkspacesScreen extends StatefulWidget {
  const WorkspacesScreen({super.key});

  @override
  State<WorkspacesScreen> createState() => _WorkspacesScreenState();
}

class _WorkspacesScreenState extends State<WorkspacesScreen> {
  final _name = TextEditingController();
  String _nameFor = '';

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context), pal = context.pal;
    if (_nameFor != state.currentId) {
      _nameFor = state.currentId;
      _name.text = state.ws.name;
    }
    return SubScreen(
      title: 'Workspaces',
      child: SubScroll(
        children: [
          const SizedBox(height: 8),
          const FieldLabel('Name of this workspace'),
          InputBox(
            icon: MIcon.edit,
            controller: _name,
            maxLength: 60,
            onChanged: state.renameWorkspace,
          ),
          const SizedBox(height: 20),
          const GroupTitle('All workspaces'),
          CardBox(
            child: DividedColumn(
              children: [
                for (final w in state.workspaces)
                  Row(
                    children: [
                      Expanded(
                        child: RowTap(
                          onTap: () {
                            if (w.id != state.currentId) {
                              state.openWorkspace(w.id);
                              showToast(context, 'Opened ${w.name}');
                            }
                            closeSub(context);
                          },
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _rowTitle(context, w.name),
                                    _rowSub(
                                      context,
                                      '${w.matrices.length} matri${w.matrices.length == 1 ? 'x' : 'ces'} · ${w.lines.where((l) => l.text.trim().isNotEmpty).length} lines · ${_shortDate(w.updated)}',
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (w.id == state.currentId)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: pal.accentSoft,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'Open',
                                    style: TextStyle(
                                      fontSize: Fs.cap,
                                      fontWeight: FontWeight.w600,
                                      color: pal.accentInk,
                                    ),
                                  ),
                                )
                              else
                                Ico(MIcon.chev, size: 18, color: pal.ink3),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: IconBtn(
                          MIcon.trash,
                          small: true,
                          label: 'Delete ${w.name}',
                          onTap: () => _delete(state, w.id),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Btn(
                'New workspace',
                icon: MIcon.plus,
                kind: BtnKind.primary,
                onTap: () {
                  state.newWorkspace();
                  showToast(context, 'New workspace created');
                  closeSub(context);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          const GroupTitle('Samples'),
          _paragraph(
            context,
            'Matscape comes with a sample workspace for each topic. If you '
            'deleted some, you can bring them back. Your own workspaces '
            'are not touched.',
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Btn(
              'Restore samples',
              icon: MIcon.folder,
              expand: false,
              onTap: () {
                final n = state.restoreSamples();
                showToast(
                  context,
                  n == 0
                      ? 'All the samples are already here'
                      : 'Restored $n sample workspace${n == 1 ? '' : 's'}',
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(AppState state, String id) async {
    final w = state.workspaces.firstWhere((x) => x.id == id);
    if (state.workspaces.length == 1) {
      showToast(context, 'Keep at least one workspace');
      return;
    }
    final ok = await confirmDialog(
      context,
      title: 'Delete “${w.name}”?',
      body:
          'Its ${w.matrices.length} matrices and ${w.lines.length} lines will be removed. This can’t be undone.',
      ok: 'Delete',
    );
    if (!ok || !mounted) return;
    state.deleteWorkspace(id);
    showToast(context, 'Deleted “${w.name}”');
  }
}

/* ---------- history ---------- */

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.host});
  final WorkspaceHost host;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context), pal = context.pal;
    final items = state.history;
    return SubScreen(
      title: 'History',
      action: items.isEmpty
          ? null
          : TextBtn(
              'Clear',
              onTap: () async {
                final ok = await confirmDialog(
                  context,
                  title: 'Clear history?',
                  body: 'Saved expressions will be removed from this list. Your workspaces stay as they are.',
                  ok: 'Clear',
                );
                if (ok) state.clearHistory();
              },
            ),
      child: SubScroll(
        children: [
          if (items.isEmpty)
            const EmptyState(
              icon: MIcon.clock,
              title: 'No history yet',
              body: 'Write an expression and move on to another line — it will be saved here for quick reuse.',
            )
          else ...[
            const SizedBox(height: 8),
            _paragraph(
              context,
              'Expressions you finish are kept here, most recent first. Tap one to add it as a new line.',
            ),
            CardBox(
              child: DividedColumn(
                children: [
                  for (final h in items)
                    RowTap(
                      onTap: () {
                        closeSub(context);
                        host.addLineWith(h.text);
                        showToast(context, 'Added from history');
                      },
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  h.text,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: mathStyle(context, size: Fs.lg),
                                ),
                                _rowSub(
                                  context,
                                  '= ${h.summary} · ${_ago(h.ts)}',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Ico(MIcon.plus, size: 18, color: pal.ink3),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/* ---------- settings ---------- */

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context), s = state.settings;

    Widget row(
      String title, {
      String? sub,
      Widget? below,
      Widget? trailing,
    }) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _rowTitle(context, title),
                    if (sub != null) _rowSub(context, sub),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 12), trailing],
            ],
          ),
          if (below != null) ...[const SizedBox(height: 8), below],
        ],
      ),
    );

    Widget stepper(
      String label,
      int value,
      int min,
      int max,
      void Function(int v) set,
    ) => StepperBox(
      value: value,
      min: min,
      max: max,
      label: label,
      onChanged: (v) => state.updateSettings((_) => set(v)),
    );

    Widget group(String title, List<Widget> rows) => Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GroupTitle(title),
          CardBox(child: DividedColumn(children: rows)),
        ],
      ),
    );

    return SubScreen(
      title: 'Settings',
      child: SubScroll(
        children: [
          group('Appearance', [
            row(
              'Theme',
              below: Seg<String>(
                options: const [
                  ('system', 'System'),
                  ('light', 'Light'),
                  ('dark', 'Dark'),
                ],
                value: s.theme,
                onChanged: (v) => state.updateSettings((s) => s.theme = v),
              ),
            ),
          ]),
          group('Results', [
            row(
              'Angle unit',
              sub: 'Used by sin, cos, tan and their inverses. Add ° to any number to force degrees.',
              below: Seg<bool>(
                options: const [(false, 'Radians'), (true, 'Degrees')],
                value: s.degrees,
                onChanged: (v) => state.updateSettings((s) => s.degrees = v),
              ),
            ),
            row(
              'Number format',
              sub: 'Exact shows fractions, square roots and π where it can.',
              below: Seg<bool>(
                options: const [(true, 'Exact'), (false, 'Decimal')],
                value: s.exact,
                onChanged: (v) => state.updateSettings((s) => s.exact = v),
              ),
            ),
            row(
              'Decimal places',
              sub: 'For values that aren’t exact.',
              trailing: stepper(
                'decimal places',
                s.precision,
                2,
                10,
                (v) => s.precision = v,
              ),
            ),
          ]),
          group('New matrices', [
            row(
              'Rows',
              trailing: stepper(
                'default rows',
                s.defRows,
                1,
                maxMatrixSize,
                (v) => s.defRows = v,
              ),
            ),
            row(
              'Columns',
              trailing: stepper(
                'default columns',
                s.defCols,
                1,
                maxMatrixSize,
                (v) => s.defCols = v,
              ),
            ),
            row(
              'Start with',
              below: Seg<bool>(
                options: const [(false, 'Zeros'), (true, 'Identity')],
                value: s.defIdentity,
                onChanged: (v) =>
                    state.updateSettings((s) => s.defIdentity = v),
              ),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const GroupTitle('About'),
                CardBox(
                  padding: const EdgeInsets.all(16),
                  child: _paragraph(
                    context,
                    'Matscape 2.0 for iOS and Android. Made by ByteMechanics. Everything is calculated on your device; nothing is sent anywhere.',
                    bottom: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ---------- help ---------- */

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key, required this.host});
  final WorkspaceHost host;

  static const _tries = [
    ('[1, 2; 3, 4]⁻¹', 'Inline matrix and inverse'),
    ('det([2, 1; 1, 3] − 2I)', 'Bare I takes the size it needs'),
    ('eig([0, −1; 1, 0])', 'Complex eigenvalues'),
    ('sin(30°)·I(2)', 'Trig with degrees'),
    ('expm([0, −π; π, 0])', 'Matrix exponential'),
    ('solve([2, 1; 1, 3], [3; 5])', 'Solve a linear system'),
  ];

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return SubScreen(
      title: 'Help & tips',
      child: SubScroll(
        children: [
          const SizedBox(height: 8),
          const GroupTitle('How it works'),
          _paragraph(
            context,
            'Keep matrices at the top and write expressions underneath — every line recalculates as you type. Tap a matrix card to edit its entries; entries can be expressions too, like sin(π/6) or 2√3.',
          ),
          _paragraph(
            context,
            'Press Enter to move to a new line. Name a result with “=” (for example M = A·B) and use M in later lines.',
          ),
          _paragraph(
            context,
            'Tap Inspect on any matrix result for its properties, eigenvalues, norms, step-by-step row reduction and decompositions.',
          ),
          _paragraph(
            context,
            'To change the order, drag a matrix card by the dots in its corner, or drag an expression by the numbered strip on its left.',
          ),
          _paragraph(
            context,
            'The operations library (the book icon) explains every operation on its own page, with examples you can try. The sample workspaces, under Workspaces, cover one topic each.',
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Btn(
              'Take the tour again',
              icon: MIcon.eye,
              expand: false,
              onTap: () => TutorialScreen.show(context),
            ),
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 8),
          const GroupTitle('Try these'),
          CardBox(
            child: DividedColumn(
              children: [
                for (final (text, caption) in _tries)
                  RowTap(
                    minHeight: 52,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    onTap: () {
                      closeSub(context);
                      host.addLineWith(text);
                      showToast(context, 'Example added');
                    },
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                text,
                                style: mathStyle(context, size: Fs.lg),
                              ),
                              _rowSub(context, caption),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Add',
                          style: TextStyle(
                            fontSize: Fs.cap,
                            fontWeight: FontWeight.w600,
                            color: pal.accentInk,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const GroupTitle('Keyboard shortcuts'),
          CardBox(
            padding: const EdgeInsets.all(16),
            child: _paragraph(
              context,
              'On a hardware keyboard you can type directly: * for ·, \' for transpose, ^-1 for the inverse. Enter adds a line, Backspace on an empty line removes it, ↑ and ↓ move between lines.',
              bottom: 0,
            ),
          ),
        ],
      ),
    );
  }
}
