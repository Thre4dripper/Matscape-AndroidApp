// The sample workspaces are teaching material: every line in them has to
// work, apart from the one that shows what an error looks like.
import 'package:flutter_test/flutter_test.dart';
import 'package:matscape/app/app_state.dart';
import 'package:matscape/app/storage.dart';

void main() {
  test('every sample workspace evaluates', () async {
    final state = AppState(MemoryStorage());
    await state.load();
    expect(state.workspaces.length, greaterThanOrEqualTo(12));
    expect(
      {for (final w in state.workspaces) w.name}.length,
      state.workspaces.length,
      reason: 'names are unique',
    );
    final problems = <String>[];
    for (final w in state.workspaces) {
      state.openWorkspace(w.id);
      for (final m in w.matrices) {
        if (!state.matResults[m.id]!.ok) problems.add('${w.name}: ${m.name}');
      }
      for (final l in w.lines) {
        final r = state.lineResults[l.id]!;
        // The showcase keeps one mismatched sum to show an error message.
        final meantToFail =
            w.name == 'Rotations & eigenvalues' && l.text == 'A + B';
        if (r.ok == meantToFail) {
          problems.add('${w.name}: ${l.text} → ${r.error}');
        }
      }
    }
    expect(problems, isEmpty);
  });
}
