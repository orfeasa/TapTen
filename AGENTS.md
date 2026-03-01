# AGENTS.md

## Project context
This repository is for an iPhone-first SwiftUI game inspired by the party game mechanic described in `PROJECT_BRIEF.md`.
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
- Avoid adding network dependencies in v1.

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
- Fixed number of rounds.
- No steal mechanic.
- Random question selection from included categories.
- No repeated questions in a single game session.
- The host sees all 10 answers immediately.
- The answering team never sees the phone during the round.
- Scores are shown after the round, not during it.
- Source links are shown after a round, not during gameplay.

## Game rules
- Team A answers first while someone from Team B acts as host and holds the phone.
- Team B then answers while someone from Team A hosts.
- One question per round.
- Default round duration is 60 seconds and should be configurable.
- Default number of rounds is 5.
- Each answer is worth 1 to 5 points based on guess difficulty.
- Tapping an answer reveals it and awards points exactly once.
- The host should be able to undo the last reveal.
- The round ends immediately when the timer reaches zero.

## Content model expectations
- Question packs are curated editorial content.
- Questions may be factual, editorial, or humorous.
- Each question has exactly one source link.
- Keep content fields flexible enough for future pack growth.
- Add validation when loading JSON.

## Testing expectations
- Put scoring and timer logic in testable units.
- Add unit tests for score-once behaviour, timer expiry, round completion, and no-repeat question selection.
- Add SwiftUI previews for user-facing views where practical.

## Delivery expectations
- Keep the app compiling after each task.
- Prefer incremental milestones over large rollouts.
- Do not add features that are outside the current task.
