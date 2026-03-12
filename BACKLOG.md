# Backlog

## Current priorities

### 1. Question feedback flow
Status: Proposed
Priority: High

Problem:
We need a way for players or hosts to flag a question that feels wrong, unclear, outdated, duplicated, or not fun.

Recommended v1 approach:
- Add a `Report Question` or `Give Feedback` action after active play, not during countdown.
- Place it on `Round Summary`, and optionally also on the post-time-up Host Round state.
- Open a small native sheet with:
  - reason
  - optional short note
  - submit action
- Submit through a prefilled email in v1.
- Keep a copy/export fallback only if email handoff proves unreliable on device.

Why this approach:
- Keeps gameplay uninterrupted.
- Avoids backend work in v1.
- Captures enough metadata for editorial review.

Feedback payload should include:
- pack name
- question ID
- question text
- source URL
- difficulty
- app version
- selected reason
- optional note

Open questions:
- Do we want only issue reporting, or also positive feedback such as `great question`?
- Should feedback be available only after the round ends, or also from pack browsing later?

### 2. Settings/default setup cleanup
Status: Proposed
Priority: Critical

Context note:
This backlog item intentionally changes the current `PROJECT_BRIEF.md` split between `Settings` and `New Game`. If shipped, the brief and README should be updated to match the new ownership model.

Problem:
- Changing values from the Home screen settings flow currently crashes the app.
- Setup responsibility is split awkwardly between global defaults and per-game configuration.

Recommended product direction:
- `Settings` should own persistent defaults only:
  - sounds
  - haptics
  - default rounds per team
  - default round timer
- `New Game` should only own session-specific setup:
  - team names
  - category selection
  - difficulty selection with multi-select `easy`, `medium`, `hard`
- Remove rounds/timer controls from `New Game`.
- Remove redundant default-setup summary from `Home`.
- Keep pack browsing on `Home`.
- Make Home actions/icons larger and clearer.

Why this direction:
- Matches user expectation for a gear/settings entry point.
- Reduces repeated configuration on every game start.
- Makes `New Game` faster and more focused.
- Separates persistent preferences from one-off session choices.

Implementation notes:
- Fix the current crash in `SettingsView` / `AppSettingsStore` before any UI cleanup ships.
- `New GameViewModel` should initialize from `AppSettingsStore.shared.defaultGameSettings`.
- Difficulty filtering needs to be added to question selection so the `New Game` screen can expose it cleanly.
- Difficulty options should default to all selected.
- Recommended behavior: changes in `Settings` affect future game setup defaults, but do not mutate an already-open `New Game` draft.

Open questions:
- Should changing settings affect only future games, or also update any in-progress draft on the `New Game` screen?

## Suggested order

1. Fix the settings crash.
2. Move rounds/timer ownership fully into persistent settings.
3. Simplify `New Game` to team names, categories, and difficulty.
4. Refresh Home composition and icon sizing after the flow is simplified.
5. Add question feedback entry points and a low-risk v1 submission path.
