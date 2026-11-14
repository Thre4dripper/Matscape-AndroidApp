import 'dart:math' as math;
import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/widgets.dart';

/// The app's layouts. One adaptive app: the layout follows the space the
/// window has and how the device is folded.
enum AppLayout {
  /// Phones and closed foldables: single column, keypad at the bottom.
  compact,

  /// Short, wide windows (a phone on its side): content left, keypad right.
  landscape,

  /// Small tablets in portrait: sidebar + workspace.
  medium,

  /// Large tablets and wide windows: sidebar + workspace + inspector.
  expanded,

  /// Foldable opened like a book: two panes split at the fold.
  book,

  /// Half-folded on a desk: results above the fold, keypad below.
  tabletop,

  /// Tiny cover screens: read-only view of the latest results.
  glance,
}

/// Width at which the sidebar appears.
const double mediumWidth = 600;

/// Width at which the permanent inspector appears.
const double expandedWidth = 1000;

/// Workspace column width at which two keypad pages fit side by side.
const double dualKeypadWidth = 700;

/// Sidebar width.
const double sideWidth = 280;

/// Space kept clear around a fold, even when the fold itself has no width.
const double minHinge = 24;

@immutable
class LayoutInfo {
  const LayoutInfo(this.layout, {this.fold = Rect.zero});

  final AppLayout layout;

  /// The strip nothing is placed on: a vertical band for [AppLayout.book],
  /// a horizontal one for [AppLayout.tabletop]. Logical pixels.
  final Rect fold;

  bool get hasSide =>
      layout == AppLayout.medium || layout == AppLayout.expanded;

  /// Screens like the library open in a pane beside the workspace.
  bool get hasDetail =>
      layout == AppLayout.expanded || layout == AppLayout.book;

  /// Screens like the library are pushed full-screen instead of embedded.
  bool get pushesScreens =>
      layout == AppLayout.compact || layout == AppLayout.landscape;

  /// The area dialogs and toasts stay inside, so they never straddle a fold.
  Rect overlayRect(Size size) => switch (layout) {
    AppLayout.book => Rect.fromLTRB(0, 0, fold.left, size.height),
    AppLayout.tabletop => Rect.fromLTRB(0, 0, size.width, fold.top),
    _ => Offset.zero & size,
  };

  /// Width of the keypad beside the content on a phone held sideways:
  /// 40% of the usable width [avail], so the content gets the larger share.
  static double landscapeKeypadWidth(double avail) =>
      (avail * .4).clamp(280.0, 440.0);

  /// Width of the inspector pane in the expanded layout.
  static double detailWidth(double width) => math.max(320, width * .28);

  static LayoutInfo of(BuildContext context) {
    final mq = MediaQuery.of(context);
    final view = View.of(context);
    return compute(
      size: mq.size,
      features: mq.displayFeatures,
      displaySize: view.display.size / view.display.devicePixelRatio,
    );
  }

  /// [size] is the window; [displaySize] the whole screen it is on, which
  /// tells a tiny cover screen apart from a small split-screen window.
  static LayoutInfo compute({
    required Size size,
    List<DisplayFeature> features = const [],
    Size? displaySize,
  }) {
    for (final f in features) {
      if (f.type != DisplayFeatureType.fold &&
          f.type != DisplayFeatureType.hinge) {
        continue;
      }
      final b = f.bounds;
      final halfOpen = f.state == DisplayFeatureState.postureHalfOpened;
      final vertical = b.top <= 0 && b.bottom >= size.height;
      final horizontal = b.left <= 0 && b.right >= size.width;
      if (vertical) {
        // Opened like a book (flat or half open): one pane per side.
        final strip = _strip(b.left, b.right);
        if (strip.$1 >= 300 && size.width - strip.$2 >= 300) {
          return LayoutInfo(
            AppLayout.book,
            fold: Rect.fromLTRB(strip.$1, 0, strip.$2, size.height),
          );
        }
      } else if (horizontal &&
          (halfOpen || f.type == DisplayFeatureType.hinge)) {
        // Standing on a desk. Opened flat, a flip phone is a normal phone.
        final strip = _strip(b.top, b.bottom);
        if (strip.$1 >= 260 && size.height - strip.$2 >= 280) {
          return LayoutInfo(
            AppLayout.tabletop,
            fold: Rect.fromLTRB(0, strip.$1, size.width, strip.$2),
          );
        }
      }
    }
    final screen = displaySize ?? size;
    if (screen.width < 480 && screen.height < 480) {
      return const LayoutInfo(AppLayout.glance);
    }
    if (size.height < 500 && size.width >= 560) {
      return const LayoutInfo(AppLayout.landscape);
    }
    if (size.width >= expandedWidth) {
      return const LayoutInfo(AppLayout.expanded);
    }
    if (size.width >= mediumWidth) {
      return const LayoutInfo(AppLayout.medium);
    }
    return const LayoutInfo(AppLayout.compact);
  }

  /// Widens a fold to at least [minHinge], centred on the real one.
  static (double, double) _strip(double a, double b) {
    if (b - a >= minHinge) return (a, b);
    final mid = (a + b) / 2;
    return (mid - minHinge / 2, mid + minHinge / 2);
  }

  @override
  bool operator ==(Object other) =>
      other is LayoutInfo && other.layout == layout && other.fold == fold;

  @override
  int get hashCode => Object.hash(layout, fold);
}

/// Centres a dialog inside [area], the part of the screen that is safe for
/// overlays (see [LayoutInfo.overlayRect]), so it never straddles a fold.
///
/// [area] is worked out by the caller before the dialog opens, because
/// Flutter hides fold information from dialog routes. Where Flutter has
/// already confined the dialog to one side of a hinge, that smaller space
/// wins.
class FoldAwareCenter extends StatelessWidget {
  const FoldAwareCenter({super.key, required this.area, required this.child});
  final Rect area;
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) => Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: math.min(area.width, c.maxWidth),
        height: math.min(area.height, c.maxHeight),
        child: Center(child: child),
      ),
    ),
  );
}
