import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../engine/engine.dart';
import 'models.dart';
import 'storage.dart';

/// Result of evaluating a user matrix's cells.
class MatEval {
  MatEval.ok(Mat this.value) : badRow = 0, badCol = 0, error = null;
  MatEval.bad(this.badRow, this.badCol, String this.error) : value = null;

  final Mat? value;
  final int badRow, badCol;
  final String? error;

  bool get ok => value != null;
  String get where => 'Row ${badRow + 1}, column ${badCol + 1}: $error';
}

const matrixLetters = 'ABCDEFGHJKLMNOPQRSTUVWXYZ';
const maxMatrixSize = 8;
const _historyLimit = 60;

/// All app data plus the evaluated results for the open workspace.
class AppState extends ChangeNotifier {
  AppState(this._storage);

  final Storage _storage;
  final settings = Settings();
  List<Workspace> workspaces = [];
  List<HistoryItem> history = [];
  String currentId = '';

  Map<String, MatEval> matResults = {};
  Map<String, EvalResult> lineResults = {};

  Timer? _saveTimer;
  final _rng = math.Random();

  Workspace get ws => workspaces.firstWhere((w) => w.id == currentId);

  /* ---------- load / save ---------- */

  Future<void> load() async {
    try {
      final raw = await _storage.read();
      if (raw != null) {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        workspaces = [
          for (final w in j['workspaces'] as List)
            Workspace.fromJson(w as Map<String, dynamic>),
        ];
        history = [
          for (final h in (j['history'] as List? ?? const []))
            HistoryItem.fromJson(h as Map<String, dynamic>),
        ];
        settings.load(j['settings'] as Map<String, dynamic>? ?? const {});
        currentId = j['currentId'] as String? ?? '';
      }
    } catch (_) {
      // Unreadable data: start fresh rather than fail to launch.
      workspaces = [];
    }
    if (workspaces.isEmpty) {
      workspaces = seedWorkspaces();
      history = [];
    }
    if (!workspaces.any((w) => w.id == currentId)) {
      currentId = workspaces.first.id;
    }
    _evaluateAll();
  }

  void _persist() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 250), flush);
  }

  /// Writes pending changes now (also called when the app is backgrounded).
  Future<void> flush() async {
    _saveTimer?.cancel();
    try {
      await _storage.write(
        jsonEncode({
          'workspaces': workspaces,
          'history': history,
          'settings': settings,
          'currentId': currentId,
        }),
      );
    } catch (_) {
      // Storage full or unavailable; the session keeps working in memory.
    }
  }

  void _changed({bool touch = true}) {
    if (touch) ws.updated = DateTime.now().millisecondsSinceEpoch;
    _evaluateAll();
    _persist();
    notifyListeners();
  }

  /* ---------- evaluation ---------- */

  void _evaluateAll() {
    final w = ws, deg = settings.degrees;
    final vars = <String, Object>{}, mats = <String, MatEval>{};
    final names = {for (final m in w.matrices) m.name};
    for (final m in w.matrices) {
      MatEval? bad;
      final data = [
        for (var i = 0; i < m.rows; i++)
          [
            for (var j = 0; j < m.cols; j++)
              () {
                final r = evalScalar(m.cells[i][j], degrees: deg);
                if (r.ok) return r.value! as double;
                bad ??= MatEval.bad(i, j, r.error ?? 'Invalid entry');
                return double.nan;
              }(),
          ],
      ];
      final res = bad ?? MatEval.ok(Mat(data, label: m.name));
      mats[m.id] = res;
      vars[m.name] = res.ok ? res.value! : InvalidVal(m.name, '${res.where}.');
    }

    EvalResult run(LineModel l) =>
        evaluate(l.text, vars: vars, degrees: deg, matrixNames: names);
    final out = <String, EvalResult>{};
    // Named values may be defined below the lines that use them, so keep
    // resolving assignments until nothing new becomes available.
    final pending = [
      for (final l in w.lines)
        if (splitAssignment(l.text) != null) l,
    ];
    var progress = true;
    while (pending.isNotEmpty && progress) {
      progress = false;
      for (var k = 0; k < pending.length; k++) {
        final l = pending[k], r = run(l);
        if (r.ok || r.unknown == null) {
          out[l.id] = r;
          final v = r.value;
          if (r.ok && r.assign != null && (v is Mat || v is double)) {
            if (v is Mat) v.label = r.assign;
            vars[r.assign!] = v!;
          }
          pending.removeAt(k--);
          progress = true;
        }
      }
    }
    for (final l in w.lines) {
      out[l.id] ??= run(l);
    }
    matResults = mats;
    lineResults = out;
  }

  /* ---------- formatting that depends on settings ---------- */

  String numText(double x) =>
      plain(x, exact: settings.exact, precision: settings.precision);

  String complexText(Object z) {
    if (z is double) return numText(z);
    final c = z as Complex;
    final re = c.re.abs() < 1e-11 ? 0.0 : c.re, im = c.im.abs();
    final ip = '${(im - 1).abs() < 1e-12 ? '' : numText(im)}i';
    if (re == 0) return (c.im < 0 ? '−' : '') + ip;
    return '${numText(re)} ${c.im < 0 ? '−' : '+'} $ip';
  }

  String resultSummary(Object v) {
    if (v is double) return numText(v);
    if (v is Mat) return '${v.rows}×${v.cols} matrix';
    if (v is ListVal) return 'λ = ${v.items.map(complexText).join(', ')}';
    if (v is MultiVal) return v.relation ?? '${v.parts.length} results';
    if (v is PolyVal) return 'Characteristic polynomial';
    if (v is TextVal) return v.text;
    return '';
  }

  /// Text that round-trips through the parser, for copying and saving.
  static String cellText(double x) {
    final d = describe(x);
    if (d.kind != NumKind.dec && d.kind != NumKind.special) return plain(x);
    var s = numStr(double.parse(x.toStringAsPrecision(12)));
    if (s.contains('e')) {
      s = x
          .toStringAsFixed(14)
          .replaceFirst(RegExp(r'0+$'), '')
          .replaceFirst(RegExp(r'\.$'), '');
    }
    return s.replaceFirst('-', '−');
  }

  static String matText(Mat m) =>
      '[${m.data.map((r) => r.map(cellText).join(', ')).join('; ')}]';

  String valueText(Object v) {
    if (v is double) return numText(v);
    if (v is Mat) return matText(v);
    return resultSummary(v);
  }

  /* ---------- lines ---------- */

  LineModel? lineById(String id) {
    for (final l in ws.lines) {
      if (l.id == id) return l;
    }
    return null;
  }

  void setLineText(String id, String text) {
    final l = lineById(id);
    if (l == null || l.text == text) return;
    l.text = text;
    _changed();
  }

  /// Inserts a line after [afterId] (or at the end) and returns it.
  LineModel addLine({String? afterId, String text = ''}) {
    final w = ws, l = LineModel(text);
    final idx = afterId == null
        ? w.lines.length - 1
        : w.lines.indexWhere((x) => x.id == afterId);
    w.lines.insert(idx + 1, l);
    _changed();
    return l;
  }

  /// Removes a line and returns the id of the line to focus next. The last
  /// remaining line is cleared instead of removed.
  String deleteLine(String id) {
    final w = ws, idx = w.lines.indexWhere((l) => l.id == id);
    if (idx < 0) return w.lines.first.id;
    if (w.lines.length == 1) {
      w.lines[0].text = '';
      _changed();
      return w.lines[0].id;
    }
    w.lines.removeAt(idx);
    _changed();
    return w.lines[math.max(0, idx - 1)].id;
  }

  /// Records a finished line in history.
  void commitLine(String id) {
    final l = lineById(id), res = lineResults[id];
    if (l == null || l.text.trim().isEmpty || res == null || !res.ok) return;
    if (history.isEmpty || history.first.text != l.text) {
      history.insert(
        0,
        HistoryItem(
          l.text,
          resultSummary(res.value!),
          DateTime.now().millisecondsSinceEpoch,
        ),
      );
      if (history.length > _historyLimit) {
        history.removeRange(_historyLimit, history.length);
      }
      _persist();
      notifyListeners();
    }
  }

  void clearHistory() {
    history = [];
    _persist();
    notifyListeners();
  }

  /* ---------- matrices ---------- */

  MatrixModel? matrixById(String id) {
    for (final m in ws.matrices) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// First unused letter, or null when all 25 are taken.
  String? freeName() {
    final used = {for (final m in ws.matrices) m.name};
    for (final l in ws.lines) {
      final a = splitAssignment(l.text);
      if (a != null) used.add(a.name);
    }
    for (final c in matrixLetters.split('')) {
      if (!used.contains(c)) return c;
    }
    return null;
  }

  /// Letters the matrix [m] could be renamed to (its own included).
  List<String> namesFor(MatrixModel m) {
    final used = {for (final x in ws.matrices) x.name};
    return [
      for (final c in matrixLetters.split(''))
        if (c == m.name || !used.contains(c)) c,
    ];
  }

  static List<List<String>> fillCells(int r, int c, bool identity) => [
    for (var i = 0; i < r; i++)
      [for (var j = 0; j < c; j++) identity && i == j ? '1' : '0'],
  ];

  MatrixModel? createMatrix(List<List<String>> cells) {
    final name = freeName();
    if (name == null) return null;
    final m = MatrixModel(name: name, cells: cells);
    ws.matrices.add(m);
    _changed();
    return m;
  }

  MatrixModel? newMatrix() => createMatrix(
    fillCells(settings.defRows, settings.defCols, settings.defIdentity),
  );

  MatrixModel? saveValueAsMatrix(Mat v) => createMatrix([
    for (final r in v.data) [for (final x in r) cellText(x)],
  ]);

  MatrixModel? duplicateMatrix(MatrixModel m) =>
      createMatrix([for (final r in m.cells) List<String>.of(r)]);

  void deleteMatrix(String id) {
    ws.matrices.removeWhere((m) => m.id == id);
    _changed();
  }

  /// Renames a matrix; returns true when some line still uses the old name.
  bool renameMatrix(MatrixModel m, String name) {
    final old = m.name;
    m.name = name;
    _changed();
    final re = RegExp('(^|[^A-Za-z])$old([^A-Za-z]|\$)');
    return ws.lines.any((l) => re.hasMatch(l.text));
  }

  void setCell(MatrixModel m, int i, int j, String text) {
    if (m.cells[i][j] == text) return;
    m.cells[i][j] = text;
    _changed();
  }

  void resizeMatrix(MatrixModel m, {int? rows, int? cols}) {
    final r = (rows ?? m.rows).clamp(1, maxMatrixSize);
    final c = (cols ?? m.cols).clamp(1, maxMatrixSize);
    final id = settings.defIdentity;
    m.cells = [
      for (var i = 0; i < r; i++)
        [
          for (var j = 0; j < c; j++)
            i < m.rows && j < m.cols
                ? m.cells[i][j]
                : (id && i == j ? '1' : '0'),
        ],
    ];
    _changed();
  }

  /// Fills a matrix from a preset. Returns true if the size had to change.
  bool presetMatrix(MatrixModel m, String preset) {
    String rnd() => '${_rng.nextInt(19) - 9}'.replaceFirst('-', '−');
    var r = m.rows, c = m.cols, resized = false;
    switch (preset) {
      case 'rotation':
        if (!(r == c && (r == 2 || r == 3))) {
          r = c = 2;
          resized = true;
        }
        m.cells = r == 2
            ? [
                ['cos(30°)', '−sin(30°)'],
                ['sin(30°)', 'cos(30°)'],
              ]
            : [
                ['cos(30°)', '−sin(30°)', '0'],
                ['sin(30°)', 'cos(30°)', '0'],
                ['0', '0', '1'],
              ];
      case 'symmetric':
        final g = fillCells(r, c, false);
        for (var i = 0; i < r; i++) {
          for (var j = 0; j < c; j++) {
            g[i][j] = j < i && i < c ? g[j][i] : rnd();
          }
        }
        m.cells = g;
      default:
        m.cells = [
          for (var i = 0; i < r; i++)
            [
              for (var j = 0; j < c; j++)
                switch (preset) {
                  'identity' => i == j ? '1' : '0',
                  'random' => rnd(),
                  'diagonal' => i == j ? '${1 + _rng.nextInt(9)}' : '0',
                  _ => '0',
                },
            ],
        ];
    }
    _changed();
    return resized;
  }
}
