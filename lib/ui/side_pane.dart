import 'package:material_ui/material_ui.dart';

import '../app/app_state.dart';
import 'drawer.dart' show navItems;
import 'icons.dart';
import 'layout.dart';
import 'matrix_card.dart';
import 'scope.dart';
import 'theme.dart';
import 'widgets.dart';

/// Sidebar of the medium and expanded layouts: navigation on top, the
/// workspace's matrices underneath.
class SidePane extends StatelessWidget {
  const SidePane({
    super.key,
    required this.state,
    required this.current,
    required this.onNavigate,
    required this.onNewMatrix,
    required this.onEditMatrix,
  });

  final AppState state;

  /// Route name of the screen that is open, to highlight it.
  final String? current;
  final ValueChanged<String> onNavigate;
  final VoidCallback onNewMatrix;
  final ValueChanged<String> onEditMatrix;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal, ws = state.ws;
    final pad = MediaQuery.paddingOf(context);
    const gap = 10.0;
    // Two cards per row inside the 16px gutters (and the 1px border).
    const cardW = (sideWidth - 1 - 32 - gap) / 2;
    return Semantics(
      label: 'Navigation and matrices',
      container: true,
      child: Container(
        width: sideWidth,
        padding: EdgeInsets.only(top: pad.top),
        decoration: BoxDecoration(
          color: pal.surface,
          border: Border(right: BorderSide(color: pal.line)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Wordmark(size: Fs.xxl),
                  const SizedBox(height: 2),
                  Text(
                    ws.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: pal.ink3),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: pal.line)),
              ),
              child: Column(
                children: [
                  for (final (to, icon, label) in navItems)
                    _NavItem(
                      icon: icon,
                      label: label,
                      current: to == current,
                      onTap: () => onNavigate(to),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.only(bottom: 24 + pad.bottom),
                children: [
                  SectionHead(
                    'Matrices',
                    action: TextBtn(
                      'New',
                      icon: MIcon.plus,
                      onTap: onNewMatrix,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        for (final m in ws.matrices)
                          _DragCard(
                            key: ValueKey(m.id),
                            state: state,
                            id: m.id,
                            name: m.name,
                            width: cardW,
                            builder: (handle) => MatrixCard(
                              model: m,
                              eval: state.matResults[m.id],
                              fmt: state.fmt,
                              width: cardW,
                              onTap: () => onEditMatrix(m.id),
                              handle: handle,
                            ),
                          ),
                        NewMatrixCard(width: cardW, onTap: onNewMatrix),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A matrix card in the sidebar's grid that can be dragged to another
/// card's place, by its handle or by holding the card. The cards shuffle as
/// it passes over them, so what you see while dragging is the order you get.
class _DragCard extends StatefulWidget {
  const _DragCard({
    super.key,
    required this.state,
    required this.id,
    required this.name,
    required this.width,
    required this.builder,
  });
  final AppState state;
  final String id, name;
  final double width;

  /// Builds the card around the given drag handle.
  final Widget Function(Widget handle) builder;

  @override
  State<_DragCard> createState() => _DragCardState();
}

class _DragCardState extends State<_DragCard> {
  bool _dragging = false;

  void _set(bool v) {
    if (mounted && _dragging != v) setState(() => _dragging = v);
  }

  /// The card as it looks under the finger. [offset] lines it up with the
  /// card it came from when the drag started on the handle.
  Widget _floating(Offset offset) => Transform.translate(
    offset: offset,
    child: Material(
      type: MaterialType.transparency,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: context.pal.sheetShadow,
              offset: const Offset(0, 6),
              blurRadius: 18,
            ),
          ],
        ),
        child: widget.builder(const Grip()),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final w = widget;
    // The handle starts a drag at once; the card itself after a hold.
    final handle = Draggable<String>(
      data: w.id,
      // The handle sits 2px in from the card's top right corner.
      feedback: _floating(Offset(-(w.width - 34), -2)),
      onDragStarted: () => _set(true),
      onDragEnd: (_) => _set(false),
      child: Semantics(
        label: 'Drag to reorder matrix ${w.name}',
        container: true,
        child: const Grip(),
      ),
    );
    return LongPressDraggable<String>(
      data: w.id,
      delay: const Duration(milliseconds: 350),
      feedback: _floating(Offset.zero),
      onDragStarted: () => _set(true),
      onDragEnd: (_) => _set(false),
      child: DragTarget<String>(
        onWillAcceptWithDetails: (d) {
          final mats = w.state.ws.matrices;
          final from = mats.indexWhere((m) => m.id == d.data);
          final to = mats.indexWhere((m) => m.id == w.id);
          if (from >= 0 && to >= 0) w.state.moveMatrix(from, to);
          return true;
        },
        builder: (_, _, _) => AnimatedOpacity(
          duration: Motion.fast,
          opacity: _dragging ? .3 : 1,
          child: w.builder(handle),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.current,
    required this.onTap,
  });
  final MIcon icon;
  final String label;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return Pressable(
      onTap: onTap,
      selected: current,
      builder: (_, down) => AnimatedContainer(
        duration: Motion.fast,
        height: 48,
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: current ? pal.accentSoft : (down ? pal.surface2 : null),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Ico(icon, size: 20, color: current ? pal.accentInk : pal.ink2),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: Fs.body,
                  fontWeight: current ? FontWeight.w600 : FontWeight.w500,
                  color: current ? pal.accentInk : pal.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
