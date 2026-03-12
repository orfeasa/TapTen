# Project Brief: iPhone Party Guessing Game

## One-line summary
A polished, host-operated iPhone party game where one team guesses answers to a prompt while the opposing team holds the phone, reads the question, and taps matching answers from a predefined list of 10.

## Product vision
Build a fast, elegant, humorous, iPhone-first party game with native iOS UX. The app should feel Apple-clean rather than flashy, while still creating high-pressure energy during timed rounds.

## Core experience
Two teams play on a single device.

- Team A takes a turn answering.
- Someone from Team B holds the phone and acts as host.
- The host sees the question and all 10 valid answers.
- Team A shouts guesses out loud.
- The host taps an answer when it is mentioned.
- The tapped answer becomes revealed and awards its points.
- After time expires, the round ends and the score is shown.
- Then Team B takes a turn while someone from Team A hosts.
- This alternates until all rounds are complete.

## v1 product decisions
- Platform: iPhone first
- Framework: SwiftUI
- Device mode: single device only
- Teams: 2
- Multiplayer sync: no
- Win condition: fixed number of rounds
- Default number of rounds: 5
- Question assignment: random from enabled categories
- Repeat questions in a session: not allowed
- Input method: host manually taps answers
- Steal mechanic: no
- Score visibility during round: hidden from players
- Score visibility after round: visible
- Source links: shown after a round only
- Content language: English only
- Tone: Apple-clean/minimal, but humorous and high-pressure
- Monetisation: maybe later, not part of v1

## UX principles
1. Native first
   - Use standard iOS navigation and controls.
   - Prefer system typography and SF Symbols.
   - Avoid custom design systems unless truly needed.

2. Optimise for host speed
   - The host is reading, listening, and tapping under pressure.
   - Make answer rows large and easy to hit.
   - Keep the timer visible at all times.
   - Minimise clutter and decision load.

3. Respect the single-device handoff
   - Include a pass-device privacy step before rounds.
   - Do not expose the question too early.
   - The answering team should not be able to see the answer list.

4. Keep tension high, visuals calm
   - Clean layout most of the time.
   - Pressure comes from timing, pacing, and small feedback cues.
   - Use restrained motion and haptics.

## Gameplay rules
### Setup
Players choose:
- Team A name
- Team B name
- Included and excluded categories
- Included difficulty tiers

Persistent settings control:
- Number of rounds
- Round duration in seconds

### During a round
- Exactly one question is active.
- The host sees all 10 answers immediately.
- Each answer has a point value from 1 to 5.
- Tapping an answer toggles it between revealed and unrevealed.
- Round points are always the sum of currently revealed answers.
- While time is active, the host uses `Pause` / `Resume` to manage pace.
- After timer expiry, the host can still adjust revealed answers before continuing.
- The round ends when the timer hits zero.

### Scoring
- Answer points equal difficulty weight.
- 1 point = very easy
- 5 points = very hard
- No speed bonus in v1
- No steal bonus in v1
- No base-plus-multiplier scheme in v1

### End of game
- After the fixed number of rounds is complete, show final scores.
- Highest total score wins.

## Question content strategy
The app supports multiple question styles:
- factual
- editorial
- humorous

Examples:
- Factual: Countries that start with the letter S
- Editorial: Things people forget to pack
- Humorous: Excuses students use for not doing homework

Important framing:
- Not every question type is objectively provable.
- For editorial and humorous prompts, answers are curated by the pack editor.
- The app should be treated as a curated party game, not an absolute truth engine.

## Content rules
- Each question has exactly 10 answers.
- Each question has exactly one source link.
- One source can support the question as a whole.
- Questions should belong to a category.
- Questions should include a validation style: factual, editorial, or humorous.
- Questions should be designed for spoken guessing, not silent trivia play.
- Answers should be short and easy for a host to scan quickly.

## Example question
Prompt: Name countries that start with the letter S

Example answers:
- Spain (1)
- Sweden (1)
- Switzerland (1)
- Serbia (2)
- Slovakia (2)
- Slovenia (2)
- Singapore (2)
- South Africa (2)
- Sudan (2)
- San Marino (3)

## Screen list for v1
1. Home
2. New Game
3. Round Intro
4. Pass Device / Privacy Screen
5. Host Round Screen
6. Round Summary
7. Scoreboard
8. Final Results
9. Question Pack Browser
10. Settings

## Detailed screen notes
### Home
- Start new game
- Browse packs
- Open How To Play sheet
- Open settings

### New Game
- Team names
- Category include/exclude
- Difficulty include/exclude
- Start game

### Round Intro
- Show whose turn it is
- Explain who should hold the phone
- Transition into privacy handoff

### Pass Device / Privacy Screen
- Prevent spoilers during handoff
- Use a clear ready or press-and-hold action

### Host Round Screen
- Show the question clearly
- Show a large countdown timer
- Show all 10 answers to the host
- Make answer taps fast and forgiving
- Keep active controls simple (`Pause`/`Resume`) and provide clear post-timeup `Continue to Summary`

### Round Summary
- Show answers found
- Show missed answers
- Show points earned this round
- Show optional source link

### Scoreboard
- Show both team totals
- Show rounds completed and remaining
- Show which team is next

### Final Results
- Show winner and final scores
- Replay or start a new game

## Technical direction
### Tech choices
- SwiftUI for UI
- Bundled JSON for v1 question packs
- Local-only architecture for v1
- Keep persistence minimal initially

### Suggested project structure
- Models/
- Views/
- ViewModels/
- Services/
- Resources/QuestionPacks/
- Tests/

### Suggested model types
- Team
- GameSettings
- QuestionPack
- Question
- AnswerOption
- RoundState
- GameSession
- ValidationStyle

## Non-goals for v1
- Cross-device multiplayer
- Live internet content fetching during gameplay
- User accounts
- User-generated packs
- Android app
- In-app purchases
- Social sharing
- Complex animations

## Quality bar
The app should:
- feel natively iOS
- compile cleanly
- use restrained, high-quality UI
- be playable by real people without explanation after a short intro
- be robust against accidental double taps and host mistakes

## Done when
The MVP is done when:
- a new game can be configured
- categories can be included or excluded
- a random unused question is selected from enabled categories
- alternating turns between the two teams work correctly
- the host can reveal answers and award points once only
- the timer ends the round correctly
- round summaries and total scores are correct
- the game ends after the configured number of rounds
- the UI feels coherent and native on iPhone

## Implementation preferences for Codex
- Start with the smallest working version.
- Build one screen or service at a time.
- Keep edits local and understandable.
- Add previews and tests as features stabilise.
- Refactor only after the core flow works.
