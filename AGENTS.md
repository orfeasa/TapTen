# AGENTS.md

## Project context
This repository is for an iPhone-first SwiftUI game ("Tap Ten", formerly "PesVres") inspired by the party game mechanic described in `PROJECT_BRIEF.md`.
Read `PROJECT_BRIEF.md` before making product or UX decisions.

## Working style
- Make the minimum high-confidence change that satisfies the task.
- Prefer native iOS patterns and system components over custom UI.
- Prefer simple, readable Swift and small files.
- Do not invent abstractions unless they clearly reduce complexity.
- Explain the plan before editing.
- After editing, summarise what changed, why, and any risks.
- If the task is ambiguous, choose the option most consistent with `PROJECT_BRIEF.md`.

## Platform and architecture
- Target iPhone first.
- Use SwiftUI.
- Keep app structure boring and testable.
- Organise code into Models, Views, ViewModels, Services, Resources, and Tests.
- Keep gameplay state separate from question-pack content.
- Use bundled local JSON for question packs in v1.
- Include multiple bundled starter packs so a fresh launch can always start a game.
- Avoid adding network dependencies in v1.
- Do not add remote question-pack fetching in v1.

## UX expectations
- The app should feel elegant, native, and Apple-clean.
- Use native controls: NavigationStack, Form, List, sheet, toolbar, Button, Toggle, Picker, confirmationDialog.
- Use system typography and SF Symbols.
- Support dark mode and Dynamic Type.
- Optimise for the host holding the phone under time pressure.
- Large tap targets are required on the round screen.
- One obvious primary action per screen.
- Avoid over-designed custom components.

## Product constraints
- Single-device only in v1.
- Two teams only in v1.
- Fixed number of rounds per team.
- No steal mechanic.
- Random question selection from included categories.
- No repeated questions in a single game session.
- The host sees all 10 answers immediately.
- The answering team never sees the phone during the round.
- Scores are shown after the round, not during it.
- Source links are available after a round ends (host round and summary), not during active countdown play.
- End-of-game screen includes winner celebration and a sassy comment based on game performance.

## Game rules
- Team A answers first while someone from Team B acts as host and holds the phone.
- Team B then answers while someone from Team A hosts.
- One question per round.
- Default round duration is 60 seconds and should be configurable.
- Default number of rounds is 5 per team.
- Each answer is worth 1 to 5 points based on guess difficulty.
- Answers are host-toggled: tapping an answer reveals it; tapping again unreveals it.
- While timer is active, active-round controls focus on `Pause`/`Resume`.
- After timer ends, the host can still toggle answers for post-timeup review before continuing.
- Timer runs continuously (not coarse second ticks).
- Display timer as whole seconds except in the final 10 seconds, where tenths are shown.
- Do not show `00:` prefix for sub-minute timer values.
- The round timer stopping at zero does not auto-advance to the next screen; host explicitly continues.
- Host round includes clear active-round controls (`Pause`/`Resume`) and a distinct post-timeup `Continue to Summary` action.
- The game ends only after both teams complete the configured rounds per team.

## Content model expectations
- Question packs are curated editorial content.
- Questions may be factual, editorial, or humorous.
- Each question must include a difficulty of `easy`, `medium`, or `hard`.
- Each question has exactly one source link.
- Keep content fields flexible enough for future pack growth.
- Add validation when loading JSON.

## Testing expectations
- Put scoring and timer logic in testable units.
- Add unit tests for score-once behaviour, timer expiry, round completion, and no-repeat question selection.
- Add unit tests for end-game sassy comment tier selection.
- Add SwiftUI previews for user-facing views where practical.
- Do not run iPhone/simulator test commands (for example, `xcodebuild test` with an iOS Simulator destination) unless the user explicitly asks in that turn.
- Do not launch iPhone simulator windows unless the user explicitly asks in that turn.

## Delivery expectations
- Keep the app compiling after each task.
- Prefer incremental milestones over large rollouts.
- Do not add features that are outside the current task.
