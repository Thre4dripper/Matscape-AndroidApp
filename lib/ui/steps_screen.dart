import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../app/app_state.dart';
import '../engine/engine.dart';
import 'icons.dart';
import 'math_view.dart';
import 'scope.dart';
import 'theme.dart';
import 'widgets.dart';

/// An expression worked out one operation at a time. Each step can open to
/// show the working, and offers more than one method where there is one.
class StepsScreen extends StatefulWidget {
  const StepsScreen({super.key, required this.lineId});
  final String lineId;

  @override
  State<StepsScreen> createState() => _StepsScreenState();
}

final _tags = RegExp('<[^>]+>');

class _StepsScreenState extends State<StepsScreen> {
  /// Working with more to produce than this is built on another isolate,
  /// behind a loader, so a long solution never freezes the screen.
  static const _heavy = 4000;

  /// Steps whose working is showing, and the method chosen for each.
  final _open = <int>{};
  final _method = <int, int>{};

  /// Working that has been built, by (step, method). Nothing is worked out
  /// until its step is opened.
  final _work = <(int, int), List<Work>>{};
  final _waiting = <(int, int)>{};

  String _key = '';
  Solution? _solution;

  /// Goes up whenever the solution changes, so working that arrives late
  /// for an older one is dropped.
  int _version = 0;

  /// The solution, worked out again only when something it depends on
  /// changes.
  Solution? _solve(AppState state) {
    final s = state.settings;
    final text = state.lineById(widget.lineId)?.text;
    final key =
        '$text|${state.ws.id}|${state.ws.updated}|${s.exact}|${s.precision}|${s.degrees}';
    if (key != _key) {
      final first = _key.isEmpty;
      _key = key;
      _version++;
      _solution = state.solutionFor(widget.lineId);
      _method.clear();
      _open.clear();
      _work.clear();
      _waiting.clear();
      // A single step is the whole question, so its working starts open.
      final steps = _solution?.steps ?? const [];
      if (first && steps.length == 1 && steps[0].methods.isNotEmpty) {
        _open.add(0);
      }
    }
    return _solution;
  }

  int _chosen(SolveStep st, int i) => st.methods.isEmpty
      ? 0
      : (_method[i] ?? 0).clamp(0, st.methods.length - 1);

  /// The working for method [mi] of step [i], or null while it is being
  /// worked out.
  List<Work>? _workOf(AppState state, SolveStep st, int i, int mi) {
    final key = (i, mi), method = st.methods[mi];
    final built = _work[key];
    if (built != null) return built;
    if (method.weight < _heavy) return _work[key] = method.work;
    if (_waiting.add(key)) {
      final version = _version;
      void done(List<Work> w) {
        if (!mounted || version != _version) return;
        setState(() {
          _work[key] = w;
          _waiting.remove(key);
        });
      }

      state
          .workOffThread(widget.lineId, i, mi)
          .then(done)
          // No second isolate available: work it out here instead.
          .catchError((Object _) => done(method.work));
    }
    return null;
  }

  /// The solution as plain text: every step, and the working of the ones
  /// that are open.
  String _asText(AppState state, Solution s) {
    final b = StringBuffer()
      ..writeln(
        '${s.assign == null ? '' : '${s.assign} = '}${s.expr} = ${state.valueText(s.value)}',
      );
    for (var i = 0; i < s.steps.length; i++) {
      final st = s.steps[i];
      b
        ..writeln()
        ..writeln('${i + 1}. ${st.title}')
        ..writeln('   ${st.expr} = ${state.valueText(st.value)}');
      if (st.methods.isEmpty || !_open.contains(i)) continue;
      final mi = _chosen(st, i), work = _work[(i, mi)];
      if (work == null) continue;
      b.writeln('   ${st.methods[mi].name}:');
      for (final w in work) {
        final pad = '   ${'  ' * w.indent}';
        final head = (w.text ?? w.label ?? w.ops.join(', ')).replaceAll(
          _tags,
          '',
        );
        if (head.isNotEmpty) b.writeln('$pad$head');
        if (w.mat != null) b.writeln('$pad${AppState.matText(w.mat!)}');
      }
    }
    return b.toString().trimRight();
  }

  /// The same as an `align*` block of LaTeX.
  String _asLatex(AppState state, Solution s) {
    final set = state.settings;
    // "expr = value", or "expr: values" where the value names its parts.
    String equals(String expr, Object v) {
      final named = v is MultiVal || v is ListVal || v is TextVal;
      return '$expr ${named ? r':\quad' : '='} ${texValue(v, exact: set.exact, precision: set.precision)}';
    }

    String bold(String text) =>
        texProse(text).replaceFirst(r'\text{', r'\textbf{');
    final lines = <String>[];
    final assign = s.assign == null ? '' : '${s.assign} = ';
    if (s.steps.length != 1) lines.add(equals('$assign${s.tex}', s.value));
    for (var i = 0; i < s.steps.length; i++) {
      final st = s.steps[i];
      lines
        ..add(bold('${i + 1}. ${st.title}'))
        ..add(equals(st.tex, st.value));
      if (st.methods.isEmpty || !_open.contains(i)) continue;
      final mi = _chosen(st, i), work = _work[(i, mi)];
      if (work == null) continue;
      if (st.methods.length > 1) lines.add(texProse('${st.methods[mi].name}:'));
      for (final w in work) {
        final pad = r'\quad ' * w.indent;
        String mat() => texMat(
          w.mat!,
          exact: set.exact,
          precision: set.precision,
          aug: w.aug,
        );
        switch (w.kind) {
          case WorkKind.text:
            lines.add('$pad${texProse(w.text!)}');
          case WorkKind.math:
            lines.add('$pad${texMath(w.text!)}');
          case WorkKind.matrix:
            if (w.label != null) lines.add('$pad${texProse(w.label!)}');
            lines.add('$pad${mat()}');
          case WorkKind.ops:
            lines
              ..add('$pad${w.ops.map(texMath).join(r',\quad ')}')
              ..add('$pad${mat()}');
        }
      }
    }
    return [
      '% $assign${s.expr}',
      r'\begin{align*}',
      lines.map((l) => '& $l').join(' \\\\\n'),
      r'\end{align*}',
    ].join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context), pal = context.pal;
    final idx = state.ws.lines.indexWhere((l) => l.id == widget.lineId);
    final sol = _solve(state);
    final title = idx < 0 ? 'Steps' : 'Steps · Expression ${idx + 1}';
    if (sol == null) {
      return SubScreen(
        title: title,
        child: const SubScroll(
          children: [
            EmptyState(
              icon: MIcon.steps,
              title: 'No steps to show',
              body: 'This expression is unfinished or has an error. Once it gives an answer, its working appears here.',
            ),
          ],
        ),
      );
    }
    final fmt = state.fmt;
    final exprSt = mathStyle(context, size: Fs.lg, height: 1.4);
    Widget box(Widget child) => SliverToBoxAdapter(child: child);
    return SubScreen(
      title: title,
      action: IconBtn(
        MIcon.copy,
        label: 'Copy the steps',
        onTap: () {
          final latex = state.settings.copyLatex;
          Clipboard.setData(
            ClipboardData(
              text: latex ? _asLatex(state, sol) : _asText(state, sol),
            ),
          );
          showToast(context, latex ? 'Steps copied as LaTeX' : 'Steps copied');
        },
      ),
      // Slivers, so that working thousands of lines long is only laid out
      // where it is on screen.
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              32 + MediaQuery.paddingOf(context).bottom,
            ),
            sliver: SliverMainAxisGroup(
              slivers: [
                // What is being worked out, and what it comes to. A single
                // step says both itself.
                if (sol.steps.length != 1)
                  box(
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          HScroll(
                            child: Text(
                              '${sol.assign == null ? '' : '${sol.assign} = '}${sol.expr}',
                              style: mathStyle(
                                context,
                                size: Fs.xl,
                                height: 1.3,
                              ),
                              softWrap: false,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _equals(context, _ValueView(sol.value, fmt)),
                        ],
                      ),
                    ),
                  ),
                if (sol.steps.isEmpty)
                  box(
                    const EmptyState(
                      icon: MIcon.steps,
                      title: 'Nothing to work out',
                      body: 'This is a value on its own. Combine it with something, like A·B or det(A), to see the working.',
                    ),
                  )
                else if (sol.steps.length > 1)
                  box(GroupTitle('${sol.steps.length} steps'))
                else
                  box(const SizedBox(height: 8)),
                for (var i = 0; i < sol.steps.length; i++)
                  _stepCard(context, state, sol, i, exprSt, fmt, pal),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _equals(BuildContext context, Widget value) => Row(
    children: [
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Text(
          '=',
          style: mathStyle(context, size: Fs.lg, color: context.pal.ink3),
        ),
      ),
      Expanded(child: HScroll(child: value)),
    ],
  );

  /// One step as a card: a sliver group, so its working can be any length.
  Widget _stepCard(
    BuildContext context,
    AppState state,
    Solution sol,
    int i,
    TextStyle exprSt,
    NumFmt fmt,
    Palette pal,
  ) {
    final st = sol.steps[i], last = i == sol.steps.length - 1;
    final open = _open.contains(i);
    final mi = _chosen(st, i);
    final work = open ? _workOf(state, st, i, mi) : null;
    Widget box(Widget child) => SliverToBoxAdapter(child: child);
    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 12),
      sliver: DecoratedSliver(
        decoration: BoxDecoration(
          color: pal.surface,
          border: Border.all(color: last ? pal.accent : pal.line),
          borderRadius: BorderRadius.circular(16),
        ),
        sliver: SliverMainAxisGroup(
          slivers: [
            box(
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _Bubble('${i + 1}'),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: Text(
                              st.title,
                              style: TextStyle(
                                fontSize: Fs.body,
                                fontWeight: FontWeight.w600,
                                color: pal.ink,
                              ),
                            ),
                          ),
                        ),
                        if (last && sol.steps.length > 1)
                          Text(
                            'ANSWER',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: .9,
                              color: pal.accentInk,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    HScroll(
                      child: Text(st.expr, style: exprSt, softWrap: false),
                    ),
                    const SizedBox(height: 6),
                    _equals(context, _ValueView(st.value, fmt)),
                    if (st.note != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        st.note!,
                        style: TextStyle(
                          fontSize: Fs.sm,
                          height: 1.4,
                          color: pal.ink2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (st.methods.isNotEmpty) ...[
              box(
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Container(height: 1, color: pal.line),
                ),
              ),
              box(
                Pressable(
                  onTap: () =>
                      setState(() => open ? _open.remove(i) : _open.add(i)),
                  label: open ? 'Hide the working' : 'Show the working',
                  builder: (_, down) => Container(
                    height: 44,
                    margin: const EdgeInsets.all(1),
                    padding: const EdgeInsets.symmetric(horizontal: 13),
                    decoration: BoxDecoration(
                      color: down ? pal.surface2 : null,
                      // The card's own corners when this is its last row.
                      borderRadius: open
                          ? null
                          : const BorderRadius.vertical(
                              bottom: Radius.circular(15),
                            ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            open ? 'Hide the working' : 'Show the working',
                            style: TextStyle(
                              fontSize: Fs.sm,
                              fontWeight: FontWeight.w600,
                              color: pal.accentInk,
                            ),
                          ),
                        ),
                        Ico(
                          open ? MIcon.up : MIcon.down,
                          size: 18,
                          color: pal.accentInk,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (open && st.methods.length > 1)
                box(
                  // The names hug their text and scroll sideways, so three
                  // methods still read in full on a narrow phone.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
                    child: HScroll(
                      child: Seg<int>(
                        small: true,
                        options: [
                          for (var k = 0; k < st.methods.length; k++)
                            (k, st.methods[k].name),
                        ],
                        value: mi,
                        onChanged: (k) => setState(() => _method[i] = k),
                      ),
                    ),
                  ),
                ),
              if (open && work == null)
                box(const _WorkingItOut())
              else if (open)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  sliver: _WorkList(
                    // A different method starts from the top again.
                    key: ValueKey((i, mi)),
                    work: work!,
                    fmt: fmt,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shown while long working is being built.
class _WorkingItOut extends StatelessWidget {
  const _WorkingItOut();

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
      child: Semantics(
        liveRegion: true,
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: pal.accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Working out the full solution…',
                style: TextStyle(fontSize: Fs.sm, color: pal.ink2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The lines of one method, built only as they scroll into view.
class _WorkList extends StatelessWidget {
  _WorkList({super.key, required this.work, required this.fmt})
    : _opNumbers = _numberOps(work);

  final List<Work> work;
  final NumFmt fmt;

  /// The number shown on each row-operation line. Counting starts again
  /// after anything that isn't one, so each reduction is numbered from 1.
  final List<int> _opNumbers;

  static List<int> _numberOps(List<Work> work) {
    var run = 0;
    return [for (final w in work) run = w.kind == WorkKind.ops ? run + 1 : 0];
  }

  @override
  Widget build(BuildContext context) => SliverList.builder(
    itemCount: work.length,
    itemBuilder: (context, k) {
      final w = work[k];
      final line = _line(context, w, _opNumbers[k]);
      return Padding(
        padding: EdgeInsets.only(
          top: 10,
          left: 14.0 * math.max(0, w.indent - 1),
        ),
        // Working that belongs to a minor is set in from what needs it.
        child: w.indent == 0
            ? line
            : Container(
                padding: const EdgeInsets.only(left: 10),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: context.pal.line, width: 2),
                  ),
                ),
                child: line,
              ),
      );
    },
  );

  Widget _line(BuildContext context, Work w, int opNumber) {
    final pal = context.pal;
    final mathSt = mathStyle(context, size: Fs.body, height: 1.5);
    final proseSt = TextStyle(fontSize: Fs.sm, height: 1.45, color: pal.ink2);
    Widget matrix() => HScroll(
      child: MatrixView(w.mat!, fmt, fontSize: 17, gap: 14, aug: w.aug),
    );
    Widget prose(String text) =>
        Text.rich(TextSpan(children: markup(text, proseSt)), style: proseSt);
    switch (w.kind) {
      case WorkKind.text:
        return prose(w.text!);
      case WorkKind.math:
        return HScroll(
          child: Text.rich(
            TextSpan(children: markup(w.text!, mathSt), style: mathSt),
            softWrap: false,
          ),
        );
      case WorkKind.matrix:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (w.label != null) ...[
              prose(w.label!),
              const SizedBox(height: 6),
            ],
            matrix(),
          ],
        );
      // A row operation: what was done, then what it gave.
      case WorkKind.ops:
        return Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: BoxDecoration(
            color: pal.bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Bubble('$opNumber', small: true),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      w.ops.join('\n'),
                      style: mathStyle(context, size: Fs.body, height: 1.45),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              matrix(),
            ],
          ),
        );
    }
  }
}

/// A step number in a small filled circle.
class _Bubble extends StatelessWidget {
  const _Bubble(this.text, {this.small = false});
  final String text;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal, d = small ? 20.0 : 24.0;
    return Container(
      width: d,
      height: d,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: pal.accentSoft, shape: BoxShape.circle),
      child: Text(
        text,
        style: TextStyle(
          fontSize: small ? 11 : 12,
          fontWeight: FontWeight.w700,
          color: pal.accentInk,
        ),
      ),
    );
  }
}

/// Any value a step can come to, set the way the workspace sets results.
class _ValueView extends StatelessWidget {
  const _ValueView(this.value, this.fmt);
  final Object value;
  final NumFmt fmt;

  @override
  Widget build(BuildContext context) {
    final st = mathStyle(context), v = value;
    if (v is double) return NumText(v, fmt, style: st);
    if (v is Mat) return MatrixView(v, fmt, fontSize: 17, gap: 14);
    if (v is ListVal) {
      return Row(
        children: [
          for (var i = 0; i < v.items.length; i++)
            Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 14),
              child: Text.rich(
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
            ),
        ],
      );
    }
    if (v is MultiVal) {
      return Row(
        children: [
          for (var i = 0; i < v.parts.length; i++) ...[
            if (i > 0) const SizedBox(width: 20),
            Text(
              v.parts[i].label,
              style: mathStyle(context, size: Fs.lg, italic: true),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('=', style: st.copyWith(color: context.pal.ink3)),
            ),
            MatrixView(v.parts[i].value, fmt, fontSize: 17, gap: 14),
          ],
        ],
      );
    }
    if (v is PolyVal) {
      return Text.rich(
        TextSpan(children: polySpans(v.coeffs, fmt, st), style: st),
        softWrap: false,
      );
    }
    return Text(
      v is TextVal ? v.text : '$v',
      style: TextStyle(fontSize: Fs.sm, color: context.pal.ink2),
    );
  }
}
