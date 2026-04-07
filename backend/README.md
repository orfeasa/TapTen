# Tap Ten Editorial Backend

This directory contains the Django-based internal editorial backend and reviewer app for Tap Ten.

It is one part of the main Tap Ten repository alongside:

- the iOS app in `PesVres/`
- the public marketing/privacy website in `website/`
- shared product, content, and release docs at the repo root

Supported runtime target:

- Python 3.10+

## Intended Domain Layout

- `playtapten.com`: public static marketing/support site
- `api.playtapten.com`: public app ingestion endpoints
- `review.playtapten.com`: authenticated internal reviewer UI

The Django app is structured so both the API and reviewer UI can run from the same Gunicorn-backed service, with routing split by subdomain and path.

## Current MVP Scope

- `GET /tapten/healthz`
- `POST /tapten/v1/question-feedback`
- `POST /tapten/v1/question-calibration/batch`
- internal reviewer login
- question queue
- question detail review page
- grouped player-report view
- question insights view
- admin-only reviewer account management
- CSV export endpoints for reviews, reports, and insights
- pack import from local JSON files
- production WSGI entrypoint via Gunicorn

## Telemetry Flow

Calibration telemetry is now a single end-to-end path:

- the iOS app records `QuestionCalibrationTelemetryEvent` values locally per round
- the app batches and uploads pending events to `https://api.playtapten.com/tapten/v1/question-calibration/batch`
- the backend stores those payloads as `CalibrationEvent` rows
- the reviewer UI exposes the stored data on:
  - `/internal/insights`
  - `/internal/questions/<id>`

The intended reviewer signals from that pipeline are:

- plays
- average revealed answers
- average completion ratio
- average points awarded
- skip rate
- average time to first reveal

## Local Setup

1. Create a virtual environment:
   - `python3 -m venv backend/.venv`
2. Install dependencies:
   - `backend/.venv/bin/pip install -r backend/requirements.txt`
3. Configure environment variables if needed.
4. Run migrations:
   - `backend/.venv/bin/python backend/manage.py migrate`
5. Create an admin user:
   - `backend/.venv/bin/python backend/manage.py createsuperuser`
6. Import the current question packs:
   - `backend/.venv/bin/python backend/manage.py import_packs --from PesVres/TapTen/Resources/QuestionPacks`
7. Collect static files:
   - `backend/.venv/bin/python backend/manage.py collectstatic --noinput`
8. Start the server:
   - `backend/.venv/bin/python backend/manage.py runserver`
9. Open:
   - reviewer UI: `http://127.0.0.1:8000/internal/`
   - API health: `http://127.0.0.1:8000/tapten/healthz`

## Production Entrypoint

The recommended production process is Gunicorn with the checked-in config:

- config: `backend/gunicorn.conf.py`
- app: `tapten_backend.wsgi:application`

Local Gunicorn smoke run:

- `backend/.venv/bin/gunicorn -c backend/gunicorn.conf.py tapten_backend.wsgi:application`

The Gunicorn config sets `chdir` to the checked-in `backend/` directory by default, so the same command works whether you launch it from the repo root or from inside `backend/`.

## Key Environment Variables

- `DJANGO_SECRET_KEY`
- `DJANGO_DEBUG`
- `DJANGO_ALLOWED_HOSTS`
- `DJANGO_CSRF_TRUSTED_ORIGINS`
- `DJANGO_USE_X_FORWARDED_HOST`
- `DJANGO_SESSION_COOKIE_SECURE`
- `DJANGO_CSRF_COOKIE_SECURE`
- `DJANGO_SECURE_SSL_REDIRECT`
- `DJANGO_SECURE_HSTS_SECONDS`
- `DJANGO_SECURE_HSTS_INCLUDE_SUBDOMAINS`
- `DJANGO_SECURE_HSTS_PRELOAD`
- `TAPTEN_API_HOST`
- `TAPTEN_REVIEW_HOST`
- `TAPTEN_APP_ROOT`
- `TAPTEN_GUNICORN_BIND`
- `TAPTEN_GUNICORN_WORKERS`
- `TAPTEN_GUNICORN_THREADS`
- `TAPTEN_GUNICORN_TIMEOUT`
- `TAPTEN_DB_ENGINE`
- `TAPTEN_DB_NAME`
- `TAPTEN_DB_USER`
- `TAPTEN_DB_PASSWORD`
- `TAPTEN_DB_HOST`
- `TAPTEN_DB_PORT`
- `TAPTEN_SQLITE_PATH`

If database variables are not set, the project defaults to SQLite.

## Deployment Notes

Example deployment files live in `backend/deploy/`:

- `deploy-release.sh`
- `nginx-site.example`
- `Caddyfile.example`
- `tapten-backend.service`
- `tapten-backup.service`
- `tapten-backup.timer`
- `tapten-backup.sh`
- `tapten-backend.env.example`

Recommended production split:

- `api.playtapten.com` for `/tapten/...`
- `review.playtapten.com` for `/internal/...`

The app can enforce that split when `TAPTEN_API_HOST` and `TAPTEN_REVIEW_HOST` are configured.

The current production deployment on the existing VPS uses:

- nginx for reverse proxy and TLS
- Certbot for certificate issuance
- Gunicorn for the Django app process
- `systemd` for service management

The repo now also includes a GitHub Actions backend deploy workflow in `.github/workflows/backend-deploy.yml` for repeatable server releases without manual `scp` and ad hoc `ssh` sessions.

Keep `Caddyfile.example` only as an optional alternative for a fresh server that is not already nginx-managed.

## First Server Deploy

Current intended server layout:

- app checkout: `/opt/tapten-backend/current` or `/home/orfeas/tapten-backend/current`
- virtualenv: `<checkout>/backend/.venv`
- SQLite DB: `/var/lib/tapten/tapten.db` for root-managed deploys, or `/home/orfeas/tapten-backend/var/tapten.db` during user-level staging
- env file: `/etc/tapten-backend.env`
- staged user-level env file: `/home/orfeas/tapten-backend/shared/tapten-backend.env`

Ubuntu/Debian prerequisite packages:

- `python3-venv`
- `nginx`
- `certbot`
- `python3-certbot-nginx`
- `sqlite3`
- `rsync`

Root-owned setup commands:

- `sudo apt update`
- `sudo apt install -y python3-venv nginx certbot python3-certbot-nginx sqlite3 rsync`
- `sudo mkdir -p /opt/tapten-backend /var/lib/tapten /var/backups/tapten`
- `sudo chown -R $USER:$USER /opt/tapten-backend`
- `sudo chown -R $USER:$USER /var/lib/tapten`
- `sudo chown -R $USER:$USER /var/backups/tapten`

User-level bootstrap commands:

- `python3 -m venv backend/.venv`
- `backend/.venv/bin/python -m pip install -r backend/requirements.txt`
- `backend/.venv/bin/python backend/manage.py migrate`
- `backend/.venv/bin/python backend/manage.py import_packs --from PesVres/TapTen/Resources/QuestionPacks`
- `backend/.venv/bin/python backend/manage.py collectstatic --noinput`
- `backend/.venv/bin/gunicorn -c backend/gunicorn.conf.py tapten_backend.wsgi:application`

Root-owned production handoff:

- copy `backend/deploy/tapten-backend.env.example` to `/etc/tapten-backend.env` and fill in secrets/hosts
  - set `TAPTEN_APP_ROOT` to the deployed checkout path
- copy `backend/deploy/tapten-backend.service` to `/etc/systemd/system/tapten-backend.service`
  - change `User` and `Group` if you are not running the service as a dedicated `tapten` account
- copy `backend/deploy/tapten-backup.service` to `/etc/systemd/system/tapten-backup.service`
  - change `User` and `Group` here to match the app service account if you are not using `tapten`
- copy `backend/deploy/tapten-backup.timer` to `/etc/systemd/system/tapten-backup.timer`
- copy `backend/deploy/nginx-site.example` to `/etc/nginx/sites-available/tapten-backend`
  - update the `/static/` alias path if `TAPTEN_APP_ROOT` is not `/opt/tapten-backend/current`
- symlink `/etc/nginx/sites-enabled/tapten-backend` to that file
- `sudo systemctl daemon-reload`
- `sudo systemctl enable --now tapten-backend`
- `sudo systemctl enable --now tapten-backup.timer`
- `sudo nginx -t`
- `sudo systemctl reload nginx`
- `sudo certbot --nginx -d api.playtapten.com -d review.playtapten.com`

If the server already has another web server bound to `80` and `443`, do not introduce Caddy in parallel. Reuse the existing nginx layer instead.

Recommended deploy sequence:

1. Create the virtualenv on the server.
   - recommended path: `/opt/tapten-backend/current/backend/.venv`
2. Install `backend/requirements.txt`.
3. Copy `/etc/tapten-backend.env` from `backend/deploy/tapten-backend.env.example`.
4. Run `python backend/manage.py migrate`.
5. Run `python backend/manage.py import_packs --from .../QuestionPacks`.
6. Run `python backend/manage.py collectstatic --noinput`.
7. Start `tapten-backend.service`.
8. Install the nginx site file and reload nginx.
9. Issue certificates with Certbot once DNS resolves.
10. Verify `https://api.playtapten.com/tapten/healthz`.

## Ops Baseline

The checked-in deploy files now assume this minimum operating baseline:

- the Gunicorn service runs as a non-root account via `tapten-backend.service`
- nginx terminates TLS and reverse proxies to Gunicorn
- public `/tapten/` ingestion routes are rate-limited in `nginx-site.example`
- SQLite backups run daily through `tapten-backup.timer`
- logs are available through `journalctl`

### Health And Logs

Useful commands during rollout:

- `curl -fsS https://api.playtapten.com/tapten/healthz`
- `systemctl status tapten-backend --no-pager -l`
- `journalctl -u tapten-backend -n 200 --no-pager`
- `systemctl status tapten-backup.timer --no-pager -l`
- `journalctl -u tapten-backup.service -n 50 --no-pager`

### Backup Layout

Default paths:

- live DB: `TAPTEN_SQLITE_PATH`, default `/var/lib/tapten/tapten.db`
- backup root: `TAPTEN_BACKUP_ROOT`, default `/var/backups/tapten`
- retention: `TAPTEN_BACKUP_RETENTION_DAYS`, default `14`

Each backup run creates:

- `tapten-<timestamp>.sqlite3.gz`
- optional `tapten-<timestamp>.sqlite3.gz.sha256`

### Restore Drill

Before relying on the service, confirm the restore path once on the server:

1. Stop the app service.
   - `sudo systemctl stop tapten-backend`
2. Pick a backup archive.
   - `ls -lah /var/backups/tapten`
3. Restore it over the SQLite path.
   - `sudo rm -f /var/lib/tapten/tapten.db`
   - `sudo gunzip -c /var/backups/tapten/tapten-<timestamp>.sqlite3.gz > /var/lib/tapten/tapten.db`
4. Restore ownership if needed.
   - `sudo chown tapten:tapten /var/lib/tapten/tapten.db`
5. Start the app and verify health.
   - `sudo systemctl start tapten-backend`
   - `curl -fsS https://api.playtapten.com/tapten/healthz`

If the service is running as a different account on the current server, replace `tapten:tapten` with that user and group.

## Deployment Automation

The backend deploy workflow is now:

- workflow: `.github/workflows/backend-deploy.yml`
- remote deploy script: `backend/deploy/deploy-release.sh`
- trigger: manual `workflow_dispatch`

### What the workflow does

1. Checks out the requested ref.
2. Packages:
   - `backend/`
   - `PesVres/TapTen/Resources/QuestionPacks/`
3. Uploads a release archive to the VPS over SSH.
4. Extracts that archive into `~/tapten-backend/releases/<release-id>`.
5. Reuses a shared Python virtualenv under `~/tapten-backend/shared/.venv`.
6. Runs:
   - `manage.py check`
   - `manage.py migrate`
   - `manage.py collectstatic --noinput`
   - optional `manage.py import_packs`
7. Syncs the prepared release into `~/tapten-backend/current/`.
8. Reloads Gunicorn with `HUP`.
9. Verifies `GET /tapten/healthz` locally.
10. Keeps a small rolling release history for rollback.

### Required GitHub configuration

Repository secrets:

- `BACKEND_DEPLOY_SSH_KEY`
- `BACKEND_DEPLOY_KNOWN_HOSTS`
  - optional but recommended; if omitted, the workflow falls back to `ssh-keyscan`

The current workflow already commits the non-secret server settings:

- host: `birthday.orfeasa.com`
- user: `orfeas`
- port: `22`
- deploy root: `/home/orfeas/tapten-backend`

### How to create the required secret

Recommended approach: create a dedicated deploy key just for GitHub Actions.

Generate it locally:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/tapten_backend_actions -C "github-actions-backend-deploy"
```

Install the public key on the server:

```bash
ssh-copy-id -i ~/.ssh/tapten_backend_actions.pub orfeas@birthday.orfeasa.com
```

Then store the private key in GitHub as the `BACKEND_DEPLOY_SSH_KEY` secret:

```bash
cat ~/.ssh/tapten_backend_actions
```

Paste the full private key contents into:

- GitHub repository `Settings`
- `Secrets and variables`
- `Actions`
- `New repository secret`
- name: `BACKEND_DEPLOY_SSH_KEY`

### Optional host verification secret

`BACKEND_DEPLOY_KNOWN_HOSTS` is not secret, but storing it avoids a live `ssh-keyscan` during deploys.

To generate it:

```bash
ssh-keyscan -p 22 birthday.orfeasa.com
```

If you want stricter pinning, paste that output into the `BACKEND_DEPLOY_KNOWN_HOSTS` GitHub secret. If you skip it, the workflow will fetch the host key automatically.

### Rollback

If a deploy fails its health check after syncing into `current`, the remote script automatically restores the most recent prior release directory and reloads Gunicorn.

Manual rollback remains possible by syncing a previous directory from `~/tapten-backend/releases/` back into `~/tapten-backend/current/` and sending Gunicorn another `HUP`.
