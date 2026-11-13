// Checks the Dart engine against results recorded from the design
// prototype's JavaScript engine (test/fixtures/prototype_engine.json).
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:matscape/engine/engine.dart';

double _num(Object? j) => switch (j) {
  num n => n.toDouble(),
  'NaN' => double.nan,
  'Infinity' => double.infinity,
  '-Infinity' => double.negativeInfinity,
  _ => throw ArgumentError('not a number: $j'),
};

bool _close(double got, double want) {
  if (want.isNaN) return got.isNaN;
  if (want.isInfinite) return got == want;
  return (got - want).abs() <= 1e-7 * math.max(1.0, want.abs());
}

String? _matDiff(Mat got, List want) {
  if (got.rows != want.length || got.cols != (want[0] as List).length) {
    return 'size ${got.rows}×${got.cols} vs ${want.length}×${(want[0] as List).length}';
  }
  for (var i = 0; i < got.rows; i++) {
    for (var j = 0; j < got.cols; j++) {
      final w = _num((want[i] as List)[j]);
      if (!_close(got.data[i][j], w)) {
        return 'entry ${i + 1},${j + 1}: ${got.data[i][j]} vs $w';
      }
    }
  }
  return null;
}

Mat _mat(String name, List<List<num>> rows) => Mat([
  for (final r in rows) [for (final x in r) x.toDouble()],
], label: name);

Map<String, Object> _vars() {
  final c = math.cos(math.pi / 4), s = math.sin(math.pi / 4);
  return {
    'A': _mat('A', [
      [4, 1, 2],
      [1, 3, 0],
      [2, 0, 5],
    ]),
    'B': _mat('B', [
      [1, 2, 3],
      [4, 5, 6],
    ]),
    'C': _mat('C', [
      [2, 0, 1],
      [1, 3, 2],
      [1, 1, 2],
    ]),
    'R': _mat('R', [
      [c, -s],
      [s, c],
    ]),
    'S': _mat('S', [
      [0, -1],
      [1, 0],
    ]),
    'N': _mat('N', [
      [1, 2],
      [2, 4],
    ]),
    'G': _mat('G', [
      [2, 1, -1],
      [-3, -1, 2],
      [-2, 1, 2],
    ]),
    'H': _mat('H', [
      [8],
      [-11],
      [-3],
    ]),
    'W': _mat('W', [
      [1, 2, 0, 3],
      [0, 1, 4, 1],
      [2, 0, 1, 5],
      [1, 1, 1, 1],
    ]),
    'k': 3.0,
  };
}

/// Describes how [r] differs from the recorded case, or null if it matches.
String? _compare(EvalResult r, Map<String, dynamic> want) {
  final t = want['t'] as String;
  if (r.assign != want['assign']) return 'assign ${r.assign}';
  if (t == 'empty') return r.empty ? null : 'expected empty';
  if (t == 'err') {
    if (r.ok) return 'expected error “${want['m']}”, got a value';
    if (r.error != want['m']) return 'error “${r.error}” vs “${want['m']}”';
    if (r.hint != want['h']) return 'hint “${r.hint}” vs “${want['h']}”';
    if (r.unknown != want['u']) return 'unknown ${r.unknown}';
    return null;
  }
  if (!r.ok) return 'unexpected error “${r.error}” (${r.hint})';
  final w = (want['w'] as List).cast<String>();
  if (r.warnings.join('|') != w.join('|')) return 'warnings ${r.warnings}';
  final v = r.value!;
  switch (t) {
    case 'num':
      if (v is! double) return 'expected a number, got ${v.runtimeType}';
      final x = _num(want['v']);
      return _close(v, x) ? null : '$v vs $x';
    case 'mat':
      if (v is! Mat) return 'expected a matrix, got ${v.runtimeType}';
      return _matDiff(v, want['d'] as List);
    case 'list':
      if (v is! ListVal) return 'expected a list, got ${v.runtimeType}';
      final items = want['items'] as List;
      if (items.length != v.items.length) return 'list length';
      for (var i = 0; i < items.length; i++) {
        final g = v.items[i], x = items[i];
        if (x is List) {
          if (g is! Complex ||
              !_close(g.re, _num(x[0])) ||
              !_close(g.im, _num(x[1]))) {
            return 'item $i: $g vs $x';
          }
        } else if (g is! double || !_close(g, _num(x))) {
          return 'item $i: $g vs $x';
        }
      }
      return null;
    case 'multi':
      if (v is! MultiVal) return 'expected parts, got ${v.runtimeType}';
      if (v.relation != want['rel']) return 'relation ${v.relation}';
      final parts = want['parts'] as List;
      if (parts.length != v.parts.length) return 'part count';
      for (var i = 0; i < parts.length; i++) {
        final p = parts[i] as Map<String, dynamic>;
        if (v.parts[i].label != p['label']) {
          return 'label ${v.parts[i].label} vs ${p['label']}';
        }
        final d = _matDiff(v.parts[i].value, p['d'] as List);
        if (d != null) return '${p['label']}: $d';
      }
      return null;
    case 'poly':
      if (v is! PolyVal) return 'expected a polynomial, got ${v.runtimeType}';
      final c = want['c'] as List;
      if (c.length != v.coeffs.length) return 'degree';
      for (var i = 0; i < c.length; i++) {
        if (!_close(v.coeffs[i], _num(c[i]))) return 'coefficient $i';
      }
      return null;
    case 'text':
      return v is TextVal && v.text == want['s'] ? null : 'text';
  }
  return 'unknown case type $t';
}

void main() {
  final fixture = jsonDecode(
    File('test/fixtures/prototype_engine.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  for (final mode in ['rad', 'deg']) {
    test('expressions match the prototype ($mode)', () {
      final failures = <String>[];
      for (final c in (fixture[mode] as List).cast<Map<String, dynamic>>()) {
        final r = evaluate(
          c['e'] as String,
          vars: _vars(),
          degrees: mode == 'deg',
        );
        final diff = _compare(r, c);
        if (diff != null) failures.add('${c['e']}  →  $diff');
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    });
  }

  test('number display matches the prototype', () {
    final failures = <String>[];
    for (final c in (fixture['fmt'] as List).cast<Map<String, dynamic>>()) {
      final x = _num(c['x']);
      final got = {
        'exact': plain(x),
        'dec4': plain(x, exact: false, precision: 4),
        'dec8': plain(x, exact: false, precision: 8),
      };
      for (final k in got.keys) {
        if (got[k] != c[k]) failures.add('$x $k: ${got[k]} vs ${c[k]}');
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  test('step-by-step working matches the prototype', () {
    final vars = _vars(), failures = <String>[];
    for (final c in (fixture['steps'] as List).cast<Map<String, dynamic>>()) {
      final m = vars[c['name']]! as Mat, tag = '${c['k']}(${c['name']})';
      final r = switch (c['k']) {
        'det' => stepsDet(m),
        'inverse' => stepsInverse(m),
        _ => stepsRref(m),
      };
      final ops = jsonEncode([for (final s in r.steps) s.ops]);
      if (ops != jsonEncode(c['ops'])) failures.add('$tag ops: $ops');
      if (r.summary != c['summary']) failures.add('$tag summary: ${r.summary}');
      if (r.note != c['note']) failures.add('$tag note: ${r.note}');
      final d = _matDiff(r.result, c['result'] as List);
      if (d != null) failures.add('$tag result: $d');
      for (var i = 0; i < r.steps.length; i++) {
        final sd = _matDiff(r.steps[i].m, (c['ms'] as List)[i] as List);
        if (sd != null) failures.add('$tag step ${i + 1}: $sd');
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  test('matrix properties match the prototype', () {
    final vars = _vars(), failures = <String>[];
    for (final c in (fixture['props'] as List).cast<Map<String, dynamic>>()) {
      final got = {
        for (final p in properties(vars[c['name']]! as Mat)) p.key: p.value,
      };
      if (jsonEncode(got) != jsonEncode(c['p'])) {
        failures.add('${c['name']}: $got vs ${c['p']}');
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });
}
