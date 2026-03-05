# Content Todo

## Current Coverage
- Everyday Life: 12 total (4 easy, 4 medium, 4 hard)
- Food & Drink: 12 total (4 easy, 4 medium, 4 hard)
- Film & TV: 12 total (4 easy, 4 medium, 4 hard)
- Music: 12 total (4 easy, 4 medium, 4 hard)
- Sport: 12 total (4 easy, 4 medium, 4 hard)
- Geography: 12 total (4 easy, 4 medium, 4 hard)
- History: 12 total (4 easy, 4 medium, 4 hard)
- Science: 12 total (4 easy, 4 medium, 4 hard)
- Technology: 12 total (4 easy, 4 medium, 4 hard)
- Travel: 12 total (4 easy, 4 medium, 4 hard)
- Work & School: 12 total (4 easy, 4 medium, 4 hard)
- Pop Culture & Trends: 12 total (4 easy, 4 medium, 4 hard)

## Audit Highlights
- Missing categories: none.
- Underfilled categories: none.
- Overfilled categories: none.
- Target distribution status: all 12 categories now meet 12 total questions with exact 4 easy / 4 medium / 4 hard.
- Open structural content tasks: none.
- Legacy mixed packs have been consolidated; active content now uses one pack file per final category.
- Duplicate pizza concept was removed; exact duplicate prompt/answer-set audit is currently clean.
- Geography duplicate-family risk reduced (South America populous prompt removed); exact duplicate prompt/answer-set audit is clean.
- Most draft questions have been promoted to `reviewed`; only targeted ambiguity/recency holdouts remain `draft`.

## Tasks

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
- [x] CREATE_PACK: Created `MusicPack.json` and reached category total 12 with exact 4 easy / 4 medium / 4 hard.
- [x] ADD_QUESTIONS: Kept seeded `karaoke-songs` (medium) and added 11 new questions (4 easy, 3 medium, 4 hard).
- [x] REVIEW_AMBIGUITY: Added acceptance guidance in editorial notes across music prompts where naming variants are likely.

### Sport
- [x] CREATE_PACK: Created `SportPack.json` with category `Sport`, 12 questions total, and exact 4 easy / 4 medium / 4 hard.
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
- [x] CREATE_PACK: Created `TechnologyPack.json` and reached category total 12 with exact 4 easy / 4 medium / 4 hard.
- [x] ADD_QUESTIONS: Kept seeded `life-mobile-app-categories-daily-use` (medium) and added 11 new questions (4 easy, 3 medium, 4 hard).
- [x] REVIEW_AMBIGUITY: Used mostly stable concepts and avoided rapidly dated model/version trivia.

### Travel
- [x] CREATE_PACK: Created `TravelPack.json` and reached category total 12 with exact 4 easy / 4 medium / 4 hard.
- [x] ADD_QUESTIONS: Kept seeded `things-people-forget-to-pack` (medium) and added 11 new questions (4 easy, 3 medium, 4 hard).
- [x] REVIEW_DUPLICATES: Reviewed overlap against Geography and kept travel prompts focused on transport, booking, airports, and trip logistics.

### Work & School
- [x] CREATE_PACK: Created `WorkSchoolPack.json` and reached category total 12 with exact 4 easy / 4 medium / 4 hard.
- [x] ADD_QUESTIONS: Kept seeded `late-to-work-excuses` (medium) and added 11 new questions (4 easy, 3 medium, 4 hard).
- [x] REVIEW_AMBIGUITY: Replaced novelty-only answer in `late-to-work-excuses` ("Alien abduction") with a plausible answer ("Public transport strike").

### Pop Culture & Trends
- [x] CREATE_PACK: Created `PopCultureTrendsPack.json` and reached category total 12 with exact 4 easy / 4 medium / 4 hard.
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
