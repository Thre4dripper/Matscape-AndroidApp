import 'package:material_ui/material_ui.dart';

import '../app/app_state.dart';
import '../app/models.dart';
import 'icons.dart';
import 'math_view.dart';
import 'theme.dart';
import 'widgets.dart';

/// A saved matrix: name, size and a small preview. Tapping opens the editor.
///
/// [chip] is the one-line form used where height is scarce (tabletop,
/// landscape): name and size only.
class MatrixCard extends StatelessWidget {
  const MatrixCard({
    super.key,
    required this.model,
    required this.eval,
    required this.fmt,
    required this.onTap,
    this.width = 132,
    this.chip = false,
    this.handle,
  });

  final MatrixModel model;
  final MatEval? eval;
  final NumFmt fmt;
  final VoidCallback onTap;
  final double width;
  final bool chip;

  /// A drag handle (usually a [Grip] wrapped in something that starts a
  /// drag). It sits on top of the card, at the top right, or at the left of
  /// a chip, and is not part of the area that opens the editor.
  final Widget? handle;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal, m = model;
    final ok = eval != null && eval!.ok;
    final name = Text(
      m.name,
      style: mathStyle(
        context,
        size: Fs.xl,
        weight: FontWeight.w600,
        italic: true,
        height: 1.1,
      ),
    );
    final dims = Text(
      '${m.rows}×${m.cols}',
      style: TextStyle(fontSize: Fs.cap, height: 1.3, color: pal.ink3),
    );
    final decoration = BoxDecoration(
      color: pal.surface,
      border: Border.all(color: ok ? pal.line : pal.danger),
      borderRadius: BorderRadius.circular(16),
    );
    final card = Pressable(
      onTap: onTap,
      label:
          'Matrix ${m.name}, ${m.rows} by ${m.cols}${ok ? '' : ', has an entry to fix'}. Edit',
      scale: .98,
      builder: (_, _) => chip
          ? Container(
              padding: EdgeInsets.fromLTRB(handle == null ? 12 : 30, 8, 12, 8),
              decoration: decoration,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [name, const SizedBox(width: 8), dims],
              ),
            )
          : Container(
              width: width,
              height: 132,
              padding: const EdgeInsets.all(12),
              decoration: decoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  name,
                  const SizedBox(height: 2),
                  dims,
                  const SizedBox(height: 8),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: ok
                          ? FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.bottomLeft,
                              child: MatrixView.preview(
                                eval!.value!,
                                fmt,
                                color: pal.ink,
                              ),
                            )
                          : const _FixTag(),
                    ),
                  ),
                ],
              ),
            ),
    );
    if (handle == null) return card;
    return Stack(
      children: [
        card,
        if (chip)
          Positioned(left: 2, top: 0, bottom: 0, child: Center(child: handle))
        else
          Positioned(top: 2, right: 2, child: handle!),
      ],
    );
  }
}

class _FixTag extends StatelessWidget {
  const _FixTag();

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: pal.dangerSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Ico(MIcon.alert, size: 12, color: pal.danger),
          const SizedBox(width: 4),
          Text(
            'Fix entry',
            style: TextStyle(
              fontSize: Fs.cap,
              fontWeight: FontWeight.w600,
              color: pal.danger,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dashed "New matrix" tile that sits after the matrix cards.
class NewMatrixCard extends StatelessWidget {
  const NewMatrixCard({
    super.key,
    required this.onTap,
    this.width = 132,
    this.chip = false,
  });
  final VoidCallback onTap;
  final double width;
  final bool chip;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final label = Text(
      'New matrix',
      style: TextStyle(
        fontSize: Fs.sm,
        fontWeight: FontWeight.w600,
        color: pal.accentInk,
      ),
    );
    return Pressable(
      onTap: onTap,
      label: 'New matrix',
      scale: .98,
      builder: (_, _) => CustomPaint(
        foregroundPainter: _DashedBorder(pal.lineStrong),
        child: Container(
          width: chip ? null : width,
          height: chip ? null : 132,
          padding: chip
              ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
              : null,
          decoration: BoxDecoration(
            color: pal.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: chip
              ? Center(widthFactor: 1, child: label)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Ico(MIcon.plus, size: 22, color: pal.accentInk),
                    const SizedBox(height: 8),
                    label,
                  ],
                ),
        ),
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  _DashedBorder(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rr = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(.5),
      const Radius.circular(16),
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color;
    for (final metric in (Path()..addRRect(rr)).computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 7) {
        canvas.drawPath(metric.extractPath(d, d + 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => old.color != color;
}
