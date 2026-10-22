#!/bin/sh
set -eu
umask 077
exec python3 "$(dirname "$0")/backup_sqlite.py" \
  "${TAPTEN_SQLITE_PATH:-/var/lib/tapten/tapten.db}" \
  "${TAPTEN_BACKUP_ROOT:-/var/backups/tapten}"
