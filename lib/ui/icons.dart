import 'package:flutter/widgets.dart';
import 'package:path_parsing/path_parsing.dart';

/// The app's icon set: one stroke family on a 24px grid, 1.75 stroke.
enum MIcon {
  menu('M4 7h16M4 12h16M4 17h16'),
  book(
    'M5 4.5h11.5A1.5 1.5 0 0 1 18 6v13.5H6.5A1.5 1.5 0 0 1 5 18V4.5ZM5 18a1.5 1.5 0 0 1 1.5-1.5H18M9 8.5h5',
  ),
  back('M15 18l-6-6 6-6'),
  chev('M9 18l6-6-6-6'),
  down('M6 9l6 6 6-6'),
  up('M6 15l6-6 6 6'),
  plus('M12 5v14M5 12h14'),
  close('M6 6l12 12M18 6L6 18'),
  trash('M4 7h16M10 11v6M14 11v6M6 7l1 13h10l1-13M9 7V4h6v3'),
  copy('M9 9h11v11H9zM5 15H4V4h11v1'),
  search('M11 18a7 7 0 1 0 0-14 7 7 0 0 0 0 14zM20 20l-4.2-4.2'),
  eye(
    'M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12zM12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6z',
  ),
  save('M12 4v11M7 10l5 5 5-5M5 20h14'),
  backspace('M21 5H9l-6 7 6 7h12zM17 9l-6 6M11 9l6 6'),
  left('M15 18l-6-6 6-6'),
  right('M9 18l6-6-6-6'),
  enter('M20 5v7a3 3 0 0 1-3 3H5M9 11l-4 4 4 4'),
  clock('M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM12 7v5l3 2'),
  sliders('M4 6h9M17 6h3M15 4v4M4 12h3M11 12h9M9 10v4M4 18h11M19 18h1M17 16v4'),
  help(
    'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM9.5 9.2a2.5 2.5 0 1 1 3.4 2.3c-.6.3-.9.8-.9 1.5v.5M12 16.8v.2',
  ),
  folder(
    'M3 6.5A1.5 1.5 0 0 1 4.5 5H9l2 2h8.5A1.5 1.5 0 0 1 21 8.5v9a1.5 1.5 0 0 1-1.5 1.5h-15A1.5 1.5 0 0 1 3 17.5z',
  ),
  check('M5 12.5l4.5 4.5L19 7'),
  minus('M6 12h12'),
  alert('M12 4l9 16H3zM12 10v4M12 17v.2'),
  info('M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM12 11v5M12 7.8v.2'),
  grid('M4 4h16v16H4zM4 9.3h16M4 14.7h16M9.3 4v16M14.7 4v16'),
  edit('M4 20h4L19 9l-4-4L4 16v4zM13.5 6.5l4 4'),
  steps('M9.5 6h10.5M9.5 12h10.5M9.5 18h10.5M4 6h1.5M4 12h1.5M4 18h1.5'),
  cloud(
    'M7 18.5h10.5a4 4 0 0 0 .5-7.97A6 6 0 0 0 6.4 9.1 4.75 4.75 0 0 0 7 18.5z',
  ),
  sync(
    'M20 12a8 8 0 0 1-14.3 4.9M4 12a8 8 0 0 1 14.3-4.9M18.5 3.5v3.8h-3.8M5.5 20.5v-3.8h3.8',
  ),

  undo('M9 14L4 9l5-5M4 9h10.5a5.5 5.5 0 0 1 0 11H11'),
  redo('M15 14l5-5-5-5M20 9H9.5a5.5 5.5 0 0 0 0 11H13'),

  /// Six dots: "drag me".
  grip('M9 6v.01M15 6v.01M9 12v.01M15 12v.01M9 18v.01M15 18v.01');

  const MIcon(this.d);
  final String d;
}

class _PathSink extends PathProxy {
  final path = Path();

  @override
  void moveTo(double x, double y) => path.moveTo(x, y);

  @override
  void lineTo(double x, double y) => path.lineTo(x, y);

  @override
  void cubicTo(
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
  ) => path.cubicTo(x1, y1, x2, y2, x3, y3);

  @override
  void close() => path.close();
}

final _cache = <MIcon, Path>{};

Path _pathFor(MIcon icon) => _cache.putIfAbsent(icon, () {
  final sink = _PathSink();
  writeSvgPathDataToPath(icon.d, sink);
  return sink.path;
});

class _IconPainter extends CustomPainter {
  _IconPainter(this.icon, this.color);
  final MIcon icon;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    canvas.drawPath(
      _pathFor(icon),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.75
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_IconPainter old) =>
      old.icon != icon || old.color != color;
}

/// Draws [icon] in the ambient [IconTheme] colour unless [color] is given.
class Ico extends StatelessWidget {
  const Ico(this.icon, {super.key, this.size, this.color});
  final MIcon icon;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final s = size ?? theme.size ?? 22;
    return SizedBox(
      width: s,
      height: s,
      child: CustomPaint(
        painter: _IconPainter(
          icon,
          color ?? theme.color ?? const Color(0xFF000000),
        ),
      ),
    );
  }
}
