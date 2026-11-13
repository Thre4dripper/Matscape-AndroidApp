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
