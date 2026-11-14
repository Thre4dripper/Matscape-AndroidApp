import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'icons.dart';
import 'layout.dart';
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
    this.label,
  });
  final String text;
  final MIcon? icon;
  final VoidCallback? onTap;
  final bool compact;

  /// What a screen reader says, when [text] alone is too short to be clear.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return Pressable(
      onTap: onTap,
      label: label,
      builder: (_, down) => AnimatedContainer(
        duration: Motion.fast,
        constraints: BoxConstraints(minHeight: compact ? 36 : 44),
        padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12),
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
            // Shortens instead of overflowing where there is little room.
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: pal.accentInk,
                  fontWeight: FontWeight.w600,
                  fontSize: compact ? 13 : Fs.sm,
                ),
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

/// The six-dot handle that says "drag me". The caller wraps it in
/// whatever starts the drag.
class Grip extends StatelessWidget {
  const Grip({super.key, this.width = 32, this.height = 32});
  final double width, height;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    // Transparent, so the whole box takes the touch, not just the dots.
    color: const Color(0x00000000),
    alignment: Alignment.center,
    child: Ico(MIcon.grip, size: 16, color: context.pal.ink3),
  );
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

/// Small-caps section heading with an action on the right.
class SectionHead extends StatelessWidget {
  const SectionHead(this.title, {super.key, required this.action});
  final String title;
  final Widget action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 4, 8),
    child: Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: Fs.cap,
                fontWeight: FontWeight.w600,
                letterSpacing: .96,
                height: 1.3,
                color: context.pal.ink3,
              ),
            ),
          ),
        ),
        action,
      ],
    ),
  );
}

/// The "Matscape" wordmark.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.size = Fs.xl});
  final double size;

  @override
  Widget build(BuildContext context) {
    final st = mathStyle(
      context,
      size: size,
      weight: FontWeight.w600,
      height: 1.15,
    );
    return Text.rich(
      TextSpan(
        style: st.copyWith(letterSpacing: -size * .01),
        children: [
          const TextSpan(text: 'Mat'),
          TextSpan(
            text: 'scape',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: context.pal.accent,
            ),
          ),
        ],
      ),
      semanticsLabel: 'Matscape',
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

/// How a screen such as the library is being shown when it is not pushed
/// full-screen: replacing the workspace column, or in the detail pane.
enum PaneKind { column, detail }

/// Tells screens they live inside a pane, and how to close themselves.
class PaneScope extends InheritedWidget {
  const PaneScope({
    super.key,
    required this.kind,
    required this.onClose,
    required super.child,
  });
  final PaneKind kind;

  /// Null when there is nothing to go back to (the always-on inspector).
  final VoidCallback? onClose;

  static PaneScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PaneScope>();

  @override
  bool updateShouldNotify(PaneScope old) =>
      old.kind != kind || (old.onClose == null) != (onClose == null);
}

/// Closes the current screen, whether it was pushed or sits in a pane.
void closeSub(BuildContext context) {
  final scope = context.getInheritedWidgetOfExactType<PaneScope>();
  if (scope == null) {
    Navigator.of(context).pop();
  } else {
    scope.onClose?.call();
  }
}

/// Screen frame: a bar with back/close, a serif title and an optional
/// action. Adapts to being pushed full-screen or embedded in a pane.
class SubScreen extends StatelessWidget {
  const SubScreen({
    super.key,
    required this.title,
    required this.child,
    this.action,
    this.onBack,
    this.backLabel = 'Back',
  });
  final String title;
  final Widget child;
  final Widget? action;

  /// When set, the bar shows a back arrow that calls this instead of
  /// closing the screen (for a page opened inside the screen).
  final VoidCallback? onBack;
  final String backLabel;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final scope = PaneScope.maybeOf(context);
    final detail = scope?.kind == PaneKind.detail;
    final top = MediaQuery.paddingOf(context).top;
    final Widget? leading;
    if (onBack != null) {
      leading = IconBtn(MIcon.back, label: backLabel, onTap: onBack);
    } else if (detail) {
      leading = scope!.onClose == null
          ? null
          : IconBtn(MIcon.close, label: 'Close panel', onTap: scope.onClose);
    } else {
      leading = IconBtn(
        MIcon.back,
        label: scope == null ? 'Back' : 'Back to workspace',
        onTap: scope == null
            ? () => Navigator.of(context).maybePop()
            : scope.onClose,
      );
    }
    final body = Column(
      children: [
        Container(
          constraints: BoxConstraints(minHeight: detail ? top + 56 : 0),
          padding: EdgeInsets.fromLTRB(8, top + 4, 8, 8),
          decoration: BoxDecoration(
            color: pal.bg,
            border: Border(bottom: BorderSide(color: pal.line)),
          ),
          child: Row(
            children: [
              ?leading,
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: detail ? 8 : 0),
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      textAlign: detail ? TextAlign.left : TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: mathStyle(
                        context,
                        size: detail ? Fs.lg : Fs.xl,
                        weight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
              action ?? SizedBox(width: detail ? 0 : 44, height: 44),
            ],
          ),
        ),
        Expanded(child: child),
      ],
    );
    // Pushed full-screen it keeps clear of a notch or camera at the side;
    // in a pane the workspace has already done that.
    return scope == null
        ? Scaffold(
            backgroundColor: pal.bg,
            body: SafeArea(top: false, bottom: false, child: body),
          )
        : Material(color: pal.bg, child: body);
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

/* ---------- toast and confirm ---------- */

OverlayEntry? _toastEntry;
Timer? _toastTimer;

/// Brief pill message at the top of the screen.
void showToast(BuildContext context, String message) {
  final overlay = Navigator.of(context, rootNavigator: true).overlay;
  if (overlay == null) return;
  _toastTimer?.cancel();
  _toastEntry?.remove();
  final entry = OverlayEntry(
    builder: (context) {
      final pal = context.pal;
      final area = LayoutInfo.of(context)
          .overlayRect(MediaQuery.sizeOf(context));
      return Positioned(
        top: MediaQuery.paddingOf(context).top + 8,
        left: area.left + 24,
        width: area.width - 48,
        child: IgnorePointer(
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Motion.base,
              curve: Motion.easeOut,
              builder: (_, t, child) => Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(0, -8 * (1 - t)),
                  child: child,
                ),
              ),
              child: Semantics(
                liveRegion: true,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: pal.ink,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        offset: Offset(0, 8),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: pal.bg,
                      fontSize: Fs.sm,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
  _toastEntry = entry;
  overlay.insert(entry);
  _toastTimer = Timer(const Duration(milliseconds: 2200), () {
    entry.remove();
    if (_toastEntry == entry) _toastEntry = null;
  });
}

/// Centered confirmation card. Resolves to true when confirmed.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String ok,
  bool danger = true,
}) async {
  final pal = context.pal;
  final area = LayoutInfo.of(context).overlayRect(MediaQuery.sizeOf(context));
  final result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cancel',
    barrierColor: pal.scrim,
    transitionDuration: Motion.base,
    transitionBuilder: (_, anim, _, child) {
      final t = CurvedAnimation(parent: anim, curve: Motion.easeOut);
      return FadeTransition(
        opacity: t,
        child: ScaleTransition(
          scale: Tween(begin: .97, end: 1.0).animate(t),
          child: child,
        ),
      );
    },
    pageBuilder: (context, _, _) => FoldAwareCenter(
      area: area,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: pal.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x47000000),
              offset: Offset(0, 16),
              blurRadius: 48,
            ),
          ],
        ),
        child: DefaultTextStyle(
          style: Theme.of(context).textTheme.bodyLarge!
              .copyWith(color: pal.ink),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: Fs.lg,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                style: TextStyle(fontSize: Fs.sm, height: 1.5, color: pal.ink2),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Btn('Cancel', onTap: () => Navigator.of(context).pop(false)),
                  const SizedBox(width: 8),
                  Btn(
                    ok,
                    kind: danger ? BtnKind.danger : BtnKind.primary,
                    onTap: () => Navigator.of(context).pop(true),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return result ?? false;
}
