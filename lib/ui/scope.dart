import 'package:flutter/widgets.dart';

import '../app/app_state.dart';
import '../app/sync.dart';
import '../engine/engine.dart';
import 'math_view.dart';

/// Makes [AppState] available to the widget tree.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  /// The state; the calling widget rebuilds whenever it changes.
  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// The state, without subscribing to changes (for callbacks).
  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}

/// Makes the Google Drive sync available to the widget tree, where there is
/// one (not in tests that don't ask for it).
class SyncScope extends InheritedNotifier<SyncController> {
  const SyncScope({
    super.key,
    required SyncController sync,
    required super.child,
  }) : super(notifier: sync);

  static SyncController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SyncScope>()?.notifier;

  /// The controller without rebuilding when its status changes.
  static SyncController? read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<SyncScope>()?.notifier;
}

extension AppStateFmt on AppState {
  NumFmt get fmt => NumFmt.of(settings);
}

/// What the inspector is looking at: a saved matrix, or a line's result
/// (optionally one part of a decomposition).
class InspectTarget {
  const InspectTarget.matrix(String this.matrixId) : lineId = null, part = 0;
  const InspectTarget.line(String this.lineId, {this.part = 0})
    : matrixId = null;
  final String? matrixId;
  final String? lineId;
  final int part;
}

/// Actions other screens ask the workspace to perform after they close.
abstract interface class WorkspaceHost {
  /// Types [text] into the active line.
  void insertText(String text, {int back = 0});

  /// Puts [text] on an empty line (reusing one if available) and focuses it.
  void addLineWith(String text);

  void openEditor(String matrixId, {bool isNew = false});

  void openInspector(InspectTarget target);

  /// Shows line [lineId] worked out step by step.
  void openSteps(String lineId);

  void saveAsMatrix(Mat value);
}
