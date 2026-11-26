# Worship Lamal — Agent Rules

## Stack

Flutter 3.9.2+ · Dart · Riverpod 3.x · GoRouter 14.x · Supabase Flutter 2.x · SharedPreferences · Material 3

## Architecture

Feature-first under `lib/features/{name}/` with `data/` (models, remote, repositories, local) and `presentation/` (providers, screens, widgets, utils). Cross-feature shared code lives in `lib/core/` or `lib/shared/widgets/`. Each feature must have a `*_feature.dart` barrel export.

## Data Flow (enforced)

`UI → Providers → Repositories → APIs/LocalStorage` — never skip a layer, never go backwards. No direct repository calls from widgets. All data flows through Riverpod providers.

## Cross-Feature Imports

Features may import another feature's **models only** via its `*_feature.dart` barrel. **Never** import another feature's providers or repositories directly. Navigation uses GoRouter with minimal data (IDs).

## Hard Constraints

1. **Do NOT refactor `features/favorites/`** — treat as a passive filter; leave as-is until told otherwise.
2. Use `git mv` when moving files to preserve git history.
3. No circular dependencies between features.
4. Providers: single-responsibility; use `.family` for parameterized state.
5. Widgets: stateless/dumb; accept data via constructor.

## Naming

Providers: `${feature}Provider`. Repositories: `${Feature}Repository`. Screens: `${Feature}Screen`. Barrels: `${feature}_feature.dart`. Models: plain name (`Song`, `Setlist`).

## Environment & Backend
- Config uses compile-time `--dart-define-from-file=.env` via `EnvConfig`. Never hardcode secrets or bundle `.env` in `pubspec.yaml`.
- Whenever a new key is added to `EnvConfig`, add its empty placeholder to `.env.example` and add a dummy `--dart-define` in `.github/workflows/ci.yml` if tests or builds require it.
- All Supabase schema changes, RLS policies, and Edge Functions must be stored in `supabase/migrations/` and `supabase/functions/`—never left only in the Dashboard.

## Git & VCS Workflow
- Always wrap git commands in `cmd /c` on Windows.
- **Branching:** Never commit feature or refactor work directly to `master`. Check `cmd /c git status` first; if on `master`, create a scoped branch (`feat/<name>`, `fix/<name>`, `refactor/<name>`, `docs/<name>`).
- **Commits:** Commit atomically after each passing batch using lowercase imperative format (`feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `ci:`). Always check `cmd /c git status` before staging to ensure `.env` or build artifacts are never staged.
- **Human Gate (Do NOT run automatically):** Never run `git merge` into `master`, `git push`, `git branch -d`, `git reset --hard`, or `git push --force`. Stop on the feature branch and report the commit hash for user review.

## Definition of Done (Before Finishing Any Task)
1. Run Dart MCP `analyze_files` (0 new errors) and `run_tests` (100% passing).
2. If files, Supabase tables/functions, routes, or Riverpod providers changed, update `ARCHITECTURE.md` (header `Last updated` date, Folder Tree, Data Model, Routing, Provider Graph, and Active Roadmap) without brittle line numbers.
3. Verify `.env` is untracked and commit the batch on the active feature branch.
4. Summarize changes, test counts, and the exact merge/push commands for the user.

## Testing

`mocktail` for mocks. Data layer: unit tests (mock APIs). Providers: provider tests (mock repositories). UI: widget/golden tests.

## Key Domain Concepts

Nashville Number System chords stored in DB, translated to letter chords at render time via `NashvilleHelper`. Key transposition via `KeyTransposer`. Two rendering paths: `RhythmBarRenderer` (rhythm charts) and `ChordLineRenderer` (legacy ChordPro lyrics).

## Windows Execution Rules

- **Prefer Dart MCP:** Use the `dart` MCP server tools for running tests, `pub`, and analyzing files whenever available.
- **Wrap CLI commands in `cmd /c`:** Always prefix terminal commands with `cmd /c` and pass `--no-pub` for Flutter test runs (e.g., `cmd /c flutter test --no-pub <path>`).
- **Never run bare `flutter test`, `dart analyze`, or `flutter pub get` in the agent terminal:** Bare commands hang on VS Code's active Dart SDK / `pubspec.lock` lock. Let VS Code auto-run `pub get` on `pubspec.yaml` save or use Dart MCP `pub`.
