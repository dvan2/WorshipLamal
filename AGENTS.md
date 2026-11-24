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

## Commits
`refactor: ...`, `feat: ...`, `fix: ...`, `docs: ...` — lowercase, imperative, scoped to one feature per commit.

## Testing
`mocktail` for mocks. Data layer: unit tests (mock APIs). Providers: provider tests (mock repositories). UI: widget/golden tests.

## Key Domain Concepts
Nashville Number System chords stored in DB, translated to letter chords at render time via `NashvilleHelper`. Key transposition via `KeyTransposer`. Two rendering paths: `RhythmBarRenderer` (rhythm charts) and `ChordLineRenderer` (legacy ChordPro lyrics).
