import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../app/app_state.dart';
import '../app/models.dart';
import '../engine/engine.dart';
import 'drawer.dart';
import 'glance.dart';
import 'icons.dart';
import 'inspector_screen.dart';
import 'keypad.dart';
import 'layout.dart';
import 'library_screen.dart';
import 'math_view.dart';
import 'matrix_card.dart';
import 'matrix_editor.dart';
import 'more_screens.dart';
import 'scope.dart';
import 'side_pane.dart';
import 'text_edit.dart' as edit;
import 'theme.dart';
import 'tutorial_screen.dart';
import 'widgets.dart';

/// A screen opened from the workspace: one of the menu destinations, or
/// the inspector for a specific matrix.
class _Screen {
  const _Screen(this.name, [this.inspect]);
  final String name;
  final InspectTarget? inspect;

  String get key =>
      '$name/${inspect?.matrixId}/${inspect?.lineId}/${inspect?.part}';
}

/// How the matrices are listed above the expressions.
enum _Rail { cards, chips, none }

/// The app's home: the workspace, arranged for whatever window and fold
/// posture it finds itself in (see [AppLayout]).
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

  LayoutInfo _info = const LayoutInfo(AppLayout.compact);

  /// The screen shown in a pane (layouts that don't push full-screen).
  _Screen? _pane;

  /// Screens currently pushed full-screen on top of the workspace.
  int _pushed = 0;

  bool _tourOpen = false;

  AppState get _state => AppScope.read(context);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final raised = _scroll.offset > 4;
      if (raised != _raised) setState(() => _raised = raised);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowTour());
  }

  /// Shows the tour the first time the app is opened. A cover screen is too
  /// small for it, so there it waits until the phone is unfolded.
  void _maybeShowTour() {
    if (!mounted || _tourOpen) return;
    final state = _state;
    if (state.tutorialSeen || _info.layout == AppLayout.glance) return;
    _tourOpen = true;
    TutorialScreen.show(context).whenComplete(() {
      _tourOpen = false;
      state.markTutorialSeen();
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

  /// Reacts to the window being resized, rotated, folded or unfolded.
  void _applyLayout(LayoutInfo info) {
    final old = _info;
    if (old == info) return;
    _info = info;
    if (old.layout == info.layout) return;
    if (old.layout == AppLayout.glance) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowTour());
    }
    // A screen can't carry over between "pushed full-screen" and "in a
    // pane", or between panes that sit in different places.
    if (info.pushesScreens || old.hasDetail != info.hasDetail) _pane = null;
    if (!info.pushesScreens && _pushed > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
      });
    }
    if (!info.pushesScreens) _collapsed = false;
  }

  FocusNode _makeFocus(String id) {
    final node = FocusNode(onKeyEvent: (_, e) => _onHardwareKey(id, e));
    node.addListener(() {
      if (!node.hasFocus || !mounted) return;
      if (_activeId != id || _collapsed) {
        // Moving to another line finishes the one being left.
        if (_activeId != id) _recordActive();
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

  /// Makes [id] the active line, puts the caret in it and scrolls it into
  /// view. [delay] holds the scroll back until a closing screen is out of
  /// the way, so the movement can be seen.
  void _focusLine(
    String id, {
    bool atEnd = true,
    Duration delay = Duration.zero,
  }) {
    setState(() => _activeId = id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      void focus() {
        final node = _focus[id], c = _ctl[id];
        if (!mounted || node == null || c == null) return;
        node.requestFocus();
        if (atEnd) {
          c.selection = TextSelection.collapsed(offset: c.text.length);
        }
      }

      // A line far off-screen isn't built yet; it gets its caret once the
      // scroll has brought it into being.
      final built = _lineKeys[id]?.currentContext != null;
      if (built) focus();
      _reveal(id, delay: delay).then((_) {
        if (!built) focus();
      });
    });
  }

  /// Counts calls to [_reveal], so that only the latest one moves the list.
  int _revealCall = 0;

  /// Scrolls smoothly until line [id] is fully on screen. Does nothing if
  /// it already is. A later call takes over from an earlier one.
  Future<void> _reveal(String id, {Duration delay = Duration.zero}) async {
    final call = ++_revealCall;
    bool stale() => call != _revealCall || !mounted || !_scroll.hasClients;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    for (var pass = 0; pass < 3; pass++) {
      if (stale()) return;
      final ctx = _lineKeys[id]?.currentContext;
      if (ctx != null) {
        // Below the view: bring its end up. Above it: bring its start down.
        for (final policy in const [
          ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
          ScrollPositionAlignmentPolicy.keepVisibleAtStart,
        ]) {
          if (stale() || !ctx.mounted) return;
          await Scrollable.ensureVisible(
            ctx,
            alignmentPolicy: policy,
            duration: Motion.slow,
            curve: Motion.easeOut,
          );
        }
        return;
      }
      // Not built yet: head for roughly the right place, then look again.
      final lines = _state.ws.lines;
      final idx = lines.indexWhere((l) => l.id == id);
      if (idx < 0) return;
      await _scroll.animateTo(
        _scroll.position.maxScrollExtent * (idx + 1) / lines.length,
        duration: Motion.slow,
        curve: Motion.easeOut,
      );
      if (stale()) return;
      await WidgetsBinding.instance.endOfFrame;
    }
  }

  /// How long to wait before scrolling after another screen closes.
  Duration get _afterClose =>
      _info.pushesScreens ? const Duration(milliseconds: 250) : Duration.zero;

  /// Puts the line being worked on into history, if it has a result.
  void _recordActive() {
    final id = _activeId;
    if (id != null) _state.commitLine(id);
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
    // Show where it went: the line may be scrolled out of view.
    if (_activeId != null) _reveal(_activeId!, delay: _afterClose);
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
    state.commitLine(line.id);
    _focusLine(line.id, delay: _afterClose);
  }

  @override
  void openEditor(String matrixId, {bool isNew = false}) =>
      showMatrixEditor(context, matrixId: matrixId, host: this);

  @override
  void openInspector(InspectTarget target) => _open(_Screen('inspect', target));

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

  /* ---------- screens ---------- */

  Widget _screenFor(_Screen s) => switch (s.name) {
    'workspaces' => const WorkspacesScreen(),
    'history' => HistoryScreen(host: this),
    'library' => LibraryScreen(host: this),
    'settings' => const SettingsScreen(),
    'help' => HelpScreen(host: this),
    _ => InspectorScreen(target: s.inspect, host: this),
  };

  /// Opens a screen: pushed full-screen on phones, in a pane elsewhere.
  void _open(_Screen s) {
    // Whatever was being typed counts as finished, so History has it.
    _recordActive();
    if (_info.pushesScreens) {
      FocusManager.instance.primaryFocus?.unfocus();
      _pushed++;
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => _screenFor(s)))
          .whenComplete(() => _pushed--);
    } else {
      setState(() => _pane = s);
    }
  }

  void _go(String to) => _open(_Screen(to));

  void _closePane() => setState(() => _pane = null);

  /// What the always-on inspector shows: the active line if it gives a
  /// matrix, else the latest line that does, else the first valid matrix.
  InspectTarget? _autoInspect(AppState state) {
    bool matrixLike(String? id) {
      final r = id == null ? null : state.lineResults[id];
      return r != null && r.ok && (r.value is Mat || r.value is MultiVal);
    }

    if (matrixLike(_activeId)) return InspectTarget.line(_activeId!);
    for (final l in state.ws.lines.reversed) {
      if (matrixLike(l.id)) return InspectTarget.line(l.id);
    }
    for (final m in state.ws.matrices) {
      if (state.matResults[m.id]?.ok ?? false) {
        return InspectTarget.matrix(m.id);
      }
    }
    return null;
  }

  /* ---------- build ---------- */

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context), pal = context.pal;
    final info = LayoutInfo.of(context);
    _sync(state);
    _applyLayout(info);
    final size = MediaQuery.sizeOf(context);

    final Widget body;
    switch (info.layout) {
      case AppLayout.glance:
        body = GlanceView(state: state);

      case AppLayout.compact:
        body = _withDrawer(
          state,
          Column(
            children: [
              _topBar(context, state.ws),
              Expanded(child: _content(context, state, _Rail.cards)),
              _keypad(context, state, rowHeight: size.height < 600 ? 38 : 44),
            ],
          ),
        );

      case AppLayout.landscape:
        // A phone on its side: results on the left, keypad on the right.
        body = _withDrawer(
          state,
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    _topBar(context, state.ws),
                    Expanded(child: _content(context, state, _Rail.chips)),
                  ],
                ),
              ),
              Container(width: 1, color: pal.line),
              SizedBox(
                width: math.min(420, size.width * .5),
                child: _keypad(
                  context,
                  state,
                  fill: true,
                  topInset: MediaQuery.paddingOf(context).top,
                ),
              ),
            ],
          ),
        );

      case AppLayout.medium:
        body = Row(
          children: [
            _side(state),
            Expanded(
              child: _pane == null
                  ? _mainColumn(context, state)
                  : _embedded(PaneKind.column),
            ),
          ],
        );

      case AppLayout.expanded:
        final detailW = LayoutInfo.detailWidth(size.width);
        final mainW = size.width - sideWidth - detailW;
        body = Row(
          children: [
            _side(state),
            Expanded(
              child: _mainColumn(
                context,
                state,
                dual: mainW >= dualKeypadWidth,
                hPad: 16,
              ),
            ),
            Container(
              width: detailW,
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: pal.line)),
              ),
              child: _detail(state),
            ),
          ],
        );

      case AppLayout.book:
        // Workspace left of the fold, inspector right of it.
        body = Row(
          children: [
            SizedBox(
              width: info.fold.left,
              child: _withDrawer(
                state,
                Column(
                  children: [
                    _topBar(context, state.ws),
                    Expanded(child: _content(context, state, _Rail.cards)),
                    _keypad(context, state),
                  ],
                ),
              ),
            ),
            _Hinge(width: info.fold.width),
            Expanded(child: _detail(state)),
          ],
        );

      case AppLayout.tabletop:
        // Results above the fold, a full-height keypad below it.
        body = Column(
          children: [
            SizedBox(
              height: info.fold.top,
              child: MediaQuery.removePadding(
                context: context,
                removeBottom: true,
                child: _pane == null
                    ? _withDrawer(
                        state,
                        Column(
                          children: [
                            _topBar(context, state.ws),
                            Expanded(
                              child: _content(context, state, _Rail.chips),
                            ),
                          ],
                        ),
                      )
                    : _embedded(PaneKind.column),
              ),
            ),
            _Hinge(height: info.fold.height),
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: _keypad(context, state, fill: true),
              ),
            ),
          ],
        );
    }

    return Scaffold(
      backgroundColor: pal.bg,
      body: SafeArea(top: false, bottom: false, child: body),
    );
  }

  /// Wraps a pane in the scaffold that owns the side menu, so the menu and
  /// its scrim stay inside that pane.
  Widget _withDrawer(AppState state, Widget child) => Scaffold(
    key: _scaffold,
    backgroundColor: context.pal.bg,
    drawerScrimColor: context.pal.scrim,
    drawer: MenuDrawer(
      workspaceName: state.ws.name,
      onNavigate: (to) {
        _scaffold.currentState?.closeDrawer();
        _go(to);
      },
    ),
    body: child,
  );

  Widget _side(AppState state) => SidePane(
    state: state,
    current: _pane?.name,
    onNavigate: _go,
    onNewMatrix: _newMatrix,
    onEditMatrix: openEditor,
  );

  /// Workspace column of the sidebar layouts: matrices live in the sidebar.
  Widget _mainColumn(
    BuildContext context,
    AppState state, {
    bool dual = false,
    double hPad = 8,
  }) => Column(
    children: [
      _topBar(context, state.ws, side: true),
      Expanded(child: _content(context, state, _Rail.none)),
      _keypad(context, state, dual: dual, hPad: hPad),
    ],
  );

  /// A screen shown in place of the workspace column.
  Widget _embedded(PaneKind kind) {
    final s = _pane!;
    return PaneScope(
      kind: kind,
      onClose: _closePane,
      child: _Entering(key: ValueKey(s.key), child: _screenFor(s)),
    );
  }

  /// The detail pane: an opened screen, or the inspector following along.
  Widget _detail(AppState state) {
    if (_pane != null) return _embedded(PaneKind.detail);
    return PaneScope(
      kind: PaneKind.detail,
      onClose: null,
      child: InspectorScreen(
        target: _autoInspect(state),
        host: this,
        auto: true,
      ),
    );
  }

  Widget _keypad(
    BuildContext context,
    AppState state, {
    bool fill = false,
    bool dual = false,
    double hPad = 8,
    double rowHeight = 44,
    double topInset = 0,
  }) => Keypad(
    page: _page,
    collapsed: _collapsed,
    degrees: state.settings.degrees,
    names: [for (final m in state.ws.matrices) m.name],
    fill: fill,
    dual: dual,
    collapsible: !fill,
    topBorder: !fill,
    hPad: hPad,
    rowHeight: rowHeight,
    topInset: topInset,
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
  );

  /// Top bar. With a sidebar ([side]) the menu button and wordmark move
  /// there and the workspace name becomes the title.
  Widget _topBar(BuildContext context, Workspace ws, {bool side = false}) {
    final pal = context.pal;
    final title = Pressable(
      onTap: () => _go('workspaces'),
      label: 'Switch workspace. Current: ${ws.name}',
      builder: (_, down) => AnimatedContainer(
        duration: Motion.fast,
        padding: EdgeInsets.symmetric(horizontal: side ? 12 : 8, vertical: 4),
        alignment: side ? Alignment.centerLeft : null,
        decoration: BoxDecoration(
          color: down ? pal.surface2 : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: side
            ? Text(
                ws.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: mathStyle(
                  context,
                  size: Fs.xl,
                  weight: FontWeight.w600,
                  height: 1.25,
                ),
              )
            : Column(
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
    );
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
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
          if (!side)
            IconBtn(
              MIcon.menu,
              label: 'Open menu',
              onTap: () {
                FocusManager.instance.primaryFocus?.unfocus();
                _scaffold.currentState?.openDrawer();
              },
            ),
          Expanded(child: title),
          IconBtn(
            MIcon.book,
            label: 'Operations library',
            onTap: () => _go('library'),
          ),
        ],
      ),
    );
  }

  /// The scrolling part: matrices (unless they're in the sidebar) and the
  /// expression lines.
  Widget _content(BuildContext context, AppState state, _Rail rail) {
    final pal = context.pal, ws = state.ws;
    return CustomScrollView(
      controller: _scroll,
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (rail != _Rail.none) ...[
                SectionHead(
                  'Matrices',
                  action: TextBtn('New', icon: MIcon.plus, onTap: _newMatrix),
                ),
                _matrixRail(context, state, chips: rail == _Rail.chips),
                const SizedBox(height: 8),
              ],
              SectionHead(
                'Expressions',
                action: TextBtn(
                  'History',
                  icon: MIcon.clock,
                  onTap: () => _go('history'),
                ),
              ),
              Container(height: 1, color: pal.line),
            ],
          ),
        ),
        // Lines can be dragged by their numbered strip to reorder them.
        SliverReorderableList(
          itemCount: ws.lines.length,
          itemBuilder: (context, i) => _line(context, state, ws.lines[i], i),
          onReorderItem: state.moveLine,
          proxyDecorator: (child, _, _) => _lifted(child, 0),
        ),
        SliverToBoxAdapter(child: _addLineRow(context)),
        const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
      ],
    );
  }

  /// How a line or matrix card looks while it is being dragged.
  Widget _lifted(Widget child, double radius) => Material(
    type: MaterialType.transparency,
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: context.pal.sheetShadow,
            offset: const Offset(0, 6),
            blurRadius: 18,
          ),
        ],
      ),
      child: child,
    ),
  );

  Widget _matrixRail(
    BuildContext context,
    AppState state, {
    required bool chips,
  }) {
    final mats = state.ws.matrices;
    return SizedBox(
      height: chips ? 46 : 136,
      child: CustomScrollView(
        controller: _rail,
        scrollDirection: Axis.horizontal,
        slivers: [
          // Drag a card by its handle, or hold the card and then drag.
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 2, 0, 2),
            sliver: SliverReorderableList(
              itemCount: mats.length,
              itemBuilder: (context, i) {
                final m = mats[i];
                return Padding(
                  key: ValueKey(m.id),
                  padding: const EdgeInsets.only(right: 10),
                  child: ReorderableDelayedDragStartListener(
                    index: i,
                    child: MatrixCard(
                      model: m,
                      eval: state.matResults[m.id],
                      fmt: state.fmt,
                      chip: chips,
                      onTap: () => openEditor(m.id),
                      handle: ReorderableDragStartListener(
                        index: i,
                        child: Semantics(
                          label: 'Drag to reorder matrix ${m.name}',
                          container: true,
                          child: Grip(
                            width: chips ? 26 : 32,
                            height: chips ? 40 : 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
              onReorderItem: state.moveMatrix,
              proxyDecorator: (child, _, _) => _lifted(child, 16),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(0, 2, 16, 2),
            sliver: SliverToBoxAdapter(
              child: NewMatrixCard(onTap: _newMatrix, chip: chips),
            ),
          ),
        ],
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
            // The whole strip is the handle for dragging the line up or down.
            child: ReorderableDragStartListener(
              index: i,
              child: Semantics(
                label: 'Line ${i + 1}. Drag to reorder',
                container: true,
                excludeSemantics: true,
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: Fs.cap,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                          color: active ? pal.onAccent : pal.ink3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Opacity(
                        opacity: .6,
                        child: Ico(
                          MIcon.grip,
                          size: 14,
                          color: active ? pal.onAccent : pal.ink3,
                        ),
                      ),
                    ],
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

/// The strip over a fold: nothing interactive is ever placed on it.
class _Hinge extends StatelessWidget {
  const _Hinge({this.width, this.height});
  final double? width, height;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return ExcludeSemantics(
      child: Container(
        width: width,
        height: height,
        color: pal.surface2,
        alignment: Alignment.center,
        child: Container(
          width: width == null ? null : 1,
          height: height == null ? null : 1,
          color: pal.lineStrong,
        ),
      ),
    );
  }
}

/// Fades and slides a screen in when it appears in a pane.
class _Entering extends StatelessWidget {
  const _Entering({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: Motion.base,
    curve: Motion.easeOut,
    builder: (_, t, child) => Opacity(
      opacity: t,
      child: Transform.translate(offset: Offset(24 * (1 - t), 0), child: child),
    ),
    child: child,
  );
}
