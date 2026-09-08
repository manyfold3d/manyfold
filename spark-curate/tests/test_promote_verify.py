# DB verification + receipts (INIT-021/SPEC-013).
# ac-7 / ac-8 / ac-9. On-disk datapackage.json is not evidence. Temporary trees only.
from __future__ import annotations

import inspect
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from typing import Any

_ROOT = Path(__file__).resolve().parents[1]
if str(_ROOT) not in sys.path:
    sys.path.insert(0, str(_ROOT))

from spark_curate.config import CurateConfig
from spark_curate.manyfold_client import PathVerifyResult
from spark_curate.promote import (
    LiveTreeGuardError,
    PromoteHalted,
    assert_not_live_tree,
    iter_batch_lines,
    run_promote,
)
from spark_curate import promote as promote_mod


def _write_pack(root: Path, rel: str, *, datapackage: bool = False) -> Path:
    category, name = rel.split("/", 1)
    dest = root / category / name
    dest.mkdir(parents=True)
    (dest / "model.stl").write_bytes(b"solid x\nendsolid\n")
    if datapackage:
        (dest / "datapackage.json").write_text(
            json.dumps({"name": name, "keywords": ["fixture"]}),
            encoding="utf-8",
        )
    return dest


def _batch(work: Path, name: str, lines: list[str]) -> Path:
    path = work / name
    path.write_text("".join(f"{ln}\n" for ln in lines) + "\n", encoding="utf-8")
    return path


class _FakeManyfold:
    def __init__(self) -> None:
        self.scans: list[list[str]] = []
        self.applies = 0
        self.results: dict[str, PathVerifyResult] = {}

    def enqueue_scan(self, paths: list[str]) -> dict[str, int]:
        self.scans.append(list(paths))
        return {"enqueued": len(paths)}

    def apply_datapackages(self) -> subprocess.CompletedProcess[bytes]:
        self.applies += 1
        return subprocess.CompletedProcess(["rake"], 0, b"", b"")

    def verify_tagged(self, paths: list[str]) -> list[PathVerifyResult]:
        out: list[PathVerifyResult] = []
        for p in paths:
            if p in self.results:
                out.append(self.results[p])
            else:
                out.append(PathVerifyResult(path=p, status="tagged", model_id=1, tag_count=1))
        return out


class VerifyDbIsSystemOfRecordTests(unittest.TestCase):
    """ac-7: datapackage.json on disk does not count as imported."""

    def test_ondisk_datapackage_untagged_in_db_is_failure(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            intake = tmp / "intake"
            lib = tmp / "library"
            rel = "AnySTL/King's Throne"
            # Already on the library disk with a datapackage — the Sep 4–5 shape.
            _write_pack(lib, rel, datapackage=True)
            self.assertTrue((lib / "AnySTL" / "King's Throne" / "datapackage.json").is_file())
            work = intake / ".spark-curate"
            work.mkdir(parents=True)
            batch = _batch(work, "batch-untagged.txt", [rel])
            fake = _FakeManyfold()
            fake.results[rel] = PathVerifyResult(
                path=rel, status="untagged", model_id=99, tag_count=0
            )
            cfg = CurateConfig(library_root=str(lib), work_dir=str(work))
            planted: Any = fake
            with self.assertRaises(PromoteHalted) as ctx:
                run_promote(
                    cfg,
                    [batch],
                    intake_root=intake,
                    do_apply=True,
                    client=planted,
                    run_id="untagged",
                )
            receipt = ctx.exception.receipt
            self.assertEqual(receipt.halted_at.reason, "verify_failed")
            self.assertNotIn(rel, receipt.verified_in_db)
            reasons = {f["path"]: f["reason"] for f in receipt.failed}
            self.assertEqual(reasons[rel], "untagged_in_db")
            # File still on disk — verify did not use it as success.
            self.assertTrue((lib / "AnySTL" / "King's Throne" / "datapackage.json").is_file())

    def test_ondisk_absent_in_db_is_failure(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            intake = tmp / "intake"
            lib = tmp / "library"
            rel = "Games/Dirk Statue - Dragon's Lair"
            _write_pack(lib, rel, datapackage=True)
            work = intake / ".spark-curate"
            work.mkdir(parents=True)
            batch = _batch(work, "batch-absent.txt", [rel])
            fake = _FakeManyfold()
            fake.results[rel] = PathVerifyResult(path=rel, status="absent")
            cfg = CurateConfig(library_root=str(lib), work_dir=str(work))
            planted: Any = fake
            with self.assertRaises(PromoteHalted) as ctx:
                run_promote(
                    cfg,
                    [batch],
                    intake_root=intake,
                    do_apply=True,
                    client=planted,
                    run_id="absent",
                )
            self.assertIn(
                {"path": rel, "reason": "absent_in_db"},
                ctx.exception.receipt.failed,
            )
            self.assertEqual(ctx.exception.receipt.verified_in_db, [])

    def test_tagged_in_db_is_verified(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            intake = tmp / "intake"
            lib = tmp / "library"
            lib.mkdir()
            rel = "AnySTL/King's Throne"
            _write_pack(intake, rel, datapackage=True)
            work = intake / ".spark-curate"
            work.mkdir()
            batch = _batch(work, "batch-ok.txt", [rel])
            fake = _FakeManyfold()
            fake.results[rel] = PathVerifyResult(
                path=rel, status="tagged", model_id=7, tag_count=3
            )
            cfg = CurateConfig(library_root=str(lib), work_dir=str(work))
            planted: Any = fake
            receipt = run_promote(
                cfg,
                [batch],
                intake_root=intake,
                do_apply=True,
                client=planted,
                run_id="tagged",
            )
            self.assertIsNone(receipt.halted_at)
            self.assertEqual(receipt.verified_in_db, [rel])
            self.assertEqual(receipt.failed, [])
            self.assertTrue((lib / "AnySTL" / "King's Throne").is_dir())
            self.assertFalse((intake / "AnySTL" / "King's Throne").exists())
            self.assertEqual(fake.applies, 1)

    def test_verify_helper_does_not_read_datapackage_json(self) -> None:
        src = inspect.getsource(promote_mod._verify_batch)
        self.assertNotIn("datapackage.json", src)
        self.assertIn("verify_tagged", src)

    def test_verify_tagged_trusts_db_not_ondisk_datapackage(self) -> None:
        """Behavioral: on-disk datapackage.json does not make verify_tagged pass."""
        from spark_curate.manyfold_client import VERIFY_RUNNER, ManyfoldClient

        self.assertNotIn("datapackage", VERIFY_RUNNER)
        with tempfile.TemporaryDirectory() as td:
            pack = Path(td) / "AnySTL" / "King's Throne"
            pack.mkdir(parents=True)
            dp = pack / "datapackage.json"
            dp.write_text(
                json.dumps({"name": "King's Throne", "keywords": ["should-not-count"]}),
                encoding="utf-8",
            )

            def run_fn(argv: list[str], **kwargs: Any) -> subprocess.CompletedProcess[bytes]:
                payload = json.dumps(
                    {
                        "results": [
                            {
                                "path": "AnySTL/King's Throne",
                                "status": "untagged",
                                "model_id": 1,
                                "tag_count": 0,
                            }
                        ]
                    }
                ).encode("utf-8")
                return subprocess.CompletedProcess(argv, 0, stdout=payload + b"\n", stderr=b"")

            client = ManyfoldClient(run_fn=run_fn, sleep_fn=lambda _s: None)
            rows = client.verify_tagged(["AnySTL/King's Throne"])
            self.assertEqual(len(rows), 1)
            self.assertEqual(rows[0].status, "untagged")
            self.assertEqual(rows[0].tag_count, 0)
            self.assertFalse(rows[0].ok)
            self.assertTrue(dp.is_file())


class ReceiptTests(unittest.TestCase):
    """ac-8: per-run receipt under the batch .spark-curate/."""

    def test_receipt_fields_and_notes(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            intake = tmp / "intake"
            lib = tmp / "library"
            lib.mkdir()
            rel = "AnySTL/King's Throne"
            _write_pack(intake, rel)
            work = intake / ".spark-curate"
            work.mkdir()
            batch = _batch(work, "batch-receipt.txt", [rel])
            cfg = CurateConfig(library_root=str(lib), work_dir=str(work))
            fake: Any = _FakeManyfold()
            receipt = run_promote(
                cfg,
                [batch],
                intake_root=intake,
                do_apply=True,
                client=fake,
                run_id="receipt-ok",
            )
            path = work / "promote-receipt-receipt-ok.json"
            self.assertTrue(path.is_file())
            data = json.loads(path.read_text(encoding="utf-8"))
            for key in (
                "batches_attempted",
                "promoted",
                "verified_in_db",
                "failed",
                "halted_at",
                "field_notes",
            ):
                self.assertIn(key, data)
            self.assertEqual(data["promoted"], [rel])
            self.assertEqual(data["verified_in_db"], [rel])
            self.assertEqual(data["failed"], [])
            self.assertIsNone(data["halted_at"])
            self.assertIn("datapackage.json is not evidence", data["field_notes"]["verified_in_db"])
            self.assertEqual(receipt.to_dict()["provenance"], "INIT-021/SPEC-013")

    def test_dry_run_receipt_does_not_move(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            intake = tmp / "intake"
            lib = tmp / "library"
            lib.mkdir()
            rel = "AnySTL/King's Throne"
            _write_pack(intake, rel)
            work = intake / ".spark-curate"
            work.mkdir()
            batch = _batch(work, "batch-dry.txt", [rel, ""])  # trailing blank via extra empty
            # Explicit trailing blank line:
            batch.write_text(f"{rel}\n\n", encoding="utf-8")
            cfg = CurateConfig(library_root=str(lib), work_dir=str(work))
            fake: Any = _FakeManyfold()
            receipt = run_promote(
                cfg,
                [batch],
                intake_root=intake,
                do_apply=False,
                client=fake,
                run_id="dry",
            )
            self.assertEqual(receipt.planned, [rel])
            self.assertEqual(receipt.promoted, [])
            self.assertEqual(fake.scans, [])
            self.assertEqual(fake.applies, 0)
            self.assertTrue((intake / "AnySTL" / "King's Throne").is_dir())

    def test_trailing_blank_line_ignored(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            batch = Path(td) / "b.txt"
            batch.write_text("AnySTL/King's Throne\n\n", encoding="utf-8")
            self.assertEqual(list(iter_batch_lines(batch)), ["AnySTL/King's Throne"])

    def test_destination_collision_never_suffixes(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            intake = tmp / "intake"
            lib = tmp / "library"
            rel = "AnySTL/King's Throne"
            _write_pack(intake, rel)
            _write_pack(lib, rel)
            (lib / "AnySTL" / "King's Throne" / "other.stl").write_bytes(b"different")
            work = intake / ".spark-curate"
            work.mkdir(parents=True)
            batch = _batch(work, "batch-collide.txt", [rel])
            cfg = CurateConfig(library_root=str(lib), work_dir=str(work))
            fake: Any = _FakeManyfold()
            with self.assertRaises(PromoteHalted) as ctx:
                run_promote(
                    cfg,
                    [batch],
                    intake_root=intake,
                    do_apply=True,
                    client=fake,
                    run_id="collide",
                )
            self.assertEqual(ctx.exception.receipt.halted_at.reason, "destination_exists")
            self.assertFalse((lib / "AnySTL" / "King's Throne (2)").exists())
            self.assertTrue((intake / "AnySTL" / "King's Throne").is_dir())

    def test_already_landed_verifies_without_removes(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            intake = tmp / "intake"
            lib = tmp / "library"
            rel = "AnySTL/King's Throne"
            _write_pack(lib, rel)
            work = intake / ".spark-curate"
            work.mkdir(parents=True)
            batch = _batch(work, "batch-idemp.txt", [rel])
            cfg = CurateConfig(library_root=str(lib), work_dir=str(work))
            fake: Any = _FakeManyfold()
            receipt = run_promote(
                cfg,
                [batch],
                intake_root=intake,
                do_apply=True,
                client=fake,
                run_id="idemp",
            )
            self.assertEqual(receipt.promoted, [rel])
            self.assertEqual(receipt.verified_in_db, [rel])
            self.assertTrue((lib / "AnySTL" / "King's Throne").is_dir())

    def test_copy_same_inode_treats_as_already_landed(self) -> None:
        """--copy when dest is src (same inode) must verify, not copytree onto self."""
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            root = tmp / "shared"
            rel = "AnySTL/King's Throne"
            _write_pack(root, rel)
            work = tmp / "work"
            work.mkdir()
            batch = _batch(work, "batch-same-inode.txt", [rel])
            cfg = CurateConfig(library_root=str(root), work_dir=str(work))
            fake: Any = _FakeManyfold()
            receipt = run_promote(
                cfg,
                [batch],
                intake_root=root,
                do_apply=True,
                copy=True,
                client=fake,
                run_id="same-inode",
            )
            self.assertIsNone(receipt.halted_at)
            self.assertEqual(receipt.promoted, [rel])
            self.assertEqual(receipt.failed, [])
            self.assertTrue((root / "AnySTL" / "King's Throne" / "model.stl").is_file())
            self.assertFalse((root / "AnySTL" / "King's Throne (2)").exists())


class LiveTreeUntouchedTests(unittest.TestCase):
    """ac-9: live library and intake/Mega are refused; fixtures are tmp."""

    def test_guard_refuses_live_library_and_mega(self) -> None:
        with self.assertRaises(LiveTreeGuardError):
            assert_not_live_tree(Path("/mnt/backups/3D-Prints"), allow_live=False)
        with self.assertRaises(LiveTreeGuardError):
            assert_not_live_tree(
                Path("/mnt/backups/3D-Prints-Unorg/intake/Mega/Anime"),
                allow_live=False,
            )
        # Sibling Unorg batch is not the library prefix.
        assert_not_live_tree(
            Path("/mnt/backups/3D-Prints-Unorg/intake/2026-08-drive-mega"),
            allow_live=False,
        )

    def test_apply_against_live_library_path_does_not_mkdir(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            intake = tmp / "intake"
            work = intake / ".spark-curate"
            work.mkdir(parents=True)
            batch = _batch(work, "batch.txt", ["AnySTL/Pack"])
            cfg = CurateConfig(
                library_root="/mnt/backups/3D-Prints",
                work_dir=str(work),
            )
            fake: Any = _FakeManyfold()
            with self.assertRaises(LiveTreeGuardError):
                run_promote(
                    cfg,
                    [batch],
                    intake_root=intake,
                    do_apply=True,
                    client=fake,
                    run_id="live-guard",
                )
            self.assertEqual(fake.scans, [])

    def test_this_file_fixtures_use_tempfile(self) -> None:
        src = Path(__file__).read_text(encoding="utf-8")
        self.assertIn("TemporaryDirectory", src)
        self.assertIn("allow_live=False", src)
