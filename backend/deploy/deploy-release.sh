#!/usr/bin/env bash
set -euo pipefail

DEPLOY_ROOT="${DEPLOY_ROOT:?DEPLOY_ROOT is required}"
RELEASE_ID="${RELEASE_ID:?RELEASE_ID is required}"
RELEASE_TARBALL="${RELEASE_TARBALL:?RELEASE_TARBALL is required}"
IMPORT_PACKS="${IMPORT_PACKS:-true}"
KEEP_RELEASES="${KEEP_RELEASES:-1}"
case "$KEEP_RELEASES" in
  1|2) ;;
  *) echo "KEEP_RELEASES must be 1 (active only) or 2 (one rollback)." >&2; exit 1 ;;
esac

RELEASES_DIR="$DEPLOY_ROOT/releases"
SHARED_DIR="$DEPLOY_ROOT/shared"
CURRENT_DIR="$DEPLOY_ROOT/current"
RELEASE_DIR="$RELEASES_DIR/$RELEASE_ID"
SHARED_VENV="$SHARED_DIR/.venv"

for command_name in python3 rsync curl tar; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Required command not found: $command_name" >&2
    exit 1
  fi
done

# Fail before mutating the shared environment if restart permission is missing.
sudo -n -l /usr/bin/systemctl restart tapten-backend.service >/dev/null

mkdir -p "$RELEASES_DIR" "$SHARED_DIR" "$CURRENT_DIR"
shopt -s nullglob
existing_releases=("$RELEASES_DIR"/*)
if ((${#existing_releases[@]} > 0)); then
  IFS=$'\n' existing_releases=($(ls -1dt "${existing_releases[@]}"))
fi
shopt -u nullglob

PREVIOUS_RELEASE="${existing_releases[0]:-}"

rm -rf "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR"

tar -xzf "$RELEASE_TARBALL" -C "$RELEASE_DIR"
rm -f "$RELEASE_TARBALL"

ENV_FILE=""
for candidate in \
  /etc/tapten-backend.env \
  "$SHARED_DIR/tapten-backend.env" \
  "$SHARED_DIR/ops-rollout/tapten-backend.env"
do
  if [[ -r "$candidate" ]]; then
    ENV_FILE="$candidate"
    break
  fi
done

if [[ -z "$ENV_FILE" ]]; then
  echo "No readable backend env file found." >&2
  exit 1
fi

set -a
source "$ENV_FILE"
set +a

if [[ ! -d "$SHARED_VENV" ]]; then
  python3 -m venv "$SHARED_VENV"
fi

"$SHARED_VENV/bin/python" -m pip install --upgrade pip
"$SHARED_VENV/bin/python" -m pip install -r "$RELEASE_DIR/backend/requirements.txt"

rm -rf "$RELEASE_DIR/backend/.venv"
ln -sfn "$SHARED_VENV" "$RELEASE_DIR/backend/.venv"

"$SHARED_VENV/bin/python" "$RELEASE_DIR/backend/manage.py" check
"$SHARED_VENV/bin/python" "$RELEASE_DIR/backend/manage.py" migrate --noinput
"$SHARED_VENV/bin/python" "$RELEASE_DIR/backend/manage.py" collectstatic --noinput

if [[ "$IMPORT_PACKS" == "true" ]]; then
  "$SHARED_VENV/bin/python" \
    "$RELEASE_DIR/backend/manage.py" \
    import_packs \
    --from "$RELEASE_DIR/PesVres/TapTen/Resources/QuestionPacks"
fi

sync_release_into_current() {
  local source_dir="$1"
  rsync -a --delete "$source_dir"/ "$CURRENT_DIR"/
}

restart_backend() {
  # HUP can retain the old Python interpreter/modules after dependency upgrades.
  sudo -n /usr/bin/systemctl restart tapten-backend.service
  sleep 2
}

check_health() {
  local api_host="${TAPTEN_API_HOST:-api.playtapten.com}"
  local body
  body="$(curl -fsS \
    -H "Host: $api_host" \
    -H "X-Forwarded-Host: $api_host" \
    -H "X-Forwarded-Proto: https" \
    http://127.0.0.1:8100/tapten/healthz)"
  [[ "$body" == *'"status":"ok"'* || "$body" == *'"status": "ok"'* ]]
}

sync_release_into_current "$RELEASE_DIR"
restart_backend

if ! check_health; then
  if [[ -n "$PREVIOUS_RELEASE" && -d "$PREVIOUS_RELEASE" ]]; then
    echo "Health check failed. Restoring previous release $PREVIOUS_RELEASE." >&2
    sync_release_into_current "$PREVIOUS_RELEASE"
    restart_backend
  fi
  echo "Deploy failed health check." >&2
  exit 1
fi

shopt -s nullglob
release_dirs=("$RELEASES_DIR"/*)
if ((${#release_dirs[@]} > 0)); then
  IFS=$'\n' release_dirs=($(ls -1dt "${release_dirs[@]}"))
fi
shopt -u nullglob

if ((${#release_dirs[@]} > KEEP_RELEASES)); then
  for stale_release in "${release_dirs[@]:KEEP_RELEASES}"; do
    rm -rf "$stale_release"
  done
fi

echo "Deploy succeeded: $RELEASE_ID"
