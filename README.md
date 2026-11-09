<h1 align="center">Gestura</h1>
<p align="center">Sign language, in your hands.</p>

<p align="center">
  <a href="https://github.com/Ziadabdellah/gestura/actions/workflows/ci.yml"><img src="https://github.com/Ziadabdellah/gestura/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <img src="https://img.shields.io/badge/Flutter-3.47-02569B?logo=flutter" alt="Flutter 3.47">
  <img src="https://img.shields.io/badge/Dart-3.13-0175C2?logo=dart" alt="Dart 3.13">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-0B6E69" alt="MIT license"></a>
</p>

Gestura is a Flutter app for Android and iOS, in development, that will teach the sign language of the European country you live in: short video lessons, spaced-repetition review and a dictionary that works offline. The interface will be available in English, Arabic, Russian, Spanish, French and German.

Every country has its own sign language, and each one is a full language with its own grammar. Gestura is meant as a learning companion, not a replacement for Deaf teachers and communities.

## Status

The project is built in phases. The foundation is in place:

| Part | What it is | Status |
|---|---|---|
| [`packages/gestura_ui`](packages/gestura_ui) | The design system: tokens, themes, fonts, components | Ready |
| [`packages/gestura_core`](packages/gestura_core) | Shared pure Dart logic | Ready |
| [`apps/gestura`](apps/gestura) | The Android and iOS app: three flavors and a first screen in six languages | In progress |

## Design system

<p align="center">
  <img src="packages/gestura_ui/test/src/components/goldens/macos/adaptive_phones.png" alt="The same screen on phones 320, 360, 412 and 430 dp wide, in English and in Arabic">
</p>

The images in this README are the golden files the tests compare against, so they always show the current code.

- **Palette.** A calm blue-green (Lagoon), a warm coral and a sun yellow, in light and dark themes. The brand colors are fixed, and every text and UI color pair is tested against WCAG 2.2 AA contrast.
- **Fonts.** Readex Pro for Latin and Arabic, with Golos Text as the fallback for Cyrillic. Both are bundled with the app, so no font is downloaded at runtime.
- **Adaptive scale.** The whole interface adapts to the phone it runs on, based on the screen's shortest side, so rotating the phone changes nothing:

  | Screen width | Text | Spacing and sizes |
  |---|---|---|
  | 320 dp | 100% | 90% |
  | 360 dp (design size) | 100% | 100% |
  | 412 dp | 112% | 114% |
  | 430 dp and wider | 112% | 115% |
  | Tablets | 100% | 100%, with a different layout instead |

  Text never shrinks below its design size, touch targets never drop below 48 dp, and the user's own text size setting is always applied on top.
- **Components.** `GButton`, `GCard`, `GChip`, `GSkeleton` and `GErrorView`, each with semantics labels, 48 dp touch targets, support for 200% text, reduced motion and right-to-left layouts.

<table>
  <tr>
    <td><img src="packages/gestura_ui/test/src/theme/goldens/macos/typography.png" alt="Type scale in English, Arabic and Russian, light and dark" width="400"></td>
    <td><img src="packages/gestura_ui/test/src/theme/goldens/macos/palette.png" alt="Color palette in light and dark" width="400"></td>
  </tr>
</table>

## Shared logic

`gestura_core` is pure Dart, with no Flutter or Firebase:

- **`Result<T>`** (`Ok` and `Err`) and a sealed **`Failure`** hierarchy, so errors are handled with exhaustive `switch` expressions instead of exceptions.
- **`normalizeForSearch`** for search that ignores Arabic diacritics and hamza forms, folds Arabic-Indic digits, Russian ё and German ß, and collapses whitespace.

## Architecture

A monorepo with pub workspaces and [melos](https://melos.invertase.dev) 8:

```
gestura/
├── pubspec.yaml          workspace and melos scripts
├── apps/
│   └── gestura/          the Android and iOS app
└── packages/
    ├── gestura_core/     pure Dart logic
    └── gestura_ui/       design system
```

- **Flavors.** `dev`, `staging` and `prod` on Android and iOS (Gradle product flavors, Xcode schemes and build configurations), each with its own application ID and name, so all three install side by side on one phone. Dev and staging builds show a corner banner.
- **Languages.** One ARB file per language (English, Arabic, Russian, Spanish, French and German), generated with `gen-l10n`. Tests check that every file has every message and that the plural rules of each language are right, including the six Arabic forms and the Russian ones.

The app will follow MVVM, keep its data offline-first, and use Firebase for sync.

## Quality

- GitHub Actions runs formatting, analysis and every test on each push and pull request, and fails if a comment is added to the code.
- [very_good_analysis](https://pub.dev/packages/very_good_analysis) with `--fatal-infos`: zero warnings and zero infos.
- Unit and widget tests, accessibility guideline tests (tap targets, labels and text contrast) on small phones, large phones and tablets, and at 200% text.
- Golden tests in English and Arabic, in light and dark.
- 100% line coverage in both packages; the app covers every line it owns.

## Getting started

Requirements: [fvm](https://fvm.app). The Flutter version is pinned in [`.fvmrc`](.fvmrc).

```bash
fvm install
fvm flutter pub get
fvm dart run melos run gen --no-select
fvm dart run melos run analyze --no-select
fvm dart run melos run test:dart --no-select
fvm dart run melos run test:flutter --no-select
```

The app also needs its Firebase config, which is not in the repository; see [Firebase setup](#firebase-setup). Then, to run the app on an Android device or an iOS simulator:

```bash
cd apps/gestura
fvm flutter run --flavor dev -t lib/main_dev.dart
```

To update the golden files after a UI change:

```bash
cd packages/gestura_ui
fvm flutter test --tags golden --update-goldens
```

## Firebase setup

Each flavor talks to Firebase: `dev` and `staging` share a development project, and `prod` has its own. The config files are not in the repository, so create your own two projects, install the [FlutterFire CLI](https://firebase.flutter.dev/docs/cli), and run this from `apps/gestura` for each flavor and each of its iOS build configurations (`Debug-<flavor>`, `Release-<flavor>` and `Profile-<flavor>`, plus the plain `Debug`, `Release` and `Profile` with the `prod` values):

```bash
flutterfire configure \
  --project=<project-id> \
  --platforms=android,ios \
  --out=lib/firebase/firebase_options_<flavor>.dart \
  --android-package-name=<application-id> \
  --android-out=android/app/src/<flavor>/google-services.json \
  --ios-bundle-id=<application-id> \
  --ios-build-config=<build-configuration> \
  --ios-out=ios/flavors/<flavor>/GoogleService-Info.plist
```

The application IDs are `app.gestura.com.dev`, `app.gestura.com.stg` and `app.gestura.com`. iOS builds call the FlutterFire CLI from an Xcode build phase, so it must be on your `PATH`.

## License

The code is released under the [MIT License](LICENSE). The Gestura name and logo, the sign language content and the bundled fonts are not covered by it; see [NOTICE.md](NOTICE.md).
