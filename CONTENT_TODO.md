# Content Todo

## Current Coverage
- Everyday Life: 13 total (3 easy, 7 medium, 3 hard)
- Food & Drink: 12 total (3 easy, 6 medium, 3 hard)
- Film & TV: 12 total (3 easy, 6 medium, 3 hard)
- Music: 0 total (0 easy, 0 medium, 0 hard)
- Sport: 0 total (0 easy, 0 medium, 0 hard)
- Geography: 13 total (6 easy, 4 medium, 3 hard)
- History: 10 total (3 easy, 4 medium, 3 hard)
- Science: 10 total (3 easy, 4 medium, 3 hard)
- Technology: 0 total (0 easy, 0 medium, 0 hard)
- Travel: 0 total (0 easy, 0 medium, 0 hard)
- Work & School: 0 total (0 easy, 0 medium, 0 hard)
- Pop Culture & Trends: 0 total (0 easy, 0 medium, 0 hard)

## Audit Highlights
- Missing categories: Music, Sport, Technology, Travel, Work & School, Pop Culture & Trends.
- Underfilled categories: History, Science.
- Overfilled categories: Everyday Life, Geography.
- Categories at 12 but with tier imbalance: Food & Drink, Film & TV.
- Exact duplicate concept found: `popular-pizza-toppings` and `food-recognizable-pizza-toppings` have equivalent prompt intent and identical answer sets.
- Near-duplicate prompt family found in Geography: multiple "most populous countries in <region>" prompts.

## Tasks

### Everyday Life
- [ ] REMOVE_QUESTIONS: Re-categorize `things-people-forget-to-pack` to Travel (keep question ID stable).
- [ ] REMOVE_QUESTIONS: Re-categorize `late-to-work-excuses` to Work & School (keep question ID stable).
- [ ] REMOVE_QUESTIONS: Re-categorize `life-mobile-app-categories-daily-use` to Technology (keep question ID stable).
- [ ] ADD_QUESTIONS: Add 1 easy Everyday Life question to reach 4 easy.
- [ ] ADD_QUESTIONS: Add 1 hard Everyday Life question to reach 4 hard.
- [ ] REVIEW_AMBIGUITY: Re-check `things-that-make-parties-awkward` for host adjudication speed; replace if matching rules are too subjective in playtests.

### Food & Drink
- [ ] REPLACE_QUESTIONS: Replace `popular-pizza-toppings` (medium) with a new easy question to remove duplicate intent with `food-recognizable-pizza-toppings`.
- [ ] REPLACE_QUESTIONS: Replace `midnight-snacks` (medium) with a new hard question to reach 4/4/4.
- [ ] REVIEW_DUPLICATES: Re-run prompt and answer-set duplication audit after replacements.

### Film & TV
- [ ] REMOVE_QUESTIONS: Re-categorize `karaoke-songs` to Music (keep question ID stable).
- [ ] REMOVE_QUESTIONS: Re-categorize `highest-grossing-film-franchises` to Pop Culture & Trends (keep question ID stable).
- [ ] ADD_QUESTIONS: Add 1 easy Film & TV question to reach 4 easy.
- [ ] ADD_QUESTIONS: Add 1 hard Film & TV question to reach 4 hard.

### Music
- [ ] CREATE_PACK: Create `MusicPack.json` with category `Music`, 12 questions total, and exact 4 easy / 4 medium / 4 hard.
- [ ] ADD_QUESTIONS: Seed with `karaoke-songs` (medium) and add 11 new questions (4 easy, 3 medium, 4 hard).
- [ ] REVIEW_AMBIGUITY: Ensure song prompts specify acceptance rules for remakes, covers, and alternate titles.

### Sport
- [ ] CREATE_PACK: Create `SportPack.json` with category `Sport`, 12 questions total, and exact 4 easy / 4 medium / 4 hard.
- [ ] REVIEW_AMBIGUITY: Prefer objective list prompts (teams, events, positions, equipment) over subjective "best ever" prompts.

### Geography
- [ ] REPLACE_QUESTIONS: Replace one easy question (`countries-starting-b` recommended) with one hard question to improve tier balance.
- [ ] REMOVE_QUESTIONS: Remove one additional easy question from the repetitive populous-country family (`geo-most-populous-countries-south-america` recommended) to land at 12 total.
- [ ] REVIEW_DUPLICATES: Review near-duplicate prompt family: `geo-most-populous-countries-europe`, `geo-most-populous-countries-north-america`, `geo-most-populous-countries-south-america`, `geo-most-populous-countries-world`.
- [ ] REVIEW_AMBIGUITY: Fix `geo-largest-deserts-world` prompt/answer mismatch ("hot deserts" wording conflicts with current answers).
- [ ] REVIEW_AMBIGUITY: Review or replace `geo-most-visited-countries-arrivals` because rankings are year-sensitive; anchor to a specific year if kept.

### History
- [ ] ADD_QUESTIONS: Add 1 easy and 1 hard History question to reach 12 total and 4/4/4 spread.
- [ ] REVIEW_AMBIGUITY: Review `hist-foundational-documents` for scope consistency and fast host adjudication.

### Science
- [ ] ADD_QUESTIONS: Add 1 easy and 1 hard Science question to reach 12 total and 4/4/4 spread.
- [ ] REVIEW_AMBIGUITY: Review `sci-famous-equations` and document acceptable spoken variants (name vs symbolic form).

### Technology
- [ ] CREATE_PACK: Create `TechnologyPack.json` with category `Technology`, 12 questions total, and exact 4 easy / 4 medium / 4 hard.
- [ ] ADD_QUESTIONS: Seed with `life-mobile-app-categories-daily-use` (medium) and add 11 new questions (4 easy, 3 medium, 4 hard).
- [ ] REVIEW_AMBIGUITY: Avoid rapidly dated model/version trivia unless a source year is explicitly included.

### Travel
- [ ] CREATE_PACK: Create `TravelPack.json` with category `Travel`, 12 questions total, and exact 4 easy / 4 medium / 4 hard.
- [ ] ADD_QUESTIONS: Seed with `things-people-forget-to-pack` (medium) and add 11 new questions (4 easy, 3 medium, 4 hard).
- [ ] REVIEW_DUPLICATES: Check overlap against Geography prompts to keep category intent distinct.

### Work & School
- [ ] CREATE_PACK: Create `WorkSchoolPack.json` with category `Work & School`, 12 questions total, and exact 4 easy / 4 medium / 4 hard.
- [ ] ADD_QUESTIONS: Seed with `late-to-work-excuses` (medium) and add 11 new questions (4 easy, 3 medium, 4 hard).
- [ ] REVIEW_AMBIGUITY: Replace novelty-only answers (for example, "Alien abduction") if they reduce fairness in host adjudication.

### Pop Culture & Trends
- [ ] CREATE_PACK: Create `PopCultureTrendsPack.json` with category `Pop Culture & Trends`, 12 questions total, and exact 4 easy / 4 medium / 4 hard.
- [ ] ADD_QUESTIONS: Seed with `highest-grossing-film-franchises` (medium) and add 11 new questions (4 easy, 3 medium, 4 hard).
- [ ] REVIEW_DUPLICATES: Check overlap against Film & TV and Music so prompt scopes stay distinct.

## Manual Review Needed
- `geo-largest-deserts-world`: prompt says "hot deserts" but current answers include non-hot deserts.
- `geo-most-visited-countries-arrivals`: likely year-sensitive; requires dated scope or replacement.
- `things-that-make-parties-awkward`: can be subjective and may slow host adjudication.
- `late-to-work-excuses`: contains novelty answer ("Alien abduction") that may conflict with category tone.
- `sci-famous-equations`: spoken matching may be inconsistent without explicit acceptance notes.
