# Changelog

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

### Docs
- Updated `README.md` to reflect:
  - current Home and Host Round UX behavior
  - pack metadata and validation requirements
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
