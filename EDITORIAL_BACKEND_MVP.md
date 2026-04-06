# Editorial Backend MVP

Status: Concrete MVP spec for an internal Tap Ten backend and reviewer web app that can be built and deployed on the existing server now.

Last updated: 2026-04-06

## Why This Exists

Tap Ten now has three connected editorial needs:

- non-technical reviewers need a structured way to review questions
- post-release player reports need intake and triage
- telemetry should help identify which questions are too easy, too hard, underperforming, or aging badly

Those needs now justify a small internal backend plus authenticated web app.

This should be treated as an editorial operations system, not a gameplay platform.

## Product Goal

Build one small internal system that can:

- receive question feedback from the app
- receive calibration telemetry from the app
- import the current pack catalog for review
- let reviewers approve or reject questions without source access
- show question-level insights from reports and telemetry

## Non-Goals

Do not build any of this into the first MVP:

- gameplay sync
- remote question delivery to players
- public-facing admin tools
- player accounts
- in-browser pack publishing directly to production
- a full authoring CMS

Keep shipped JSON packs as the release source of truth in the first implementation.

## Recommended MVP Shape

Use one deployable backend service that serves:

- public ingestion endpoints for the app
- an authenticated internal reviewer web UI
- simple internal JSON/CSV export endpoints or CLI commands

Recommended stack:

- Django
- Gunicorn
- SQLite
- nginx
- `systemd`
- server-rendered HTML templates for the web UI

Do not start with:

- React SPA
- Docker orchestration
- Postgres
- background job infrastructure heavier than cron or `systemd` timers

## Users And Roles

### Admin

Can:

- manage reviewer accounts
- import packs
- view all queues
- export data
- override statuses

### Reviewer

Can:

- see assigned or unassigned review queues
- open question detail
- leave comments
- approve
- request changes
- mark refresh-needed

### Approver

Can do everything a reviewer can, plus:

- give final approval on questions or packs that require a second sign-off

For MVP, `admin` and `approver` can be the same role if needed.

## Source Of Truth Model

For MVP:

- repo JSON pack files remain the shipping source of truth
- the backend stores an imported catalog snapshot for review and analytics
- the web app stores review decisions, comments, reports, and telemetry

This gives non-technical reviewers access without making the web app responsible for release publishing yet.

## Core Capabilities To Build Now

### 1. Authenticated reviewer login

Minimum acceptable options:

- magic-link email login
- password login with session cookies

Recommendation for MVP:

- password login with admin-created users
- secure session cookies
- no self-signup

### 2. Catalog import from pack JSON

The system needs a way to ingest the current question library.

Recommended import shape:

- CLI command or admin-only upload that reads current pack JSON files
- inserts or updates question catalog records
- records `packVersion`
- records current `quality`
- preserves review comments/history separately from content fields

Recommended command:

- `backend/.venv/bin/python backend/manage.py import_packs --from PesVres/TapTen/Resources/QuestionPacks`

### 3. Reviewer queue

The first useful screen.

Should support filters for:

- status
- pack
- category
- difficulty tier
- quality
- assigned reviewer
- needs second approval

### 4. Question detail review page

This is the main review surface.

It should show:

- prompt
- answer list with points
- category
- difficulty tier and score
- validation style
- source URL
- editorial notes
- difficulty notes
- current quality
- current review state
- prior decisions/comments
- linked player reports summary
- linked telemetry summary

Actions:

- approve
- request changes
- mark refresh-needed
- mark playtested
- assign reviewer
- leave comment

### 5. Player report triage view

Should show grouped report items by:

- question
- reason
- count
- latest report date

This should link back to the related question detail page.

### 6. Question insights view

Show compact telemetry and report signals for each question:

- times played
- average revealed answers
- average completion ratio
- average points scored
- skip rate
- average time to first reveal
- recent report count
- latest report reasons

This turns the system into a real editorial decision tool instead of only a comment inbox.

### 7. Export

For MVP, export matters more than inline publishing.

Minimum exports:

- CSV of review decisions
- CSV of grouped reports
- CSV of question insight summaries

Nice-to-have:

- JSON export of review state keyed by `questionID`

## Public App Endpoints

These should be live in MVP:

- `GET /tapten/healthz`
- `POST /tapten/v1/question-feedback`
- `POST /tapten/v1/question-calibration/batch`

The calibration endpoint should be included in MVP if you are already committing to the internal review app and insights workflow.

Without telemetry, the internal tool only solves review coordination.
With telemetry, it becomes an editorial quality system.

## Internal Web Routes

Suggested first route set:

- `GET /internal/login`
- `POST /internal/login`
- `POST /internal/logout`
- `GET /internal`
- `GET /internal/questions`
- `GET /internal/questions/:id`
- `POST /internal/questions/:id/review`
- `POST /internal/questions/:id/assign`
- `GET /internal/reports`
- `GET /internal/reports/:group_id`
- `GET /internal/insights`
- `GET /internal/packs`
- `GET /internal/export/reviews.csv`
- `GET /internal/export/reports.csv`
- `GET /internal/export/insights.csv`

## MVP Data Model

### `users`

Fields:

- `id`
- `email`
- `name`
- `role`
- `password_hash`
- `created_at`
- `disabled_at`

### `question_catalog`

Imported snapshot of current pack content.

Fields:

- `id`
- `pack_id`
- `pack_title`
- `pack_version`
- `question_id`
- `prompt`
- `category`
- `difficulty_tier`
- `difficulty_score`
- `validation_style`
- `source_url`
- `content_type`
- `quality`
- `difficulty_notes`
- `editorial_notes`
- `answers_json`
- `content_hash`
- `imported_at`
- `is_current`

### `question_review_state`

Current workflow state for the latest imported question record.

Fields:

- `id`
- `question_catalog_id`
- `workflow_state`
- `assigned_user_id`
- `requires_second_approval`
- `approved_by_user_id`
- `approved_at`
- `playtested_at`
- `refresh_needed_at`
- `updated_at`

### `question_review_comments`

Fields:

- `id`
- `question_catalog_id`
- `user_id`
- `comment_type`
- `body`
- `created_at`

### `question_review_decisions`

Immutable review history.

Fields:

- `id`
- `question_catalog_id`
- `user_id`
- `decision`
- `notes`
- `created_at`

### `feedback_reports`

As defined in `BACKEND_PLAN.md`.

### `feedback_report_groups`

Derived grouping table or materialized view.

Fields:

- `id`
- `question_id`
- `pack_id`
- `pack_version`
- `reason`
- `report_count`
- `first_seen_at`
- `last_seen_at`
- `latest_note`
- `status`

### `calibration_events`

As defined in `BACKEND_PLAN.md`.

### `question_insight_snapshots`

Derived summaries for fast UI loading.

Fields:

- `id`
- `question_id`
- `pack_id`
- `pack_version`
- `sample_count`
- `skip_rate`
- `average_revealed_answers`
- `average_completion_ratio`
- `average_points_awarded`
- `average_time_to_first_reveal`
- `report_count_30d`
- `last_played_at`
- `computed_at`

## Review Workflow Mapping

The internal app should use the workflow in `CONTENT_REVIEW_WORKFLOW.md`.

Recommended UI states:

- `proposed`
- `in-review`
- `changes-requested`
- `approved`
- `playtested`
- `refresh-needed`

Recommended JSON quality mapping:

- `draft`
- `reviewed`
- `playtested`
- `needs-refresh`

Important implementation rule:

- the web app should not rewrite pack JSON directly in MVP
- instead it should track review state and export decisions so source-controlled content can be updated intentionally

## Telemetry Insights To Show

Per question:

- total plays
- plays in last 30 days
- average revealed answers
- average completion ratio
- average points scored
- skip rate
- average time to first reveal
- current difficulty tier
- recent report count
- recent report reasons

Per pack:

- total questions
- reviewed count
- playtested count
- refresh-needed count
- most-reported questions
- easiest questions by completion ratio
- hardest questions by completion ratio

Per category:

- total plays
- average completion ratio
- average points
- skip rate
- questions with highest report volume

## Privacy And Security

Keep telemetry editorial-only and low-risk.

Collect:

- question identifiers
- pack/version
- round outcome metrics
- build/version metadata if useful

Do not collect:

- player accounts
- names
- email addresses from gameplay telemetry
- freeform gameplay transcripts

Security baseline:

- HTTPS only
- authenticated internal UI
- hashed passwords
- CSRF protection on internal forms
- strict request-size limits on public ingestion endpoints
- reverse-proxy rate limiting

## Deployment Shape

Recommended server layout:

- app checkout: `/opt/tapten-backend/current`
- virtualenv: `/opt/tapten-backend/current/backend/.venv`
- env file: `/etc/tapten-backend.env`
- SQLite DB: `/var/lib/tapten/tapten.db`
- backups: `/var/backups/tapten/`
- systemd service: `tapten-backend.service`
- nginx site: `/etc/nginx/sites-available/tapten-backend`

Suggested public/internal routing:

- public app ingestion under `/tapten/...`
- internal review UI under `/internal/...`

## Build Now Vs Later

### Build now

- backend service skeleton
- SQLite schema and migrations
- reviewer auth
- pack import command
- feedback ingestion
- calibration batch ingestion
- reviewer queue
- question detail page
- review decisions/comments
- grouped reports view
- per-question insights view
- CSV exports

### Build later

- inline content editing in the browser
- pack diff and revision compare
- browser-based publishing back to repo
- playtest session management
- notification emails
- richer analytics dashboards

## Recommended Rollout Order

### Milestone 1: Backend foundation

Build:

- service skeleton
- DB schema
- auth
- health check
- feedback endpoint
- calibration endpoint

Done when:

- the service runs on the server
- health check works
- app payloads can be stored successfully

### Milestone 2: Catalog import and reviewer queue

Build:

- pack import
- question catalog tables
- queue page
- question detail page

Done when:

- the current library can be imported
- a reviewer can log in and review a question without repo access

### Milestone 3: Reports and insights

Build:

- grouped reports
- question insight summaries
- report-to-question linking

Done when:

- reviewers can prioritize questions using real report and telemetry signals

### Milestone 4: Operational polish

Build:

- exports
- backups
- restore notes
- reviewer account management

Done when:

- the service is safe to rely on for ongoing editorial operations

## Success Criteria

This MVP is successful if:

- non-technical reviewers can review and approve questions without source access
- feedback reports arrive reliably
- calibration telemetry produces usable question insights
- authors can prioritize weak questions based on evidence
- the backend stays small enough to self-host comfortably

## Immediate Next Tasks

1. Build the Django service and DB schema.
2. Add the public feedback endpoint.
3. Add the public calibration batch endpoint.
4. Add pack import from local JSON files.
5. Build the reviewer login and question queue.
6. Build question detail, decision, and comment flows.
7. Build grouped reports and question insights pages.
8. Deploy behind nginx on the existing server.
