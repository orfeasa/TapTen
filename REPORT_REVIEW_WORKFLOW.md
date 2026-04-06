# Report Review Workflow

Status: Operating workflow for handling in-app question reports and turning them into shipped content fixes.

Last updated: 2026-04-06

## Why This Exists

Tap Ten already lets players flag questions in-app.

That creates a clear operational need:

- receive reports reliably
- review them without building a heavy admin product
- convert accepted issues into bundled content changes
- close the loop after those fixes ship

This document defines the editorial workflow that should sit on top of the narrow backend described in `BACKEND_PLAN.md`.

## Core Principle

Treat the backend as an intake and review system, not as a live content platform.

Important implication:

- reports can be received server-side immediately
- content fixes still ship through local JSON pack edits and app releases

## Current App Reality

Today the app already supports:

- structured `QuestionFeedbackReport` payloads
- in-app submission after a round
- local retry queueing if delivery is unavailable
- direct configuration of a reporting endpoint per build

That means the first useful workflow starts after ingestion, not after a new app architecture effort.

## End-to-End Workflow

### 1. Player submits a report

The host uses `Flag question` after a round.

The app submits a structured report containing:

- report metadata (`id`, `submittedAt`, `appVersion`)
- question identity (`questionID`, `prompt`, `category`)
- content context (`packID`, `packTitle`, `packVersion`)
- editorial context (`difficultyTier`, `validationStyle`, `sourceURL`)
- review reason and optional note

### 2. Backend accepts and stores the raw report

Phase 1 backend target:

- `POST /tapten/v1/question-feedback`
- success response: `204 No Content`

The backend should:

- validate the payload strictly
- store the raw report durably
- avoid mutating or overwriting the original submission

Raw storage is the source of truth.

### 3. A review queue is derived from raw reports

Do not review straight from the raw ingestion table.

Create a review-oriented layer keyed primarily by:

- `questionID`
- current `packVersion`
- `reason`

This review layer should group repeated complaints so editors see one actionable item instead of many identical rows.

Useful derived fields:

- first report timestamp
- latest report timestamp
- report count
- latest note
- latest app version seen
- current review status

### 4. Editorial triage happens in batches

Recommended cadence:

- light beta phase: twice weekly
- after broader rollout: daily on weekdays

At triage time, group and sort by:

- `questionID`
- `reason`
- report count
- recency
- pack version

### 5. Each grouped issue gets a clear disposition

Minimum review statuses:

- `new`
- `reviewed`
- `accepted`
- `wont_fix`
- `shipped`

Recommended meaning:

- `new`: not yet triaged
- `reviewed`: seen by editorial, no implementation decision yet
- `accepted`: a content or policy change should be made
- `wont_fix`: reviewed and intentionally not changing
- `shipped`: the accepted change is in a released build

### 6. Accepted items become content work

Once a report group is accepted, the actual fix usually happens in bundled content, not on the backend.

Typical fix path:

1. Edit the relevant JSON pack.
2. Adjust prompt, answers, category, difficulty, or source metadata.
3. Bump `packVersion` when the change is meaningful.
4. Run the pack audit.
5. Ship through the next app/content release.

### 7. Close the loop after release

After release, mark related accepted report groups as `shipped`.

Recommended rule:

- mark a report group `shipped` when the fix is present in a released build for the affected `questionID` and newer `packVersion`

Keep the raw reports for history even after the grouped issue is closed.

## Decision Rules By Report Type

### `inappropriate`

Handle first.

Expectation:

- same-day or next-review triage
- low threshold for action

### `wrongCategory`

Usually a clean editorial decision.

Expectation:

- act once the report is clearly valid
- repeated reports strengthen confidence but are not always required

### `tooEasy` / `tooDifficult`

Do not overreact to single reports.

Expectation:

- prefer repeated reports before changing content
- later combine with calibration telemetry when Phase 2 exists

### `other`

Human reading required.

Expectation:

- read the note
- decide whether it maps to an existing reason or needs a manual editorial change

## Priority Rules

Recommended triage order:

1. `inappropriate`
2. broken or dubious source issues
3. repeated `wrongCategory`
4. repeated `tooEasy` / `tooDifficult`
5. one-off `other`

Suggested default action thresholds:

- one solid `inappropriate` report can justify review immediately
- one obvious `wrongCategory` report can justify change
- difficulty changes should usually need repeated reports or later telemetry support

## Minimal Data Shape For Ops

Keep two layers:

### Raw reports

Immutable ingestion records.

### Review groups

Recommended fields:

- group identifier
- `questionID`
- `packID`
- `packVersion`
- `reason`
- report count
- first seen timestamp
- last seen timestamp
- latest note snapshot
- status
- editorial owner
- review notes
- target release or milestone
- shipped app version, if applicable

## Recommended Operational Tooling

Do not start with a browser admin app.

Start with:

- SQLite
- SSH access
- small CLI export scripts
- CSV export when needed

Useful first commands:

- `reports list --status new`
- `reports summarize --by question`
- `reports summarize --by pack`
- `reports export-csv`

## Relationship To Calibration Telemetry

Question reports are subjective signals.

Calibration telemetry, once enabled, adds behavioral evidence such as:

- answers found
- points awarded
- finish reason
- time to first reveal

Recommended use:

- use reports alone for clear suitability or category issues
- use reports plus telemetry for difficulty rebalancing

## Release Checklist For Accepted Report Fixes

Before closing an accepted report group:

1. Verify the relevant question pack change is present.
2. Confirm `packVersion` handling is still coherent.
3. Run the local pack audit.
4. Ship the build containing the fix.
5. Mark the grouped issue as `shipped`.

## What Not To Build Yet

Avoid:

- public moderation pages
- user accounts
- per-player histories
- live remote question replacement
- a large internal CMS

The right v1 ops shape is durable intake plus lightweight editorial review.
