# Tap Ten

Tap Ten is an iPhone-first, host-operated party guessing game built with SwiftUI.

Two teams play on one device. One team answers out loud while the other team hosts, watches the question and answer list, and taps matches under time pressure.

## Current MVP Behavior

- Single-device game with exactly two teams.
- Configurable round count and round duration.
- Random question selection from enabled categories.
- No repeated questions in a single game session.
- Bundled local JSON question packs only (no network fetching).
- Pass-device flow between rounds.
- Host round with:
  - visible question and all 10 answers
  - large tap targets
  - continuous countdown timer
  - answer tap toggles reveal/unreveal
  - fixed bottom action button (`Pause` / `Resume`, then `Continue to Summary`)
  - source-link icon available once the round ends
- Round summary with points, scoreboard, and source link.
- Final results with winner celebration and a randomized sassy verdict based on answer performance.

## Project Layout

```text
PesVres/
  TapTen/
    App/
    Models/
    Services/
    ViewModels/
    Views/
    Resources/QuestionPacks/
  TapTenTests/
  TapTenUITests/
```

## Question Packs

Question packs live in `PesVres/TapTen/Resources/QuestionPacks/` and are bundled in the app.

Each question must include:

- exactly 10 answers
- points from 1 to 5 per answer
- one `sourceURL`
- `validationStyle` (`factual`, `editorial`, or `humorous`)

Malformed pack data is validated and surfaced with clean loader errors.

## Build

Open in Xcode:

- `PesVres/TapTen.xcodeproj`
- scheme: `TapTen`

CLI build (no simulator required):

```bash
xcodebuild build \
  -project PesVres/TapTen.xcodeproj \
  -scheme TapTen \
  -destination 'generic/platform=iOS' \
  -derivedDataPath /tmp/pesvres-dd \
  CODE_SIGNING_ALLOWED=NO
```

## Tests

Unit tests are under `PesVres/TapTenTests/Unit/` and cover:

- game engine turn alternation and round completion
- no-repeat question selection
- question-pack loading and validation
- game setup category selection behavior
- end-game sassy comment tier logic

Note: avoid launching iOS simulator test runs unless explicitly needed in the current task.

## Working Notes

- Product and UX constraints: see `PROJECT_BRIEF.md`.
- Repository working conventions: see `AGENTS.md`.
