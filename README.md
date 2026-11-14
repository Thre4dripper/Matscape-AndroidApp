# Matscape

A matrix calculator for Android and iOS. Keep matrices at the top of a
workspace, write expressions underneath, and every line recalculates as
you type.

Matscape 2 is a ground-up rewrite in Flutter. Version 1 (native Android)
lives on the `main` branch history.

## What it does

- Workspaces of named matrices and expression lines, saved on the device
- Entries can be expressions: `sin(π/6)`, `2√3`, `1/3`
- Exact results where possible: fractions, square roots, multiples of π
- Arithmetic, powers, inverse, transpose, determinant, trace, rank, RREF,
  null and column space, linear systems
- Eigenvalues and eigenvectors, characteristic polynomial
- LU, QR, Cholesky and SVD decompositions, pseudo-inverse, norms, condition number
- Matrix functions: `expm`, `sinm`, `cosm`, `sqrtm`
- Step-by-step solutions for any expression: one step per operation, each
  opening to show the working, with a choice of method where there is one
  (cofactor expansion or row reduction; the 2×2 formula, Gauss–Jordan or the
  adjugate; elimination, Cramer’s rule or the inverse; Gram–Schmidt for QR;
  AᵀA for the SVD). Working is complete at every size the editor allows:
  every entry of a product, every minor of an adjugate, a cofactor expansion
  followed all the way down to 2×2. It is built only when a step is opened,
  on another isolate behind a loader when it is long, and drawn lazily
- Copy as plain text or as LaTeX (Settings → Copying): results as `bmatrix`
  and fractions, a whole solution as an `align*` block
- Inspector with properties and step-by-step determinant, inverse and RREF
- An operations library with a page for each operation: what it means, how
  to write it, worked examples and a button to try them
- Twelve sample workspaces, one per topic, and a tour on first launch
- Matrices and expressions can be dragged into a different order
- Everything is calculated on the device. The only thing that ever leaves it
  is optional backup and sync to the user's own Google Drive
- Backup & sync (Settings): Google Sign-In with only the `drive.appdata`
  permission. Each device writes `sync-<device id>.json` to the hidden app
  folder of the user's Drive and merges the others' files: newest change per
  workspace wins, an unseen change on two devices keeps both, deletions and
  history clears carry over. No server of ours is involved

## One app, every screen

The layout follows the window size and, on foldables, how the device is
folded (`lib/ui/layout.dart`):

| Layout | When | What you get |
| --- | --- | --- |
| Compact | Phones, closed foldables | Single column, keypad at the bottom |
| Landscape | A phone on its side | Results on the left, keypad on the right |
| Medium | Small tablets (600px and wider) | Sidebar with navigation and matrices, workspace beside it |
| Expanded | Large tablets (1000px and wider) | Sidebar, workspace and a live inspector; two keypad pages when there is room |
| Book | Foldable opened flat | Workspace on one side of the fold, inspector on the other |
| Tabletop | Foldable half-open on a desk | Results above the fold, full-height keypad below |
| Glance | Small cover screens | Read-only latest results |

## Project layout

```
lib/
  engine/   Math engine — pure Dart, shared by both platforms
  app/      Data model, app state and storage
  ui/       Screens and widgets
test/       Engine tests, parity tests against the design prototype, app tests,
            and checks that every sample workspace and library example works
```

The engine has no Flutter dependency: `lib/engine/engine.dart` is the whole
public surface (`evaluate`, `explain`, `describe`, decompositions).

`explain` (in `lib/engine/steps.dart`) is what the Steps screen shows. It
evaluates the expression while keeping the value of every part, then walks
it in the order it is worked out and writes one step per operation. The
tests in `test/steps_complex_test.dart` type each step back into the
evaluator and check every line of arithmetic in the working, so a step can
never show a number the engine would not give.

The one place working stops short is cofactor expansion above 8×8, which
would need n!/2 two-by-two determinants (1.8 million for a 10×10). There it
expands one level and row reduction carries the complete working. Matrices
that large only come from functions such as `kron`; the editor stops at 8×8.

`lib/engine/latex.dart` turns values, expressions and lines of working into
LaTeX. No LaTeX compiler runs in the tests: `test/latex_test.dart` checks the
output is well formed (balanced braces and environments, known commands, no
symbol left unconverted).

## Sync

- `lib/app/sync_merge.dart`: the merge, pure Dart; `test/sync_merge_test.dart`
  pins every rule and that all devices converge in any order.
- `lib/app/drive_store.dart`: Drive v3 REST on `dart:io`, no Google API
  package.
- `lib/app/google_account.dart`: `google_sign_in` 7.x, asking only for
  `drive.appdata`.
- `lib/app/sync.dart`: when to sync and the device's own bookkeeping, kept
  in a folder the platform never backs up so a restored phone doesn't reuse
  its old phone's id. Other devices' changes come in on opening, on coming
  back to the app and on Sync now, so nothing changes under the user; this
  device's edits go out a few seconds after a pause and on leaving. "Live"
  (per device, off by default) also looks every 30 seconds while open.
- `lib/app/matrix_draft.dart`: the matrix editor's draft, with undo and redo;
  a matrix changes only when the editor's Done saves it.
- `lib/app/google_config.dart` and `ios/Runner/Info.plist` hold the Google
  Cloud client ids. With the ids empty, Settings says sync isn't available in
  this build.

## Site

`site/` is the public home page, privacy policy and support page, published
to GitHub Pages by `.github/workflows/pages.yml`. Google's sign-in consent
screen and both stores link to it. Plain HTML and CSS, in the app's colours,
with a Latin-only copy of the brand font.

## Design

`design/` is the design project (Open Design, which is compatible with
Claude Design): the HTML prototype, the layout boards, the brand files and
the sources of the store pictures and films. Open Design opens it straight
from this folder and edits it in place. Only its source is committed.

To open it in Open Design on a new machine: in Open Design's settings, add
this repository's folder as a project location and scan. `design/` is the
only folder in it with a project file, so it is the only one imported.

The app leads and the design follows:

- `design/HANDOFF.md` lists every change to what a user sees that the design
  has not caught up with yet.
- `tool/screenshots.sh` renders the real app into `design/reference/`, one
  picture per screen and device, for the designer to work from.

The prompt for the design tool is always the same: "Read `HANDOFF.md` and
bring the design up to date, using the pictures in `reference/` as the truth
for how the app looks."

## Developing

```bash
flutter pub get
flutter test
flutter run
```

Release builds:

```bash
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
flutter build ipa --release --obfuscate --split-debug-info=build/symbols
```

`--obfuscate --split-debug-info` makes the compiled Dart code about a fifth
smaller. Keep the `build/symbols` folder of each release you ship: it is what
turns a crash's stack trace back into readable names
(`flutter symbolize -i trace.txt -d build/symbols/app.android-arm64.symbols`).

For a single APK to sideload, build one per CPU type instead of one that
carries all three:

```bash
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/symbols
```

## Versions

Releases are numbered `year.quarter.counter`, for example `2026.4.2`. The
counter starts at the month of the quarter and goes up by one with every
release in that quarter, manual or automated. The build number in
`pubspec.yaml` is the same version as one whole number — year, quarter,
two-digit counter — so `2026.4.2` is build `2026402`.

## App size

A phone downloads about 8 MB from Google Play. About 5.4 MB of that is the
Flutter engine, which every Flutter app carries; the rest is the app's own
code, the fonts (0.5 MB) and the Android runtime glue.

- Maths is set in STIX Two Text, bundled in full so matrices look the same
  on every device. The symbols that font lacks (√, ≤, →, ⋯ …) come from
  `STIXTwoMath-Symbols.otf`, a subset of STIX Two Math made with Flutter's
  `font-subset` tool (`bin/cache/artifacts/engine/<host>/font-subset` in
  the Flutter SDK). Superscript letters, such as the T of a transpose, are
  in no STIX font; they come from `NotoSerif-Superscripts.ttf`, cut from
  Noto Serif the same way.
- Icons are drawn from path data, so no icon font is bundled.
- The launcher icon's background is an XML gradient, not an image.

Android release signing reads `RELEASE_KEYSTORE_PATH`, `RELEASE_STORE_PASSWORD`,
`RELEASE_KEY_ALIAS` and `RELEASE_KEY_PASSWORD` from the environment or from
`android/local.properties`. Without them the release build is signed with the
debug key.

## Licence

See [LICENSE](LICENSE). The bundled STIX Two fonts and the Noto Serif superscripts
are under the SIL Open Font License (`assets/fonts/OFL.txt` and
`assets/fonts/OFL-NotoSerif.txt`).
