# Worship Lamal — Agent Rules & Workflow

## Stack

Flutter 3.9.2+ · Dart · Riverpod 3.x · GoRouter 14.x · Supabase Flutter 2.x · SharedPreferences · Material 3

## Architecture & Data Flow

- **Feature-first:** Organize features under `lib/features/{name}/` with `data/` (`models`, `remote`, `repositories`, `local`) and `presentation/` (`providers`, `screens`, `widgets`, `utils`).
- **Shared code:** Cross-feature code lives in `lib/core/` or `lib/shared/widgets/`.
- **Barrels:** Every feature must expose a `*_feature.dart` barrel file.
- **Data Flow (enforced):** `UI → Providers → Repositories → APIs/LocalStorage` — never skip a layer or go backwards. No direct repository calls from widgets.
- **Cross-Feature Imports:** Features may import another feature's **models only** via its `*_feature.dart` barrel. **Never** import another feature's providers or repositories directly. Pass minimal data (IDs) through GoRouter.

## Hard Constraints

1. **Do NOT refactor `features/favorites/`** — treat it as a passive filter; leave it as-is until explicitly instructed.
2. Use `git mv` when moving files to preserve history.
3. No circular dependencies between features.
4. Providers: single-responsibility; use `.family` for parameterized state.
5. Widgets: keep stateless/dumb; accept data via constructor.

## Naming

- Providers: `${feature}Provider`
- Repositories: `${Feature}Repository`
- Screens: `${Feature}Screen`
- Barrels: `${feature}_feature.dart`
- Models: plain name (`Song`, `Setlist`)

## Key Domain Concepts

Nashville Number System chords are stored in the DB and translated to letter chords at render time via `NashvilleHelper`. Key transposition uses `KeyTransposer`. Two rendering paths exist: `RhythmBarRenderer` (rhythm charts) and `ChordLineRenderer` (legacy ChordPro lyrics).

## Environment & Backend

- Config uses compile-time `--dart-define-from-file=.env` via `EnvConfig`. Never hardcode secrets or bundle `.env` in `pubspec.yaml`.
- Whenever a new key is added to `EnvConfig`, add its empty placeholder to `.env.example` and add a dummy `--dart-define` in `.github/workflows/ci.yml` if tests or builds require it.
- All Supabase schema changes, RLS policies, and Edge Functions must be stored in `supabase/migrations/` and `supabase/functions/`—never left only in the Dashboard.

## Planning & Execution Workflow

- **Plan-First Gate:** For any task modifying 3+ files, adding new dependencies, or changing Supabase schemas/Edge Functions, present a concise batch plan and wait for user approval before editing files.

## Testing

- Use `mocktail` for mocks. Data layer: unit tests (mock APIs). Providers: provider tests (mock repositories). UI: widget/golden tests.
- **Test incrementally per layer:** Write and run the targeted test file via Dart MCP as each service, repository, or provider is created—do not write all production files before running tests.

## Git & VCS Workflow

- Always wrap git commands in `cmd /c` on Windows.
- **Branching:** Never commit feature or refactor work directly to `master`. Check `cmd /c git status` first; if on `master`, create a scoped branch (`feat/<name>`, `fix/<name>`, `refactor/<name>`, `docs/<name>`).
- **Commits:** Commit atomically after each passing batch using lowercase imperative format (`feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `ci:`). Always check `cmd /c git status` before staging to ensure `.env` or build artifacts are never staged.
- **Human Gate (Do NOT run automatically):** Never run `git merge` into `master`, `git push`, `git branch -d`, `git reset --hard`, or `git push --force`. Stop on the feature branch and report the commit hash for user review.

## Documentation & Roadmap Sync

- Whenever files, Supabase tables/functions, routes, or Riverpod providers change, update `ARCHITECTURE.md` (header `Last updated` date, Folder Tree, Data Model, Routing, and Provider Graph) without brittle line numbers.
- **Active Roadmap rules (`ARCHITECTURE.md`):**
  - Check off `[x]` an active roadmap item when its implementation passes tests.
  - Once all items in a milestone are checked off, remove the completed items so the roadmap only tracks active and upcoming work.
  - Never invent or append new `[ ]` roadmap items autonomously; only add new items when the user approves a feature plan.

## Definition of Done (Before Finishing Any Task)

1. **Verify (when `lib/`, `test/`, or `pubspec.yaml` changed):** Run Dart MCP `analyze_files` (0 new errors) and `run_tests` (100% passing). Skip Dart test runs on `web/`-, `supabase/`-, or docs-only batches.
2. **Sync Docs:** Apply all `## Documentation & Roadmap Sync` rules above.
3. **Commit:** Verify `.env` is untracked via `cmd /c git status` and commit the batch on the active feature branch.
4. **Hand Off:** Summarize changes, test counts, and the exact merge/push commands for the user.

## Windows Execution Rules

- **Prefer Dart MCP:** Use the `dart` MCP server tools for running tests, `pub`, and analyzing files whenever available.
- **Wrap CLI commands in `cmd /c`:** Always prefix terminal commands with `cmd /c` and pass `--no-pub` for Flutter test runs (e.g., `cmd /c flutter test --no-pub <path>`).
- **Never run bare `flutter test`, `dart analyze`, or `flutter pub get` in the agent terminal:** Bare commands hang on VS Code's active Dart SDK / `pubspec.lock` lock. Let VS Code auto-run `pub get` on `pubspec.yaml` save or use Dart MCP `pub`.