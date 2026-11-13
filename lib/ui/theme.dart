import 'package:material_ui/material_ui.dart';

/// Design tokens from the Matscape 2 design (app.css).
@immutable
class Palette extends ThemeExtension<Palette> {
  const Palette({
    required this.dark,
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.surface3,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.line,
    required this.lineStrong,
    required this.accent,
    required this.accentInk,
    required this.accentSoft,
    required this.onAccent,
    required this.danger,
    required this.dangerSoft,
    required this.onDanger,
    required this.ok,
    required this.okSoft,
    required this.note,
    required this.noteSoft,
    required this.key,
    required this.keyOp,
    required this.keyFn,
    required this.keyPress,
    required this.keyShadow,
    required this.scrim,
    required this.sheetShadow,
  });

  final bool dark;
  final Color bg, surface, surface2, surface3;
  final Color ink, ink2, ink3;
  final Color line, lineStrong;
  final Color accent, accentInk, accentSoft, onAccent;
  final Color danger, dangerSoft, onDanger;
  final Color ok, okSoft;
  final Color note, noteSoft;
  final Color key, keyOp, keyFn, keyPress, keyShadow;
  final Color scrim, sheetShadow;

  static const light = Palette(
    dark: false,
    bg: Color(0xFFF6F7F9),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFECEFF3),
    surface3: Color(0xFFE3E7ED),
    ink: Color(0xFF12151A),
    ink2: Color(0xFF434A55),
    ink3: Color(0xFF5F6773),
    line: Color(0xFFDFE3E9),
    lineStrong: Color(0xFFC3C9D2),
    accent: Color(0xFF1F43C9),
    accentInk: Color(0xFF1A39AD),
    accentSoft: Color(0xFFE7ECFB),
    onAccent: Color(0xFFFFFFFF),
    danger: Color(0xFFB4291F),
    dangerSoft: Color(0xFFFBE9E7),
    onDanger: Color(0xFFFFFFFF),
    ok: Color(0xFF1B6E45),
    okSoft: Color(0xFFE4F3EA),
    note: Color(0xFF7A4B00),
    noteSoft: Color(0xFFFDF3DC),
    key: Color(0xFFFFFFFF),
    keyOp: Color(0xFFDDE2EA),
    keyFn: Color(0xFFF4F6F9),
    keyPress: Color(0xFFCFD6E0),
    keyShadow: Color(0x2412151A),
    scrim: Color(0x6B0C0E12),
    sheetShadow: Color(0x290C0E12),
  );

  static const night = Palette(
    dark: true,
    bg: Color(0xFF0D0F13),
    surface: Color(0xFF161920),
    surface2: Color(0xFF1B1F27),
    surface3: Color(0xFF242934),
    ink: Color(0xFFECEFF4),
    ink2: Color(0xFFB9C0CB),
    ink3: Color(0xFF959DAB),
    line: Color(0xFF2A303B),
    lineStrong: Color(0xFF3B4350),
    accent: Color(0xFF8EA8FF),
    accentInk: Color(0xFFA9BCFF),
    accentSoft: Color(0xFF1E2847),
    onAccent: Color(0xFF0B0E16),
    danger: Color(0xFFFF8F84),
    dangerSoft: Color(0xFF3A1C1A),
    onDanger: Color(0xFF1A0B09),
    ok: Color(0xFF7AD3A2),
    okSoft: Color(0xFF15301F),
    note: Color(0xFFF3C46B),
    noteSoft: Color(0xFF33280F),
    key: Color(0xFF262B35),
    keyOp: Color(0xFF323947),
    keyFn: Color(0xFF1F242D),
    keyPress: Color(0xFF3D4655),
    keyShadow: Color(0x80000000),
    scrim: Color(0x99000000),
    sheetShadow: Color(0x80000000),
  );

  @override
  Palette copyWith() => this;

  @override
  Palette lerp(Palette? other, double t) => t < 0.5 ? this : (other ?? this);
}

extension PaletteContext on BuildContext {
  Palette get pal => Theme.of(this).extension<Palette>()!;
}

/// Font for anything mathematical: expressions, results, matrix names.
const mathFont = 'STIXTwoText';

/// Type scale.
abstract final class Fs {
  static const cap = 12.0;
  static const sm = 14.0;
  static const body = 16.0;
  static const lg = 18.0;
  static const xl = 22.0;
  static const xxl = 28.0;
  static const math = 20.0;
}

/// Motion.
abstract final class Motion {
  static const fast = Duration(milliseconds: 160);
  static const base = Duration(milliseconds: 220);
  static const slow = Duration(milliseconds: 300);
  static const easeOut = Cubic(.2, .8, .2, 1);
  static const easeIn = Cubic(.4, 0, 1, 1);
}

TextStyle mathStyle(
  BuildContext context, {
  double size = Fs.math,
  FontWeight weight = FontWeight.w400,
  bool italic = false,
  Color? color,
  double height = 1.35,
}) => TextStyle(
  fontFamily: mathFont,
  fontSize: size,
  fontWeight: weight,
  fontStyle: italic ? FontStyle.italic : FontStyle.normal,
  color: color ?? context.pal.ink,
  height: height,
  fontFeatures: const [
    FontFeature.liningFigures(),
    FontFeature.tabularFigures(),
  ],
);

/// Sub-screen pages slide in 24px and fade, as in the design.
class _ScreenInTransition extends PageTransitionsBuilder {
  const _ScreenInTransition();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondary,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Motion.easeOut,
      reverseCurve: Motion.easeIn,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(24 / 400, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

ThemeData buildTheme(Palette p) {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: p.accent,
        brightness: p.dark ? Brightness.dark : Brightness.light,
      ).copyWith(
        primary: p.accent,
        onPrimary: p.onAccent,
        surface: p.surface,
        onSurface: p.ink,
        error: p.danger,
      );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.bg,
    extensions: [p],
    // The design's body text: 16px, 1.5 line height, no extra tracking
    // (Material's defaults add letter spacing).
    textTheme: const TextTheme(
      bodyLarge: TextStyle(fontSize: Fs.body, height: 1.5, letterSpacing: 0),
      bodyMedium: TextStyle(fontSize: Fs.body, height: 1.5, letterSpacing: 0),
      bodySmall: TextStyle(letterSpacing: 0),
      titleMedium: TextStyle(letterSpacing: 0),
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: p.accent,
      selectionColor: p.accent.withValues(alpha: .25),
      selectionHandleColor: p.accent,
    ),
    // iOS is left on its default native push so the back-swipe keeps working.
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: _ScreenInTransition()},
    ),
  );
}
