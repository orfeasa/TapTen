# Tap Ten

Tap Ten is an iPhone-first, host-operated party guessing game built with SwiftUI.

This repository is not only the iOS app. It currently contains three product surfaces plus shared planning and release docs:

- the Tap Ten iOS app in `PesVres/`
- the public marketing/privacy website in `website/`
- the internal Django editorial backend and reviewer tool in `backend/`

Two teams play on one device. One team answers out loud while the other team hosts, watches the question and answer list, and taps matches under time pressure.

## Repository Overview

- `PesVres/`: the shipped iPhone app, tests, assets, and bundled question packs
- `website/`: the public static site deployed to `playtapten.com`
- `backend/`: the self-hosted Django service behind `api.playtapten.com` and `review.playtapten.com`
- `fastlane/` and `.github/workflows/`: beta release and deployment automation
- root docs such as `PROJECT_BRIEF.md`, `PROJECT_BACKLOG.md`, `BACKEND_PLAN.md`, and `EDITORIAL_BACKEND_MVP.md`: product, content, and ops guidance

## Current MVP Behavior

- Single-device game with exactly two teams.
- Portrait-only on iPhone in v1.
- Minimum supported iPhone OS is currently iOS 17.
- Configurable default rounds per team and round duration via Settings.
- Random question selection from enabled categories and difficulty tiers.
- No repeated questions in a single game session.
- Bundled local JSON question packs only (no network fetching).
- Warm, Apple-native visual direction with restrained motion.
- Playful-but-clear in-app tone for supporting copy and verdicts.
- Cleaner Home with a title-first hero, a quieter native toolbar gear, `Game defaults` status cards, one strong primary CTA, larger secondary actions, and a separate `How To Play` sheet.
- Home includes a cleaner native `Browse Library` screen that explains the base game library versus premium expansions.
- New Game focuses on team names, category filters, and difficulty tiers, while rounds/timer live in Settings defaults and the setup screen uses warmer card-based grouping plus a pinned bottom `Start Game` action so the main CTA stays visible.
  - Team names open with a random curated funny/sassy suggested pair and can be cycled with `Shuffle Names` or edited manually.
- Pass-device handoff flow between rounds with clear answering/hosting emphasis and a playful primary `Show Question` CTA.
- Dedicated question preview step between handoff and live play so the host can read the prompt before the timer starts.
- Host round with:
  - visible question and all 10 answers
  - large tap targets
  - continuous countdown timer
  - answer rows sorted alphabetically for faster scanning
  - tap-to-toggle answers (tap again to untap) during active play and after time-up review
  - subtle reveal reward feedback (animation + transient `+points`)
  - differentiated reveal haptics by answer value
  - tense final-seconds timer treatment
  - countdown tension audio now starts in the final `10` seconds
  - de-emphasized active-round `Pause` / `Resume` utility control
  - clear post-timeup CTA (`Continue to Summary`)
  - labeled post-timeup review actions for `View source` and `Flag question`
  - narrow-screen post-timeup review tools now stay on one row without colliding with long questions
- Round summary with stronger points-first hierarchy, a larger verdict moment, scoreboard, and one clear progression CTA without extra source/report controls.
- Round Summary and Final Results now play lightweight payoff stings on appear.
- Post-timeup `Flag question` opens a native feedback sheet, shows question details (`category`, `difficulty`, `source`), submits directly in-app when a reporting endpoint is configured, and otherwise saves reports locally for retry once delivery is available.
- Final results with stronger winner hero, warmer celebration accents, winner/runner-up distinction, and post-game actions (`Play Again`, `Home`).
- Shared theme tokens for warm background/card, celebration gold, reveal green, and playful accent colors used for controls and prominent gradient capsule CTAs.
- Minimal v1 Settings screen (`sounds`, `haptics`, default rounds, default timer) plus safe in-game end confirmation.
  - Settings is available from Home via the toolbar gear button.
  - `Sounds` and `Haptics` toggles now directly control in-round feedback behavior.
  - `End Game` is available during in-progress game flow and always requires explicit confirmation.
- Optional editorial metadata fields in local packs for quality control (`contentType`, `quality`, `difficultyNotes`, `editorialNotes`, `packVersion`).
- Four bundled premium expansions are now present in the app bundle: `After Dark Vol. 1`, `Date Night`, `Office & Icebreakers`, and `Holiday Chaos`.

## Project Layout

```text
.
├── PesVres/
│   ├── TapTen/
│   │   ├── App/
│   │   ├── Models/
│   │   ├── Services/
│   │   ├── ViewModels/
│   │   ├── Views/
│   │   └── Resources/QuestionPacks/
│   ├── TapTenTests/
│   └── TapTenUITests/
├── backend/
│   ├── editorial/
│   ├── tapten_backend/
│   └── deploy/
├── website/
│   └── public/
├── fastlane/
└── .github/workflows/
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
- each starter category currently has 30 questions with exact `10 easy / 10 medium / 10 hard` distribution
- four premium expansion packs are bundled locally at 40 questions each (`14 easy / 13 medium / 13 hard`):
  - `After Dark Vol. 1`
  - `Date Night`
  - `Office & Icebreakers`
  - `Holiday Chaos`

Malformed pack data is validated and surfaced with clean loader errors.
For authoring and audit workflow, see:
- `PesVres/TapTen/Resources/QuestionPacks/CONTENT_AUTHORING_SPEC.md`
- `CONTENT_REVIEW_WORKFLOW.md`
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

## TestFlight Automation

This repo now includes a minimal fastlane + GitHub Actions path for TestFlight beta uploads.

- Bundler installs fastlane from the root `Gemfile`.
- The fastlane lane is `beta` in `fastlane/Fastfile`.
- The lane:
  - authenticates with an App Store Connect API key from environment variables
  - increments the iOS build number
  - archives the app for App Store/TestFlight distribution
  - uploads the build to TestFlight
- Marketing version remains manual. Keep updating that in Xcode when you want a new visible app version.

Configure these GitHub Actions secrets before using the workflow:

- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_ISSUER_ID`
- `APP_STORE_CONNECT_API_KEY_BASE64`
  - Either the raw contents of your App Store Connect `.p8` API key file or a base64-encoded version of that file.

Trigger it either by:

- running the `TestFlight Beta` workflow manually from GitHub Actions
- pushing a tag that matches `beta-*`

Notes:

- The workflow intentionally does not automate App Store metadata, screenshots, or App Store release submission yet.
- App Store release remains manual.
- This first pass also does not add `fastlane match`. If Xcode automatic signing is not enough on the CI runner, add certificate/profile import or a signing solution later.
- Optional in-app question-reporting delivery can be enabled per build with `QuestionFeedbackEndpointURL` in the app’s info dictionary or `TAPTEN_FEEDBACK_ENDPOINT` in the environment. The current project config points that key at `https://api.playtapten.com/tapten/v1/question-feedback`.
- Optional question-calibration telemetry upload can be enabled per build with `QuestionCalibrationEndpointURL` in the app’s info dictionary or `TAPTEN_CALIBRATION_ENDPOINT` in the environment. The current project config points that key at `https://api.playtapten.com/tapten/v1/question-calibration/batch`.
- TestFlight beta builds inject `QuestionPackTesterUnlocksEnabled=YES`, so premium packs can be unlocked locally without payment during testing.
- Local debug builds also enable tester unlocks by default.
- `TAPTEN_TESTER_UNLOCKS_ENABLED` can still override that behavior from the environment when needed.

## Tests

Unit tests are under `PesVres/TapTenTests/Unit/` and cover:

- game engine turn alternation and round completion
- no-repeat question selection
- question-pack loading and validation
- game setup category selection behavior
- end-game sassy comment tier logic
- host round tap-toggle behavior and countdown behavior

Note: avoid launching iOS simulator test runs unless explicitly needed in the current task.

## Website

The repo now includes a lightweight static marketing/beta site in `website/`.

- `website/public/index.html` explains the core game loop, links to the beta/signup flow, and keeps support secondary to the main beta CTA.
- `website/public/privacy.html` provides the public privacy policy.
- `website/public/styles.css` contains the shared site styling.
- `website/README.md` and `website/AGENTS.md` hold website-specific maintenance notes.
- `.github/workflows/website-pages.yml` deploys the site to GitHub Pages from `main` when website files change.

The live website is `https://playtapten.com`. The GitHub Pages workflow is in-repo, and deployment/maintenance notes live in `website/README.md`.

## Working Notes

- Product and UX constraints: see `PROJECT_BRIEF.md`.
- Development preference: use modern iOS APIs within the current deployment floor rather than contorting the app for older iOS support.
- Prioritized follow-up work: see `PROJECT_BACKLOG.md`.
- Post-v1 monetization strategy: see `MONETIZATION_PLAN.md`.
- Narrow self-hosted backend rollout: see `BACKEND_PLAN.md`.
- Internal editorial backend and reviewer app MVP: see `EDITORIAL_BACKEND_MVP.md`.
- Current Django backend implementation and deploy notes: see `backend/README.md`.
- Backend deploy automation workflow: see `.github/workflows/backend-deploy.yml`.
- Question report intake and editorial handling: see `REPORT_REVIEW_WORKFLOW.md`.
- Question authoring, review, and approval process: see `CONTENT_REVIEW_WORKFLOW.md`.
- Repository working conventions: see `AGENTS.md`.
- Release smoke-test protocol: see `RELEASE_CHECKLIST.md`.

## Release Notes

- Full session history and shipped changes: `CHANGELOG.md`.
