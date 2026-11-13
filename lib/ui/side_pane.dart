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
                          MatrixCard(
                            model: m,
                            eval: state.matResults[m.id],
                            fmt: state.fmt,
                            width: cardW,
                            onTap: () => onEditMatrix(m.id),
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
