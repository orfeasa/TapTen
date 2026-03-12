# Project Backlog

## Product Status
- Current milestone: Playable MVP with full core game loop and complete v1 category baseline.
- Current state:
  - Home, New Game, Pass Device, Host Round, Round Summary, Final Results, and Settings are implemented.
  - Settings now safely owns persistent defaults for rounds/timer, while New Game focuses on team names, categories, and difficulty tiers.
  - Host Round supports timer, pause/resume, source link after time-up, and answer tap toggling.
  - Question pack loader validates richer metadata and difficulty score/tier consistency.
  - Question content now covers all 12 target categories with 12 questions each and exact 4 easy / 4 medium / 4 hard spread.
  - Setup category picker now reflects all 12 shipped categories.
  - New Game now supports difficulty-tier filtering and preflight validation for empty playable pools.
  - Runtime round feedback now respects `Sounds` and `Haptics` settings.
  - Home now includes a native pack browser showing category coverage and pack-level counts.
  - Home now shows live current-settings chips and uses simpler native toolbar/settings chrome.
  - Legacy mixed pack files were consolidated into one-category pack files.
  - Debug-only round telemetry now records category/answers/points/time-remaining for playtest tuning.
  - A reusable pre-release checklist now exists in `RELEASE_CHECKLIST.md`.
  - Most `quality: \"draft\"` questions have been promoted to `reviewed`, with a small holdout list in `CONTENT_TODO.md`.
  - Accessibility pass completed for Dynamic Type and VoiceOver on core game-flow controls.
  - First UX review batch is implemented (Home hierarchy cleanup, How To Play interactivity fix, setup category completeness, and round-summary CTA wording).
  - Playful color pass applied; controls use warmer accents and prominent action tinting now aligns with Home’s orange-led palette.
  - Latest polish pass refined New Game into warm setup cards with a pinned `Start Game` action, aligned in-flow CTA styling, reduced Host Round pause emphasis, and increased Round Summary verdict emphasis while grouping source/report tools beside the summary question.
- Release readiness: Not ready for content freeze; gameplay loop is stable, but remaining UX polish and final editorial QA are still open.

## Active Decisions
- Final content category target is fixed to 12 categories:
  - Everyday Life, Food & Drink, Film & TV, Music, Sport, Geography, History, Science, Technology, Travel, Work & School, Pop Culture & Trends.
- Content quality workflow requires post-edit auditing (duplicates, ambiguity, overlap, score/tier integrity).
- Home keeps instructional content in a separate How To Play sheet (not a large on-home card).
- Home keeps `Browse Question Packs` as a secondary top-level action.
- Host answer rows are currently sorted alphabetically for scanning speed.
- Host-round interaction baseline is tap-to-toggle answers with active-round `Pause`/`Resume` and post-timeup `Continue to Summary`.
- Home should use a single strong brand title (remove duplicate `Tap Ten` heading).
- Navigation chrome should use standard native bars/back behavior instead of mixed floating controls.
- New Game should use clearer editable team fields and a stronger full-width primary `Start Game` action.
- Setup category selection should expose all 12 shipped categories.
- Setup difficulty filtering is multi-select (`easy`, `medium`, `hard`) with all tiers enabled by default.
- End-game actions should use native destructive confirmation dialog patterns.
- Final Results secondary action should be label/destination aligned (`Home` to Home), while `Play Again` remains the primary replay action.
- Round Summary CTA labels should be state-specific (`Next Round` / `Continue to Final Results`).
- Settings should stay visually aligned with the warm app theme and use native control styling.
- Question feedback v1 should use a prefilled email flow rather than backend submission.
- Settings changes should affect future setup defaults only, not mutate an already-open New Game draft.

## Backlog

### P0 - Now

- [x] TASK: Fix Settings crash and move rounds/timer ownership into defaults
  - Type: Bug / UX
  - Priority: P0
  - Status: Completed
  - Area: `Views/Home`, `Views/NewGame`, `Views/Home/SettingsView`, `Services/AppSettingsStore`, setup state wiring
  - Goal: Make the gear-based settings flow safe and let persistent defaults own rounds/timer so New Game stays focused on session-specific choices.
  - Acceptance Criteria:
    - Changing `Rounds per Team` or `Round Timer` in Settings does not crash.
    - Settings owns persistent defaults for rounds/timer.
    - New Game no longer shows rounds/timer controls.
    - New Game continues to expose team names, categories, and difficulty tiers.
    - Home no longer shows redundant `Default setup` capsules.
    - `Browse Question Packs` remains available on Home.
    - Updating Settings changes future New Game defaults, but does not mutate an already-open setup draft.
  - Notes:
    - Settings writes now go through explicit setter methods instead of self-mutating property observers.
    - Home still seeds New Game from `AppSettingsStore.shared.defaultGameSettings`, so future drafts pick up new defaults without mutating an already-open setup screen.
    - Home now shows a lighter current-settings summary rather than the older redundant default-setup strip.

- [x] TASK: Restore Home `How To Play` action interactivity
  - Type: UX / Bug
  - Priority: P0
  - Status: Completed
  - Area: `Views/Home`, onboarding sheet presentation
  - Goal: Ensure the secondary onboarding action is visibly and functionally tappable.
  - Acceptance Criteria:
    - Tapping `How To Play` on Home always presents the sheet.
    - The control has clear enabled-state affordance and native tap feedback.
    - No overlap/gesture conflict blocks taps on the control.

- [x] TASK: Refine Home hierarchy and navigation consistency
  - Type: UX
  - Priority: P0
  - Status: Completed
  - Area: `Views/Home`, shared navigation bars/toolbars
  - Goal: Make top-level flow feel confidently native and visually coherent.
  - Acceptance Criteria:
    - Home presents one primary brand title (no duplicate heading).
    - Screens use consistent native navigation bars and back affordances.
    - Floating/custom back controls are removed where a standard nav pattern is expected.

- [x] TASK: Improve New Game setup clarity and category completeness
  - Type: UX / Feature
  - Priority: P0
  - Status: Completed
  - Area: `Views/NewGame`, `ViewModels/NewGameViewModel`, `Services/CategoryCatalogService`
  - Goal: Reduce setup friction and ensure all shipped content is selectable.
  - Acceptance Criteria:
    - Team name rows clearly communicate editability with native field affordances.
    - `Start Game` is a clear full-width primary action with strong prominence.
    - Category list shows the exact 12-category final set.
    - Include/exclude all actions remain visible and predictable.
    - Setup validation avoids dead-end starts due to catalog mismatch.

- [x] TASK: Normalize end-game confirmation and round progression CTAs
  - Type: UX
  - Priority: P0
  - Status: Completed
  - Area: `Views/GameFlow/HostRoundView`, `Views/GameFlow/RoundSummaryView`, shared game-flow actions
  - Goal: Make destructive actions safer and progression actions easier to scan.
  - Acceptance Criteria:
    - End-game actions consistently use native destructive confirmation dialogs.
    - Round Summary uses state-based CTA labels (`Next Round`, `Continue to Final Results`).
    - CTA wording is consistent with current game state across the flow.

- [x] TASK: Align Final Results secondary action label with destination
  - Type: UX / Bug
  - Priority: P0
  - Status: Completed
  - Area: `Views/GameFlow/GameFlowView`, `Views/NewGame/NewGameView`
  - Goal: Ensure Final Results secondary action text matches its destination behavior.
  - Acceptance Criteria:
    - Final Results secondary button is labeled `Home`.
    - Tapping it exits the finished flow and returns to Home.
    - Post-game actions no longer imply a setup destination when they return Home.

- [x] TASK: Add automated content audit check for regression prevention
  - Type: QA / Tooling
  - Priority: P0
  - Status: Completed
  - Area: `TapTenTests` and/or project-local audit script
  - Goal: Make pack quality checks repeatable and enforceable before merge.
  - Acceptance Criteria:
    - A single command can run pack integrity checks (schema + score/tier + prompt duplication).
    - The check reports category/tier coverage against release targets.
    - Audit usage is documented for future content edits.
  - Notes:
    - This should complement existing loader tests, not replace them.

### P1 - Next

- [x] TASK: Add post-round question feedback via email
  - Type: Feature / Content QA
  - Priority: P1
  - Status: Completed
  - Area: `Views/GameFlow`, round summary / post-timeup review, local feedback composition
  - Goal: Let hosts flag unclear, outdated, duplicate, or low-quality questions without interrupting active play.
  - Acceptance Criteria:
    - `Report Question` or equivalent is available after active play, not during countdown.
    - The flow opens a native sheet with question details (`category`, `difficulty`, `source`), reason selection, and note capture.
    - Supported reasons are `Too easy`, `Too difficult`, `Wrong category`, `Inappropriate`, and `Other`.
    - `Other` requires a note before submission.
    - Submitting creates a prefilled email with structured question metadata and reason-specific review language.
    - Included metadata covers pack name, question ID, prompt, source URL, difficulty tier, app version, selected reason, and note.
    - The feedback entry point does not weaken the main continue/progression CTA.
  - Notes:
    - v1 entry point lives on `Round Summary` to keep active and time-up host states uncluttered.
    - Feedback drafts currently target `tapten-reports@orfeasa.com` via `QuestionFeedbackComposer`.

- [x] TASK: Refresh Settings layout to native control language
  - Type: UX
  - Priority: P1
  - Status: Completed
  - Area: `Views/Settings`
  - Goal: Align Settings with the app’s warm visual language and native form behavior.
  - Acceptance Criteria:
    - Settings uses native `Form`/list grouping and system-standard control styling.
    - Stepper/adjustment controls follow native interaction patterns.
    - Background and section styling remain consistent with the warm app palette.

- [x] TASK: Add difficulty filtering to New Game setup
  - Type: Feature
  - Priority: P1
  - Status: Completed
  - Area: `Views/NewGame`, `ViewModels/NewGameViewModel`, `Services/GameEngine`
  - Goal: Let hosts include/exclude easy/medium/hard questions before starting a session.
  - Acceptance Criteria:
    - Setup UI provides tier filters with native controls.
    - Round selection uses both category and difficulty filters.
    - Clear validation message appears when filter combination yields no playable question pool.

- [x] TASK: Connect Settings toggles to runtime behavior
  - Type: Feature
  - Priority: P1
  - Status: Completed
  - Area: `Services/AppSettingsStore`, `Services/CountdownSoundService`, `Views/GameFlow/HostRoundView`
  - Goal: Make `Sounds` and `Haptics` settings affect in-round feedback.
  - Acceptance Criteria:
    - Disabling sounds suppresses countdown and round-end audio.
    - Disabling haptics suppresses reveal haptic feedback.
    - Existing behavior remains unchanged when toggles are enabled.

- [x] TASK: Add Question Pack Browser screen
  - Type: Feature
  - Priority: P1
  - Status: Completed
  - Area: `Views/Home`, new content browser view(s)
  - Goal: Expose pack/category metadata before game start.
  - Acceptance Criteria:
    - Home offers navigation to a pack browser.
    - Browser shows pack title, category coverage, and question counts.
    - UI remains native and lightweight (no custom heavy components).

- [x] TASK: Consolidate legacy pack files after category migration
  - Type: Content / Cleanup
  - Priority: P1
  - Status: Completed
  - Area: `Resources/QuestionPacks`
  - Goal: Remove transitional pack fragmentation now that final packs are in place.
  - Acceptance Criteria:
    - Deprecated legacy pack files are either migrated or removed.
    - No duplicate prompt concepts remain due to overlapping legacy/new files.
    - Loader still finds sufficient packs for fresh installs.

- [x] TASK: Run editorial pass and quality promotion on draft questions
  - Type: Content QA
  - Priority: P1
  - Status: Completed
  - Area: `Resources/QuestionPacks`
  - Goal: Move newly added questions from `quality: "draft"` to reviewed/playtested status where appropriate.
  - Acceptance Criteria:
    - Draft questions are reviewed for ambiguity, adjudication speed, and spoken clarity.
    - `quality` values are updated consistently (`reviewed` or `playtested`) where checks pass.
    - Any unresolved prompts are tracked in `CONTENT_TODO.md` with concrete follow-ups.

### P2 - Later

- [x] TASK: Full accessibility and Dynamic Type pass across gameplay flow
  - Type: UX / Accessibility
  - Priority: P2
  - Status: Completed
  - Area: All player-facing screens
  - Goal: Improve readability and interaction reliability under larger text and VoiceOver.
  - Acceptance Criteria:
    - Core flow remains usable at larger Dynamic Type sizes.
    - Primary controls remain reachable and clearly labeled for VoiceOver.
    - Any clipped/overlapping layouts are fixed.
  - Notes:
    - Added Dynamic Type scaling refinements and VoiceOver hints/combined semantics across core flow.
    - Keep manual large-text smoke checks in `RELEASE_CHECKLIST.md` before release.

- [x] TASK: Add lightweight game telemetry hooks for playtest tuning
  - Type: Technical
  - Priority: P2
  - Status: Completed
  - Area: `ViewModels/GameFlowViewModel`, local diagnostics
  - Goal: Capture low-risk gameplay signals to tune difficulty and pacing.
  - Acceptance Criteria:
    - Round-level metrics can be inspected in debug builds (for example: answers revealed, time remaining, category).
    - No network dependency is introduced for v1.
    - Telemetry code is isolated and easy to disable.

- [x] TASK: Release readiness checklist and smoke-test protocol
  - Type: Release / QA
  - Priority: P2
  - Status: Completed
  - Area: docs + test process
  - Goal: Standardize pre-release checks before TestFlight.
  - Acceptance Criteria:
    - Checklist covers build, critical gameplay flow, and content integrity.
    - Includes manual pass for host-speed adjudication and source-link visibility rules.
    - Checklist is documented and reusable.

## In Progress

- [ ] TASK: Maintain `CONTENT_TODO.md` as the live content QA queue
  - Type: Planning / Content
  - Priority: P0
  - Status: In Progress
  - Area: repo root docs
  - Goal: Keep one actionable source of truth for unresolved content review and cleanup tasks.
  - Acceptance Criteria:
    - Coverage/tier summary stays accurate after each content batch.
    - Remaining tasks are atomic and execution-ready.
    - Manual-review flags are updated as issues are resolved.

## Blocked

- [ ] TASK: Content freeze for release candidate
  - Type: Release
  - Priority: P1
  - Status: Blocked
  - Area: Content pipeline
  - Goal: Reach a stable, balanced, low-ambiguity content set suitable for broad playtesting.
  - Acceptance Criteria:
    - Final 12 categories stay complete with 12 questions each and balanced tiers.
    - Setup category picker is aligned with shipped content taxonomy.
    - Manual editorial review issues are closed or explicitly deferred.
    - Duplicate and near-duplicate prompt checks remain clean.
  - Notes:
    - Blocked by pending editorial review and final content freeze sign-off.

## Manual Review Needed
- Final editorial holdouts still marked `quality: "draft"` in `CONTENT_TODO.md` need manual review/playtest before freeze.
- Spot-check near-boundary prompts where category overlap is plausible (`Film & TV` vs `Pop Culture & Trends`, `Geography` vs `Travel`).
- Confirm host adjudication speed on harder prompts in `Science`, `Technology`, and `History` during live playtests.
