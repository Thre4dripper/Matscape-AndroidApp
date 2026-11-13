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
- Inspector with properties and step-by-step determinant, inverse and RREF
- Everything is calculated on the device; nothing is sent anywhere

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
test/       Engine tests, parity tests against the design prototype, app tests
```

The engine has no Flutter dependency: `lib/engine/engine.dart` is the whole
public surface (`evaluate`, `describe`, decompositions, step-by-step helpers).

## Developing

```bash
flutter pub get
flutter test
flutter run
```

Release builds:

```bash
flutter build appbundle --release
flutter build ipa --release
```

Android release signing reads `RELEASE_KEYSTORE_PATH`, `RELEASE_STORE_PASSWORD`,
`RELEASE_KEY_ALIAS` and `RELEASE_KEY_PASSWORD` from the environment or from
`android/local.properties`. Without them the release build is signed with the
debug key.

## Licence

See [LICENSE](LICENSE). The bundled STIX Two Text fonts are under the SIL Open
Font License (`assets/fonts/OFL.txt`).
