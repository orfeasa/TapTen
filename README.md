# Tap Ten

Tap Ten is an iPhone-first, host-operated party guessing game built with SwiftUI.

Two teams play on one device. One team answers out loud while the other team hosts, watches the question and answer list, and taps matches under time pressure.

## Current MVP Behavior

- Single-device game with exactly two teams.
- Portrait-only on iPhone in v1.
- Configurable default rounds per team and round duration via Settings.
- Random question selection from enabled categories and difficulty tiers.
- No repeated questions in a single game session.
- Bundled local JSON question packs only (no network fetching).
- Warm, Apple-native visual direction with restrained motion.
- Playful-but-clear in-app tone for supporting copy and verdicts.
- Cleaner Home with focused hero copy, a native toolbar gear, live `Current settings` chips, one strong primary CTA, larger secondary actions, and a separate `How To Play` sheet.
- Home includes a native `Browse Question Packs` screen with category and pack-level counts.
- New Game focuses on team names, category filters, and difficulty tiers, while rounds/timer live in Settings defaults and the setup screen uses warmer card-based grouping plus a pinned bottom `Start Game` action so the main CTA stays visible.
- Pass-device handoff flow between rounds with clear answering/hosting emphasis and a playful primary `Start Round` CTA.
- Host round with:
  - visible question and all 10 answers
  - large tap targets
  - continuous countdown timer
  - answer rows sorted alphabetically for faster scanning
  - tap-to-toggle answers (tap again to untap) during active play and after time-up review
  - subtle reveal reward feedback (animation + transient `+points`)
  - differentiated reveal haptics by answer value
  - tense final-seconds timer treatment
  - de-emphasized active-round `Pause` / `Resume` utility control
  - clear post-timeup CTA (`Continue to Summary`)
  - labeled post-timeup review actions for `View Source` and `Report Question`
  - narrow-screen post-timeup review tools now stack safely instead of colliding with long questions
- Round summary with stronger points-first hierarchy, a larger verdict moment, scoreboard, and one clear progression CTA without extra source/report controls.
- Post-timeup `Report Question` opens a native feedback sheet, shows question details (`category`, `difficulty`, `source`), and prepares a reason-specific email draft for `too easy`, `too difficult`, `wrong category`, `inappropriate`, or `other`.
- Final results with stronger winner hero, warmer celebration accents, winner/runner-up distinction, and post-game actions (`Play Again`, `Home`).
- Shared theme tokens for warm background/card, celebration gold, reveal green, and playful accent colors used for controls and prominent gradient capsule CTAs.
- Minimal v1 Settings screen (`sounds`, `haptics`, default rounds, default timer) plus safe in-game end confirmation.
  - Settings is available from Home via the toolbar gear button.
  - `Sounds` and `Haptics` toggles now directly control in-round feedback behavior.
  - `End Game` is available during in-progress game flow and always requires explicit confirmation.
- Optional editorial metadata fields in local packs for quality control (`contentType`, `quality`, `difficultyNotes`, `editorialNotes`, `packVersion`).

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
- `difficultyScore` that equals the sum of the 10 answer points
- `difficultyTier` (`easy`, `medium`, `hard`) that matches the score bands
- one `sourceURL`
- `validationStyle` (`factual`, `editorial`, or `humorous`)

Optional metadata is supported for curation (`contentType`, `quality`, `tags`, `difficultyNotes`, `editorialNotes`, `packVersion`).

Current content target status:
- final 12-category set is present:
  - `Everyday Life`, `Food & Drink`, `Film & TV`, `Music`, `Sport`, `Geography`, `History`, `Science`, `Technology`, `Travel`, `Work & School`, `Pop Culture & Trends`
- each category currently has 12 questions with exact `4 easy / 4 medium / 4 hard` distribution

Malformed pack data is validated and surfaced with clean loader errors.
For authoring and audit workflow, see:
- `PesVres/TapTen/Resources/QuestionPacks/CONTENT_AUTHORING_SPEC.md`
- `CONTENT_TODO.md`
- Run a full local pack audit with:
  - `./scripts/audit_question_packs.sh`

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
- host round tap-toggle behavior and countdown behavior

Note: avoid launching iOS simulator test runs unless explicitly needed in the current task.

## Working Notes

- Product and UX constraints: see `PROJECT_BRIEF.md`.
- Prioritized follow-up work: see `PROJECT_BACKLOG.md`.
- Repository working conventions: see `AGENTS.md`.
- Release smoke-test protocol: see `RELEASE_CHECKLIST.md`.

## Release Notes

- Full session history and shipped changes: `CHANGELOG.md`.
