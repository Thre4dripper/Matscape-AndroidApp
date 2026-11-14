import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../engine/engine.dart';
import '../engine/engine.dart' as engine show hasSteps;
import 'models.dart';
import 'storage.dart';
import 'sync_merge.dart';

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

/// Top-level so the closure sent to the other isolate carries only these
/// values, never the app state.
Future<List<Work>> _workOffThread(
  String text,
  int step,
  int method,
  Map<String, Object> vars,
  bool degrees,
  bool exact,
  int precision,
) => Isolate.run(
  () => workFor(
    text,
    step,
    method,
    vars: vars,
    degrees: degrees,
    exact: exact,
    precision: precision,
  ),
);
const _historyLimit = 60;

/// All app data plus the evaluated results for the open workspace.
class AppState extends ChangeNotifier {
  AppState(this._storage);

  final Storage _storage;
  final settings = Settings();
  List<Workspace> workspaces = [];
  List<HistoryItem> history = [];
  String currentId = '';

  /// False until the first-launch tutorial has been shown.
  bool tutorialSeen = false;

  /// Deleted workspaces, each with the version that was deleted, so a sync
  /// doesn't bring them back.
  Map<String, int> deleted = {};

  /// Workspaces edited since the last full sync. Their [Workspace.base] is
  /// the version the edits started from; see [_touch].
  final Set<String> _edited = {};

  /// When history was last cleared; older items from other devices are
  /// dropped too.
  int historyClearedAt = 0;

  /// When a setting last changed, so sync knows which device's settings win.
  int settingsUpdated = 0;

  int get _now => DateTime.now().millisecondsSinceEpoch;

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
        tutorialSeen = j['tutorialSeen'] as bool? ?? false;
        deleted = {
          for (final e in (j['deleted'] as Map? ?? const {}).entries)
            e.key as String: e.value as int,
        };
        historyClearedAt = j['historyClearedAt'] as int? ?? 0;
        settingsUpdated = j['settingsUpdated'] as int? ?? 0;
        _edited
          ..clear()
          ..addAll([for (final id in j['edited'] as List? ?? const []) '$id']);
        _adoptSampleIds();
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

  /// Data saved before samples had fixed ids: an untouched sample gets its
  /// fixed id and date, so it matches the same sample on other devices.
  void _adoptSampleIds() {
    final samples = {for (final s in seedWorkspaces()) s.contentKey: s};
    for (var i = 0; i < workspaces.length; i++) {
      final w = workspaces[i];
      if (w.id.startsWith(samplePrefix)) continue;
      final s = samples[w.contentKey];
      if (s == null || workspaces.any((o) => o.id == s.id)) continue;
      if (currentId == w.id) currentId = s.id;
      workspaces[i] = s;
    }
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
          'tutorialSeen': tutorialSeen,
          'deleted': deleted,
          'historyClearedAt': historyClearedAt,
          'settingsUpdated': settingsUpdated,
          'edited': _edited.toList(),
        }),
      );
    } catch (_) {
      // Storage full or unavailable; the session keeps working in memory.
    }
  }

  void _changed({bool touch = true}) {
    if (touch) _touch(ws);
    _evaluateAll();
    _persist();
    notifyListeners();
  }

  /// Stamps an edit. The first edit since the last full sync records the
  /// version it started from as [Workspace.base]: a version from another
  /// device that is newer than that was never seen here, so sync keeps it as
  /// a copy rather than letting this edit overwrite it.
  void _touch(Workspace w) {
    if (_edited.add(w.id)) w.base = w.updated;
    w.updated = _now;
  }

  /// A full sync merged every device's changes: whatever is edited next
  /// starts from what is here now.
  void markSynced() {
    if (_edited.isEmpty) return;
    _edited.clear();
    _persist();
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
    _vars = vars;
  }

  /// Every matrix and named value of the workspace, as last evaluated.
  Map<String, Object> _vars = const {};

  /// Whether a line does anything that can be shown step by step.
  bool hasSteps(String lineId) {
    final l = lineById(lineId), r = lineResults[lineId];
    return l != null &&
        r != null &&
        r.ok &&
        engine.hasSteps(l.text, vars: _vars);
  }

  /// The working for a line, one operation at a time; null when the line
  /// has no answer to work towards.
  Solution? solutionFor(String lineId) {
    final l = lineById(lineId), r = lineResults[lineId];
    if (l == null || r == null || !r.ok) return null;
    return explain(
      l.text,
      vars: _vars,
      degrees: settings.degrees,
      exact: settings.exact,
      precision: settings.precision,
    );
  }

  /// The working of one method of one step of a line, worked out on
  /// another isolate so a long one doesn't freeze the screen.
  Future<List<Work>> workOffThread(String lineId, int step, int method) {
    final l = lineById(lineId);
    if (l == null) return Future.value(const []);
    return _workOffThread(
      l.text,
      step,
      method,
      // A copy: the workspace may be edited while this runs.
      Map.of(_vars),
      settings.degrees,
      settings.exact,
      settings.precision,
    );
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

  /// What the copy button puts on the clipboard for [v]: plain text, or
  /// LaTeX when that is chosen in Settings.
  String copyText(Object v) => settings.copyLatex
      ? texValue(v, exact: settings.exact, precision: settings.precision)
      : valueText(v);

  /// What to tell the user after copying.
  String get copiedNote => settings.copyLatex ? 'Copied as LaTeX' : 'Copied';

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

  /// Moves the line at [from] so it ends up at index [to].
  void moveLine(int from, int to) => _move(ws.lines, from, to);

  void _move<T>(List<T> list, int from, int to) {
    if (from < 0 || from >= list.length) return;
    to = to.clamp(0, list.length - 1);
    if (from == to) return;
    list.insert(to, list.removeAt(from));
    _changed();
  }

  /// Records a finished line in history: most recent first, each
  /// expression once. Lines without a result are not kept.
  void commitLine(String id) {
    final l = lineById(id), res = lineResults[id];
    if (l == null || l.text.trim().isEmpty || res == null || !res.ok) return;
    final summary = resultSummary(res.value!);
    if (history.isNotEmpty &&
        history.first.text == l.text &&
        history.first.summary == summary) {
      return;
    }
    history.removeWhere((h) => h.text == l.text);
    history.insert(
      0,
      HistoryItem(l.text, summary, DateTime.now().millisecondsSinceEpoch),
    );
    if (history.length > _historyLimit) {
      history.removeRange(_historyLimit, history.length);
    }
    _persist();
    notifyListeners();
  }

  void clearHistory() {
    history = [];
    historyClearedAt = _now;
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

  /// Moves the matrix at [from] so it ends up at index [to].
  void moveMatrix(int from, int to) => _move(ws.matrices, from, to);

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

  /* ---------- workspaces ---------- */

  void renameWorkspace(String name) {
    final n = name.trim();
    ws.name = n.isEmpty ? 'Untitled workspace' : n;
    _touch(ws);
    _persist();
    notifyListeners();
  }

  void openWorkspace(String id) {
    currentId = id;
    _changed(touch: false);
  }

  Workspace newWorkspace() {
    final s = settings;
    final w = Workspace(
      name: 'Untitled workspace ${workspaces.length + 1}',
      updated: _now,
      matrices: [
        MatrixModel(
          name: 'A',
          cells: fillCells(s.defRows, s.defCols, s.defIdentity),
        ),
      ],
      lines: [LineModel('')],
    );
    workspaces.insert(0, w);
    openWorkspace(w.id);
    return w;
  }

  /// Deletes a workspace; the last one can't be removed.
  bool deleteWorkspace(String id) {
    if (workspaces.length == 1) return false;
    final gone = workspaces.where((w) => w.id == id).firstOrNull;
    if (gone == null) return false;
    workspaces.remove(gone);
    // The version that was deleted, not the time: changes made on another
    // device that this one never saw are newer, so they survive the delete.
    deleted[id] = gone.updated;
    if (currentId == id) currentId = workspaces.first.id;
    _changed(touch: false);
    return true;
  }

  /// Puts back workspaces a sync removed (deleted on another device), dated
  /// now so the restore reaches the other devices too. [open] reopens the
  /// one that was open.
  void restoreWorkspaces(List<Workspace> list, {String? open}) {
    final now = _now;
    final have = {for (final w in workspaces) w.id};
    for (final w in list.reversed) {
      if (have.contains(w.id)) continue;
      // A new version of the deleted one, so it outlives the delete.
      workspaces.insert(0, w.copyWith(updated: now, base: w.updated));
      _edited.add(w.id);
    }
    if (open != null && workspaces.any((w) => w.id == open)) currentId = open;
    _changed(touch: false);
  }

  /// Puts back the sample workspaces that are no longer in the list
  /// (matched by id or name). Returns how many were added.
  int restoreSamples() {
    final have = {
      for (final w in workspaces) ...[w.id, w.name],
    };
    final now = _now;
    final missing = [
      for (final w in seedWorkspaces())
        if (!have.contains(w.id) && !have.contains(w.name))
          // Dated now, so the restore beats the deletion on other devices.
          w.copyWith(updated: now, base: 0),
    ];
    if (missing.isEmpty) return 0;
    for (final w in missing) {
      deleted.remove(w.id);
    }
    workspaces.addAll(missing);
    _persist();
    notifyListeners();
    return missing.length;
  }

  /* ---------- sync ---------- */

  /// Everything that syncs, as a document for this device to upload.
  SyncDoc toSyncDoc({
    required String device,
    required String deviceName,
    required int savedAt,
  }) => SyncDoc(
    device: device,
    deviceName: deviceName,
    savedAt: savedAt,
    workspaces: [for (final w in workspaces) w.copyWith()],
    deleted: Map.of(deleted),
    history: List.of(history),
    historyClearedAt: historyClearedAt,
    settings: settings.toJson(),
    settingsUpdated: settingsUpdated,
  );

  /// Takes on a merged document. The open workspace stays open if it still
  /// exists.
  void applySyncDoc(SyncDoc doc) {
    workspaces = [for (final w in doc.workspaces) w.copyWith()];
    if (workspaces.isEmpty) {
      // Everything was deleted elsewhere; the app always has one workspace.
      final s = settings;
      workspaces = [
        Workspace(
          name: 'Untitled workspace',
          updated: _now,
          matrices: [
            MatrixModel(
              name: 'A',
              cells: fillCells(s.defRows, s.defCols, s.defIdentity),
            ),
          ],
          lines: [LineModel('')],
        ),
      ];
    }
    deleted = Map.of(doc.deleted);
    history = List.of(doc.history);
    historyClearedAt = doc.historyClearedAt;
    settings.load(doc.settings);
    settingsUpdated = doc.settingsUpdated;
    if (!workspaces.any((w) => w.id == currentId)) {
      currentId = workspaces.first.id;
    }
    _evaluateAll();
    _persist();
    notifyListeners();
  }

  /* ---------- tutorial ---------- */

  void markTutorialSeen() {
    if (tutorialSeen) return;
    tutorialSeen = true;
    _persist();
  }

  /* ---------- settings ---------- */

  void updateSettings(void Function(Settings s) change) {
    change(settings);
    settingsUpdated = _now;
    _changed(touch: false);
  }
}
