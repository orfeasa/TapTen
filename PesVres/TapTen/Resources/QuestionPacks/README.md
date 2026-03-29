# Question Packs

Question packs are bundled local JSON files for v1.

- One file contains one pack.
- Each question must include exactly 10 answers.
- Each question must provide difficulty metadata:
  - `difficultyScore` must equal the sum of all 10 answer `points`.
  - `difficultyTier` uses these bands:
    - `easy`: 12...18
    - `medium`: 19...26
    - `hard`: 27...35
- Each question must include one `validationStyle`: `factual`, `editorial`, or `humorous`.
- Answer points must be between 1 and 5.
- Each question must include one `sourceURL`.
- Source URLs must be valid `http` or `https` links.

Optional editorial metadata (not shown in gameplay UI yet):
- Pack level: `summary`, `packVersion`
- Optional pack monetization metadata: `monetization.access`, `monetization.storeProductID`, `monetization.bundleProductIDs`, `monetization.merchandisingLabel`
- Question level: `contentType`, `quality`, `tags`, `difficultyNotes`, `editorialNotes`
- Legacy compatibility: existing `difficulty` (`easy`/`medium`/`hard`) is still accepted during migration.

Current content planning docs:
- Authoring rules: `CONTENT_AUTHORING_SPEC.md`
- Remaining content work: repo-root `CONTENT_TODO.md`
- Project-level prioritization: repo-root `PROJECT_BACKLOG.md`
- Audit command: repo-root `./scripts/audit_question_packs.sh`

Current repository layout:
- The permanent free starter library uses one active JSON pack per final category (12 files total today).
- Premium expansion JSON files can live alongside those base packs and declare `monetization.access: "premium"`.
- The setup screen derives playable categories from the currently accessible bundled packs.

Target final category set:
- Everyday Life
- Food & Drink
- Film & TV
- Music
- Sport
- Geography
- History
- Science
- Technology
- Travel
- Work & School
- Pop Culture & Trends

## Post-Edit Audit (Required)

After adding or changing pack content, run a quick audit before merging:
- no duplicate prompts across JSON files
- no duplicate or overlapping answers within a question
- every question has exactly 10 answers
- answer points stay in `1...5`
- `difficultyScore` equals sum of answer points
- `difficultyTier` matches score band (`easy 12...18`, `medium 19...26`, `hard 27...35`)
- spot-check prompts for host speed and low ambiguity in spoken play
- verify the free starter library remains at `12` questions per base category with `4 easy / 4 medium / 4 hard`
- verify each premium expansion pack lands at `24` questions with `8 easy / 8 medium / 8 hard`
