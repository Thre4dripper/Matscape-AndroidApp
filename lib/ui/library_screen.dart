import 'package:material_ui/material_ui.dart';

import '../app/app_state.dart' show matrixLetters;
import '../engine/engine.dart';
import 'icons.dart';
import 'library_data.dart';
import 'math_view.dart';
import 'scope.dart';
import 'theme.dart';
import 'widgets.dart';

/// The operations library: a searchable list of everything the app can
/// calculate. Tapping an entry opens a page that explains it, with worked
/// examples and a button to try them in the workspace.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key, required this.host});
  final WorkspaceHost host;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _query = TextEditingController();
  final _queryFocus = FocusNode();
  String _group = 'All';

  /// The entry whose page is open, if any.
  Op? _open;

  @override
  void dispose() {
    _query.dispose();
    _queryFocus.dispose();
    super.dispose();
  }

  void _show(Op? op) {
    _queryFocus.unfocus();
    setState(() => _open = op);
  }

  @override
  Widget build(BuildContext context) {
    final open = _open;
    return PopScope(
      // The system back button returns to the list before leaving it.
      canPop: open == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _show(null);
      },
      child: SubScreen(
        title: 'Operations',
        onBack: open == null ? null : () => _show(null),
        backLabel: 'Back to operations',
        // The list stays alive underneath, so it keeps its scroll position.
        child: IndexedStack(
          index: open == null ? 0 : 1,
          children: [
            ExcludeFocus(excluding: open != null, child: _list(context)),
            if (open == null)
              const SizedBox.shrink()
            else
              _OpPage(key: ValueKey(open), op: open, host: widget.host),
          ],
        ),
      ),
    );
  }

  Widget _list(BuildContext context) {
    final pal = context.pal;
    final tokens = _query.text
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    final items = [
      for (final o in ops)
        if ((_group == 'All' || o.group == _group) &&
            tokens.every(o.haystack.contains))
          o,
    ];
    final groups = {for (final o in items) o.group};

    return ListView(
      padding: EdgeInsets.fromLTRB(
        0,
        8,
        0,
        32 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FieldLabel('Search operations'),
              InputBox(
                icon: MIcon.search,
                controller: _query,
                focusNode: _queryFocus,
                hint: 'inverse, eigen, sin…',
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            itemCount: opGroups.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) => ChipBtn(
              opGroups[i],
              on: opGroups[i] == _group,
              onTap: () => setState(() => _group = opGroups[i]),
            ),
          ),
        ),
        if (items.isEmpty)
          EmptyState(
            icon: MIcon.search,
            title: 'No operations match “${_query.text}”',
            body: 'Try a shorter word like “inv”, “eig” or “trig”, or clear the filter.',
            action: Btn(
              'Clear search',
              expand: false,
              onTap: () {
                setState(() {
                  _query.clear();
                  _group = 'All';
                });
                _queryFocus.requestFocus();
              },
            ),
          ),
        for (final g in groups)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GroupTitle(g),
                CardBox(
                  child: DividedColumn(
                    children: [
                      for (final o in items.where((o) => o.group == g))
                        RowTap(
                          minHeight: 0,
                          label: '${o.title}. ${o.desc}. Open',
                          onTap: () => _show(o),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      o.syntax,
                                      style: mathStyle(context, size: Fs.lg),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      o.desc,
                                      style: TextStyle(
                                        fontSize: 13,
                                        height: 1.45,
                                        color: pal.ink2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Ico(MIcon.chev, size: 18, color: pal.ink3),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/* ---------- one operation's page ---------- */

/// A worked example, ready to show.
class _Example {
  _Example(this.inline, this.named, this.given, this.result);

  /// As typed in one line, with matrices written in square brackets.
  final String inline;

  /// The same expression with each of those matrices given a letter, the
  /// way it reads when the matrices are saved in the workspace.
  final String named;

  /// The letters this example introduces, with their matrices.
  final List<(String, Mat)> given;
  final EvalResult result;
}

final _inlineMatrix = RegExp(r'\[[^\[\]]*\]');

class _OpPage extends StatelessWidget {
  const _OpPage({super.key, required this.op, required this.host});
  final Op op;
  final WorkspaceHost host;

  /// Works the examples out in order; a name set by one is available to
  /// the next, as in a workspace. Inline matrices are given the letters
  /// A, B, C … so each example can also be shown with named matrices.
  List<_Example> _run(bool degrees) {
    EvalResult eval(String text, Map<String, Object> vars) =>
        evaluate(text, vars: vars, degrees: degrees, matrixNames: const {});

    final vars = <String, Object>{};
    // Letters the examples already use for something else stay free.
    final taken = op.examples.join().replaceAll(_inlineMatrix, '');
    final letters = [
      for (final c in matrixLetters.split(''))
        if (!taken.contains(c)) c,
    ];
    final named = <String, String>{};

    return [
      for (final text in op.examples)
        () {
          final given = <(String, Mat)>[];
          var shown = text;
          if (!op.inlineOnly) {
            shown = text.replaceAllMapped(_inlineMatrix, (m) {
              final src = m[0]!;
              var letter = named[src];
              if (letter == null) {
                final v = eval(src, const {}).value;
                if (v is! Mat || named.length >= letters.length) return src;
                letter = named[src] = letters[named.length];
                given.add((letter, v));
              }
              return letter;
            });
          }
          final r = eval(text, vars);
          final v = r.value;
          if (r.ok && r.assign != null && (v is Mat || v is double)) {
            vars[r.assign!] = v!;
          }
          return _Example(text, shown, given, r);
        }(),
    ];
  }

  void _try(BuildContext context) {
    closeSub(context);
    for (final e in op.examples) {
      host.addLineWith(e);
    }
    showToast(
      context,
      op.examples.length == 1
          ? 'Example added to your workspace'
          : '${op.examples.length} examples added to your workspace',
    );
  }

  void _insert(BuildContext context) {
    closeSub(context);
    host.insertText(op.ins, back: op.back);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context), pal = context.pal;
    final results = _run(state.settings.degrees);
    final sample = state.workspaces
        .where((w) => w.name == op.sampleName)
        .firstOrNull;
    final insLabel = op.ins.replaceFirst(RegExp(r'\(\)$'), '( )').trim();
    final body = TextStyle(fontSize: 15, height: 1.6, color: pal.ink2);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            children: [
              GroupTitle(op.group),
              Semantics(
                header: true,
                child: Text(
                  op.title,
                  style: mathStyle(
                    context,
                    size: Fs.xxl,
                    weight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CardBox(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How to write it',
                      style: TextStyle(fontSize: Fs.cap, color: pal.ink3),
                    ),
                    const SizedBox(height: 4),
                    Text(op.syntax, style: mathStyle(context, size: Fs.xl)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ..._paragraphs(op.about, body),
              for (final (heading, text) in op.more) ...[
                const SizedBox(height: 12),
                Semantics(
                  header: true,
                  child: Text(
                    heading,
                    style: TextStyle(
                      fontSize: Fs.body,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                      color: pal.ink,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                ..._paragraphs(text, body),
              ],
              const SizedBox(height: 12),
              GroupTitle(results.length == 1 ? 'Example' : 'Examples'),
              CardBox(
                child: DividedColumn(
                  children: [
                    for (final e in results)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        child: _ExampleView(e, state.fmt),
                      ),
                  ],
                ),
              ),
              if (op.notes.isNotEmpty) ...[
                const SizedBox(height: 24),
                const GroupTitle('Good to know'),
                for (final n in op.notes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 10, right: 10),
                          child: Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: pal.ink3,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Expanded(child: Text(n, style: body)),
                      ],
                    ),
                  ),
              ],
              if (sample != null) ...[
                const SizedBox(height: 16),
                const GroupTitle('More to explore'),
                CardBox(
                  child: RowTap(
                    onTap: () {
                      state.openWorkspace(sample.id);
                      closeSub(context);
                      showToast(context, 'Opened ${sample.name}');
                    },
                    child: Row(
                      children: [
                        Ico(MIcon.folder, size: 20, color: pal.ink2),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sample.name,
                                style: TextStyle(
                                  fontSize: Fs.body,
                                  fontWeight: FontWeight.w600,
                                  height: 1.35,
                                  color: pal.ink,
                                ),
                              ),
                              Text(
                                'Sample workspace on this topic',
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: pal.ink3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Ico(MIcon.chev, size: 18, color: pal.ink3),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        // Actions stay in reach however long the page is.
        Container(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            12 + MediaQuery.paddingOf(context).bottom,
          ),
          decoration: BoxDecoration(
            color: pal.bg,
            border: Border(top: BorderSide(color: pal.line)),
          ),
          child: Row(
            children: [
              Btn('Insert $insLabel', onTap: () => _insert(context)),
              const SizedBox(width: 8),
              Btn(
                'Try it out',
                icon: MIcon.plus,
                kind: BtnKind.primary,
                onTap: () => _try(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Text split into paragraphs at blank lines.
List<Widget> _paragraphs(String text, TextStyle style) => [
  for (final p in text.split('\n\n'))
    Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(p, style: style),
    ),
];

/// One example: the matrices it uses, drawn properly; the expression
/// written with their names; the answer; and the same thing as it is typed
/// in one line.
class _ExampleView extends StatelessWidget {
  const _ExampleView(this.example, this.fmt);
  final _Example example;
  final NumFmt fmt;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal, e = example;
    final caption = TextStyle(fontSize: Fs.cap, height: 1.4, color: pal.ink3);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (e.given.isNotEmpty) ...[
          Wrap(
            spacing: 20,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final (letter, m) in e.given)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      letter,
                      style: mathStyle(context, size: Fs.lg, italic: true),
                    ),
                    Text(
                      '  =  ',
                      style: mathStyle(context, size: Fs.lg, color: pal.ink3),
                    ),
                    Flexible(
                      child: HScroll(
                        child: MatrixView(m, fmt, fontSize: 17, gap: 14),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        HScroll(
          child: Text(
            e.named,
            softWrap: false,
            style: mathStyle(context, size: Fs.lg),
          ),
        ),
        const SizedBox(height: 4),
        _ExampleResult(e.result, fmt),
        if (e.named != e.inline) ...[
          const SizedBox(height: 10),
          Text('Typed in one line', style: caption),
          const SizedBox(height: 2),
          Text(
            e.inline,
            style: mathStyle(context, size: Fs.sm, color: pal.ink2),
          ),
        ],
      ],
    );
  }
}

/// The answer to an example, typeset like a result in the workspace.
class _ExampleResult extends StatelessWidget {
  const _ExampleResult(this.res, this.fmt);
  final EvalResult res;
  final NumFmt fmt;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal, st = mathStyle(context);
    if (!res.ok) return ErrorNote(res.error ?? 'No result', hint: res.hint);
    final v = res.value!;
    final eq = Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Text(
        '=',
        style: mathStyle(context, size: Fs.lg, color: pal.ink3),
      ),
    );
    Widget caption(String text) => Text(
      text,
      style: TextStyle(fontSize: Fs.cap, height: 1.4, color: pal.ink3),
    );

    final parts = <Widget>[];
    if (v is double) {
      parts.add(
        HScroll(
          child: Row(
            children: [
              eq,
              NumText(v, fmt, style: st),
            ],
          ),
        ),
      );
    } else if (v is Mat) {
      parts.add(HScroll(child: Row(children: [eq, MatrixView(v, fmt)])));
    } else if (v is ListVal) {
      parts.add(
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: [
            for (var i = 0; i < v.items.length; i++)
              Text.rich(
                TextSpan(
                  style: st,
                  children: [
                    const TextSpan(
                      text: 'λ',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                    sub('${i + 1}', st),
                    const TextSpan(text: ' = '),
                    ...complexSpans(v.items[i], fmt, st),
                  ],
                ),
                softWrap: false,
              ),
          ],
        ),
      );
    } else if (v is MultiVal) {
      if (v.relation != null) {
        parts.add(
          Text(
            v.relation!,
            style: mathStyle(context, size: Fs.sm, color: pal.ink3),
          ),
        );
      }
      // Each part stays whole; parts that don't fit move to the next row.
      parts.add(
        Wrap(
          spacing: 20,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final p in v.parts)
              HScroll(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      p.label,
                      style: mathStyle(context, size: Fs.lg, italic: true),
                    ),
                    const SizedBox(width: 8),
                    // Labels such as "λ = 5" already carry their sign.
                    if (!p.label.contains('=')) eq,
                    MatrixView(p.value, fmt),
                  ],
                ),
              ),
          ],
        ),
      );
    } else if (v is PolyVal) {
      parts.add(
        HScroll(
          child: Row(
            children: [
              eq,
              Text.rich(
                TextSpan(children: polySpans(v.coeffs, fmt, st), style: st),
                softWrap: false,
              ),
            ],
          ),
        ),
      );
    } else if (v is TextVal) {
      parts.add(Text(v.text, style: TextStyle(fontSize: 13, color: pal.ink3)));
    }
    if (res.assign != null) parts.add(caption('Saved as ${res.assign}'));
    for (final w in res.warnings) {
      parts.add(caption(w));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < parts.length; i++) ...[
          if (i > 0) const SizedBox(height: 4),
          parts[i],
        ],
      ],
    );
  }
}

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: TextStyle(
        fontSize: Fs.sm,
        fontWeight: FontWeight.w600,
        color: context.pal.ink2,
      ),
    ),
  );
}

/// Bordered single-line text input with a leading icon. Uses the system
/// keyboard (unlike the math fields).
class InputBox extends StatefulWidget {
  const InputBox({
    super.key,
    required this.icon,
    required this.controller,
    this.focusNode,
    this.hint = '',
    this.maxLength,
    this.onChanged,
  });
  final MIcon icon;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final int? maxLength;
  final ValueChanged<String>? onChanged;

  @override
  State<InputBox> createState() => _InputBoxState();
}

class _InputBoxState extends State<InputBox> {
  FocusNode? _own;
  FocusNode get _node => widget.focusNode ?? (_own ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _node.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _node.removeListener(_refresh);
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal, focused = _node.hasFocus;
    return AnimatedContainer(
      duration: Motion.fast,
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: pal.surface,
        border: Border.all(color: focused ? pal.accent : pal.lineStrong),
        borderRadius: BorderRadius.circular(12),
        boxShadow: focused
            ? [BoxShadow(color: pal.accentSoft, spreadRadius: 3)]
            : null,
      ),
      child: Row(
        children: [
          Ico(widget.icon, size: 18, color: pal.ink3),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _node,
              maxLines: 1,
              maxLength: widget.maxLength,
              autocorrect: false,
              cursorColor: pal.accent,
              textInputAction: TextInputAction.done,
              style: TextStyle(fontSize: Fs.body, color: pal.ink),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                counterText: '',
                hintText: widget.hint,
                hintStyle: TextStyle(fontSize: Fs.body, color: pal.ink3),
              ),
              onChanged: widget.onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
