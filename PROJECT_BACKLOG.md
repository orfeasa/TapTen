# Project Backlog

## Product Status
- Current milestone: Playable MVP with full core game loop and complete v1 category baseline.
- Current state:
  - Home, New Game, Pass Device, Host Round, Round Summary, Final Results, and Settings are implemented.
  - Host Round supports timer, pause/resume, source link after time-up, and answer tap toggling.
  - Question pack loader validates richer metadata and difficulty score/tier consistency.
  - Question content now covers all 12 target categories with 12 questions each and exact 4 easy / 4 medium / 4 hard spread.
  - Setup category picker still exposes only 6 categories, so not all shipped content is selectable yet.
- Release readiness: Not ready for content freeze; gameplay loop is stable, but setup parity and final editorial QA are still open.

## Active Decisions
- Final content category target is fixed to 12 categories:
  - Everyday Life, Food & Drink, Film & TV, Music, Sport, Geography, History, Science, Technology, Travel, Work & School, Pop Culture & Trends.
- Content quality workflow requires post-edit auditing (duplicates, ambiguity, overlap, score/tier integrity).
- Home keeps instructional content in a separate How To Play sheet (not a large on-home card).
- Host answer rows are currently sorted alphabetically for scanning speed.
- Host-round interaction baseline is tap-to-toggle answers with active-round `Pause`/`Resume` and post-timeup `Continue to Summary`.

## Backlog

### P0 - Now

- [ ] TASK: Align setup category catalog with final category set
  - Type: Feature
  - Priority: P0
  - Status: Planned
  - Area: `Services/CategoryCatalogService`, `Views/NewGame`, `ViewModels/NewGameViewModel`
  - Goal: Ensure category selection UI reflects the exact final taxonomy and can start games against all shipped categories.
  - Acceptance Criteria:
    - Category list in setup matches the 12-category final set exactly.
    - Starting a game with selected categories never fails due to missing catalog entries.
    - Category names are consistent across loader data, setup UI, and docs.
  - Notes:
    - Current setup catalog still exposes only 6 categories.

- [ ] TASK: Add automated content audit check for regression prevention
  - Type: QA / Tooling
  - Priority: P0
  - Status: Planned
  - Area: `TapTenTests` and/or project-local audit script
  - Goal: Make pack quality checks repeatable and enforceable before merge.
  - Acceptance Criteria:
    - A single command can run pack integrity checks (schema + score/tier + prompt duplication).
    - The check reports category/tier coverage against release targets.
    - Audit usage is documented for future content edits.
  - Notes:
    - This should complement existing loader tests, not replace them.

- [ ] TASK: Run editorial pass and quality promotion on draft questions
  - Type: Content QA
  - Priority: P0
  - Status: Planned
  - Area: `Resources/QuestionPacks`
  - Goal: Move newly added questions from `quality: "draft"` to reviewed/playtested status where appropriate.
  - Acceptance Criteria:
    - Draft questions are reviewed for ambiguity, adjudication speed, and spoken clarity.
    - `quality` values are updated consistently (`reviewed` or `playtested`) where checks pass.
    - Any unresolved prompts are tracked in `CONTENT_TODO.md` with concrete follow-ups.

### P1 - Next

- [ ] TASK: Add difficulty filtering to New Game setup
  - Type: Feature
  - Priority: P1
  - Status: Planned
  - Area: `Views/NewGame`, `ViewModels/NewGameViewModel`, `Services/GameEngine`
  - Goal: Let hosts include/exclude easy/medium/hard questions before starting a session.
  - Acceptance Criteria:
    - Setup UI provides tier filters with native controls.
    - Round selection uses both category and difficulty filters.
    - Clear validation message appears when filter combination yields no playable question pool.

- [ ] TASK: Connect Settings toggles to runtime behavior
  - Type: Feature
  - Priority: P1
  - Status: Planned
  - Area: `Services/AppSettingsStore`, `Services/CountdownSoundService`, `Views/GameFlow/HostRoundView`
  - Goal: Make `Sounds` and `Haptics` settings affect in-round feedback.
  - Acceptance Criteria:
    - Disabling sounds suppresses countdown and round-end audio.
    - Disabling haptics suppresses reveal haptic feedback.
    - Existing behavior remains unchanged when toggles are enabled.

- [ ] TASK: Add Question Pack Browser screen
  - Type: Feature
  - Priority: P1
  - Status: Planned
  - Area: `Views/Home`, new content browser view(s)
  - Goal: Expose pack/category metadata before game start.
  - Acceptance Criteria:
    - Home offers navigation to a pack browser.
    - Browser shows pack title, category coverage, and question counts.
    - UI remains native and lightweight (no custom heavy components).

- [ ] TASK: Consolidate legacy pack files after category migration
  - Type: Content / Cleanup
  - Priority: P1
  - Status: Planned
  - Area: `Resources/QuestionPacks`
  - Goal: Remove transitional pack fragmentation now that final packs are in place.
  - Acceptance Criteria:
    - Deprecated legacy pack files are either migrated or removed.
    - No duplicate prompt concepts remain due to overlapping legacy/new files.
    - Loader still finds sufficient packs for fresh installs.

### P2 - Later

- [ ] TASK: Full accessibility and Dynamic Type pass across gameplay flow
  - Type: UX / Accessibility
  - Priority: P2
  - Status: Planned
  - Area: All player-facing screens
  - Goal: Improve readability and interaction reliability under larger text and VoiceOver.
  - Acceptance Criteria:
    - Core flow remains usable at larger Dynamic Type sizes.
    - Primary controls remain reachable and clearly labeled for VoiceOver.
    - Any clipped/overlapping layouts are fixed.

- [ ] TASK: Add lightweight game telemetry hooks for playtest tuning
  - Type: Technical
  - Priority: P2
  - Status: Planned
  - Area: `ViewModels/GameFlowViewModel`, local diagnostics
  - Goal: Capture low-risk gameplay signals to tune difficulty and pacing.
  - Acceptance Criteria:
    - Round-level metrics can be inspected in debug builds (for example: answers revealed, time remaining, category).
    - No network dependency is introduced for v1.
    - Telemetry code is isolated and easy to disable.

- [ ] TASK: Release readiness checklist and smoke-test protocol
  - Type: Release / QA
  - Priority: P2
  - Status: Planned
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
    - Blocked by pending editorial review and setup-catalog parity work.

## Manual Review Needed
- Review newly added questions currently marked `quality: "draft"` and promote status after playtest/editor pass.
- Spot-check near-boundary prompts where category overlap is plausible (`Film & TV` vs `Pop Culture & Trends`, `Geography` vs `Travel`).
- Confirm host adjudication speed on harder prompts in `Science`, `Technology`, and `History` during live playtests.
