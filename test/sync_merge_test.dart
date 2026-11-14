// Merging devices' copies of the data: every rule, and that every device
// reaches the same result whatever order the copies arrive in.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:matscape/app/models.dart';
import 'package:matscape/app/sync_merge.dart';

Workspace _ws(
  String id,
  int updated, {
  String? name,
  String line = 'A',
  int base = 0,
}) => Workspace(
  id: id,
  name: name ?? 'Workspace $id',
  updated: updated,
  base: base,
  matrices: [
    MatrixModel(
      id: '$id-a',
      name: 'A',
      cells: [
        ['1'],
      ],
    ),
  ],
  lines: [LineModel(line, id: '$id-l')],
);

SyncDoc _doc(
  String device, {
  List<Workspace> ws = const [],
  Map<String, int> deleted = const {},
  List<HistoryItem> history = const [],
  int cleared = 0,
  Map<String, dynamic> settings = const {},
  int settingsAt = 0,
  String? name,
}) => SyncDoc(
  device: device,
  deviceName: name ?? 'Device $device',
  savedAt: 0,
  workspaces: [for (final w in ws) w.copyWith()],
  deleted: Map.of(deleted),
  history: List.of(history),
  historyClearedAt: cleared,
  settings: Map.of(settings),
  settingsUpdated: settingsAt,
);

Map<String, String> _lines(SyncDoc d) => {
  for (final w in d.workspaces) w.id: w.lines.map((l) => l.text).join('|'),
};

void main() {
  test('a workspace new on another device is added', () {
    final (out, report) = merge(_doc('a', ws: [_ws('w1', 10)]), [
      _doc('b', ws: [_ws('w2', 20)]),
    ]);
    expect(out.workspaces.map((w) => w.id), ['w2', 'w1']);
    expect(report.added, 1);
    expect(report.conflicts, 0);
  });

  test('the later change wins when it was made on top of the other', () {
    // b synced w1 (base 10) and then edited it at 20.
    final (out, report) = merge(_doc('a', ws: [_ws('w1', 10, line: 'old')]), [
      _doc('b', ws: [_ws('w1', 20, line: 'new', base: 10)]),
    ]);
    expect(_lines(out), {'w1': 'new'});
    expect(report.updated, 1);
    expect(report.conflicts, 0);
    // The base belongs to the version: merging leaves it alone.
    expect(out.workspaces.single.base, 10);
  });

  test('two unseen changes to one workspace keep both', () {
    // Both edited w1 after syncing it at 10.
    final (out, report) = merge(
      _doc(
        'a',
        ws: [_ws('w1', 30, line: 'from a', base: 10)],
        name: 'Pixel',
      ),
      [
        _doc(
          'b',
          ws: [_ws('w1', 20, line: 'from b', base: 10)],
          name: 'iPad',
        ),
      ],
    );
    expect(report.conflicts, 1);
    expect(out.workspaces, hasLength(2));
    final kept = out.workspaces.firstWhere((w) => w.id == 'w1');
    final copy = out.workspaces.firstWhere((w) => w.id != 'w1');
    expect(kept.lines.single.text, 'from a');
    expect(copy.lines.single.text, 'from b');
    expect(copy.name, 'Workspace w1 (from iPad)');
  });

  test('the conflict copy is the same on every device, and made once', () {
    final a = _doc('a', ws: [_ws('w1', 30, line: 'from a', base: 10)]);
    final b = _doc('b', ws: [_ws('w1', 20, line: 'from b', base: 10)]);
    final (onA, _) = merge(a, [b]);
    final (onB, _) = merge(b, [a]);
    expect(
      onA.workspaces.map((w) => w.id).toSet(),
      onB.workspaces.map((w) => w.id).toSet(),
    );
    // Syncing again, with a device that still has the old file, adds nothing.
    final (again, report) = merge(onA, [onB, b]);
    expect(again.workspaces, hasLength(2));
    expect(report.conflicts, 0);
    expect(report.changed, isFalse);
  });

  test('same content on two devices is not a conflict', () {
    final (out, report) = merge(
      _doc('a', ws: [_ws('w1', 30, line: 'same', base: 10)]),
      [
        _doc('b', ws: [_ws('w1', 20, line: 'same', base: 10)]),
      ],
    );
    expect(out.workspaces, hasLength(1));
    expect(report.conflicts, 0);
  });

  test('a deletion wins over older changes', () {
    final (out, report) = merge(_doc('a', ws: [_ws('w1', 10)]), [
      _doc('b', deleted: {'w1': 15}),
    ]);
    expect(out.workspaces, isEmpty);
    expect(out.deleted, {'w1': 15});
    expect(report.removed, 1);
  });

  test('a change after the deletion brings the workspace back', () {
    final (out, _) = merge(_doc('a', ws: [_ws('w1', 20, line: 'kept')]), [
      _doc('b', deleted: {'w1': 15}),
    ]);
    expect(_lines(out), {'w1': 'kept'});
  });

  test('a delete leaves changes the deleting device never saw', () {
    // b deleted the version it had (10); a had already edited it at 20.
    final (out, report) = merge(
      _doc('a', ws: [_ws('w1', 20, line: 'unsent edit', base: 10)]),
      [
        _doc('b', deleted: {'w1': 10}),
      ],
    );
    expect(_lines(out), {'w1': 'unsent edit'});
    expect(report.removed, 0);
  });

  test('a late offline edit is kept even after the other device synced '
      'again', () {
    // a edited at 30 from 10 and synced twice; c only received a's version
    // (an older file that still rewrote the base). b edited at 20 from 10
    // while offline, and only now uploads.
    final docs = [
      _doc(
        'a',
        ws: [_ws('w1', 30, line: 'from a', base: 10)],
        name: 'Pixel',
      ),
      _doc(
        'c',
        ws: [_ws('w1', 30, line: 'from a', base: 30)],
        name: 'Mac',
      ),
      _doc(
        'b',
        ws: [_ws('w1', 20, line: 'from b', base: 10)],
        name: 'iPad',
      ),
    ];
    for (final local in docs) {
      final (out, _) = merge(local, [
        for (final d in docs)
          if (d != local) d,
      ]);
      expect(out.workspaces.map((w) => w.lines.single.text).toSet(), {
        'from a',
        'from b',
      }, reason: 'on ${local.device}');
    }
  });

  test('a deleted conflict copy is not made again', () {
    final a = _doc('a', ws: [_ws('w1', 30, line: 'from a', base: 10)]);
    final b = _doc('b', ws: [_ws('w1', 20, line: 'from b', base: 10)]);
    final (onA, _) = merge(a, [b]);
    final copyId = onA.workspaces.firstWhere((w) => w.id != 'w1').id;
    final afterDelete = _doc(
      'a',
      ws: [onA.workspaces.firstWhere((w) => w.id == 'w1')],
      deleted: {copyId: 40},
    );
    // b's file still has its old version.
    final (out, report) = merge(afterDelete, [b]);
    expect(out.workspaces.map((w) => w.id), ['w1']);
    expect(report.conflicts, 0);
  });

  test('samples from two devices are one sample', () {
    final s = seedWorkspaces();
    final (out, report) = merge(_doc('a', ws: s), [_doc('b', ws: s)]);
    expect(out.workspaces, hasLength(s.length));
    expect(report.changed, isFalse);
  });

  test('an edited sample beats a fresh install', () {
    final s = seedWorkspaces();
    final edited = s.first.copyWith(updated: 5000000000000)
      ..lines.first.text = 'my edit';
    final (out, report) = merge(_doc('new-phone', ws: s), [
      _doc('old-phone', ws: [edited, ...s.skip(1)]),
    ]);
    expect(out.workspaces.first.lines.first.text, 'my edit');
    expect(report.conflicts, 0);
  });

  test('the same sample edited on two devices keeps both edits', () {
    final s = seedWorkspaces().first;
    final onA = s.copyWith(updated: 5000000000002)..lines.first.text = 'a';
    final onB = s.copyWith(updated: 5000000000001)..lines.first.text = 'b';
    final (out, report) = merge(_doc('a', ws: [onA]), [
      _doc('b', ws: [onB]),
    ]);
    expect(report.conflicts, 1);
    expect(out.workspaces.map((w) => w.lines.first.text).toSet(), {'a', 'b'});
  });

  test('history is the union, newest first, without anything cleared', () {
    final (out, _) = merge(
      _doc(
        'a',
        history: [HistoryItem('det(A)', '43', 30), HistoryItem('A⁻¹', 'm', 5)],
        cleared: 10,
      ),
      [
        _doc(
          'b',
          history: [
            HistoryItem('det(A)', '43', 20),
            HistoryItem('tr(A)', '12', 25),
            HistoryItem('A+B', 'm', 8),
          ],
        ),
      ],
    );
    expect(out.history.map((h) => '${h.text}@${h.ts}'), [
      'det(A)@30',
      'tr(A)@25',
    ]);
    expect(out.historyClearedAt, 10);
  });

  test('history stays at its limit', () {
    final many = [for (var i = 0; i < 50; i++) HistoryItem('a$i', 's', i + 1)];
    final more = [
      for (var i = 0; i < 50; i++) HistoryItem('b$i', 's', i + 100),
    ];
    final (out, _) = merge(_doc('a', history: many), [
      _doc('b', history: more),
    ]);
    expect(out.history, hasLength(historyLimit));
    expect(out.history.first.text, 'b49');
  });

  test('settings come from the device that changed them last', () {
    final (out, _) = merge(
      _doc('a', settings: {'theme': 'dark'}, settingsAt: 5),
      [
        _doc('b', settings: {'theme': 'light'}, settingsAt: 9),
      ],
    );
    expect(out.settings['theme'], 'light');
    expect(out.settingsUpdated, 9);
  });

  test('every device gets the same result, in any order', () {
    final docs = [
      _doc(
        'a',
        ws: [
          _ws('w1', 30, line: 'a1', base: 10),
          _ws('w2', 12),
        ],
        history: [HistoryItem('x', '1', 3)],
        settings: {'exact': true},
        settingsAt: 4,
      ),
      _doc(
        'b',
        ws: [
          _ws('w1', 20, line: 'b1', base: 10),
          _ws('w3', 40),
        ],
        deleted: {'w2': 15},
        history: [HistoryItem('y', '2', 6)],
      ),
      _doc(
        'c',
        ws: [
          _ws('w1', 25, line: 'c1', base: 10),
          _ws('w4', 5),
        ],
        settings: {'exact': false},
        settingsAt: 8,
      ),
    ];
    String result(SyncDoc local, List<SyncDoc> others) {
      final (out, _) = merge(local, others);
      return out.fingerprint;
    }

    final expected = result(docs[0], [docs[1], docs[2]]);
    expect(result(docs[0], [docs[2], docs[1]]), expected);
    expect(result(docs[1], [docs[0], docs[2]]), expected);
    expect(result(docs[2], [docs[1], docs[0]]), expected);
    // Two copies for the two unseen changes to w1, and w2 stays deleted.
    final (out, _) = merge(docs[0], [docs[1], docs[2]]);
    expect(out.workspaces.map((w) => w.id), hasLength(5));
    expect(out.workspaces.any((w) => w.id == 'w2'), isFalse);
  });

  test('merging a result again changes nothing', () {
    final (once, _) = merge(
      _doc('a', ws: [_ws('w1', 30, line: 'a', base: 10)]),
      [
        _doc(
          'b',
          ws: [
            _ws('w1', 20, line: 'b', base: 10),
            _ws('w2', 5),
          ],
        ),
      ],
    );
    final (twice, report) = merge(once, [once]);
    expect(twice.fingerprint, once.fingerprint);
    expect(report.changed, isFalse);
  });

  test('a doc survives the trip through JSON', () {
    final d = _doc(
      'a',
      ws: [_ws('w1', 30, base: 10)],
      deleted: {'w9': 3},
      history: [HistoryItem('det(A)', '43', 7)],
      cleared: 2,
      settings: {'theme': 'dark'},
      settingsAt: 6,
    );
    final back = jsonDecode(jsonEncode(d)) as Map<String, dynamic>;
    expect(SyncDoc.fromJson(back).fingerprint, d.fingerprint);
  });
}
