#!/bin/sh
set -eu

DB_PATH="${TAPTEN_SQLITE_PATH:-/var/lib/tapten/tapten.db}"
BACKUP_ROOT="${TAPTEN_BACKUP_ROOT:-/var/backups/tapten}"
RETENTION_DAYS="${TAPTEN_BACKUP_RETENTION_DAYS:-14}"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
TMP_DB="$BACKUP_ROOT/tapten-$TIMESTAMP.sqlite3"
ARCHIVE_PATH="$TMP_DB.gz"
CHECKSUM_PATH="$ARCHIVE_PATH.sha256"

if [ ! -f "$DB_PATH" ]; then
  echo "SQLite database not found at $DB_PATH" >&2
  exit 1
fi

if ! command -v sqlite3 >/dev/null 2>&1; then
  echo "sqlite3 is required for backups" >&2
  exit 1
fi

install -d "$BACKUP_ROOT"

sqlite3 "$DB_PATH" ".backup '$TMP_DB'"
gzip -f "$TMP_DB"

if command -v sha256sum >/dev/null 2>&1; then
  sha256sum "$ARCHIVE_PATH" > "$CHECKSUM_PATH"
fi

find "$BACKUP_ROOT" -type f \( -name 'tapten-*.sqlite3.gz' -o -name 'tapten-*.sqlite3.gz.sha256' \) -mtime +"$RETENTION_DAYS" -delete

echo "Created backup $ARCHIVE_PATH"
