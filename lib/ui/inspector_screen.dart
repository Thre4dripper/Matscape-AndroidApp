import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../app/app_state.dart';
import '../app/models.dart';
import '../engine/engine.dart';
import 'icons.dart';
import 'math_view.dart';
import 'scope.dart';
import 'theme.dart';
import 'widgets.dart';

/// Everything about one matrix: properties, eigenvalues, norms,
/// step-by-step row reduction and decompositions.
class InspectorScreen extends StatefulWidget {
  const InspectorScreen({super.key, required this.target, required this.host});
  final InspectTarget target;
  final WorkspaceHost host;

  @override
  State<InspectorScreen> createState() => _InspectorScreenState();
}

T? _safe<T>(T Function() f) {
  try {
    return f();
  } on MathError {
    return null;
  }
}

class _InspectorScreenState extends State<InspectorScreen> {
  String _step = 'det';
  String _dec = 'lu';

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context), t = widget.target;
    var title = 'Matrix', error = '';
    Mat? value;
    MatrixModel? model;
    if (t.matrixId != null) {
      model = state.matrixById(t.matrixId!);
      final r = model == null ? null : state.matResults[model.id];
      if (model == null) {
        error = 'This matrix no longer exists.';
      } else {
        title = 'Matrix ${model.name}';
        if (r != null && r.ok) {
          value = r.value;
        } else if (r != null) {
          error = r.where;
        }
      }
    } else {
      final idx = state.ws.lines.indexWhere((l) => l.id == t.lineId);
      final res = state.lineResults[t.lineId];
      Object? v = res != null && res.ok ? res.value : null;
      var label = '';
      if (v is MultiVal) {
        final part = t.part < v.parts.length ? v.parts[t.part] : null;
        v = part?.value;
        if (part != null) label = ' · ${part.label}';
      }
      title = 'Line ${idx + 1}$label';
      if (v is Mat) {
        value = v;
      } else {
        error = 'This line no longer gives a matrix.';
      }
    }

    if (value == null) {
      return SubScreen(
        title: title,
        child: SubScroll(
          children: [
            EmptyState(
              icon: MIcon.alert,
              title: 'Nothing to inspect',
              body: error,
            ),
          ],
        ),
      );
    }
    return SubScreen(title: title, child: _body(context, state, value, model));
  }

  Widget _body(
    BuildContext context,
    AppState state,
    Mat a,
    MatrixModel? model,
  ) {
    final pal = context.pal, fmt = state.fmt;
    final sq = a.rows == a.cols;
    final d = sq ? _safe(() => det(a)) : null;
    final tr = sq ? traceOf(a) : null;
    final rk = rank(a);
    final props = [
      for (final p in properties(a))
        if (p.key != 'square' || !sq) p,
    ];
    final eig = sq ? _safe(() => eigenvalues(a)) : null;
    final cp = sq ? _safe(() => charpoly(a)) : null;
    final condV = _safe(() => cond(a));

    final stepKinds = sq
        ? const [
            ('det', 'Determinant'),
            ('inverse', 'Inverse'),
            ('rref', 'RREF'),
          ]
        : const [('rref', 'RREF')];
    final step = stepKinds.any((k) => k.$1 == _step)
        ? _step
        : stepKinds.first.$1;
    final decKinds = sq
        ? const [
            ('lu', 'LU'),
            ('qr', 'QR'),
            ('svd', 'SVD'),
            ('chol', 'Cholesky'),
          ]
        : const [('qr', 'QR'), ('svd', 'SVD')];
    final dec = decKinds.any((k) => k.$1 == _dec) ? _dec : decKinds.first.$1;

    final statSt = mathStyle(context, size: Fs.xl, height: 1.3);
    Widget stat(Widget val, String cap) => Container(
      color: pal.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(fit: BoxFit.scaleDown, child: val),
          Text(
            cap,
            style: TextStyle(fontSize: Fs.cap, color: pal.ink3),
          ),
        ],
      ),
    );
    Widget statNum(double? v, String cap) => stat(
      v == null ? Text('—', style: statSt) : NumText(v, fmt, style: statSt),
      cap,
    );

    final kvSt = mathStyle(context, size: Fs.lg);
    Widget kv(String k, Widget v) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                children: markup(
                  k,
                  TextStyle(fontSize: Fs.sm, color: pal.ink2),
                ),
              ),
              style: TextStyle(fontSize: Fs.sm, color: pal.ink2),
            ),
          ),
          const SizedBox(width: 12),
          v,
        ],
      ),
    );
    Widget kvNum(String k, double v) => kv(k, NumText(v, fmt, style: kvSt));

    Widget pair(Widget a, Widget b) => IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: a),
          const SizedBox(width: 1),
          Expanded(child: b),
        ],
      ),
    );

    return SubScroll(
      children: [
        // Hero
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Column(
            children: [
              HScroll(center: true, child: MatrixView(a, fmt, fontSize: 22)),
              const SizedBox(height: 8),
              Text(
                '${a.rows} rows × ${a.cols} columns',
                style: TextStyle(fontSize: Fs.cap, color: pal.ink3),
              ),
            ],
          ),
        ),
        // Stats
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: pal.line,
            border: Border.all(color: pal.line),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              pair(
                stat(
                  Text('${a.rows}×${a.cols}', style: statSt),
                  sq ? 'Square' : 'Rectangular',
                ),
                statNum(d, sq ? 'Determinant' : 'Determinant · square only'),
              ),
              const SizedBox(height: 1),
              pair(
                statNum(tr, sq ? 'Trace' : 'Trace · square only'),
                stat(
                  Text('$rk', style: statSt),
                  rk == math.min(a.rows, a.cols)
                      ? 'Rank · full'
                      : 'Rank · deficient',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const GroupTitle('Properties'),
        LayoutBuilder(
          builder: (context, c) {
            final w = (c.maxWidth - 8) / 2;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in props)
                  Semantics(
                    label: '${p.label}: ${p.value ? 'yes' : 'no'}',
                    excludeSemantics: true,
                    child: Container(
                      width: w,
                      constraints: const BoxConstraints(minHeight: 40),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: p.value ? pal.okSoft : pal.surface,
                        border: Border.all(
                          color: p.value ? const Color(0x00000000) : pal.line,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Ico(
                            p.value ? MIcon.check : MIcon.minus,
                            size: 16,
                            color: p.value ? pal.ok : pal.ink3,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              p.label,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.3,
                                fontWeight: p.value
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: p.value ? pal.ok : pal.ink3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        if (sq) ...[
          const SizedBox(height: 20),
          const GroupTitle('Eigenvalues'),
          if (eig != null)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < eig.length; i++)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: pal.surface,
                      border: Border.all(color: pal.line),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text.rich(
                      TextSpan(
                        style: kvSt,
                        children: [
                          const TextSpan(
                            text: 'λ',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                          sub('${i + 1}', kvSt),
                          const TextSpan(text: ' = '),
                          ...complexSpans(eig[i], fmt, kvSt),
                        ],
                      ),
                      softWrap: false,
                    ),
                  ),
              ],
            )
          else
            _note(context, 'Couldn’t compute eigenvalues for this matrix.'),
          if (cp != null) ...[
            _note(context, 'Characteristic polynomial'),
            Text.rich(
              TextSpan(
                style: kvSt.copyWith(height: 1.6),
                children: [
                  ...markup('p(<i>λ</i>) = ', kvSt),
                  ...polySpans(cp, fmt, kvSt),
                ],
              ),
            ),
          ],
        ],
        const SizedBox(height: 20),
        const GroupTitle('Norms'),
        CardBox(
          child: DividedColumn(
            children: [
              kvNum('Frobenius ‖A‖<sub>F</sub>', frob(a)),
              kvNum('Spectral ‖A‖<sub>2</sub>', norm2(a)),
              kvNum('1-norm (max column sum)', norm1(a)),
              kvNum('∞-norm (max row sum)', normInf(a)),
              kv(
                'Condition number',
                condV == null
                    ? Text('—', style: kvSt)
                    : condV.isInfinite
                    ? Text('∞ · singular', style: kvSt)
                    : NumText(condV, fmt, style: kvSt),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const GroupTitle('Step by step'),
        Seg<String>(
          options: stepKinds,
          value: step,
          onChanged: (v) => setState(() => _step = v),
        ),
        _steps(context, state, step, a),
        const SizedBox(height: 20),
        const GroupTitle('Decompose'),
        Seg<String>(
          options: decKinds,
          value: dec,
          onChanged: (v) => setState(() => _dec = v),
        ),
        _decomp(context, state, dec, a),
        const SizedBox(height: 20),
        Row(
          children: model != null
              ? [
                  Btn(
                    'Edit entries',
                    icon: MIcon.edit,
                    onTap: () {
                      final id = model.id;
                      Navigator.of(context).pop();
                      widget.host.openEditor(id);
                    },
                  ),
                  const SizedBox(width: 8),
                  Btn(
                    'Use in a new line',
                    icon: MIcon.plus,
                    kind: BtnKind.primary,
                    onTap: () {
                      final name = model.name;
                      Navigator.of(context).pop();
                      widget.host.addLineWith(name);
                    },
                  ),
                ]
              : [
                  Btn(
                    'Copy',
                    icon: MIcon.copy,
                    onTap: () {
                      Clipboard.setData(
                        ClipboardData(text: AppState.matText(a)),
                      );
                      showToast(context, 'Copied');
                    },
                  ),
                  const SizedBox(width: 8),
                  Btn(
                    'Save as matrix',
                    icon: MIcon.save,
                    kind: BtnKind.primary,
                    onTap: () => widget.host.saveAsMatrix(a),
                  ),
                ],
        ),
      ],
    );
  }

  Widget _note(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Text(text, style: TextStyle(fontSize: 13, color: context.pal.ink3)),
  );

  Widget _steps(BuildContext context, AppState state, String kind, Mat a) {
    final pal = context.pal, fmt = state.fmt;
    final StepsResult r;
    try {
      r = switch (kind) {
        'det' => stepsDet(a),
        'inverse' => stepsInverse(a),
        _ => stepsRref(a),
      };
    } on MathError catch (e) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: ErrorNote(e.message, hint: e.hint),
      );
    }
    final opSt = mathStyle(context, size: Fs.body, height: 1.45);
    var n = 0;
    Widget item(List<String> ops, Mat? m) {
      n++;
      return Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: pal.surface,
          border: Border.all(color: pal.line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(top: 1),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: pal.accentSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$n',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: pal.accentInk,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(ops.join('\n'), style: opSt)),
              ],
            ),
            if (m != null) ...[
              const SizedBox(height: 8),
              HScroll(
                child: MatrixView(m, fmt, fontSize: 17, gap: 14, aug: r.aug),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        item([
          kind == 'inverse' ? 'Start with [A | I]' : 'Start with A',
        ], r.start),
        for (final s in r.steps) item(s.ops, s.m),
        if (r.steps.isEmpty)
          item([
            'Already in the target form — no row operations needed.',
          ], null),
        Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: pal.accentSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(r.summary, style: opSt.copyWith(color: pal.accentInk)),
        ),
        if (r.note != null) _note(context, r.note!),
      ],
    );
  }

  Widget _decomp(BuildContext context, AppState state, String kind, Mat a) {
    final fmt = state.fmt;
    final List<(String, Mat)> parts;
    final String rel;
    try {
      switch (kind) {
        case 'lu':
          final r = lu(a);
          parts = [('P', r.p), ('L', cleanM(r.l)), ('U', cleanM(r.u))];
          rel = 'PA = LU';
        case 'qr':
          final r = qr(a);
          parts = [('Q', r.q), ('R', r.r)];
          rel = 'A = QR';
        case 'svd':
          final r = svd(a);
          parts = [('U', r.u), ('Σ', r.s), ('Vᵀ', r.vt)];
          rel = 'A = UΣVᵀ';
        default:
          parts = [('L', cleanM(cholesky(a)))];
          rel = 'A = LLᵀ';
      }
    } on MathError catch (e) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: ErrorNote(e.message, hint: e.hint),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _note(context, rel),
        for (final (label, m) in parts)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                Text(
                  label,
                  style: mathStyle(context, size: Fs.lg, italic: true),
                ),
                const SizedBox(width: 8),
                Text(
                  '=',
                  style: mathStyle(
                    context,
                    size: Fs.lg,
                    color: context.pal.ink3,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: HScroll(
                    child: MatrixView(m, fmt, fontSize: 17, gap: 14),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
