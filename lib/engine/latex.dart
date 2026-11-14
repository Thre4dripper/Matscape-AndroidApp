/// LaTeX for values and for the working of a solution, ready to paste into
/// a paper or a set of notes.
library;

import 'format.dart';
import 'types.dart';

/// One number: `\frac{2}{3}`, `2\sqrt{3}`, `\frac{\pi}{6}`, `1.25`.
String texNum(double x, {bool exact = true, int precision = 4}) {
  final d = describe(x, exact: exact, precision: precision);
  final s = d.neg ? '-' : '';
  String over(String top) => d.d == 1 ? '$s$top' : '$s\\frac{$top}{${d.d}}';
  switch (d.kind) {
    case NumKind.special:
      return switch (d.text) {
        '∞' => r'\infty',
        '−∞' => r'-\infty',
        _ => r'\text{undefined}',
      };
    case NumKind.integer:
      return '$s${d.text}';
    case NumKind.frac:
      return over('${d.n}');
    case NumKind.surd:
      return over('${d.n == 1 ? '' : d.n}\\sqrt{${d.k}}');
    case NumKind.pi:
      return over('${d.n == 1 ? '' : d.n}\\pi');
    case NumKind.dec:
      return '$s${d.text ?? '${d.mant} \\times 10^{${d.exp}}'}';
  }
}

/// A matrix as a `bmatrix`, or as an array with a bar where an augmented
/// half starts at column [aug].
String texMat(Mat m, {bool exact = true, int precision = 4, int? aug}) {
  final rows = [
    for (final r in m.data)
      r.map((x) => texNum(x, exact: exact, precision: precision)).join(' & '),
  ].join(r' \\ ');
  if (aug == null || aug <= 0 || aug >= m.cols) {
    return '\\begin{bmatrix} $rows \\end{bmatrix}';
  }
  final spec = '${'c' * aug}|${'c' * (m.cols - aug)}';
  return '\\left[\\begin{array}{$spec} $rows \\end{array}\\right]';
}

String _texComplex(Object z, bool exact, int precision) {
  String num(double x) => texNum(x, exact: exact, precision: precision);
  if (z is double) return num(z);
  final c = z as Complex;
  if (c.im.abs() < 1e-12) return num(c.re);
  final im = num(c.im.abs());
  final i = '${im == '1' ? '' : im}i';
  if (c.re.abs() < 1e-12) return '${c.im < 0 ? '-' : ''}$i';
  return '${num(c.re)} ${c.im < 0 ? '-' : '+'} $i';
}

String _texPoly(List<double> cf, bool exact, int precision) {
  final deg = cf.length - 1, b = StringBuffer();
  for (var k = 0; k <= deg; k++) {
    final c = cleanNum(cf[k]), p = deg - k;
    if (c.abs() < 1e-12) continue;
    final mag = texNum(c.abs(), exact: exact, precision: precision);
    b.write(b.isEmpty ? (c < 0 ? '-' : '') : (c < 0 ? ' - ' : ' + '));
    if (p == 0 || mag != '1') b.write(mag);
    if (p >= 1) b.write(r'\lambda');
    if (p >= 2) b.write('^{$p}');
  }
  return b.isEmpty ? '0' : b.toString();
}

/// Any result the app can show.
String texValue(Object v, {bool exact = true, int precision = 4}) {
  if (v is double) return texNum(v, exact: exact, precision: precision);
  if (v is Mat) return texMat(v, exact: exact, precision: precision);
  if (v is ListVal) {
    return [
      for (var i = 0; i < v.items.length; i++)
        '${texMath(v.sym)}_{${i + 1}} = ${_texComplex(v.items[i], exact, precision)}',
    ].join(r',\quad ');
  }
  if (v is MultiVal) {
    return [
      for (final p in v.parts)
        '${texMath(p.label)} ${p.label.contains('=') ? r':\;' : '='} ${texMat(p.value, exact: exact, precision: precision)}',
    ].join(r',\quad ');
  }
  if (v is PolyVal) return _texPoly(v.coeffs, exact, precision);
  if (v is TextVal) return texProse(v.text);
  return '';
}

const _superscripts = {
  '⁰': '0',
  '¹': '1',
  '²': '2',
  '³': '3',
  '⁴': '4',
  '⁵': '5',
  '⁶': '6',
  '⁷': '7',
  '⁸': '8',
  '⁹': '9',
  '⁻': '-',
};

const _symbols = {
  '·': r' \cdot ',
  '−': '-',
  '–': '-',
  '÷': r' \div ',
  '×': r' \times ',
  'λ': r'\lambda ',
  'σ': r'\sigma ',
  'Σ': r'\Sigma ',
  'π': r'\pi ',
  '‖': r'\|',
  '→': r' \to ',
  '↔': r' \leftrightarrow ',
  '…': r'\dots ',
  '∘': r' \circ ',
  '°': r'^{\circ}',
  'ᵀ': r'^{\mathsf{T}}',
  '⁺': '^{+}',
  '∛': r'\sqrt[3]',
};

final _supRun = RegExp('[⁰¹²³⁴⁵⁶⁷⁸⁹⁻]+');
final _tag = RegExp(r'<(/?)(i|sub|sup)>');
final _rowName = RegExp(r'\bR(\d+)');
final _fraction = RegExp(r'(?<![\d.}])(\d+)/(\d+)(?![\d.])');
final _word = RegExp(r'(?<![\\A-Za-z])[A-Za-z]{2,}(?![A-Za-z])');

/// Where a bracket opened at [open] closes, or -1.
int _closing(String s, int open) {
  var depth = 0;
  for (var i = open; i < s.length; i++) {
    if (s[i] == '(') depth++;
    if (s[i] == ')' && --depth == 0) return i;
  }
  return -1;
}

/// √(…) and √x as `\sqrt{…}`.
String _roots(String s) {
  final b = StringBuffer();
  var i = 0;
  while (i < s.length) {
    if (s[i] != '√') {
      b.write(s[i++]);
      continue;
    }
    i++;
    if (i < s.length && s[i] == '(') {
      final end = _closing(s, i);
      if (end > 0) {
        b.write('\\sqrt{${_roots(s.substring(i + 1, end))}}');
        i = end + 1;
        continue;
      }
    }
    final m = RegExp(r'[\d.]+|[A-Za-zλσπ]').matchAsPrefix(s, i);
    b.write('\\sqrt{${m?[0] ?? ''}}');
    i = m?.end ?? i;
  }
  return b.toString();
}

/// A line of maths from the working (or a label such as "Vᵀ") as LaTeX.
/// Understands the working's own markup: `<i>`, `<sub>`, `<sup>`.
String texMath(String line) {
  var s = _roots(line);
  // Tags first, so their names are never taken for words.
  s = s.replaceAllMapped(
    _tag,
    (m) => switch ((m[1], m[2])) {
      ('', 'sub') => '_{',
      ('', 'sup') => '^{',
      ('/', 'sub') || ('/', 'sup') => '}',
      _ => '',
    },
  );
  s = s.replaceAllMapped(_rowName, (m) => 'R_{${m[1]}}');
  s = s.replaceAllMapped(_fraction, (m) => '\\tfrac{${m[1]}}{${m[2]}}');
  // Words are upright; single letters stay as variables.
  s = s.replaceAllMapped(
    _word,
    (m) => m[0] == 'det' ? r'\det ' : '\\text{${m[0]}}',
  );
  s = s.replaceAllMapped(
    _supRun,
    (m) => '^{${m[0]!.split('').map((c) => _superscripts[c]).join()}}',
  );
  _symbols.forEach((from, to) => s = s.replaceAll(from, to));
  return s.replaceAll(RegExp(' {2,}'), ' ').trim();
}

/// A sentence from the working as `\text{…}`, with any subscripts set as
/// maths inside it.
String texProse(String line) {
  var s = line.replaceAllMapped(RegExp(r'[%&#_$]'), (m) => '\\${m[0]}');
  s = s.replaceAllMapped(RegExp(r'<sub>(.*?)</sub>'), (m) => '\$_{${m[1]}}\$');
  s = s.replaceAllMapped(RegExp(r'<sup>(.*?)</sup>'), (m) => '\$^{${m[1]}}\$');
  s = s.replaceAll(_tag, '');
  s = s.replaceAllMapped(
    _supRun,
    (m) => '\$^{${m[0]!.split('').map((c) => _superscripts[c]).join()}}\$',
  );
  // Symbols LaTeX has no text-mode glyph for.
  const inline = {
    'λ': r'$\lambda$',
    'σ': r'$\sigma$',
    'Σ': r'$\Sigma$',
    'π': r'$\pi$',
    'ᵀ': r'$^{\mathsf{T}}$',
    '⁻¹': r'$^{-1}$',
    '⁺': r'$^{+}$',
    '²': r'$^{2}$',
    '³': r'$^{3}$',
    '·': r'$\cdot$',
    '−': '-',
    '÷': r'$\div$',
    '×': r'$\times$',
    '…': r'\dots{}',
    '‖': r'$\|$',
    '→': r'$\to$',
    '∞': r'$\infty$',
    '≥': r'$\ge$',
    '≤': r'$\le$',
    '√': r'$\surd$',
  };
  inline.forEach((from, to) => s = s.replaceAll(from, to));
  return '\\text{$s}';
}
