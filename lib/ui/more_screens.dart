import 'package:material_ui/material_ui.dart';

import '../app/app_state.dart';
import 'icons.dart';
import 'library_screen.dart' show FieldLabel, InputBox;
import 'scope.dart';
import 'theme.dart';
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
                            final nav = Navigator.of(context);
                            if (w.id != state.currentId) {
                              state.openWorkspace(w.id);
                              showToast(context, 'Opened ${w.name}');
                            }
                            nav.pop();
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
                  final nav = Navigator.of(context);
                  state.newWorkspace();
                  showToast(context, 'New workspace created');
                  nav.pop();
                },
              ),
            ],
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
              body: 'Press Enter on any expression and it will be saved here for quick reuse.',
            )
          else ...[
            const SizedBox(height: 8),
            _paragraph(
              context,
              'Press Enter on a line to keep it here. Tap an entry to add it as a new line.',
            ),
            CardBox(
              child: DividedColumn(
                children: [
                  for (final h in items)
                    RowTap(
                      onTap: () {
                        Navigator.of(context).pop();
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
