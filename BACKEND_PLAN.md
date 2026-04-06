# Backend Plan

Status: Planning document for a narrow self-hosted backend on a user-managed VPS.

Last updated: 2026-04-06

## Why This Exists

Tap Ten is still intentionally local-first for gameplay and bundled content. The app now has two narrow backend-shaped needs:

- question feedback delivery
- optional telemetry ingestion for content calibration later

This document defines the recommended rollout for a self-hosted backend on the user's existing server, without turning the app into a networked product.

For a concrete internal-tool MVP that combines reviewer workflow, player reports, and telemetry insights, see `EDITORIAL_BACKEND_MVP.md`.

## Scope Guardrails

The backend should not become a general app platform.

In scope:

- receive question feedback reports over HTTPS
- later receive anonymized question-calibration telemetry
- provide lightweight health checks and export paths for editorial review

Out of scope:

- gameplay sync
- multiplayer
- remote question-pack delivery
- account systems
- push notifications
- a public admin web app in the first pass

## Current App Reality

Today the app already supports:

- direct in-app question feedback submission through `QuestionFeedbackSubmissionService`
- local retry queueing when delivery is unavailable
- local-only monetization telemetry
- local-only question calibration telemetry summaries

Important implication:

- Phase 1 backend work can start with question feedback only.
- No app architecture rewrite is needed to activate the first endpoint.
- Editorial handling after ingestion is defined separately in `REPORT_REVIEW_WORKFLOW.md`.

## Recommended Rollout

### Phase 1: Self-Hosted Feedback Endpoint

This should be the first backend milestone.

Goal:

- let builds send `QuestionFeedbackReport` payloads to a real HTTPS endpoint

App impact:

- no new gameplay networking
- no schema change required in the app
- only configure `QuestionFeedbackEndpointURL` or `TAPTEN_FEEDBACK_ENDPOINT`

Recommended endpoint:

- `POST /tapten/v1/question-feedback`
- success response: `204 No Content`

Validation rules:

- require valid JSON body
- require all current report fields
- cap request size aggressively
- reject obviously malformed URLs, blank IDs, and oversized notes

Storage:

- store raw reports durably for editorial review
- export through SSH/CLI first, not a public dashboard

### Phase 2: Question Calibration Upload

This should happen only after feedback delivery is live and stable.

Goal:

- upload anonymized per-question outcome events so difficulty can be calibrated from real play

Recommended endpoint:

- `POST /tapten/v1/question-calibration/batch`

Recommended upload model:

- send batched events rather than one request per round
- keep the client queue local and retryable, mirroring the feedback pattern
- the app records `QuestionCalibrationTelemetryEvent` values locally, then `QuestionCalibrationSubmissionService` flushes pending batches when the app becomes active and after a round is finalized
- accept either a raw JSON array of events or an object with an `events` array on the backend

Editorial coupling:

- the same uploaded events should be stored as backend `CalibrationEvent` records
- those records should drive the reviewer-facing question insights views on `review.playtapten.com`
- question detail pages and the global insights screen should expose the same core signals the app uploads:
  - plays
  - completion ratio
  - points awarded
  - skip rate
  - time to first reveal

Suggested retention:

- keep raw calibration events for `90` days
- keep derived summaries longer if they remain useful

### Phase 3: Small Editorial Ops Layer

Only add this if Phase 1 and Phase 2 prove useful.

Possible additions:

- CSV export commands
- read-only SSH-only admin scripts
- daily summary jobs for problem questions and difficulty drift

Operational note:

- the recommended review and closure process for question reports lives in `REPORT_REVIEW_WORKFLOW.md`
- the broader internal reviewer app and insights system is specified in `EDITORIAL_BACKEND_MVP.md`

If the goal is only narrow intake and telemetry delivery, keep the service small. Do not introduce broader editorial UI concerns into that intake-only slice unless they are already needed operationally.

## Recommended Stack

For a small self-managed server, the most pragmatic stack is:

- Django for the application layer
- Gunicorn for the WSGI process
- nginx for TLS termination and reverse proxy on servers that already use nginx
- SQLite for the first production database
- `systemd` for service management
- `journald` for logs

Why this stack:

- Django fits the review/auth/export workflow better than a narrow custom service
- Gunicorn is a boring production default for a small internal tool
- SQLite is enough for low-volume feedback and tester telemetry
- nginx reuses the existing VPS web stack cleanly
- `systemd` is simpler than introducing Docker before it is needed

When to move past SQLite:

- if write volume grows materially
- if multiple workers are needed
- if ad hoc analytics starts to strain the single-file database

Until then, keep the operational footprint small.

## Server Layout

Recommended host layout:

- service user: `tapten`
- app directory: `/opt/tapten-backend/current`
- writable data: `/var/lib/tapten/`
- SQLite database: `/var/lib/tapten/tapten.db`
- backups: `/var/backups/tapten/`
- config file: `/etc/tapten-backend.env`
- reverse proxy config: `/etc/nginx/sites-available/tapten-backend`

Bootstrap rule:

- use `root` only for initial server setup
- run the app process as the dedicated `tapten` user

## Public Routes

Initial public routes:

- `GET /tapten/healthz`
- `POST /tapten/v1/question-feedback`

Deferred routes:

- `POST /tapten/v1/question-calibration/batch`

Admin/export routes should not be public in the first pass.

Use SSH access plus local CLI tooling instead.

## Data Model

### Feedback table

Recommended fields:

- server-side primary key
- received timestamp
- client `submittedAt`
- report `id`
- `reason`
- `note`
- `appVersion`
- `packID`
- `packTitle`
- `packVersion`
- `questionID`
- `prompt`
- `category`
- `difficultyTier`
- `validationStyle`
- `sourceURL`

### Calibration table

Recommended fields:

- server-side primary key
- received timestamp
- client event timestamp
- `packID`
- `packTitle`
- `packVersion`
- `questionID`
- `prompt`
- `category`
- `difficultyTier`
- `finishReason`
- `roundDurationSeconds`
- `revealedAnswerIndices`
- `totalAnswers`
- `pointsAwarded`
- `remainingTimeAtFinish`
- `timeToFirstReveal`

## Security and Privacy

Principles:

- HTTPS only
- no service process running as `root`
- strict request-size limits
- rate limiting at the proxy layer
- schema validation in the app service

Specific notes:

- do not assume any embedded mobile secret is truly secret
- treat the feedback endpoint as a public ingestion endpoint with validation and rate limiting
- free-text notes may contain accidental personal information, so keep access restricted and logs minimal
- do not expose raw records on a public website

## Logging, Backups, and Monitoring

Minimum operational baseline:

- structured application logs to stdout/stderr
- `journald` log retention with rotation
- daily SQLite backup job into `/var/backups/tapten/`
- simple restore drill documented before relying on the service
- health check monitored manually at first

If off-box backups become available later, add them before collecting meaningful production history.

## Deployment Shape

Recommended deployment flow:

1. Sync the backend code to `/opt/tapten-backend/releases/<timestamp>/` or the chosen deploy path.
2. Update `/opt/tapten-backend/current` to the new release.
3. Recreate or reuse the Python virtualenv and install `backend/requirements.txt`.
4. Run migrations.
5. Restart `tapten-backend.service`.
6. Verify `GET /tapten/healthz`.
7. Point the app build at the feedback endpoint.

For the current tester phase, subdomain-based deployment on the existing host is acceptable and now live on:

- `api.playtapten.com`
- `review.playtapten.com`

## Concrete Next Steps

1. Implement a tiny self-hosted backend service in a new repo folder such as `backend/`.
2. Ship only `healthz` plus `POST /tapten/v1/question-feedback` in the first pass.
3. Add SQLite persistence, log structure, and CSV export tooling.
4. Deploy it behind nginx on the VPS with a dedicated non-root service user.
5. Configure the Tap Ten build with the real feedback endpoint URL.
6. Add calibration-upload support only after the feedback path is stable.

## Recommended Order of Work

First:

- feedback endpoint
- deploy flow
- backups

Second:

- calibration upload
- editorial summary scripts

Later:

- any broader telemetry or admin tooling

## Non-Goals

Do not use this server plan to justify:

- remote pack syncing
- player accounts
- cross-device game state
- a large analytics pipeline

The backend should stay narrow enough that it can be understood, deployed, and recovered by one person.
