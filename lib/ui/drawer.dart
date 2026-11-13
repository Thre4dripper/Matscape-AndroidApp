import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'icons.dart';
import 'theme.dart';
import 'widgets.dart';

/// Destinations outside the workspace: (route name, icon, label). Shown in
/// the side menu on phones and in the sidebar on tablets.
const navItems = [
  ('workspaces', MIcon.folder, 'Workspaces'),
  ('history', MIcon.clock, 'History'),
  ('library', MIcon.book, 'Operations library'),
  ('settings', MIcon.sliders, 'Settings'),
  ('help', MIcon.help, 'Help & tips'),
];

/// Side menu: where everything outside the workspace lives.
class MenuDrawer extends StatelessWidget {
  const MenuDrawer({
    super.key,
    required this.workspaceName,
    required this.onNavigate,
  });
  final String workspaceName;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal, mq = MediaQuery.of(context);
    return Container(
      width: math.min(304, mq.size.width * .82),
      padding: EdgeInsets.only(
        top: mq.padding.top + 8,
        bottom: mq.padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: pal.surface,
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            offset: Offset(8, 0),
            blurRadius: 32,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: pal.line)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Wordmark(size: Fs.xxl),
                const SizedBox(height: 2),
                Text(
                  workspaceName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: pal.ink3),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                for (final (to, icon, label) in navItems)
                  RowTap(
                    onTap: () => onNavigate(to),
                    minHeight: 48,
                    radius: 12,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Ico(icon, size: 20, color: pal.ink2),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: Fs.body,
                              fontWeight: FontWeight.w500,
                              color: pal.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Matscape 2.0 · ByteMechanics',
              style: TextStyle(fontSize: Fs.cap, color: pal.ink3),
            ),
          ),
        ],
      ),
    );
  }
}
