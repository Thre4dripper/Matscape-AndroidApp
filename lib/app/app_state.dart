import 'dart:async';
import 'dart:convert';

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
}
