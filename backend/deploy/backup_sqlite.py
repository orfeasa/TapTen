#!/usr/bin/env python3
"""Publish one verified private SQLite archive; serialize publication and pruning."""

import fcntl
import gzip
import hashlib
import os
from pathlib import Path
import shutil
import sqlite3
import sys
import tempfile
from contextlib import closing
from datetime import datetime, timezone


def backup(source: Path, root: Path) -> Path:
    if not source.is_file():
        raise ValueError("Source database missing")
    root.mkdir(parents=True, exist_ok=True, mode=0o700)
    with os.fdopen(
        os.open(root / ".tapten-backup.lock", os.O_CREAT | os.O_RDWR, 0o600), "w"
    ) as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        # Only our staging directories, never a published snapshot.
        for stale in root.glob(".tapten-backup-*"):
            if stale.is_dir() and not stale.is_symlink():
                shutil.rmtree(stale)
        with tempfile.TemporaryDirectory(prefix=".tapten-backup-", dir=root) as staging:
            directory = Path(staging)
            database = directory / "snapshot.sqlite3"
            with closing(
                sqlite3.connect(source.resolve().as_uri() + "?mode=ro", uri=True)
            ) as src:
                with closing(sqlite3.connect(database)) as dst:
                    src.backup(dst)
                    if dst.execute("PRAGMA integrity_check").fetchall() != [("ok",)]:
                        raise ValueError("Backup integrity check failed")
            stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
            name = f"tapten-{stamp}.sqlite3.gz"
            archive = directory / name
            with database.open("rb") as src, gzip.open(archive, "wb") as dst:
                shutil.copyfileobj(src, dst)
            with gzip.open(archive, "rb") as check:
                while check.read(1024 * 1024):
                    pass  # Read to EOF to verify the gzip CRC.
            with archive.open("rb") as handle:
                digest = hashlib.file_digest(handle, "sha256").hexdigest()
            checksum = directory / (name + ".sha256")
            checksum.write_text(f"{digest}  {name}\n")
            for path in (archive, checksum):
                path.chmod(0o600)
                with path.open("rb") as handle:
                    os.fsync(handle.fileno())
            # Unique names preserve the last good pair even if interrupted here.
            archive.replace(root / name)
            checksum.replace(root / checksum.name)
            for pattern in ("tapten-*.sqlite3.gz", "tapten-*.sqlite3.gz.sha256"):
                for old in root.glob(pattern):
                    if old.name not in (name, checksum.name):
                        old.unlink()
            return root / name


if __name__ == "__main__":
    os.umask(0o077)
    print("Created backup", backup(Path(sys.argv[1]), Path(sys.argv[2])))
