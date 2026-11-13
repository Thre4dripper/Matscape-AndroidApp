import 'package:material_ui/material_ui.dart';

import '../app/app_state.dart';
import '../engine/engine.dart';
import 'icons.dart';
import 'math_view.dart';
import 'scope.dart';
import 'theme.dart';
import 'widgets.dart';

/// Read-only view for tiny cover screens: the latest results and a hint to
/// open the phone to edit.
class GlanceView extends StatelessWidget {
  const GlanceView({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal, ws = state.ws, fmt = state.fmt;
    final pad = MediaQuery.paddingOf(context);
    final valueSt = mathStyle(context, size: Fs.xl, height: 1.3);

    // The last two lines that produced a result, oldest first.
    final items = <Widget>[];
    for (var i = ws.lines.length - 1; i >= 0 && items.length < 2; i--) {
      final l = ws.lines[i], r = state.lineResults[l.id];
      if (l.text.trim().isEmpty || r == null || !r.ok) continue;
      final v = r.value!;
      final Widget value;
      if (v is double) {
        value = Text.rich(
          TextSpan(
            style: valueSt,
            children: [
              const TextSpan(text: '= '),
              ...numSpans(v, fmt, valueSt),
            ],
          ),
          softWrap: false,
        );
      } else if (v is Mat) {
        value = MatrixView.preview(v, fmt, color: pal.ink);
      } else {
        value = Text(
          state.resultSummary(v),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: valueSt,
        );
      }
      items.insert(
        0,
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: pal.surface,
            border: Border.all(color: pal.line),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: mathStyle(context, size: Fs.sm, color: pal.ink2),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: value,
              ),
            ],
          ),
        ),
      );
    }

    return Semantics(
      label: 'Matscape at a glance',
      container: true,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, pad.top + 16, 20, pad.bottom + 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Wordmark(),
            Text(
              ws.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: Fs.cap, height: 1.35, color: pal.ink3),
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              Text(
                'No results yet',
                style: TextStyle(fontSize: Fs.sm, color: pal.ink3),
              )
            else
              ...items,
            const SizedBox(height: 4),
            Row(
              children: [
                Ico(MIcon.up, size: 16, color: pal.ink3),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Open the phone to edit',
                    style: TextStyle(fontSize: 13, color: pal.ink3),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
