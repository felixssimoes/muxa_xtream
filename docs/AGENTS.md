# Repository Guidelines

## Project Structure & Module Organization
- `lib/`: Public package code (entrypoint: `lib/muxa_xtream.dart`). Keep APIs small and documented.
- `test/`: Unit tests (e.g., `test/muxa_xtream_test.dart`). Mirror `lib/` structure; one `*_test.dart` per unit.
- `docs/`: Design notes and requirements.
- Root files: `pubspec.yaml` (deps, SDK), `analysis_options.yaml` (lints), `README.md`, `CHANGELOG.md`.

## Build, Test, and Development Commands
- Install deps: `flutter pub get` — resolves package dependencies.
- Run tests: `flutter test` — executes `flutter_test` suites.
- Coverage: `flutter test --coverage` — outputs `coverage/lcov.info`.
- Static analysis: `flutter analyze` — checks style and common issues.
- Format: `dart format .` — apply standard Dart formatting.
- Publish check: `flutter pub publish --dry-run` — validates package readiness.

## Coding Style & Naming Conventions
- Indentation: 2 spaces, no tabs. Use `dart format`.
- Lints: `flutter_lints` (see `analysis_options.yaml`). Fix all analyzer warnings.
- Files: `lowercase_with_underscores.dart` (e.g., `my_service.dart`).
- Types: `UpperCamelCase`; members/variables: `lowerCamelCase`; constants: `SCREAMING_SNAKE_CASE`.
- Public API lives under `lib/`; avoid exposing internals inadvertently.

## Testing Guidelines
- Framework: `flutter_test` with `test(...)` and `group(...)`.
- Location: place tests in `test/`; name files `*_test.dart`.
- Aim for fast, deterministic unit tests. Prefer pure Dart tests for logic.
- Run locally: `flutter test && flutter analyze && dart format --output=none --set-exit-if-changed .` before PRs.

## Commit & Pull Request Guidelines
- Commits: follow Conventional Commits (e.g., `feat: add parser`, `fix: handle null input`, `test: add edge cases`). Keep messages imperative and scoped.
- PRs: include a clear description, linked issues, and test coverage for changes. Screenshot logs only when relevant.
- Checks: ensure tests pass, analyzer is clean, and code is formatted. Update `CHANGELOG.md` and bump `version` in `pubspec.yaml` for releases.

## Security & Configuration Tips
- Do not commit secrets or `.dart_tool/`. Respect `environment` constraints in `pubspec.yaml`.
- Prefer relative imports within this package; avoid reaching outside `lib/`.
- For new APIs, add minimal docs in code and an example in `README.md`.
