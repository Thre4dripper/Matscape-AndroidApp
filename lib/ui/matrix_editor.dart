import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../app/app_state.dart';
import '../app/models.dart';
import '../engine/engine.dart';
import 'icons.dart';
import 'keypad.dart';
import 'layout.dart';
import 'math_view.dart';
import 'scope.dart';
import 'text_edit.dart' as edit;
import 'theme.dart';
import 'widgets.dart';

/// Opens the matrix editor.
///
/// Entries are typed with the editor's own keypad, so the system keyboard
/// never opens and the matrix stays visible while typing. How it is shown
/// follows the layout: a bottom sheet on phones, a centred dialog on
/// tablets, one side of the fold on a book-style foldable, and split
/// around the fold (or left/right on a short, wide screen) otherwise.
Future<void> showMatrixEditor(
  BuildContext context, {
  required String matrixId,
  required WorkspaceHost host,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return Navigator.of(context).push(
    _EditorRoute(matrixId: matrixId, host: host, scrim: context.pal.scrim),
  );
}

/// A popup route of our own rather than a dialog route: Flutter confines
/// dialogs to one side of a fold and hides the fold from them, but the
/// editor needs to see it to split itself around it.
class _EditorRoute extends PopupRoute<void> {
  _EditorRoute({
    required this.matrixId,
    required this.host,
    required this.scrim,
  });
  final String matrixId;
  final WorkspaceHost host;
  final Color scrim;

  @override
  Color get barrierColor => scrim;

  @override
  bool get barrierDismissible => true;

  @override
  String get barrierLabel => 'Close editor';

  @override
  Duration get transitionDuration => Motion.slow;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> _,
    Animation<double> _,
  ) => _MatrixEditor(matrixId: matrixId, host: host);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> _,
    Widget child,
  ) {
    final t = CurvedAnimation(
      parent: animation,
      curve: Motion.easeOut,
      reverseCurve: Motion.easeIn,
    );
    return switch (LayoutInfo.of(context).layout) {
      AppLayout.compact ||
      AppLayout.book ||
      AppLayout.glance => SlideTransition(
        position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(t),
        child: child,
      ),
      AppLayout.medium || AppLayout.expanded => FadeTransition(
        opacity: t,
        child: ScaleTransition(
          scale: Tween(begin: .98, end: 1.0).animate(t),
          child: child,
        ),
      ),
      _ => FadeTransition(opacity: t, child: child),
    };
  }
}

const _fnKeys = [
  KeyDef('π', 'π', kind: KeyKind.op, aria: 'Pi'),
  KeyDef('√', '√', kind: KeyKind.op, aria: 'Square root'),
  KeyDef('(', '(', kind: KeyKind.op, aria: 'Open bracket'),
  KeyDef(')', ')', kind: KeyKind.op, aria: 'Close bracket'),
  KeyDef('x<sup>□</sup>', '^', kind: KeyKind.op, aria: 'Power'),
  KeyDef('°', '°', kind: KeyKind.op, aria: 'Degrees'),
  KeyDef('sin', 'sin()', kind: KeyKind.fn, back: 1),
  KeyDef('cos', 'cos()', kind: KeyKind.fn, back: 1),
  KeyDef('tan', 'tan()', kind: KeyKind.fn, back: 1),
  KeyDef('<i>e</i>', 'e', kind: KeyKind.op, aria: 'Euler’s number'),
  KeyDef('ln', 'ln()', kind: KeyKind.fn, back: 1),
];

const _presets = [
  ('zero', 'Zeros'),
  ('identity', 'Identity'),
  ('random', 'Random'),
  ('symmetric', 'Symmetric'),
  ('diagonal', 'Diagonal'),
  ('rotation', 'Rotation 30°'),
];

final _plainNumber = RegExp(r'^\s*[−-]?\d*\.?\d+\s*$');

class _MatrixEditor extends StatefulWidget {
  const _MatrixEditor({required this.matrixId, required this.host});
  final String matrixId;
  final WorkspaceHost host;

  @override
  State<_MatrixEditor> createState() => _MatrixEditorState();
}

class _MatrixEditorState extends State<_MatrixEditor> {
  final _entry = TextEditingController();
  late final FocusNode _entryFocus = FocusNode(onKeyEvent: _onHardwareKey);
  final _selKey = GlobalKey();
  int _i = 0, _j = 0;
  bool _fill = false;

  /// How far the sheet has been dragged down.
  double _drag = 0;
  bool _loaded = false;

  AppState get _state => AppScope.read(context);
  MatrixModel? get _m => _state.matrixById(widget.matrixId);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _loadEntry();
    }
  }

  @override
  void dispose() {
    _entry.dispose();
    _entryFocus.dispose();
    super.dispose();
  }

  /// Puts the selected cell's text in the entry field, fully selected so
  /// typing replaces it.
  void _loadEntry() {
    final m = _m;
    if (m == null) return;
    _i = math.min(_i, m.rows - 1);
    _j = math.min(_j, m.cols - 1);
    _entry.text = m.cells[_i][_j];
    edit.selectAll(_entry);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _entryFocus.requestFocus();
      final ctx = _selKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
          alignment: .5,
          duration: Motion.fast,
        );
      }
    });
  }

  void _select(int i, int j) => setState(() {
    _i = i;
    _j = j;
    _loadEntry();
  });

  void _entryChanged() {
    final m = _m;
    if (m != null) _state.setCell(m, _i, _j, _entry.text);
  }

  void _next() {
    final m = _m;
    if (m == null) return;
    var i = _i, j = _j + 1;
    if (j >= m.cols) {
      j = 0;
      i++;
    }
    if (i >= m.rows) {
      Navigator.of(context).pop();
    } else {
      _select(i, j);
    }
  }

  KeyEventResult _onHardwareKey(FocusNode _, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final m = _m, key = e.logicalKey;
    if (m == null) return KeyEventResult.ignored;
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      _next();
    } else if (key == LogicalKeyboardKey.arrowUp && _i > 0) {
      _select(_i - 1, _j);
    } else if (key == LogicalKeyboardKey.arrowDown && _i < m.rows - 1) {
      _select(_i + 1, _j);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  void _key(void Function(TextEditingController c) change) {
    change(_entry);
    _entryChanged();
  }

  void _resize({int? rows, int? cols}) {
    final m = _m;
    if (m == null) return;
    _state.resizeMatrix(m, rows: rows, cols: cols);
    setState(_loadEntry);
  }

  void _preset(String p) {
    final m = _m;
    if (m == null) return;
    if (_state.presetMatrix(m, p)) showToast(context, 'Set to a 2×2 rotation');
    setState(_loadEntry);
  }

  Future<void> _rename() async {
    final m = _m;
    if (m == null) return;
    final area = LayoutInfo.of(context).overlayRect(MediaQuery.sizeOf(context));
    final name = await showDialog<String>(
      context: context,
      barrierColor: context.pal.scrim,
      builder: (_) =>
          _NameDialog(area: area, current: m.name, names: _state.namesFor(m)),
    );
    if (name == null || name == m.name || !mounted) return;
    final old = m.name;
    final used = _state.renameMatrix(m, name);
    showToast(
      context,
      used
          ? 'Renamed to $name — update lines that use $old'
          : 'Renamed to $name',
    );
  }

  void _duplicate() {
    final m = _m;
    if (m == null) return;
    final copy = _state.duplicateMatrix(m);
    if (copy == null) {
      showToast(context, 'All 25 matrix names are in use');
      return;
    }
    Navigator.of(context).pop();
    showToast(context, 'Duplicated ${m.name} as ${copy.name}');
  }

  Future<void> _delete() async {
    final m = _m;
    if (m == null) return;
    final ok = await confirmDialog(
      context,
      title: 'Delete matrix ${m.name}?',
      body:
          'Lines that use ${m.name} will show an error until you create it again.',
      ok: 'Delete',
    );
    if (!ok || !mounted) return;
    Navigator.of(context).pop();
    _state.deleteMatrix(m.id);
    showToast(context, 'Deleted matrix ${m.name}');
  }

  void _inspect() {
    Navigator.of(context).pop();
    widget.host.openInspector(InspectTarget.matrix(widget.matrixId));
  }

  /* ---------- build ---------- */

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context), pal = context.pal;
    final m = state.matrixById(widget.matrixId);
    if (m == null) return const SizedBox.shrink();
    final res = state.matResults[m.id];
    final info = LayoutInfo.of(context);
    final mq = MediaQuery.of(context), size = mq.size, pad = mq.padding;

    // Matrix on one side, its keypad on the other (of a fold, or of a
    // short wide screen).
    List<Widget> matrixSide() => [
      _head(context, m),
      _dims(context, state, m, res),
      Expanded(child: _grid(context, state, m)),
      _entryRow(context, state, m),
      _message(context, state, m),
      const SizedBox(height: 8),
    ];
    List<Widget> keypadSide() => [
      const SizedBox(height: 8),
      _strip(context),
      Expanded(child: _pad(context, m, fill: true)),
    ];
    // Everything stacked. The grid always takes the height of four rows
    // (less on a short screen) and scrolls inside it, so adding or removing
    // rows never moves the controls around it.
    List<Widget> stacked() => [
      _head(context, m),
      _dims(context, state, m, res),
      Flexible(
        child: SizedBox(height: _gridHeight, child: _grid(context, state, m)),
      ),
      _entryRow(context, state, m),
      _message(context, state, m),
      _strip(context),
      _pad(context, m),
    ];

    switch (info.layout) {
      case AppLayout.tabletop:
        return Material(
          color: pal.surface,
          child: Column(
            children: [
              SizedBox(
                height: info.fold.top,
                child: Padding(
                  padding: EdgeInsets.only(top: pad.top),
                  child: Column(children: matrixSide()),
                ),
              ),
              SizedBox(height: info.fold.height),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 8 + pad.bottom),
                  child: Column(children: keypadSide()),
                ),
              ),
            ],
          ),
        );
      case AppLayout.landscape:
        return Material(
          color: pal.surface,
          child: SafeArea(
            child: Row(
              children: [
                Expanded(child: Column(children: matrixSide())),
                Container(width: 1, color: pal.line),
                SizedBox(
                  width: LayoutInfo.landscapeKeypadWidth(
                    size.width - pad.horizontal,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(children: keypadSide()),
                  ),
                ),
              ],
            ),
          ),
        );
      case AppLayout.medium || AppLayout.expanded:
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: math.min(560, size.width - 48),
              maxHeight: size.height - pad.vertical - 48,
            ),
            child: _panel(
              radius: BorderRadius.circular(20),
              shadow: const BoxShadow(
                color: Color(0x47000000),
                offset: Offset(0, 24),
                blurRadius: 64,
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: stacked(),
                ),
              ),
            ),
          ),
        );
      case AppLayout.compact || AppLayout.book || AppLayout.glance:
        // A bottom sheet; on a book-style foldable it stays left of the fold.
        return Align(
          alignment: Alignment.bottomLeft,
          child: Transform.translate(
            offset: Offset(0, _drag),
            child: SizedBox(
              width: info.layout == AppLayout.book
                  ? info.fold.left
                  : size.width,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: size.height - pad.top - 8,
                ),
                child: _panel(
                  radius: const BorderRadius.vertical(top: Radius.circular(20)),
                  shadow: BoxShadow(
                    color: pal.sheetShadow,
                    offset: const Offset(0, -8),
                    blurRadius: 32,
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 8 + pad.bottom),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [_grabber(context), ...stacked()],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
    }
  }

  Widget _panel({
    required Widget child,
    required BorderRadius radius,
    required BoxShadow shadow,
  }) => DecoratedBox(
    decoration: BoxDecoration(borderRadius: radius, boxShadow: [shadow]),
    child: Material(
      color: context.pal.surface,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: child,
    ),
  );

  /// The sheet's handle: drag it down to dismiss.
  Widget _grabber(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onVerticalDragUpdate: (d) =>
        setState(() => _drag = math.max(0, _drag + d.delta.dy)),
    onVerticalDragEnd: (d) {
      if (_drag > 90 || (d.primaryVelocity ?? 0) > 700) {
        Navigator.of(context).pop();
      } else {
        setState(() => _drag = 0);
      }
    },
    child: SizedBox(
      height: 22,
      width: double.infinity,
      child: Center(
        child: Container(
          width: 36,
          height: 5,
          decoration: BoxDecoration(
            color: context.pal.lineStrong,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    ),
  );

  Widget _head(BuildContext context, MatrixModel m) {
    final pal = context.pal;
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.only(left: 16, right: 12),
      child: Row(
        children: [
          // Title and name picker share what the action buttons leave over.
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    'Matrix',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.fade,
                    style: mathStyle(
                      context,
                      size: Fs.xl,
                      weight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Pressable(
                  onTap: _rename,
                  label: 'Matrix name ${m.name}. Change',
                  builder: (_, down) => Container(
                    height: 40,
                    constraints: const BoxConstraints(minWidth: 60),
                    padding: const EdgeInsets.only(left: 10, right: 6),
                    decoration: BoxDecoration(
                      color: down ? pal.surface2 : pal.surface,
                      border: Border.all(color: pal.lineStrong),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          m.name,
                          style: mathStyle(
                            context,
                            size: Fs.xl,
                            weight: FontWeight.w600,
                            italic: true,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Ico(MIcon.down, size: 16, color: pal.ink2),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconBtn(
            MIcon.trash,
            width: 40,
            danger: true,
            label: 'Delete matrix',
            onTap: _delete,
          ),
          IconBtn(
            MIcon.copy,
            width: 40,
            label: 'Duplicate matrix',
            onTap: _duplicate,
          ),
          IconBtn(
            MIcon.eye,
            width: 40,
            label: 'Inspect matrix',
            onTap: _inspect,
          ),
          const SizedBox(width: 4),
          Pressable(
            onTap: () => Navigator.of(context).pop(),
            builder: (_, down) => Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: down ? pal.accentInk : pal.accent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Done',
                style: TextStyle(
                  color: pal.onAccent,
                  fontSize: Fs.sm,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dims(
    BuildContext context,
    AppState state,
    MatrixModel m,
    MatEval? res,
  ) => LayoutBuilder(
    builder: (context, c) =>
        _dimsRow(context, state, m, res, narrow: c.maxWidth < 380),
  );

  Widget _dimsRow(
    BuildContext context,
    AppState state,
    MatrixModel m,
    MatEval? res, {
    required bool narrow,
  }) {
    final pal = context.pal;
    var detText = '';
    if (res != null && res.ok && m.rows == m.cols) {
      detText = 'det ${state.numText(det(res.value!))}';
    }
    Widget dim(String label, int v, ValueChanged<int> onChanged) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: pal.ink2,
          ),
        ),
        const SizedBox(width: 8),
        StepperBox(
          value: v,
          min: 1,
          max: maxMatrixSize,
          compact: true,
          buttonWidth: narrow ? 30 : null,
          label: label.toLowerCase(),
          onChanged: onChanged,
        ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          dim('Rows', m.rows, (v) => _resize(rows: v)),
          SizedBox(width: narrow ? 10 : 16),
          dim('Cols', m.cols, (v) => _resize(cols: v)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              detText,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: mathStyle(context, size: Fs.body, color: pal.ink2),
            ),
          ),
        ],
      ),
    );
  }

  /// Four rows of cells, the gaps between them and the padding around.
  static const _gridHeight = 4 * 44.0 + 3 * 6.0 + 16;

  Widget _grid(BuildContext context, AppState state, MatrixModel m) {
    final pal = context.pal, deg = state.settings.degrees;
    const gap = 6.0, minCell = 52.0, cellH = 44.0;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      constraints: const BoxConstraints(minHeight: 64),
      decoration: BoxDecoration(
        color: pal.surface2,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, c) {
          final avail = c.maxWidth - 16;
          final cellW = math.max(
            minCell,
            (avail - (m.cols - 1) * gap) / m.cols,
          );
          Widget cell(int i, int j) {
            final txt = m.cells[i][j], r = evalScalar(txt, degrees: deg);
            final sel = i == _i && j == _j;
            final st = mathStyle(
              context,
              size: r.ok ? Fs.lg : Fs.sm,
              height: 1.2,
              color: r.ok ? pal.ink : pal.danger,
            );
            final border = !r.ok ? pal.danger : (sel ? pal.accent : pal.line);
            return Pressable(
              key: sel ? _selKey : null,
              onTap: () => _select(i, j),
              selected: sel,
              label:
                  'Row ${i + 1}, column ${j + 1}: ${txt.trim().isEmpty ? 'empty' : txt}${r.ok ? '' : ', needs fixing'}',
              builder: (_, _) => AnimatedContainer(
                duration: Motion.fast,
                width: cellW,
                height: cellH,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: !r.ok
                      ? pal.dangerSoft
                      : (sel ? pal.accentSoft : pal.surface),
                  border: Border.all(color: border, width: sel ? 2 : 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: r.ok
                      ? NumText(r.value! as double, state.fmt, style: st)
                      : Text(txt.trim().isEmpty ? '?' : txt, style: st),
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                children: [
                  for (var i = 0; i < m.rows; i++) ...[
                    if (i > 0) const SizedBox(height: gap),
                    Row(
                      children: [
                        for (var j = 0; j < m.cols; j++) ...[
                          if (j > 0) const SizedBox(width: gap),
                          cell(i, j),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _entryRow(BuildContext context, AppState state, MatrixModel m) {
    final pal = context.pal;
    final txt = m.cells[_i][_j];
    final r = evalScalar(txt, degrees: state.settings.degrees);
    final labelSt = mathStyle(context, size: Fs.lg, color: pal.ink2);
    final showValue = r.ok && !_plainNumber.hasMatch(txt);
    final valueSt = mathStyle(context, size: Fs.lg, color: pal.ink3);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      constraints: const BoxConstraints(minHeight: 52),
      decoration: BoxDecoration(
        color: pal.surface,
        border: Border.all(color: pal.accent, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text.rich(
            TextSpan(
              style: labelSt,
              children: [
                TextSpan(
                  text: m.name,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
                sub('${_i + 1},${_j + 1}', labelSt),
              ],
            ),
            semanticsLabel: '${m.name}, row ${_i + 1}, column ${_j + 1}',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _entry,
              focusNode: _entryFocus,
              keyboardType: TextInputType.none,
              inputFormatters: const [
                edit.MathKeysFormatter(transposeQuote: false),
              ],
              autocorrect: false,
              enableSuggestions: false,
              maxLines: 1,
              cursorColor: pal.accent,
              style: mathStyle(context, size: 22),
              decoration: const InputDecoration.collapsed(hintText: ''),
              onChanged: (_) => _entryChanged(),
            ),
          ),
          if (showValue) ...[
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * .32,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text.rich(
                  TextSpan(
                    style: valueSt,
                    children: [
                      const TextSpan(text: '= '),
                      ...numSpans(r.value! as double, state.fmt, valueSt),
                    ],
                  ),
                  softWrap: false,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _message(BuildContext context, AppState state, MatrixModel m) {
    final pal = context.pal, txt = m.cells[_i][_j];
    final r = evalScalar(txt, degrees: state.settings.degrees);
    final error = !r.ok && txt.trim().isNotEmpty;
    final text = r.ok
        ? 'Tap any entry to edit it · sin(30°), 2√3, 1/3 all work'
        : (error ? r.error! : 'Type a value for this entry');
    return Container(
      constraints: const BoxConstraints(minHeight: 28),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Semantics(
        liveRegion: true,
        child: Row(
          children: [
            if (error) ...[
              Ico(MIcon.alert, size: 16, color: pal.danger),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: error ? pal.danger : pal.ink3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _strip(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Row(
        children: [
          Seg<bool>(
            small: true,
            options: const [(false, 'f(x)'), (true, 'Fill')],
            value: _fill,
            onChanged: (v) => setState(() => _fill = v),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(0, 2, 16, 2),
                children: [
                  if (_fill)
                    for (final (id, label) in _presets)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChipBtn(
                          label,
                          height: 44,
                          onTap: () => _preset(id),
                        ),
                      )
                  else
                    for (final k in _fnKeys)
                      Container(
                        constraints: const BoxConstraints(minWidth: 44),
                        margin: const EdgeInsets.only(right: 6, bottom: 1),
                        child: KeyCap(
                          kind: k.kind,
                          label: k.aria,
                          onTap: () => _key(
                            (c) => edit.insertText(c, k.ins, back: k.back),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: KeyLabel(
                              k.label,
                              k.kind,
                              size: k.kind == KeyKind.fn ? 14 : 18,
                            ),
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The number pad; with [fill] its rows share all the height on offer.
  Widget _pad(BuildContext context, MatrixModel m, {bool fill = false}) {
    final pal = context.pal;
    final last = _i == m.rows - 1 && _j == m.cols - 1;
    Widget d(String n) => KeyCap(
      onTap: () => _key((c) => edit.insertText(c, n)),
      child: KeyLabel(n, KeyKind.digit, size: 22),
    );
    Widget o(String l, String ins, String aria) => KeyCap(
      kind: KeyKind.op,
      label: aria,
      onTap: () => _key((c) => edit.insertText(c, ins)),
      child: KeyLabel(l, KeyKind.op, size: 22),
    );
    Widget u(MIcon icon, String aria, VoidCallback onTap) =>
        KeyCap(kind: KeyKind.util, label: aria, onTap: onTap, child: Ico(icon));
    final rows = <List<Widget>>[
      [
        d('7'),
        d('8'),
        d('9'),
        o('÷', '/', 'Divide'),
        u(MIcon.backspace, 'Delete', () => _key(edit.backspace)),
      ],
      [
        d('4'),
        d('5'),
        d('6'),
        o('×', '·', 'Multiply'),
        u(MIcon.left, 'Move cursor left', () => edit.moveCaret(_entry, -1)),
      ],
      [
        d('1'),
        d('2'),
        d('3'),
        o('−', '−', 'Minus'),
        u(MIcon.right, 'Move cursor right', () => edit.moveCaret(_entry, 1)),
      ],
      [
        KeyCap(
          kind: KeyKind.op,
          label: 'Change sign',
          onTap: () => _key(edit.toggleSign),
          child: const KeyLabel('±', KeyKind.op, size: 22),
        ),
        d('0'),
        KeyCap(
          label: 'Decimal point',
          onTap: () => _key((c) => edit.insertText(c, '.')),
          child: const KeyLabel('.', KeyKind.digit, size: 22),
        ),
        o('+', '+', 'Plus'),
        KeyCap(
          kind: KeyKind.enter,
          label: last ? 'Done editing' : 'Next entry',
          onTap: _next,
          child: Text(
            last ? 'Done' : 'Next',
            style: TextStyle(
              color: pal.onAccent,
              fontSize: Fs.body,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ];
    Widget padRow(List<Widget> keys) => Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var k = 0; k < keys.length; k++) ...[
          if (k > 0) const SizedBox(width: 6),
          Expanded(child: keys[k]),
        ],
      ],
    );
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      decoration: BoxDecoration(
        color: pal.surface,
        border: Border(top: BorderSide(color: pal.line)),
      ),
      child: Column(
        children: [
          for (var r = 0; r < rows.length; r++) ...[
            if (r > 0) const SizedBox(height: 6),
            if (fill)
              Expanded(child: padRow(rows[r]))
            else
              SizedBox(height: 46, child: padRow(rows[r])),
          ],
        ],
      ),
    );
  }
}

/// Letter picker for renaming a matrix.
class _NameDialog extends StatelessWidget {
  const _NameDialog({
    required this.area,
    required this.current,
    required this.names,
  });
  final Rect area;
  final String current;
  final List<String> names;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return FoldAwareCenter(
      area: area,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 380),
        decoration: BoxDecoration(
          color: pal.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Matrix name',
              style: TextStyle(
                fontSize: Fs.lg,
                fontWeight: FontWeight.w700,
                color: pal.ink,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final n in names)
                  Pressable(
                    onTap: () => Navigator.of(context).pop(n),
                    selected: n == current,
                    label: n,
                    builder: (_, down) => Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: n == current
                            ? pal.accent
                            : (down ? pal.surface2 : pal.surface),
                        border: Border.all(
                          color: n == current ? pal.accent : pal.lineStrong,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        n,
                        style: mathStyle(
                          context,
                          size: Fs.lg,
                          weight: FontWeight.w600,
                          italic: true,
                          height: 1.1,
                          color: n == current ? pal.onAccent : pal.ink,
                        ).copyWith(decoration: TextDecoration.none),
                      ),
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
