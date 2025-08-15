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
- Commits: use Conventional Commits with structured, multi-line messages.
  - Subject: `type(scope): concise summary` (imperative, max ~50 chars).
  - Blank line after subject.
  - Body: wrapped at ~72 cols; bullets for key changes; include “why” when helpful.
  - Prefer small scopes (e.g., `core`, `http`, `docs`, `tool`).
  - Tip: when committing via CLI, avoid literal `\n` in `-m` strings — Git does not interpret escapes.
    - Use multiple `-m` flags for paragraphs, or pipe a properly formatted message via stdin: `git commit -F - <<'MSG'` ... `MSG`.
    - Example:
      - `git commit -m "feat(url): add probe" -m "- Adds HEAD/Range probe\n- Adds tests"` (note: each `-m` is a new paragraph; for line breaks within a paragraph, prefer `-F -`).
      - `git commit -F - <<'MSG'\nfeat(url): add probe\n\n- Adds HEAD/Range probe\n- Adds tests\nMSG`
  - Examples:
    - `chore(core): complete Phase 0 bootstrap`
      
      - Add `lib/src/api.dart` and export from `lib/muxa_xtream.dart`.
      - Add `tool/verify.sh` (format, analyze, tests; fallbacks; auto-format).
      - Remove template Calculator and example test.
      - Mark Phase 0 done in `docs/DEVELOPMENT_PLAN.md`.
    - `feat(models): add user/server and catalog types`
      
      - Implement parsing with null-tolerant converters.
      - Add unit tests for required/optional fields.
- PRs: include a clear description, linked issues, and test coverage where applicable. Screenshot logs only when relevant.
- Checks: run `bash tool/verify.sh` locally; ensure format, analyze, and tests pass. Update `CHANGELOG.md` and bump `version` in `pubspec.yaml` for releases.

## Plan Updates (DEVELOPMENT_PLAN.md)
- Status rules:
  - When a phase’s first task is completed, set that phase status to `in progress`.
  - When all tasks in a phase are completed, set that phase status to `done`.
- Always tick completed tasks with `- [x]` and leave remaining as `- [ ]`.
- Update the plan in the same commit as the code/tests that fulfill a task.
- Work style: proceed task-by-task within the current `in progress` phase.
  - Pick the next unchecked task in the active phase and complete it end-to-end (code, tests, docs) before starting another.
  - Avoid batching multiple tasks from the same phase in a single PR/commit unless they are trivially coupled and cannot be validated independently.
  - Prefer one commit per task; ensure the message references the specific task.

## Examples & Demos
- Keep `example/` up-to-date with the public API.
  - Every time a new public API is added or changed, update `example/main.dart` to include a minimal usage snippet that exercises it.
  - Prefer mock-friendly flows (e.g., `--mock` flag) so examples run without external network access.
  - Update `example/README.md` with any new flags, outputs, or steps needed to try the new API.
  - Include the example updates and docs in the same commit as the API change.

## Security & Configuration Tips
- Do not commit secrets or `.dart_tool/`. Respect `environment` constraints in `pubspec.yaml`.
- Prefer relative imports within this package; avoid reaching outside `lib/`.
- For new APIs, add minimal docs in code and an example in `README.md`.
