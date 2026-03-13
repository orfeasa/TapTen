# Changelog

## 2026-03-12

### Added
- Post-timeup Host Round `Report Question` flow with:
  - native feedback sheet
  - question details (`category`, `difficulty`, `source`)
  - reason selection for `Too easy`, `Too difficult`, `Wrong category`, `Inappropriate`, or `Other`
  - optional notes, with notes required for `Other`
  - structured prefilled email draft for editorial review sent to `tapten-reports@orfeasa.com`

### Changed
- Setup ownership and navigation:
  - Settings now owns persistent defaults for rounds per team and round duration
  - New Game now focuses on team names, category filters, and difficulty tiers
  - Home now shows a lighter live `Current settings` summary and gives larger visual weight to its main actions
  - New Game now keeps `Start Game` pinned to the bottom so hosts can start without scrolling to the end of setup
- UI polish pass:
  - Home settings button now uses simpler native toolbar chrome
  - New Game now uses warm card-based setup sections instead of a plain settings-style form
  - Pass Device and other warm screens now use softer radial background color fields without visible gradient seams
  - in-flow `Start Round` and `Continue to Summary` CTAs now use the shared playful gradient capsule treatment
  - active Host Round `Pause` / `Resume` is now a lower-emphasis utility control
  - Host Round time-up review now carries labeled `View Source` and `Report Question` actions, while Round Summary stays focused on points, verdict, score, and progression
  - Round Summary verdict is larger and more characterful
  - Round Summary progression iconography now matches the rest of the game-flow CTA styling
  - in-game `End Game` confirmation is anchored to its toolbar action instead of using a visually misleading tip direction
  - Final Results now uses a stronger hero/score layout and a clearer `Home` secondary action instead of the previous setup-return action
  - Final Results `Home` now exits the full finished-game flow back to Home instead of landing on `New Game`

### Fixed
- Settings no longer crashes when changing rounds or timer defaults from the gear flow.
- New Game no longer relies on a `safeAreaInset` bottom CTA, reducing the risk of navigation-transition instability on push/pop.
- Host Round time-up layout no longer clips long question text under the review panel.
- Host Round time-up review tools now stack on narrow iPhones so `View Source` / `Report Question` no longer collide with long prompts.
- Report sheet action layout no longer shows an awkward separator between its two utility buttons.

### Platform
- iPhone app now runs portrait-only in v1; landscape is intentionally disabled until there is a real wider-layout pass.

### Docs
- Updated `PROJECT_BACKLOG.md`, `PROJECT_BRIEF.md`, `README.md`, and `RELEASE_CHECKLIST.md` to reflect the new Settings/New Game responsibility split and the shipped reporting flow.

## 2026-03-05

### Added
- `scripts/audit_question_packs.sh` for one-command local content integrity checks:
  - schema constraints (`10` answers, points `1...5`, score/tier consistency)
  - duplicate prompt detection
  - final category/tier coverage report
- `RELEASE_CHECKLIST.md` with reusable release smoke-test protocol and ship/no-ship gates.
- Home `Browse Question Packs` experience with:
  - category-level question/difficulty coverage
  - pack-level title/category/count summaries
- Debug-only round telemetry in `GameFlowViewModel` for playtest diagnostics (`category`, `revealed/total`, `points`, `time remaining`).

### Changed
- Game setup and flow:
  - Final Results secondary action now uses destination-accurate copy (`Home`) instead of the earlier setup-return wording
  - setup now exposes all 12 final categories
  - setup adds difficulty-tier filtering (`easy` / `medium` / `hard`)
  - start validation now surfaces a clear message when filters yield no playable pool
  - round summary CTA labels now use state-specific copy (`Next Round`, `Continue to Final Results`)
- Visual direction and controls:
  - applied a playful color refresh across Home, New Game, Settings, and game-flow surfaces
  - kept glass-like treatment restrained to controls/chips while preserving readable warm content surfaces
  - moved prominent system-tinted actions from blue to warm orange to align with Home styling
- Runtime feedback settings:
  - `Sounds` toggle now controls countdown and round-end audio behavior
  - `Haptics` toggle now controls reveal haptic feedback
- Content pipeline:
  - consolidated legacy mixed packs into one-pack-per-category structure
  - removed transitional files (`EverydayPack`, `FactualAndPopPack`, `PartyPack`, `StarterPack`)
  - promoted most `quality: "draft"` questions to `quality: "reviewed"`; explicit holdouts remain for manual review
- Accessibility polish:
  - improved Dynamic Type scaling on Host Round, Pass Device, Round Summary, and Final Results typography
  - added VoiceOver hints/combined semantics for key actions and pack-browser rows

### Docs
- Updated `PROJECT_BACKLOG.md` with completed backlog items and current in-progress accessibility pass.
- Updated `CONTENT_TODO.md` with post-consolidation audit status and explicit editorial holdouts.
- Updated `README.md` to reflect category+difficulty filtering, pack browser, runtime feedback wiring, and release checklist location.
- Updated post-game action wording docs (`Start New Game`) and warm/playful tint direction notes.

## 2026-03-04

### Added
- `CONTENT_TODO.md` as the single actionable content-work queue:
  - current per-category/per-tier coverage snapshot
  - gap analysis against the final 12-category target
  - atomic, category-grouped content tasks
  - manual review list for uncertain prompts
- `PROJECT_BACKLOG.md` as the main project planning document with:
  - product status
  - active decisions
  - prioritized backlog (`P0`, `P1`, `P2`)
  - in-progress, blocked, and manual-review sections
- `CONTENT_AUTHORING_SPEC.md` for project-local reusable question-pack authoring guidance.
- Additional category pack files for expanded content coverage:
  - `EverydayLifePack.json`
  - `FilmTVPack.json`
  - `FoodDrinkPack.json`
  - `GeographyPack.json`
  - `HistoryPack.json`
  - `SciencePack.json`
- New category pack files to complete the final category set:
  - `MusicPack.json`
  - `SportPack.json`
  - `TechnologyPack.json`
  - `TravelPack.json`
  - `WorkSchoolPack.json`
  - `PopCultureTrendsPack.json`

### Changed
- Home/onboarding UX:
  - Home layout simplified around brand + hero + one clear primary action
  - large `How To Play` card removed from Home
  - concise 3-step `How To Play` moved into a sheet
  - subtle warm gradient and restrained glass-like control styling applied to small controls
  - setup status capsules added near the top (`2 teams`, `5 rounds`, `60 sec`)
- Host Round interaction flow:
  - answer rows sorted alphabetically for faster host scanning
  - answers now support tap/tap-again toggle during active play and after timer end
  - dedicated `Undo Last` active-round control removed
  - active control simplified to `Pause` / `Resume`, then `Continue to Summary` when time is up
- Question model and loader:
  - richer question metadata support (`contentType`, `difficultyTier`, `difficultyScore`, `quality`, `tags`, `difficultyNotes`, `editorialNotes`)
  - validation enforces 10 answers, points in `1...5`, `difficultyScore == sum(points)`, and tier-band consistency
  - backward compatibility kept for legacy `difficulty` field where migration is needed
- Question pack content normalization:
  - final category taxonomy now fully populated (12 categories)
  - each category now has exactly 12 questions with exact 4 easy / 4 medium / 4 hard distribution
  - duplicate/near-duplicate prompt issues from migration were reduced and re-audited

### Docs
- Updated `README.md` to reflect:
  - current Home and Host Round UX behavior
  - pack metadata and validation requirements
- Updated `CONTENT_TODO.md` and `PROJECT_BACKLOG.md` to reflect completed category normalization and current remaining work.
- Updated `PROJECT_BRIEF.md` and `AGENTS.md` gameplay notes to match current Host Round interactions.
- Updated question-pack docs to align with audit-first content workflow and final category migration target.

## 2026-03-02

### Added
- Minimal native `Settings` screen with:
  - sounds on/off
  - haptics on/off
  - default rounds
  - default timer
- Safe in-game exit flow with confirmation before ending an active game.
- Optional editorial metadata support for local question packs:
  - `contentType`
  - `quality`
  - `difficultyNotes`
  - `editorialNotes`
  - `packVersion`

### Changed
- Visual direction across game flow screens:
  - warmer off-white surfaces
  - restrained celebration accents in warm gold/yellow
  - preserved native SwiftUI/Apple-clean feel
- Pass Device screen refined to feel ritual-like with clearer answering/hosting emphasis.
- Host Round screen refined for speed/clarity:
  - question-first hierarchy
  - active controls grouped together (`Undo Last`, `Pause`/`Resume`)
  - clear post-timeup continue flow
  - subtle reveal payoff and differentiated haptics
- Round Summary refined with stronger points-first hierarchy and playful verdict treatment.
- Final Results refined into a stronger finale:
  - winner hero emphasis
  - warmer celebration tone
  - clear `Play Again` and `Home` actions
- In-app copy refreshed to be concise, playful, and consistent.

### Fixed
- Round timer countdown stability issues in the final seconds.
- Removed countdown rendering artifacts that looked like value flicker/regression.
- Preserved post-timeup host ability to tick/untick answers before continuing.
- Clarified and aligned round-count behavior to be rounds per team (not total shared rounds).

### Docs
- Updated `README.md` to reflect current gameplay/UI behavior and data model.
- Updated `AGENTS.md` game rules to match current Host Round interactions.
