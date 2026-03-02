# Changelog

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

### Docs
- Updated `README.md` to reflect current gameplay/UI behavior and data model.
- Updated `AGENTS.md` game rules to match current Host Round interactions.
