# niscala

Flutter app (Dart SDK ^3.13, Flutter stable). Currently Android-only — there is no `ios/`, `web/`, or desktop platform folder.

## Commands

- `flutter pub get` — install dependencies
- `flutter analyze` — static analysis (lints from `flutter_lints`, see `analysis_options.yaml`)
- `flutter test` — run all tests; `flutter test test/<file>_test.dart` for one file
- `dart format .` — format code
- `flutter run` — run on a connected device/emulator

## Workflow

- Before calling a change done, `flutter analyze` must report no issues and `flutter test` must pass.
- Edited `.dart` files are auto-formatted by a hook in `.claude/settings.json`.
- Don't edit generated or build output: `build/`, `.dart_tool/`, `pubspec.lock` (change `pubspec.yaml` and run `flutter pub get` instead).

## CI

`.github/workflows/` runs Claude Code PR review (`claude-code-review.yml`) and `@claude` mentions (`claude.yml`).
