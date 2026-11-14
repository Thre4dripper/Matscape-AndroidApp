# Matscape

A matrix calculator in Flutter for Android and iOS. `README.md` describes
what it does and how the code is laid out.

## Checks

Run all three before calling a change done:

```bash
dart format lib test tool
flutter analyze
flutter test
```

## Design handoff

`design/` is the Open Design project itself (Open Design is compatible with
Claude Design). Open Design opens it from here and edits it in place, so the
designer's changes show up in `git status` like any other change. The app is
the source of truth; the design follows it.

When a change alters what a user sees (a new screen or state, a changed
layout, a renamed button), do all of this as part of the same change:

1. Add an entry under "Waiting for design" in `design/HANDOFF.md`, with the
   next `H-` number: what changed in a designer's terms, the commits once
   they exist, what it affects, and which reference pictures show it.
2. If it is a new screen or state, add a scene for it to
   `tool/screenshots/render_test.dart`.
3. Run `tool/screenshots.sh`. It renders every scene from the real app into
   `design/reference/`, where the designer reads them.

Open Design writes into `design/` while it works. Don't edit design files
there during one of its runs, and don't commit them halfway through one.

`design/reference/` and the design's films, music and store pictures are
not committed: scripts make them again.
