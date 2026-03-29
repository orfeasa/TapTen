# Content Todo

## Current Coverage
Free starter library:
- Everyday Life: 30 total (10 easy, 10 medium, 10 hard)
- Food & Drink: 30 total (10 easy, 10 medium, 10 hard)
- Film & TV: 30 total (10 easy, 10 medium, 10 hard)
- Music: 30 total (10 easy, 10 medium, 10 hard)
- Sport: 30 total (10 easy, 10 medium, 10 hard)
- Geography: 30 total (10 easy, 10 medium, 10 hard)
- History: 30 total (10 easy, 10 medium, 10 hard)
- Science: 30 total (10 easy, 10 medium, 10 hard)
- Technology: 30 total (10 easy, 10 medium, 10 hard)
- Travel: 30 total (10 easy, 10 medium, 10 hard)
- Work & School: 30 total (10 easy, 10 medium, 10 hard)
- Pop Culture & Trends: 30 total (10 easy, 10 medium, 10 hard)

## Audit Highlights
- Missing categories: none.
- Underfilled categories: none.
- Overfilled categories: none.
- Target distribution status: all 12 categories now meet 30 total questions with exact 10 easy / 10 medium / 10 hard.
- Open structural content tasks: none.
- Legacy mixed packs have been consolidated; active content now uses one pack file per final category.
- Duplicate pizza concept was removed; exact duplicate prompt/answer-set audit is currently clean.
- Geography duplicate-family risk reduced (South America populous prompt removed); exact duplicate prompt/answer-set audit is clean.
- Most draft questions have been promoted to `reviewed`; only targeted ambiguity/recency holdouts remain `draft`.
- Audit tooling now treats the 12-category starter library and premium expansions separately, so premium packs can add new playable categories without weakening the free-base guarantees.

## Premium Expansion Queue

### Evergreen Launch Wave
- [x] CREATE_PACK: Author `After Dark Vol. 1` as a 40-question premium expansion (`14 easy / 13 medium / 13 hard`) with broad adult party energy that stays suggestive rather than explicit.
- [x] CREATE_PACK: Author `Date Night` as a 40-question premium expansion (`14 easy / 13 medium / 13 hard`) focused on couples, flirting, romance, and relationship habits.
- [x] CREATE_PACK: Author `Office & Icebreakers` as a 40-question premium expansion (`14 easy / 13 medium / 13 hard`) covering meetings, presentations, workplace awkwardness, and team banter.
- [x] REVIEW_POSITIONING: Finalized one-line store descriptions and audience labels for the first three evergreen premium expansions.
- [x] REVIEW_DUPLICATES: Audit the evergreen premium wave against the free starter library to avoid prompt-family overlap that weakens perceived value.

Approved positioning:
- `After Dark Vol. 1`
  - audience label: Adults
  - store line: `Cheeky, chaotic prompts for grown-up game nights.`
- `Date Night`
  - audience label: Couples
  - store line: `Flirty, romantic, and mildly exposing in the fun way.`
- `Office & Icebreakers`
  - audience label: Work Friends
  - store line: `Meeting-room awkwardness, presentation panic, and team-banter gold.`

### Seasonal Premium Follow-Up
- [x] CREATE_PACK: Author `Holiday Chaos` as a 40-question premium expansion (`14 easy / 13 medium / 13 hard`) covering travel stress, gift drama, family gatherings, and party mishaps.
- [x] REVIEW_TIMING: Prepared `Holiday Chaos` for an October to November merchandising window with copy that still reads well after purchase outside the season.

Approved positioning:
- `Holiday Chaos`
  - audience label: Seasonal
  - store line: `Travel meltdowns, gift drama, and festive-group chaos.`
  - merchandising window: October to November

### Wave-2 Discovery
- [ ] DISCOVERY: Scope `Family-Friendly Extras` as the next evergreen premium candidate after the first paid launch.
- [ ] DISCOVERY: Scope `US Pop Culture / 2020s Trends` with explicit guardrails for recency drift and faster content aging.

### Everyday Life
- [x] REMOVE_QUESTIONS: Re-categorize `things-people-forget-to-pack` to Travel (kept question ID stable).
- [x] REMOVE_QUESTIONS: Re-categorize `late-to-work-excuses` to Work & School (kept question ID stable).
- [x] REMOVE_QUESTIONS: Re-categorize `life-mobile-app-categories-daily-use` to Technology (kept question ID stable).
- [x] ADD_QUESTIONS: Added 1 easy Everyday Life question (`life-common-bathroom-items`) to reach 4 easy.
- [x] ADD_QUESTIONS: Added 1 hard Everyday Life question (`life-important-personal-documents`) to reach 4 hard.
- [x] REVIEW_AMBIGUITY: Replaced `things-that-make-parties-awkward` content with a less subjective event-disruption variant while keeping the same ID.

### Food & Drink
- [x] REPLACE_QUESTIONS: Replaced `popular-pizza-toppings` (medium) with a new easy question (`food-common-fresh-fruits`) to remove duplicate pizza intent.
- [x] REPLACE_QUESTIONS: Replaced `midnight-snacks` (medium) with a new hard question (`food-common-wine-grape-varieties`) to reach 4/4/4.
- [x] REVIEW_DUPLICATES: Re-ran prompt and answer-set duplication audit after replacements.

### Film & TV
- [x] REMOVE_QUESTIONS: Re-categorized `karaoke-songs` to Music (kept question ID stable).
- [x] REMOVE_QUESTIONS: Re-categorized `highest-grossing-film-franchises` to Pop Culture & Trends (kept question ID stable).
- [x] ADD_QUESTIONS: Added 1 easy Film & TV question (`film-major-streaming-platforms`) to reach 4 easy.
- [x] ADD_QUESTIONS: Added 1 hard Film & TV question (`film-common-camera-shot-types`) to reach 4 hard.

### Music
- [x] CREATE_PACK: Created `MusicPack.json`; the category now sits at the current 30-question target with balanced tiers.
- [x] ADD_QUESTIONS: Kept seeded `karaoke-songs` (medium) and added 11 new questions (4 easy, 3 medium, 4 hard).
- [x] REVIEW_AMBIGUITY: Added acceptance guidance in editorial notes across music prompts where naming variants are likely.

### Sport
- [x] CREATE_PACK: Created `SportPack.json`; the category now sits at the current 30-question target with balanced tiers.
- [x] REVIEW_AMBIGUITY: Used objective prompts focused on positions, events, rules, and terminology.

### Geography
- [x] REPLACE_QUESTIONS: Replaced one easy geography question with a hard one (`geo-largest-islands-world`) to improve tier balance.
- [x] REMOVE_QUESTIONS: Removed `geo-most-populous-countries-south-america` to land at 12 total.
- [x] REVIEW_DUPLICATES: Reviewed populous-country near-duplicate family and reduced overlap by removing one region-level prompt.
- [x] REVIEW_AMBIGUITY: Fixed `geo-largest-deserts-world` mismatch by changing scope to non-polar deserts.
- [x] REVIEW_AMBIGUITY: Anchored `geo-most-visited-countries-arrivals` to 2019 in prompt and notes for stable adjudication.

### History
- [x] ADD_QUESTIONS: Added 1 easy (`hist-world-changing-inventions`) and 1 hard (`hist-major-chinese-dynasties`) History question to reach 12 and 4/4/4.
- [x] REVIEW_AMBIGUITY: Updated `hist-foundational-documents` prompt/notes for clearer scope and spoken adjudication.

### Science
- [x] ADD_QUESTIONS: Added 1 easy (`sci-common-weather-phenomena`) and 1 hard (`sci-human-endocrine-glands`) Science question to reach 12 and 4/4/4.
- [x] REVIEW_AMBIGUITY: Updated `sci-famous-equations` editorial notes with explicit spoken variant acceptance guidance.

### Technology
- [x] CREATE_PACK: Created `TechnologyPack.json`; the category now sits at the current 30-question target with balanced tiers.
- [x] ADD_QUESTIONS: Kept seeded `life-mobile-app-categories-daily-use` (medium) and added 11 new questions (4 easy, 3 medium, 4 hard).
- [x] REVIEW_AMBIGUITY: Used mostly stable concepts and avoided rapidly dated model/version trivia.

### Travel
- [x] CREATE_PACK: Created `TravelPack.json`; the category now sits at the current 30-question target with balanced tiers.
- [x] ADD_QUESTIONS: Kept seeded `things-people-forget-to-pack` (medium) and added 11 new questions (4 easy, 3 medium, 4 hard).
- [x] REVIEW_DUPLICATES: Reviewed overlap against Geography and kept travel prompts focused on transport, booking, airports, and trip logistics.

### Work & School
- [x] CREATE_PACK: Created `WorkSchoolPack.json`; the category now sits at the current 30-question target with balanced tiers.
- [x] ADD_QUESTIONS: Kept seeded `late-to-work-excuses` (medium) and added 11 new questions (4 easy, 3 medium, 4 hard).
- [x] REVIEW_AMBIGUITY: Replaced novelty-only answer in `late-to-work-excuses` ("Alien abduction") with a plausible answer ("Public transport strike").

### Pop Culture & Trends
- [x] CREATE_PACK: Created `PopCultureTrendsPack.json`; the category now sits at the current 30-question target with balanced tiers.
- [x] ADD_QUESTIONS: Kept seeded `highest-grossing-film-franchises` (medium) and added 11 new questions (4 easy, 3 medium, 4 hard).
- [x] REVIEW_DUPLICATES: Checked overlap against Film & TV and Music and kept prompt scopes distinct.

## Manual Review Needed
- Keep these intentionally-held draft items under manual editorial review before content freeze:
  - `film-classic-animated-tv-series`
  - `geo-most-visited-countries-arrivals`
  - `music-jazz-subgenres`
  - `sci-famous-equations`
  - `pop-common-chat-emojis`
  - `pop-common-internet-slang`
  - `pop-fashion-style-labels`
  - `travel-border-control-terms`
  - `travel-common-visa-types`
  - `workschool-teaching-method-terms`
