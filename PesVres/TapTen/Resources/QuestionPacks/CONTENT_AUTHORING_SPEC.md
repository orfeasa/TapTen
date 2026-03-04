# Tap Ten Question Pack Authoring Spec

This spec defines how to author future `QuestionPacks/*.json` files for Tap Ten.

## 1) JSON Schema Used by the App

### Pack object

Required fields:
- `id` (string, non-empty)
- `title` (string, non-empty)
- `languageCode` (string, non-empty, currently `en`)
- `questions` (array, at least 1)

Optional fields:
- `packVersion` (string)

### Question object

Required fields:
- `id` (string, non-empty)
- `category` (string, non-empty)
- `prompt` (string, non-empty)
- `validationStyle` (`factual` | `editorial` | `humorous`)
- `sourceURL` (valid `http`/`https` URL)
- `answers` (array of exactly 10 answer objects)

Difficulty fields:
- `difficultyScore` (integer) should be present on new content
- `difficultyTier` (`easy` | `medium` | `hard`) should be present on new content
- `difficulty` (legacy) is accepted for migration compatibility

Optional metadata:
- `contentType` (string)
- `quality` (string)
- `tags` (array of strings)
- `difficultyNotes` (string)
- `editorialNotes` (string)

### Answer object

Required fields:
- `text` (string, non-empty)
- `points` (integer, `1...5`)

Validation:
- exactly 10 answers per question
- answer texts must be unique within a question (case-insensitive)

## 2) Allowed Categories

Use this final category set exactly:
- `Everyday Life`
- `Food & Drink`
- `Film & TV`
- `Music`
- `Sport`
- `Geography`
- `History`
- `Science`
- `Technology`
- `Travel`
- `Work & School`
- `Pop Culture & Trends`

Migration note:
- If content introduces or reassigns categories, keep `CategoryCatalogService` in sync so setup filtering remains accurate.

## 3) contentType Rules

`contentType` is optional but recommended for curation/searching.

Rules:
- use short kebab-case labels (`factual-list`, `opinion-list`, `humorous-scenarios`)
- one primary type per question
- keep naming stable across packs

## 4) difficultyScore and difficultyTier Rules

`difficultyScore` is the sum of all 10 answer `points`.

`difficultyTier` must match score band:
- `easy`: `12...18`
- `medium`: `19...26`
- `hard`: `27...35`

Authoring workflow:
1. Assign answer points.
2. Compute total score.
3. Set `difficultyScore` to that total.
4. Set `difficultyTier` from the matching band.

## 5) Answer Scoring Guidelines

Scoring is per answer, not per question:
- `1`: very common / obvious guess
- `2`: common
- `3`: moderate stretch
- `4`: hard
- `5`: rare but fair

Guidance:
- keep lower-point answers as common spoken guesses
- reserve `4`/`5` for legitimate stretch answers, not trivia traps
- design the full 10-answer distribution to hit the intended tier band

## 6) Prompt-Writing Guidelines (Spoken Party Play)

- Write prompts that are easy to read aloud in one breath.
- Prefer plain language and everyday wording.
- Keep scope clear (single idea, no ambiguity).
- Avoid tricky negations, legalistic wording, or multi-part asks.
- Optimize for fast host matching of spoken guesses.

## 7) Duplicate and Overlap Rules

- No duplicate answer text (case-insensitive).
- Avoid near-duplicates that collapse to the same spoken intent.
- Avoid parent/child overlap (example: `Dog` and `Golden Retriever` in same list) unless intentionally scoped and clearly defensible.
- Keep answers mutually distinct enough for fast host judgment.

## 8) Tone and Safety Constraints

- Keep tone playful, social, and party-appropriate.
- Avoid hate, harassment, explicit sexual content, and graphic violence.
- Avoid prompts that target protected classes or encourage humiliation.
- Avoid medical/legal/financial advice framing in question content.

## 9) Source Expectations

- Exactly one source URL per question.
- Source should support the list framing (factual or curated editorial basis).
- Prefer stable, reputable URLs over ephemeral links.
- Use direct links when possible, not generic homepages.

## 10) quality Field Usage

`quality` is optional curation metadata. Use a small consistent vocabulary:
- `draft` (new, not reviewed)
- `reviewed` (editor reviewed)
- `playtested` (validated in real gameplay)
- `needs-refresh` (source or relevance aging)

Keep values lowercase kebab-case and consistent across packs.

## 11) Post-Change Audit Checklist

Any pack update should include a lightweight audit pass before merge.

Required checks:
- Prompt uniqueness across all pack files (no duplicate prompts).
- Schema/validation integrity per question:
  - exactly 10 answers
  - answer points in `1...5`
  - `difficultyScore == sum(answer points)`
  - `difficultyTier` matches score band
- No duplicate or near-overlapping answers inside a single question.
- Prompt adjudication speed: host can map spoken guesses quickly without legalistic interpretation.
- Category-level review: verify each category still has a sensible easy/medium/hard spread for available question count.
- Category target review: for release target, each category should remain at exactly 12 questions with 4 easy / 4 medium / 4 hard.

Recommended cadence:
- Run full audit after any batch edit to packs.
- Mark newly added or significantly changed questions as `quality: \"draft\"` until reviewed/playtested.
- Keep repo-root `CONTENT_TODO.md` updated after each content audit pass.

## Example Question (recommended style)

```json
{
  "id": "countries-starting-s",
  "category": "Geography",
  "prompt": "Name countries that start with the letter S",
  "validationStyle": "factual",
  "difficultyTier": "medium",
  "difficultyScore": 19,
  "contentType": "factual-list",
  "quality": "reviewed",
  "tags": ["geography", "countries", "letters"],
  "difficultyNotes": "Common entries first, rarer entries toward the end.",
  "editorialNotes": "Accept common spoken variants.",
  "sourceURL": "https://en.wikipedia.org/wiki/List_of_sovereign_states",
  "answers": [
    { "text": "Spain", "points": 1 },
    { "text": "Sweden", "points": 1 },
    { "text": "Switzerland", "points": 1 },
    { "text": "Serbia", "points": 2 },
    { "text": "Slovakia", "points": 2 },
    { "text": "Slovenia", "points": 2 },
    { "text": "Singapore", "points": 2 },
    { "text": "South Africa", "points": 2 },
    { "text": "Sudan", "points": 2 },
    { "text": "San Marino", "points": 3 }
  ]
}
```
