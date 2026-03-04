# Project Backlog

## Product Status
- Current milestone: Playable MVP with full core game loop and active content expansion.
- Current state:
  - Home, New Game, Pass Device, Host Round, Round Summary, Final Results, and Settings are implemented.
  - Host Round supports timer, pause/resume, source link after time-up, and answer tap toggling.
  - Question pack loader now validates richer metadata and difficulty score/tier consistency.
  - Content baseline exists, but category coverage and difficulty balance are not at release target.
- Release readiness: Not ready for content freeze yet; core gameplay is usable, but content and category-completeness gaps remain.

## Active Decisions
- Final content category target is fixed to 12 categories:
  - Everyday Life, Food & Drink, Film & TV, Music, Sport, Geography, History, Science, Technology, Travel, Work & School, Pop Culture & Trends.
- Content quality workflow requires post-edit auditing (duplicates, ambiguity, overlap, score/tier integrity).
- Home keeps instructional content in a separate How To Play sheet (not a large on-home card).
- Host answer rows are currently sorted alphabetically for scanning speed.
- Host-round interaction baseline is tap-to-toggle answers with active-round `Pause`/`Resume` and post-timeup `Continue to Summary`.

## Backlog

### P0 - Now

- [ ] TASK: Execute category normalization to final 12-category content set
  - Type: Content
  - Priority: P0
  - Status: Planned
  - Area: `Resources/QuestionPacks`
  - Goal: Reach exactly 12 questions per final category with exact 4 easy / 4 medium / 4 hard distribution.
  - Acceptance Criteria:
    - All 12 target categories exist.
    - Each category has 12 questions and exact 4/4/4 tier spread.
    - Validation passes for all packs (10 answers, points 1...5, score/tier integrity).
    - Legacy duplicate/overlap issues identified in `CONTENT_TODO.md` are addressed.
  - Notes:
    - `CONTENT_TODO.md` is the execution source of truth.

- [ ] TASK: Align setup category catalog with final category set
  - Type: Feature
  - Priority: P0
  - Status: Planned
  - Area: `Services/CategoryCatalogService`, `Views/NewGame`, `ViewModels/NewGameViewModel`
  - Goal: Ensure category selection UI reflects final product taxonomy and avoids dead-end game starts.
  - Acceptance Criteria:
    - Category list in setup matches the exact final category set.
    - Starting a game with selected categories never fails due to missing content without a clear validation message.
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
  - Goal: Make `Sounds` and `Haptics` settings actually affect in-round feedback.
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
  - Goal: Remove transitional pack fragmentation once final packs are in place.
  - Acceptance Criteria:
    - Deprecated packs (`StarterPack`, mixed/legacy packs) are either migrated or removed.
    - No duplicate prompt concepts remain because of overlapping legacy/new files.
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

- [ ] TASK: Rich metadata rollout and validation hardening for question packs
  - Type: Content Model / Validation
  - Priority: P0
  - Status: In Progress
  - Area: `Models/Question`, `Services/QuestionPackLoader`, `TapTenTests/Unit/QuestionPackLoaderTests`
  - Goal: Complete migration to richer question metadata while preserving compatibility.
  - Acceptance Criteria:
    - All active packs decode with metadata fields where present.
    - Loader validation errors remain clear and actionable.
    - Compatibility path for legacy `difficulty` remains intentional and documented.
  - Notes:
    - Code and tests are already partially updated in the current workspace.

- [ ] TASK: Content audit execution planning
  - Type: Planning / Content
  - Priority: P0
  - Status: In Progress
  - Area: repo root docs
  - Goal: Keep one actionable content work queue for subsequent implementation runs.
  - Acceptance Criteria:
    - `CONTENT_TODO.md` remains current with category counts, tier gaps, and review flags.
    - Tasks remain atomic enough for one-pass Codex execution.

## Blocked

- [ ] TASK: Content freeze for release candidate
  - Type: Release
  - Priority: P1
  - Status: Blocked
  - Area: Content pipeline
  - Goal: Reach a stable, balanced, low-ambiguity content set suitable for broad playtesting.
  - Acceptance Criteria:
    - Final 12 categories complete with 12 questions each and balanced tiers.
    - Manual ambiguity review issues are closed or explicitly deferred.
    - Duplicate and near-duplicate prompt checks are clean.
  - Notes:
    - Blocked by unfinished category migration and editorial review workload.

## Manual Review Needed
- Review ambiguous questions already flagged in `CONTENT_TODO.md`:
  - `geo-largest-deserts-world`
  - `geo-most-visited-countries-arrivals`
  - `things-that-make-parties-awkward`
  - `late-to-work-excuses`
  - `sci-famous-equations`
- Confirm desired scope for category availability during migration (show all final categories vs hide empty categories).
- Verify final tone split between `Film & TV` and `Pop Culture & Trends` to reduce overlap during authoring.
