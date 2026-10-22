import concurrent.futures
import importlib.util
import sqlite3
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

MODULE_PATH = Path(__file__).with_name("backup_sqlite.py")
spec = importlib.util.spec_from_file_location("backup_helper", MODULE_PATH)
helper = importlib.util.module_from_spec(spec)
spec.loader.exec_module(helper)


class BackupTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.source = self.root / "source.db"
        self.backups = self.root / "backups"
        self.backups.mkdir()
        with sqlite3.connect(self.source) as db:
            db.execute("CREATE TABLE records (value TEXT)")
            db.execute("INSERT INTO records VALUES ('preserved')")

    def run_backup(self):
        helper.backup(self.source, self.backups)

    def restore(self):
        import gzip, hashlib

        archive = next(self.backups.glob("tapten-*.sqlite3.gz"))
        checksum = archive.with_name(archive.name + ".sha256").read_text().split()[0]
        self.assertEqual(hashlib.sha256(archive.read_bytes()).hexdigest(), checksum)
        restored = self.root / "restored.db"
        restored.write_bytes(gzip.decompress(archive.read_bytes()))
        with sqlite3.connect(restored) as db:
            self.assertEqual(db.execute("PRAGMA integrity_check").fetchall(), [("ok",)])
            self.assertEqual(
                db.execute("SELECT value FROM records").fetchall(), [("preserved",)]
            )

    def test_success_restore_and_retention(self):
        self.run_backup()
        self.run_backup()
        self.assertEqual(len(list(self.backups.glob("tapten-*.sqlite3.gz"))), 1)
        self.restore()
        for snapshot in self.backups.glob("tapten-*.sqlite3.gz"):
            self.assertEqual(snapshot.stat().st_mode & 0o777, 0o600)

    def test_corrupt_source_preserves_snapshot(self):
        self.run_backup()
        before = {
            p.name: p.read_bytes() for p in self.backups.glob("tapten-*.sqlite3.gz")
        }
        self.source.write_bytes(b"not a SQLite database")
        with self.assertRaises(sqlite3.DatabaseError):
            self.run_backup()
        self.assertEqual(
            before,
            {p.name: p.read_bytes() for p in self.backups.glob("tapten-*.sqlite3.gz")},
        )
        self.restore()

    def test_missing_source_preserves_snapshot(self):
        self.run_backup()
        self.source.unlink()
        with self.assertRaises(ValueError):
            self.run_backup()
        self.restore()

    def test_publication_failure_preserves_snapshot(self):
        self.run_backup()
        with patch.object(Path, "replace", side_effect=OSError("disk failure")):
            with self.assertRaises(OSError):
                self.run_backup()
        self.restore()

    def test_concurrent_runs_leave_one_snapshot(self):
        with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
            list(pool.map(lambda _: self.run_backup(), range(3)))
        self.assertEqual(len(list(self.backups.glob("tapten-*.sqlite3.gz"))), 1)
        self.restore()
