# Content Review Workflow

Status: Operating workflow for reviewing, approving, and shipping Tap Ten questions.

Last updated: 2026-04-06

## Why This Exists

Tap Ten question content is curated editorial content, not user-generated runtime data.

That means question quality needs a real review process before shipping, especially if:

- all existing questions should pass through a consistent approval path
- new packs and future questions will keep being added
- more than one person may help review content

This document defines that process.

## Core Principle

Approval is a content decision, not just a schema pass.

A question is not ready to ship only because it:

- has valid JSON
- has 10 answers
- passes score and tier checks

A shippable question also needs:

- clear spoken-play wording
- defensible answer set boundaries
- sensible category placement
- appropriate tone
- source support
- acceptable host adjudication speed

## Relationship To Existing Content Metadata

This workflow intentionally fits the current repo and app model.

Current content metadata already supports:

- `quality`
- `editorialNotes`
- `difficultyNotes`
- `packVersion`

Current `quality` values remain:

- `draft`
- `reviewed`
- `playtested`
- `needs-refresh`

Important rule:

- use workflow approval states for the process
- use `quality` as the lightweight content-status signal stored in JSON

Do not overload the JSON with many process-only states unless the repo truly needs that later.

## Roles

Recommended roles for a small editorial workflow:

### Author

Creates or edits a question.

Responsible for:

- initial prompt and answer set
- source selection
- difficulty scoring
- first-pass editorial notes
- self-check before review

### Reviewer

Checks whether the question is good enough for gameplay and content quality.

Responsible for:

- ambiguity review
- category fit review
- answer distinctness review
- tone and suitability review
- spoken-play speed review

### Approver

Makes the final ship/no-ship call for the current revision.

For a small team, the reviewer and approver can be the same person.

For higher confidence:

- use one reviewer plus one approver for premium packs or sensitive categories

### Playtest Reviewer

Optional but useful before release.

Responsible for:

- checking how the question behaves in real rounds
- spotting answer-list friction
- identifying adjudication or pacing issues not obvious on paper

## Review Units

Review content at the question level, not only at the pack level.

Each question should be independently able to move through the workflow.

Pack-level review still matters for:

- overlap
- category balance
- tier balance
- theme consistency

But pack review should happen after question-level review, not instead of it.

## Workflow States

Use these process states in docs, review sheets, or backlog tracking:

- `proposed`
- `in-review`
- `changes-requested`
- `approved`
- `playtested`
- `shipped`
- `refresh-needed`

Recommended mapping to JSON `quality`:

- `proposed` / `in-review` / `changes-requested` -> `draft`
- `approved` -> `reviewed`
- `playtested` -> `playtested`
- `refresh-needed` -> `needs-refresh`

Important rule:

- do not mark a question `reviewed` in JSON until it has actually been approved

## End-to-End Workflow

### 1. Author creates or edits a question

The author prepares:

- prompt
- 10 answers
- point values
- `difficultyScore`
- `difficultyTier`
- `validationStyle`
- `sourceURL`
- optional `contentType`
- optional `tags`
- `difficultyNotes` if needed
- `editorialNotes` if host adjudication guidance is useful

New or materially edited questions should start as:

- workflow state: `proposed`
- JSON quality: `draft`

### 2. Author runs self-check

Before asking for review, the author should confirm:

- the prompt reads cleanly out loud
- answers are distinct enough for spoken play
- points feel fair
- score and tier match
- category is defensible
- the source supports the framing
- the question is not a near-duplicate of existing content

Then run the pack audit.

### 3. Reviewer performs editorial review

The reviewer should make one of three calls:

- approve
- request changes
- reject for now

Review questions against the checklist below.

If changes are needed:

- workflow state becomes `changes-requested`
- JSON quality stays `draft`

If approved:

- workflow state becomes `approved`
- JSON quality becomes `reviewed`

### 4. Optional second approval

Use a second approval when:

- the question is borderline on ambiguity
- the topic is sensitive
- the category is premium or brand-sensitive
- the source basis is weaker or more editorial
- the pack is close to release and mistakes are expensive

For small teams, do not require two approvals for every single question.

Default recommendation:

- one reviewer is enough for ordinary low-risk questions
- two-person approval is recommended for premium packs, spicy humor, and edge-case prompts

### 5. Pack-level pass

After question-level approvals, do a pack-level pass for:

- duplicate families
- repeated answer patterns
- uneven difficulty feel
- category overlap
- tone consistency
- too many fragile or high-argument questions in one pack

Pack review can still send approved questions back for revision.

### 6. Playtest pass

Before shipping a meaningful batch, playtest a representative sample.

Promote questions from `reviewed` to `playtested` only when they behave well in real rounds.

Good candidates for playtest priority:

- hard questions
- humorous/editorial prompts
- prompts with tight answer boundaries
- prompts with many likely synonym variants

### 7. Ship and maintain

Once the approved batch ships:

- keep final content in the pack JSON
- keep `quality` updated accurately
- record follow-up issues in `CONTENT_TODO.md`
- use question reports plus playtesting to decide later refresh work

If a question ages badly or causes repeated friction:

- move it to workflow state `refresh-needed`
- set JSON `quality` to `needs-refresh`

## Question Review Checklist

Every reviewer should check:

### Prompt clarity

- Is the prompt understandable on first read?
- Can the host read it aloud in one breath?
- Does it avoid legalistic or over-qualified wording?

### Spoken adjudication speed

- Can the host quickly map spoken guesses to answers?
- Are likely synonyms manageable?
- Does the question need `editorialNotes` to keep adjudication sane?

### Answer distinctness

- Are answers unique?
- Are near-duplicates avoided?
- Are parent/child overlaps avoided unless intentionally defensible?

### Category fit

- Does this belong in the stated category?
- Is it drifting into a neighboring category?

### Difficulty quality

- Do the point values feel fair?
- Does the full answer set feel like the claimed tier?
- Is it hard because of rarity, not because the prompt is vague?

### Tone and suitability

- Does it fit Tap Ten’s tone?
- Could it create mean, awkward, unsafe, or off-brand gameplay?

### Source support

- Does the source actually support the framing?
- Is the source stable enough?
- Is the question too recency-sensitive for bundled content?

## Approval Rules

Use these practical default rules:

- A question should not ship without at least one explicit reviewer approval.
- A question with unresolved ambiguity should not be promoted out of `draft`.
- Borderline questions should prefer revision over argument.
- If reviewers disagree on category or answer boundaries, the question is not yet approved.
- If a question needs too much verbal explanation to work, rewrite or replace it.

## Multi-Reviewer Operating Model

If you involve more people, use a simple assignment model:

- one author
- one primary reviewer
- optional final approver

Recommended conventions:

- keep one owner per question revision
- keep reviewer comments in one place
- resolve review comments before approval
- avoid silent edits after approval without re-review

For batch review, track:

- question ID
- pack
- current workflow state
- assigned reviewer
- decision date
- approval decision
- follow-up notes

## Suggested Working Surfaces

Keep the operational footprint light.

Recommended split:

- JSON pack files remain the source of truth for shippable content
- `CONTENT_TODO.md` stays the active queue for unresolved content work
- this workflow doc defines process and decision rules

If more coordination is needed later, add a simple review sheet or CSV with:

- `questionID`
- `pack`
- `author`
- `reviewer`
- `state`
- `decision`
- `notes`

Do not start with a CMS.

## Existing Content Migration Plan

Because you want all existing questions to pass through the process too, use a staged sweep:

### Pass 1: Baseline review

Review all currently shipped questions at least once.

Goal:

- every question reaches either `approved/reviewed` or `changes-requested/draft`

### Pass 2: Risk-first re-review

Prioritize:

- current `draft` questions
- questions with recency drift risk
- questions with known ambiguity
- humorous/editorial questions
- premium packs

### Pass 3: Playtest confirmation

Promote representative approved questions to `playtested` based on real rounds.

You do not need to playtest every question before using the workflow, but you should playtest enough to validate the category and pack standards.

## Relationship To Player Reports

Player reports do not replace editorial review.

They are useful for:

- finding missed ambiguity
- spotting outdated or weak questions
- identifying tone misses
- triggering refresh work after release

Use `REPORT_REVIEW_WORKFLOW.md` for the post-release intake path.

## What Not To Do

Avoid:

- treating audit success as approval
- letting authors self-approve by default
- inventing too many process states inside JSON
- relying on memory instead of recorded review decisions
- shipping large batches of `draft` questions because they are structurally valid

The right shape is a lightweight but explicit approval process with clear ownership and recorded decisions.
