import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../app/app_state.dart';
import '../app/models.dart';
import '../engine/engine.dart';
import 'drawer.dart';
import 'icons.dart';
import 'inspector_screen.dart';
import 'keypad.dart';
import 'library_screen.dart';
import 'math_view.dart';
import 'matrix_editor.dart';
import 'more_screens.dart';
import 'scope.dart';
import 'text_edit.dart' as edit;
import 'theme.dart';
import 'widgets.dart';

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

class WorkspaceScreen extends StatefulWidget {
  const WorkspaceScreen({super.key});

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen>
    implements WorkspaceHost {
  final _scaffold = GlobalKey<ScaffoldState>();
  final _scroll = ScrollController();
  final _rail = ScrollController();
  final _ctl = <String, TextEditingController>{};
  final _focus = <String, FocusNode>{};
  final _lineKeys = <String, GlobalKey>{};

  String? _activeId;
  String _wsId = '';
  String _page = 'num';
  bool _collapsed = false;
  bool _raised = false;

  AppState get _state => AppScope.read(context);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final raised = _scroll.offset > 4;
      if (raised != _raised) setState(() => _raised = raised);
    });
  }

  @override
  void dispose() {
    for (final c in _ctl.values) {
      c.dispose();
    }
    for (final f in _focus.values) {
      f.dispose();
    }
    _scroll.dispose();
    _rail.dispose();
    super.dispose();
  }

  /* ---------- keeping text fields in step with the model ---------- */

  void _sync(AppState state) {
    final ws = state.ws;
    if (ws.id != _wsId) {
      _wsId = ws.id;
      _activeId = ws.lines.isEmpty ? null : ws.lines.first.id;
    }
    final ids = {for (final l in ws.lines) l.id};
    for (final id in _ctl.keys.toList()) {
      if (ids.contains(id)) continue;
      // Disposed after this frame, once the field using them is gone.
      final c = _ctl.remove(id)!, f = _focus.remove(id)!;
      _lineKeys.remove(id);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        c.dispose();
        f.dispose();
      });
    }
    for (final l in ws.lines) {
      final c = _ctl[l.id];
      if (c == null) {
        _ctl[l.id] = TextEditingController(text: l.text);
        _focus[l.id] = _makeFocus(l.id);
        _lineKeys[l.id] = GlobalKey();
      } else if (c.text != l.text) {
        c.value = TextEditingValue(
          text: l.text,
          selection: TextSelection.collapsed(offset: l.text.length),
        );
      }
    }
    if (_activeId != null && !ids.contains(_activeId)) {
      _activeId = ws.lines.isEmpty ? null : ws.lines.last.id;
    }
  }

  FocusNode _makeFocus(String id) {
    final node = FocusNode(onKeyEvent: (_, e) => _onHardwareKey(id, e));
    node.addListener(() {
      if (!node.hasFocus || !mounted) return;
      if (_activeId != id || _collapsed) {
        setState(() {
          _activeId = id;
          _collapsed = false;
        });
      }
    });
    return node;
  }

  KeyEventResult _onHardwareKey(String id, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final lines = _state.ws.lines, idx = lines.indexWhere((l) => l.id == id);
    final key = e.logicalKey;
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      _commit(id);
    } else if (key == LogicalKeyboardKey.backspace &&
        _ctl[id]!.text.isEmpty &&
        lines.length > 1) {
      _deleteLine(id);
    } else if (key == LogicalKeyboardKey.arrowUp && idx > 0) {
      _focusLine(lines[idx - 1].id);
    } else if (key == LogicalKeyboardKey.arrowDown && idx < lines.length - 1) {
      _focusLine(lines[idx + 1].id);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  void _focusLine(String id, {bool atEnd = true}) {
    setState(() => _activeId = id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final node = _focus[id], c = _ctl[id];
      if (!mounted || node == null || c == null) return;
      node.requestFocus();
      if (atEnd) {
        c.selection = TextSelection.collapsed(offset: c.text.length);
      }
      final ctx = _lineKeys[id]?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
          duration: Motion.base,
          curve: Motion.easeOut,
        );
      }
    });
  }

  /// The field the keypad types into; creates a line if there is none.
  TextEditingController _target() {
    final state = _state;
    var id = _activeId;
    if (id == null || !_ctl.containsKey(id)) {
      id = state.ws.lines.isEmpty ? state.addLine().id : state.ws.lines.last.id;
      _sync(state);
      _activeId = id;
    }
    if (!_focus[id]!.hasFocus) {
      final keepCaret = _ctl[id]!.selection.isValid;
      _focus[id]!.requestFocus();
      if (!keepCaret) {
        _ctl[id]!.selection = TextSelection.collapsed(
          offset: _ctl[id]!.text.length,
        );
      }
    }
    return _ctl[id]!;
  }

  void _typed() {
    final id = _activeId;
    if (id != null) _state.setLineText(id, _ctl[id]!.text);
    if (_collapsed) setState(() => _collapsed = false);
  }

  /* ---------- line actions ---------- */

  void _commit(String id) {
    final state = _state;
    state.commitLine(id);
    final lines = state.ws.lines, idx = lines.indexWhere((l) => l.id == id);
    if (idx + 1 < lines.length && lines[idx + 1].text.trim().isEmpty) {
      _focusLine(lines[idx + 1].id);
    } else {
      _focusLine(state.addLine(afterId: id).id);
    }
  }

  void _deleteLine(String id) => _focusLine(_state.deleteLine(id));

  void _addLine() {
    final state = _state;
    final last = state.ws.lines.isEmpty ? null : state.ws.lines.last.id;
    _focusLine(state.addLine(afterId: last).id);
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    showToast(context, 'Copied');
  }

  /* ---------- WorkspaceHost ---------- */

  @override
  void insertText(String text, {int back = 0}) {
    edit.insertText(_target(), text, back: back);
    _typed();
    showToast(
      context,
      'Inserted ${text.replaceFirst(RegExp(r'\(\)$'), '( )').trim()}',
    );
  }

  @override
  void addLineWith(String text) {
    final state = _state, lines = state.ws.lines;
    final active = _activeId == null ? null : state.lineById(_activeId!);
    final LineModel line;
    if (active != null && active.text.trim().isEmpty) {
      line = active;
    } else if (lines.isNotEmpty && lines.last.text.trim().isEmpty) {
      line = lines.last;
    } else {
      line = state.addLine(afterId: lines.isEmpty ? null : lines.last.id);
    }
    state.setLineText(line.id, text);
    _focusLine(line.id);
  }

  @override
  void openEditor(String matrixId, {bool isNew = false}) =>
      showMatrixEditor(context, matrixId: matrixId, host: this);

  @override
  void openInspector(InspectTarget target) =>
      _push(InspectorScreen(target: target, host: this));

  @override
  void saveAsMatrix(Mat value) {
    final m = _state.saveValueAsMatrix(value);
    if (m == null) {
      showToast(context, 'All 25 matrix names are in use');
      return;
    }
    showToast(context, 'Saved as matrix ${m.name}');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_rail.hasClients) {
        _rail.animateTo(
          _rail.position.maxScrollExtent,
          duration: Motion.slow,
          curve: Motion.easeOut,
        );
      }
    });
  }

  void _newMatrix() {
    final m = _state.newMatrix();
    if (m == null) {
      showToast(context, 'All 25 matrix names are in use');
    } else {
      openEditor(m.id, isNew: true);
    }
  }

  void _push(Widget screen) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  void _go(String to) {
    switch (to) {
      case 'workspaces':
        _push(const WorkspacesScreen());
      case 'history':
        _push(HistoryScreen(host: this));
      case 'library':
        _push(LibraryScreen(host: this));
      case 'settings':
        _push(const SettingsScreen());
      case 'help':
        _push(HelpScreen(host: this));
    }
  }

  /* ---------- build ---------- */

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context), pal = context.pal, ws = state.ws;
    _sync(state);
    return Scaffold(
      key: _scaffold,
      backgroundColor: pal.bg,
      drawerScrimColor: pal.scrim,
      drawer: MenuDrawer(
        workspaceName: ws.name,
        onNavigate: (to) {
          _scaffold.currentState?.closeDrawer();
          _go(to);
        },
      ),
      body: Column(
        children: [
          _topBar(context, ws),
          Expanded(
            child: SingleChildScrollView(
              controller: _scroll,
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionHead(
                    'Matrices',
                    TextBtn('New', icon: MIcon.plus, onTap: _newMatrix),
                  ),
                  _matrixRail(context, state),
                  const SizedBox(height: 8),
                  _sectionHead(
                    'Expressions',
                    TextBtn(
                      'History',
                      icon: MIcon.clock,
                      onTap: () => _go('history'),
                    ),
                  ),
                  Container(height: 1, color: pal.line),
                  for (var i = 0; i < ws.lines.length; i++)
                    _line(context, state, ws.lines[i], i),
                  _addLineRow(context),
                ],
              ),
            ),
          ),
          Keypad(
            page: _page,
            collapsed: _collapsed,
            degrees: state.settings.degrees,
            names: [for (final m in ws.matrices) m.name],
            onPage: (p) => setState(() => _page = p),
            onToggleCollapsed: () => setState(() => _collapsed = !_collapsed),
            onInsert: (text, back) {
              edit.insertText(_target(), text, back: back);
              _typed();
            },
            onBackspace: () {
              edit.backspace(_target());
              _typed();
            },
            onMove: (d) => edit.moveCaret(_target(), d),
            onEnter: () {
              _target();
              _commit(_activeId!);
            },
            onAngle: () {
              state.updateSettings((s) => s.degrees = !s.degrees);
              showToast(
                context,
                'Angles in ${state.settings.degrees ? 'degrees' : 'radians'}',
              );
            },
            onNewMatrix: _newMatrix,
          ),
        ],
      ),
    );
  }

  Widget _topBar(BuildContext context, Workspace ws) {
    final pal = context.pal;
    return Container(
      padding: EdgeInsets.fromLTRB(
        8,
        MediaQuery.paddingOf(context).top + 4,
        8,
        8,
      ),
      decoration: BoxDecoration(
        color: pal.bg,
        border: Border(
          bottom: BorderSide(
            color: _raised ? pal.line : const Color(0x00000000),
          ),
        ),
      ),
      child: Row(
        children: [
          IconBtn(
            MIcon.menu,
            label: 'Open menu',
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
              _scaffold.currentState?.openDrawer();
            },
          ),
          Expanded(
            child: Pressable(
              onTap: () => _go('workspaces'),
              label: 'Switch workspace. Current: ${ws.name}',
              builder: (_, down) => AnimatedContainer(
                duration: Motion.fast,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: down ? pal.surface2 : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Wordmark(),
                    Text(
                      ws.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: Fs.cap,
                        height: 1.35,
                        color: pal.ink3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconBtn(
            MIcon.book,
            label: 'Operations library',
            onTap: () => _go('library'),
          ),
        ],
      ),
    );
  }

  Widget _sectionHead(String title, Widget action) => Padding(
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

  Widget _matrixRail(BuildContext context, AppState state) {
    final pal = context.pal, mats = state.ws.matrices;
    return SizedBox(
      height: 136,
      child: ListView.separated(
        controller: _rail,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
        itemCount: mats.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          if (i == mats.length) {
            return Pressable(
              onTap: _newMatrix,
              label: 'New matrix',
              scale: .98,
              builder: (_, _) => CustomPaint(
                painter: _DashedBorder(pal.lineStrong),
                child: Container(
                  width: 132,
                  decoration: BoxDecoration(
                    color: pal.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Ico(MIcon.plus, size: 22, color: pal.accentInk),
                      const SizedBox(height: 8),
                      Text(
                        'New matrix',
                        style: TextStyle(
                          fontSize: Fs.sm,
                          fontWeight: FontWeight.w600,
                          color: pal.accentInk,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          final m = mats[i], res = state.matResults[m.id];
          final ok = res != null && res.ok;
          return Pressable(
            onTap: () => openEditor(m.id),
            label:
                'Matrix ${m.name}, ${m.rows} by ${m.cols}${ok ? '' : ', has an entry to fix'}. Edit',
            scale: .98,
            builder: (_, _) => Container(
              width: 132,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: pal.surface,
                border: Border.all(color: ok ? pal.line : pal.danger),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 2),
                  Text(
                    '${m.rows}×${m.cols}',
                    style: TextStyle(
                      fontSize: Fs.cap,
                      height: 1.3,
                      color: pal.ink3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: ok
                          ? FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.bottomLeft,
                              child: MatrixView.preview(
                                res.value!,
                                state.fmt,
                                color: pal.ink,
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: pal.dangerSoft,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Ico(MIcon.alert, size: 12, color: pal.danger),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Fix entry',
                                    style: TextStyle(
                                      fontSize: Fs.cap,
                                      fontWeight: FontWeight.w600,
                                      color: pal.danger,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _line(BuildContext context, AppState state, LineModel l, int i) {
    final pal = context.pal, active = l.id == _activeId;
    final res = state.lineResults[l.id];
    final hasText = l.text.trim().isNotEmpty;
    final error = hasText && res != null && !res.ok && !res.empty;
    return Container(
      key: _lineKeys[l.id],
      decoration: BoxDecoration(
        color: pal.surface,
        border: Border(bottom: BorderSide(color: pal.line)),
      ),
      child: Stack(
        children: [
          // Gutter: line number, accent when active, red foot on error.
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 40,
            child: AnimatedContainer(
              duration: Motion.fast,
              padding: const EdgeInsets.only(top: 14),
              alignment: Alignment.topCenter,
              decoration: BoxDecoration(
                color: active ? pal.accent : pal.surface2,
                border: Border(
                  right: BorderSide(color: active ? pal.accent : pal.line),
                  bottom: error
                      ? BorderSide(color: pal.danger, width: 3)
                      : BorderSide.none,
                ),
              ),
              child: ExcludeSemantics(
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    fontSize: Fs.cap,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    color: active ? pal.onAccent : pal.ink3,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 52),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          constraints: const BoxConstraints(minHeight: 40),
                          alignment: Alignment.centerLeft,
                          child: TextField(
                            controller: _ctl[l.id],
                            focusNode: _focus[l.id],
                            // The app's keypad does the typing; a hardware
                            // keyboard still works.
                            keyboardType: TextInputType.none,
                            inputFormatters: const [edit.MathKeysFormatter()],
                            autocorrect: false,
                            enableSuggestions: false,
                            maxLines: 1,
                            cursorColor: pal.accent,
                            style: mathStyle(
                              context,
                              height: 1.4,
                            ).copyWith(letterSpacing: .2),
                            decoration: InputDecoration.collapsed(
                              hintText: 'Type or tap the keys below',
                              hintStyle: TextStyle(
                                fontSize: Fs.body,
                                color: pal.ink3,
                                letterSpacing: 0,
                              ),
                            ),
                            onChanged: (t) => state.setLineText(l.id, t),
                          ),
                        ),
                        if (hasText && res != null)
                          _result(context, state, l, res),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Opacity(
                    opacity: active ? 1 : .7,
                    child: IconBtn(
                      MIcon.close,
                      small: true,
                      label: 'Delete expression ${i + 1}',
                      onTap: () => _deleteLine(l.id),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _addLineRow(BuildContext context) {
    final pal = context.pal;
    return Pressable(
      onTap: _addLine,
      builder: (_, down) => Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: down ? pal.surface2 : pal.surface,
          border: Border(bottom: BorderSide(color: pal.line)),
        ),
        child: Row(
          children: [
            Ico(MIcon.plus, size: 18, color: pal.ink3),
            const SizedBox(width: 8),
            Text(
              'Add expression',
              style: TextStyle(fontSize: Fs.sm, color: pal.ink3),
            ),
          ],
        ),
      ),
    );
  }

  /* ---------- results ---------- */

  Widget _eq(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: Text(
      '=',
      style: mathStyle(context, size: Fs.lg, color: context.pal.ink3),
    ),
  );

  Widget _hint(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(text, style: TextStyle(fontSize: 13, color: context.pal.ink3)),
  );

  Widget _caption(BuildContext context, String text) => Text(
    text,
    style: TextStyle(fontSize: Fs.cap, color: context.pal.ink3),
  );

  Widget _result(
    BuildContext context,
    AppState state,
    LineModel l,
    EvalResult res,
  ) {
    final pal = context.pal, fmt = state.fmt;
    if (res.empty) return _hint(context, 'Finish the expression after “=”.');
    if (!res.ok) {
      return Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 4),
        child: ErrorNote(res.error!, hint: res.hint),
      );
    }
    final v = res.value!, st = mathStyle(context);
    Widget copyBtn(String what) => IconBtn(
      MIcon.copy,
      small: true,
      label: 'Copy $what',
      onTap: () => _copy(state.valueText(v)),
    );

    final parts = <Widget>[];
    if (v is double) {
      parts.add(
        Row(
          children: [
            _eq(context),
            Expanded(
              child: HScroll(child: NumText(v, fmt, style: st)),
            ),
            copyBtn('result'),
          ],
        ),
      );
    } else if (v is Mat) {
      parts.add(
        Row(
          children: [
            _eq(context),
            Expanded(child: HScroll(child: MatrixView(v, fmt))),
          ],
        ),
      );
      // Size on the left, actions on the right; the actions drop to their
      // own row when the line is too narrow for both.
      parts.add(
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '${v.rows}×${v.cols}${res.assign != null ? ' · saved as ${res.assign}' : ''}',
              style: TextStyle(fontSize: Fs.cap, color: pal.ink3),
            ),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TextBtn(
                  'Inspect',
                  icon: MIcon.eye,
                  compact: true,
                  onTap: () => openInspector(InspectTarget.line(l.id)),
                ),
                TextBtn(
                  'Save as matrix',
                  icon: MIcon.save,
                  compact: true,
                  onTap: () => saveAsMatrix(v),
                ),
                copyBtn('matrix'),
              ],
            ),
          ],
        ),
      );
    } else if (v is ListVal) {
      parts.add(
        Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: 14,
                runSpacing: 6,
                children: [
                  for (var i = 0; i < v.items.length; i++)
                    Text.rich(
                      TextSpan(
                        style: st,
                        children: [
                          const TextSpan(
                            text: 'λ',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                          sub('${i + 1}', st),
                          const TextSpan(text: ' = '),
                          ...complexSpans(v.items[i], fmt, st),
                        ],
                      ),
                      softWrap: false,
                    ),
                ],
              ),
            ),
            copyBtn('eigenvalues'),
          ],
        ),
      );
    } else if (v is MultiVal) {
      parts.add(
        _caption(
          context,
          v.relation != null
              ? '${v.relation} · tap a matrix to inspect it'
              : 'Tap a matrix to inspect it',
        ),
      );
      parts.add(
        HScroll(
          child: Row(
            children: [
              for (var i = 0; i < v.parts.length; i++)
                Padding(
                  padding: EdgeInsets.only(
                    right: i == v.parts.length - 1 ? 12 : 20,
                  ),
                  child: Pressable(
                    onTap: () =>
                        openInspector(InspectTarget.line(l.id, part: i)),
                    label: 'Inspect ${v.parts[i].label}',
                    builder: (_, down) => AnimatedContainer(
                      duration: Motion.fast,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: down ? pal.surface2 : null,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text(
                            v.parts[i].label,
                            style: mathStyle(
                              context,
                              size: Fs.lg,
                              italic: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _eq(context),
                          MatrixView(v.parts[i].value, fmt),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    } else if (v is PolyVal) {
      parts.add(
        Row(
          children: [
            _eq(context),
            Expanded(
              child: HScroll(
                child: Text.rich(
                  TextSpan(children: polySpans(v.coeffs, fmt, st), style: st),
                  softWrap: false,
                ),
              ),
            ),
          ],
        ),
      );
      parts.add(_caption(context, 'p(λ) = det(λI − A)'));
    } else if (v is TextVal) {
      parts.add(_hint(context, v.text));
    }

    for (final w in res.warnings) {
      parts.add(
        Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: pal.noteSoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Ico(MIcon.info, size: 16, color: pal.note),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  w,
                  style: TextStyle(fontSize: 13, height: 1.4, color: pal.note),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < parts.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            parts[i],
          ],
        ],
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  _DashedBorder(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rr = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(.5),
      const Radius.circular(16),
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color;
    for (final metric in (Path()..addRRect(rr)).computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 7) {
        canvas.drawPath(metric.extractPath(d, d + 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => old.color != color;
}
