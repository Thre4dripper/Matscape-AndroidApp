import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Caret-aware edits for fields driven by the app's own keypads.

(int, int) _range(TextEditingController c) {
  final sel = c.selection, n = c.text.length;
  if (!sel.isValid) return (n, n);
  return (sel.start.clamp(0, n), sel.end.clamp(0, n));
}

void _set(TextEditingController c, String text, int caret) {
  c.value = TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: caret),
  );
}

/// Inserts [str] at the caret, then steps the caret [back] characters so it
/// lands inside brackets: `insertText(c, 'det()', back: 1)`.
void insertText(TextEditingController c, String str, {int back = 0}) {
  final (s, e) = _range(c);
  _set(c, c.text.replaceRange(s, e, str), s + str.length - back);
}

final _fnOpen = RegExp(r'[A-Za-z0-9]+\($');
const _pairs = {'(': ')', '[': ']', '|': '|'};

/// Deletes backwards, removing a whole `name(` (and its empty `)`), an
/// empty bracket pair, or the two-character `⁻¹` in one press.
void backspace(TextEditingController c) {
  final v = c.text;
  var (s, e) = _range(c);
  if (s != e) {
    _set(c, v.replaceRange(s, e, ''), s);
    return;
  }
  if (s == 0) return;
  final before = v.substring(0, s), after = v.substring(s);
  var cut = 1, extra = 0;
  final fn = _fnOpen.firstMatch(before);
  if (fn != null) {
    cut = fn[0]!.length;
    if (after.startsWith(')')) extra = 1;
  } else if (before.endsWith('⁻¹')) {
    cut = 2;
  } else {
    final close = _pairs[before[before.length - 1]];
    if (close != null && after.startsWith(close)) extra = 1;
  }
  _set(
    c,
    before.substring(0, before.length - cut) + after.substring(extra),
    s - cut,
  );
}

void moveCaret(TextEditingController c, int delta) {
  final (s, _) = _range(c);
  c.selection = TextSelection.collapsed(
    offset: (s + delta).clamp(0, c.text.length),
  );
}

void selectAll(TextEditingController c) {
  c.selection = TextSelection(baseOffset: 0, extentOffset: c.text.length);
}

final _leadingMinus = RegExp(r'^[−-]');
final _hasSign = RegExp(r'[+−-]');

/// Flips the sign of a whole entry: 3 → −3, −3 → 3, 1+2 → −(1+2).
void toggleSign(TextEditingController c) {
  final v = c.text.trim();
  final nv = _leadingMinus.hasMatch(v)
      ? v.substring(1)
      : (_hasSign.hasMatch(v) ? '−($v)' : '−$v');
  _set(c, nv, nv.length);
}

/// Hardware-keyboard conveniences: `*` types ·, `'` types ᵀ.
class MathKeysFormatter extends TextInputFormatter {
  const MathKeysFormatter({this.transposeQuote = true});
  final bool transposeQuote;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var t = newValue.text.replaceAll('*', '·');
    if (transposeQuote) t = t.replaceAll("'", 'ᵀ');
    return t == newValue.text ? newValue : newValue.copyWith(text: t);
  }
}
