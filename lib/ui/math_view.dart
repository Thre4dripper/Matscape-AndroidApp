import 'package:material_ui/material_ui.dart';

import '../app/models.dart';
import '../engine/engine.dart';
import 'theme.dart';

/// How numbers are shown; comes from the user's settings.
@immutable
class NumFmt {
  const NumFmt({this.exact = true, this.precision = 4});
  NumFmt.of(Settings s) : this(exact: s.exact, precision: s.precision);
  final bool exact;
  final int precision;
}

/* ---------- inline building blocks ---------- */

double _fs(TextStyle s) => s.fontSize ?? Fs.math;

/// Raised or lowered text that doesn't change the line height.
InlineSpan _shifted(
  List<InlineSpan> children,
  TextStyle style, {
  required bool up,
}) {
  final fs = _fs(style);
  return WidgetSpan(
    alignment: PlaceholderAlignment.baseline,
    baseline: TextBaseline.alphabetic,
    child: Transform.translate(
      offset: Offset(0, up ? -fs * .42 : fs * .18),
      child: Text.rich(
        TextSpan(
          children: children,
          style: style.copyWith(fontSize: fs * .65, height: 1),
        ),
      ),
    ),
  );
}

InlineSpan sup(String text, TextStyle style) =>
    _shifted([TextSpan(text: text)], style, up: true);

InlineSpan sub(String text, TextStyle style) =>
    _shifted([TextSpan(text: text)], style, up: false);

/// Tiny markup for labels: `<i>`, `<sup>` and `<sub>`, nestable.
/// Example: `<i>e</i><sup><i>A</i></sup>`.
List<InlineSpan> markup(String src, TextStyle style) {
  var i = 0;
  List<InlineSpan> run(TextStyle st) {
    final spans = <InlineSpan>[];
    final buf = StringBuffer();
    void flush() {
      if (buf.isEmpty) return;
      spans.add(TextSpan(text: buf.toString(), style: st));
      buf.clear();
    }

    while (i < src.length) {
      if (src[i] != '<') {
        buf.write(src[i++]);
        continue;
      }
      final end = src.indexOf('>', i);
      final tag = src.substring(i + 1, end);
      i = end + 1;
      flush();
      if (tag.startsWith('/')) return spans;
      if (tag == 'i') {
        spans.addAll(run(st.copyWith(fontStyle: FontStyle.italic)));
      } else {
        final inner = run(st.copyWith(fontSize: _fs(st) * .65, height: 1));
        spans.add(_shifted(inner, st, up: tag == 'sup'));
      }
    }
    flush();
    return spans;
  }

  return run(style);
}

class _Frac extends StatelessWidget {
  const _Frac(this.top, this.bottom, this.style);
  final List<InlineSpan> top;
  final String bottom;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final small = style.copyWith(fontSize: _fs(style) * .74, height: 1.15);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text.rich(
                TextSpan(children: top, style: small),
                textAlign: TextAlign.center,
                softWrap: false,
              ),
            ),
            Container(height: 1, color: style.color),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                bottom,
                style: small,
                textAlign: TextAlign.center,
                softWrap: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

InlineSpan _frac(List<InlineSpan> top, int den, TextStyle style) => WidgetSpan(
  alignment: PlaceholderAlignment.middle,
  child: _Frac(top, '$den', style),
);

/// Spans for one real number, typeset as a fraction, root or multiple of π
/// when the format allows.
List<InlineSpan> numSpans(double x, NumFmt f, TextStyle style) {
  final d = describe(x, exact: f.exact, precision: f.precision);
  final sign = d.neg ? '−' : '';
  switch (d.kind) {
    case NumKind.special:
    case NumKind.integer:
      return [TextSpan(text: sign + d.text!)];
    case NumKind.frac:
      return [
        if (d.neg) const TextSpan(text: '−'),
        _frac([TextSpan(text: '${d.n}')], d.d, style),
      ];
    case NumKind.surd:
    case NumKind.pi:
      final coef = d.n == 1 ? '' : '${d.n}';
      final top = d.kind == NumKind.pi
          ? <InlineSpan>[TextSpan(text: '$coefπ')]
          : <InlineSpan>[
              TextSpan(text: '$coef√'),
              TextSpan(
                text: '${d.k}',
                style: const TextStyle(decoration: TextDecoration.overline),
              ),
            ];
      return [
        if (d.neg) const TextSpan(text: '−'),
        if (d.d == 1) ...top else _frac(top, d.d, style),
      ];
    case NumKind.dec:
      if (d.text != null) return [TextSpan(text: sign + d.text!)];
      return [
        TextSpan(text: '$sign${d.mant}×10'),
        sup('${d.exp}'.replaceFirst('-', '−'), style),
      ];
  }
}

/// Spans for an eigenvalue: a real number or a ± b·i.
List<InlineSpan> complexSpans(Object z, NumFmt f, TextStyle style) {
  if (z is double) return numSpans(z, f, style);
  final c = z as Complex;
  final re = c.re.abs() < 1e-11 ? 0.0 : c.re, im = c.im.abs();
  final imag = <InlineSpan>[
    if ((im - 1).abs() >= 1e-12) ...numSpans(im, f, style),
    const TextSpan(
      text: 'i',
      style: TextStyle(fontStyle: FontStyle.italic),
    ),
  ];
  if (re == 0) return [if (c.im < 0) const TextSpan(text: '−'), ...imag];
  return [
    ...numSpans(re, f, style),
    TextSpan(text: c.im < 0 ? ' − ' : ' + '),
    ...imag,
  ];
}

/// Spans for a polynomial in λ, highest power first.
List<InlineSpan> polySpans(List<double> cf, NumFmt f, TextStyle style) {
  final n = cf.length - 1, out = <InlineSpan>[];
  for (var k = 0; k < cf.length; k++) {
    final c = cf[k], p = n - k;
    if (c.abs() < 1e-11) continue;
    final a = c.abs();
    out.add(
      TextSpan(
        text: out.isEmpty ? (c < 0 ? '−' : '') : (c < 0 ? ' − ' : ' + '),
      ),
    );
    if (!((a - 1).abs() < 1e-12 && p > 0)) out.addAll(numSpans(a, f, style));
    if (p > 0) {
      out.add(
        const TextSpan(
          text: 'λ',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      );
      if (p > 1) out.add(sup('$p', style));
    }
  }
  return out.isEmpty ? [const TextSpan(text: '0')] : out;
}

/// One number as a widget.
class NumText extends StatelessWidget {
  const NumText(this.value, this.fmt, {super.key, this.style});
  final double value;
  final NumFmt fmt;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final st = style ?? mathStyle(context);
    return Text.rich(
      TextSpan(children: numSpans(value, fmt, st), style: st),
      softWrap: false,
    );
  }
}

/* ---------- matrices ---------- */

class _BracketPainter extends CustomPainter {
  _BracketPainter(this.color, this.width, this.stroke);
  final Color color;
  final double width, stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = color;
    final h = stroke / 2, r = const Radius.circular(3);
    final left = Path()
      ..moveTo(width, h)
      ..lineTo(h + 3, h)
      ..arcToPoint(Offset(h, h + 3), radius: r, clockwise: false)
      ..lineTo(h, size.height - h - 3)
      ..arcToPoint(Offset(h + 3, size.height - h), radius: r, clockwise: false)
      ..lineTo(width, size.height - h);
    canvas.drawPath(left, paint);
    canvas.save();
    canvas.translate(size.width, 0);
    canvas.scale(-1, 1);
    canvas.drawPath(left, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BracketPainter old) =>
      old.color != color || old.width != width || old.stroke != stroke;
}

/// A typeset matrix in square brackets.
class MatrixView extends StatelessWidget {
  const MatrixView(
    this.m,
    this.fmt, {
    super.key,
    this.fontSize = Fs.math,
    this.gap = 18,
    this.rowGap = 4,
    this.aug,
    this.preview = false,
    this.color,
  });

  /// Compact form for matrix cards: at most 3×3 with ⋯ / ⋮ for the rest.
  const MatrixView.preview(this.m, this.fmt, {super.key, this.color})
    : fontSize = 13,
      gap = 8,
      rowGap = 0,
      aug = null,
      preview = true;

  final Mat m;
  final NumFmt fmt;
  final double fontSize, gap, rowGap;

  /// Column index where an augmented block starts (draws a divider).
  final int? aug;
  final bool preview;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final ink = color ?? DefaultTextStyle.of(context).style.color ?? pal.ink;
    final st = mathStyle(context, size: fontSize, color: ink, height: 1.3);
    final rows = preview && m.rows > 3 ? 3 : m.rows;
    final cols = preview && m.cols > 3 ? 3 : m.cols;
    final moreCols = preview && m.cols > 3, moreRows = preview && m.rows > 3;
    final totalCols = cols + (moreCols ? 1 : 0);

    Widget cell(Widget child, int i, int j) {
      final isAug = aug != null && j == aug;
      return Container(
        margin: EdgeInsets.only(left: j == 0 ? 0 : (isAug ? gap / 2 : gap)),
        padding: EdgeInsets.only(
          left: isAug ? gap / 2 + 2 : 0,
          top: i == 0 ? 0 : rowGap,
        ),
        decoration: isAug
            ? BoxDecoration(
                border: Border(left: BorderSide(color: pal.lineStrong)),
              )
            : null,
        alignment: Alignment.centerRight,
        child: child,
      );
    }

    Widget txt(String s) => Text(s, style: st, softWrap: false);

    final table = Table(
      defaultColumnWidth: const IntrinsicColumnWidth(),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        for (var i = 0; i < rows; i++)
          TableRow(
            children: [
              for (var j = 0; j < cols; j++)
                cell(NumText(m.data[i][j], fmt, style: st), i, j),
              if (moreCols) cell(txt('⋯'), i, cols),
            ],
          ),
        if (moreRows)
          TableRow(
            children: [
              for (var j = 0; j < totalCols; j++) cell(txt('⋮'), rows, j),
            ],
          ),
      ],
    );

    return Semantics(
      label: preview
          ? null
          : '${m.rows} by ${m.cols} matrix. ${[for (var i = 0; i < m.rows; i++) 'row ${i + 1}: ${m.data[i].map((x) => plain(x, exact: fmt.exact, precision: fmt.precision)).join(', ')}'].join('; ')}',
      excludeSemantics: true,
      child: CustomPaint(
        painter: preview
            ? _BracketPainter(ink, 4, 1)
            : _BracketPainter(ink, 6, 1.5),
        child: Padding(
          padding: preview
              ? const EdgeInsets.symmetric(horizontal: 7, vertical: 2)
              : const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
          child: table,
        ),
      ),
    );
  }
}

/// Lets wide math scroll sideways instead of overflowing.
class HScroll extends StatelessWidget {
  const HScroll({super.key, required this.child, this.center = false});
  final Widget child;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final scroll = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(top: 2, bottom: 4),
      child: child,
    );
    return center ? Center(child: scroll) : scroll;
  }
}
