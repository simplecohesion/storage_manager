# Repository Guidelines

## Project structure & module organization

- `lib/`: package source. Public entry point is `lib/storage_manager.dart` (export surface).
  - `lib/core/`: platform/file abstractions (`LocalFile`, web vs native implementations).
  - `lib/controllers/`, `lib/models/`, `lib/enums/`, `lib/widgets/`: feature modules.
- `test/`: Flutter tests (files named `*_test.dart`).
- Root config: `pubspec.yaml`, `analysis_options.yaml` (includes `very_good_analysis`), `CHANGELOG.md`.

## Build, test, and development commands

- `flutter pub get`: install dependencies (includes a Git dependency via `flutter_download_manager`).
- `flutter analyze`: run static analysis/lints.
- `dart format .`: format all Dart files.
- `flutter test`: run unit tests in `test/`.
- `flutter test --coverage`: generate coverage output under `coverage/` (optional).

## Coding style & naming conventions

- Use Dart defaults: 2-space indentation, trailing commas for nicer formatting.
- Naming: files `snake_case.dart`, classes/types `PascalCase`, members `camelCase`.
- Keep the public API deliberate: add/adjust exports in `lib/storage_manager.dart` when promoting new APIs.
- Prefer platform-safe boundaries: keep `dart:io` usage out of web-facing code unless properly isolated/guarded.

## Testing guidelines

- Add tests for new behavior and regressions; place them in `test/` and name them `*_test.dart`.
- When changing file/path logic, consider both web and native flows (`lib/core/`).

## Commit & pull request guidelines

- Follow commit patterns used in history when possible: `feat:`, `fix:`, `chore(deps):`, `style:` (use `feat!:`/`fix!:` for breaking changes).
- PRs should include: a clear description (what/why), commands run (e.g. `flutter analyze`, `flutter test`), and any user-facing changes noted in `CHANGELOG.md`.
