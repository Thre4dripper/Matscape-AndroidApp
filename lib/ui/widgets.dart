import 'package:material_ui/material_ui.dart';

import 'icons.dart';
import 'theme.dart';

/* ---------- press feedback ---------- */

/// Tappable area that tells its builder whether it is being pressed.
/// It never takes keyboard focus, so text fields keep their caret.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.onTap,
    required this.builder,
    this.label,
    this.selected,
    this.scale = 1,
  });
  final VoidCallback? onTap;
  final Widget Function(BuildContext context, bool pressed) builder;
  final String? label;
  final bool? selected;

  /// Scale applied while pressed.
  final double scale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    Widget child = widget.builder(context, _down && enabled);
    if (widget.scale != 1) {
      child = AnimatedScale(
        scale: _down && enabled ? widget.scale : 1,
        duration: Motion.fast,
        curve: Motion.easeOut,
        child: child,
      );
    }
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      selected: widget.selected,
      excludeSemantics: widget.label != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _set(true) : null,
        onTapUp: enabled ? (_) => _set(false) : null,
        onTapCancel: enabled ? () => _set(false) : null,
        onTap: widget.onTap,
        child: child,
      ),
    );
  }
}

/* ---------- buttons ---------- */

class IconBtn extends StatelessWidget {
  const IconBtn(
    this.icon, {
    super.key,
    required this.onTap,
    required this.label,
    this.small = false,
    this.danger = false,
    this.width = 44,
  });
  final MIcon icon;
  final VoidCallback? onTap;
  final String label;
  final bool small, danger;
  final double width;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return Pressable(
      onTap: onTap,
      label: label,
      builder: (_, down) => AnimatedContainer(
        duration: Motion.fast,
        width: width,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: down ? pal.surface3 : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Ico(
          icon,
          size: small ? 18 : 22,
          color: danger ? pal.danger : (small ? pal.ink3 : pal.ink),
        ),
      ),
    );
  }
}

class TextBtn extends StatelessWidget {
  const TextBtn(
    this.text, {
    super.key,
    required this.onTap,
    this.icon,
    this.compact = false,
  });
  final String text;
  final MIcon? icon;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return Pressable(
      onTap: onTap,
      builder: (_, down) => AnimatedContainer(
        duration: Motion.fast,
        constraints: BoxConstraints(minHeight: compact ? 36 : 44),
        padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12),
        decoration: BoxDecoration(
          color: down ? pal.accentSoft : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Ico(icon!, size: 18, color: pal.accentInk),
              const SizedBox(width: 6),
            ],
            Text(
              text,
              style: TextStyle(
                color: pal.accentInk,
                fontWeight: FontWeight.w600,
                fontSize: compact ? 13 : Fs.sm,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum BtnKind { plain, primary, danger }

class Btn extends StatelessWidget {
  const Btn(
    this.text, {
    super.key,
    required this.onTap,
    this.icon,
    this.kind = BtnKind.plain,
    this.expand = true,
  });
  final String text;
  final MIcon? icon;
  final VoidCallback? onTap;
  final BtnKind kind;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final (bg, fg, border) = switch (kind) {
      BtnKind.plain => (pal.surface, pal.ink, pal.lineStrong),
      BtnKind.primary => (pal.accent, pal.onAccent, pal.accent),
      BtnKind.danger => (pal.danger, pal.onDanger, pal.danger),
    };
    final pressed = switch (kind) {
      BtnKind.plain => pal.surface2,
      BtnKind.primary => pal.accentInk,
      BtnKind.danger => pal.danger,
    };
    final child = Pressable(
      onTap: onTap,
      builder: (_, down) => AnimatedContainer(
        duration: Motion.fast,
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: down ? pressed : bg,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Ico(icon!, size: 18, color: fg),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w600,
                  fontSize: Fs.sm,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return expand ? Expanded(child: child) : child;
  }
}

/* ---------- segmented control, stepper, chip ---------- */

class Seg<T> extends StatelessWidget {
  const Seg({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.small = false,
  });
  final List<(T, String)> options;
  final T value;
  final ValueChanged<T> onChanged;

  /// Hug the labels instead of filling the width.
  final bool small;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    Widget item((T, String) o) {
      final on = o.$1 == value;
      return Pressable(
        onTap: () => onChanged(o.$1),
        selected: on,
        builder: (_, _) => AnimatedContainer(
          duration: Motion.fast,
          height: small ? 38 : 36,
          padding: EdgeInsets.symmetric(horizontal: small ? 12 : 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? pal.surface : null,
            borderRadius: BorderRadius.circular(9),
            boxShadow: on
                ? [
                    BoxShadow(
                      color: pal.keyShadow,
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Text(
            o.$2,
            maxLines: 1,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: on ? pal.ink : pal.ink2,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: pal.surface3,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: small ? MainAxisSize.min : MainAxisSize.max,
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: 2),
            small ? item(options[i]) : Expanded(child: item(options[i])),
          ],
        ],
      ),
    );
  }
}

class StepperBox extends StatelessWidget {
  const StepperBox({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.label,
    this.compact = false,
    this.buttonWidth,
  });
  final int value, min, max;
  final ValueChanged<int> onChanged;
  final String label;
  final bool compact;

  /// Overrides the − / + button width (for narrow screens).
  final double? buttonWidth;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    Widget btn(String glyph, int delta, String what) {
      final enabled = delta < 0 ? value > min : value < max;
      return Pressable(
        onTap: enabled ? () => onChanged(value + delta) : null,
        label: '$what $label',
        builder: (_, down) => Container(
          width: buttonWidth ?? (compact ? 36 : 44),
          height: compact ? 36 : 40,
          alignment: Alignment.center,
          color: down ? pal.surface2 : null,
          child: Text(
            glyph,
            style: TextStyle(
              fontSize: compact ? 18 : 20,
              height: 1,
              color: enabled ? pal.ink : pal.lineStrong,
            ),
          ),
        ),
      );
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: pal.surface,
        border: Border.all(color: pal.lineStrong),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn('−', -1, 'Decrease'),
          Container(
            constraints: BoxConstraints(minWidth: compact ? 24 : 32),
            alignment: Alignment.center,
            child: Text(
              '$value',
              style: mathStyle(
                context,
                size: compact ? Fs.body : Fs.lg,
                height: 1.2,
              ),
            ),
          ),
          btn('+', 1, 'Increase'),
        ],
      ),
    );
  }
}

class ChipBtn extends StatelessWidget {
  const ChipBtn(
    this.text, {
    super.key,
    required this.onTap,
    this.on = false,
    this.height = 36,
  });
  final String text;
  final VoidCallback onTap;
  final bool on;
  final double height;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return Pressable(
      onTap: onTap,
      selected: on,
      builder: (_, down) => Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? pal.ink : (down ? pal.surface2 : pal.surface),
          border: Border.all(color: on ? pal.ink : pal.lineStrong),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: on ? pal.bg : pal.ink2,
          ),
        ),
      ),
    );
  }
}

/* ---------- layout pieces ---------- */

class GroupTitle extends StatelessWidget {
  const GroupTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Semantics(
      header: true,
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: Fs.cap,
          fontWeight: FontWeight.w600,
          letterSpacing: .96,
          color: context.pal.ink3,
        ),
      ),
    ),
  );
}

class CardBox extends StatelessWidget {
  const CardBox({super.key, required this.child, this.padding});
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: padding,
      decoration: BoxDecoration(
        color: pal.surface,
        border: Border.all(color: pal.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

/// Children separated by hairlines, as in the design's `.list`.
class DividedColumn extends StatelessWidget {
  const DividedColumn({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) Container(height: 1, color: context.pal.line),
        children[i],
      ],
    ],
  );
}

/// Row that highlights while pressed (list rows, nav items).
class RowTap extends StatelessWidget {
  const RowTap({
    super.key,
    required this.onTap,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.minHeight = 56,
    this.radius = 0,
    this.label,
  });
  final VoidCallback onTap;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double minHeight, radius;
  final String? label;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    label: label,
    builder: (context, down) => AnimatedContainer(
      duration: Motion.fast,
      constraints: BoxConstraints(minHeight: minHeight),
      padding: padding,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: down ? context.pal.surface2 : null,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    ),
  );
}

/// Sub-screen frame: back button, centred serif title, optional action.
class SubScreen extends StatelessWidget {
  const SubScreen({
    super.key,
    required this.title,
    required this.child,
    this.action,
  });
  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return Scaffold(
      backgroundColor: pal.bg,
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(
              8,
              MediaQuery.paddingOf(context).top + 4,
              8,
              8,
            ),
            decoration: BoxDecoration(
              color: pal.bg,
              border: Border(bottom: BorderSide(color: pal.line)),
            ),
            child: Row(
              children: [
                IconBtn(
                  MIcon.back,
                  label: 'Back',
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: mathStyle(
                        context,
                        size: Fs.xl,
                        weight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
                action ?? const SizedBox(width: 44, height: 44),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Standard scrolling body for sub-screens.
class SubScroll extends StatelessWidget {
  const SubScroll({super.key, required this.children, this.controller});
  final List<Widget> children;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) => ListView(
    controller: controller,
    padding: EdgeInsets.fromLTRB(
      16,
      8,
      16,
      32 + MediaQuery.paddingOf(context).bottom,
    ),
    children: children,
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });
  final MIcon icon;
  final String title, body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        children: [
          Ico(icon, size: 32, color: pal.ink3),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(color: pal.ink, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: Fs.sm, color: pal.ink3),
            ),
          ),
          if (action != null) ...[const SizedBox(height: 8), action!],
        ],
      ),
    );
  }
}

/// Inline error with an optional hint line.
class ErrorNote extends StatelessWidget {
  const ErrorNote(this.message, {super.key, this.hint = ''});
  final String message, hint;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Ico(MIcon.alert, size: 18, color: pal.danger),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: TextStyle(
                  fontSize: Fs.sm,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                  color: pal.danger,
                ),
              ),
              if (hint.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    hint,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: pal.ink2,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
