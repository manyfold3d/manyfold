# Fail-loud promote loop (INIT-021/SPEC-013).
# ac-1 / ac-5 / ac-6. Planted failures — not asserted-only. Temporary trees only.
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

from spark_curate.__main__ import build_parser, main
from spark_curate.config import CurateConfig
from spark_curate.manyfold_client import (
    KubectlRetriesExhausted,
    ManyfoldClient,
    PermanentKubectlError,
    classify_kubectl_failure,
)
from spark_curate.promote import PromoteHalted, run_promote, run_promote_cli


def _write_pack(root: Path, rel: str) -> Path:
    category, name = rel.split("/", 1)
    dest = root / category / name
    dest.mkdir(parents=True)
    (dest / "model.stl").write_bytes(b"solid x\nendsolid\n")
    return dest


def _batch(work: Path, name: str, lines: list[str]) -> Path:
    path = work / name
    path.write_text("".join(f"{ln}\n" for ln in lines) + "\n", encoding="utf-8")
    return path


class _FakeManyfold:
    def __init__(self) -> None:
        self.scans: list[list[str]] = []
        self.applies = 0
        self.scan_error: BaseException | None = None
        self.apply_error: BaseException | None = None

    def enqueue_scan(self, paths: list[str]) -> dict[str, int]:
        if self.scan_error is not None:
            raise self.scan_error
        self.scans.append(list(paths))
        return {"enqueued": len(paths)}

    def apply_datapackages(self) -> subprocess.CompletedProcess[bytes]:
        if self.apply_error is not None:
            raise self.apply_error
        self.applies += 1
        return subprocess.CompletedProcess(["rake"], 0, b"", b"")

    def verify_tagged(self, paths: list[str]) -> list[Any]:
        from spark_curate.manyfold_client import PathVerifyResult

        return [PathVerifyResult(path=p, status="tagged", model_id=1, tag_count=2) for p in paths]


class PromoteEntryPointTests(unittest.TestCase):
    """ac-1: MODE=promote is the version-controlled entry point."""

    def test_parser_accepts_mode_promote_and_paths_file(self) -> None:
        parser = build_parser()
        ns = parser.parse_args(
            ["--mode", "promote", "--paths-file", "/tmp/batch.txt"]
        )
        self.assertEqual(ns.mode, "promote")
        self.assertEqual(ns.paths_files, ["/tmp/batch.txt"])

    def test_missing_paths_file_is_nonzero(self) -> None:
        rc = main(["--mode", "promote", "--library", "/tmp/spark-curate-promote-missing"])
        self.assertEqual(rc, 2)

    def test_cli_dry_run_over_tmp_batch(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            intake = tmp / "intake"
            lib = tmp / "library"
            lib.mkdir()
            rel = "AnySTL/King's Throne"
            _write_pack(intake, rel)
            work = intake / ".spark-curate"
            work.mkdir()
            batch = _batch(work, "batch-001.txt", [rel])
            rc = main(
                [
                    "--mode",
                    "promote",
                    "--library",
                    str(lib),
                    "--intake",
                    str(intake),
                    "--paths-file",
                    str(batch),
                ]
            )
            self.assertEqual(rc, 0)
            receipts = list(work.glob("promote-receipt-*.json"))
            self.assertEqual(len(receipts), 1)
            data = json.loads(receipts[0].read_text(encoding="utf-8"))
            self.assertEqual(data["promoted"], [])
            self.assertEqual(data["planned"], [rel])
            self.assertIsNone(data["halted_at"])
            self.assertTrue((intake / "AnySTL" / "King's Throne").is_dir())
            self.assertFalse((lib / "AnySTL" / "King's Throne").exists())


class PlantedScanHaltTests(unittest.TestCase):
    """ac-5: planted non-zero scan HALTS, names the batch, exits non-zero."""

    def test_planted_scan_failure_halts_and_skips_later_batch(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            intake = tmp / "intake"
            lib = tmp / "library"
            lib.mkdir()
            first = "AnySTL/King's Throne"
            later = "Games/Later Pack"
            _write_pack(intake, first)
            _write_pack(intake, later)
            work = intake / ".spark-curate"
            work.mkdir()
            batch_fail = _batch(work, "01-fail.txt", [first])
            batch_later = _batch(work, "02-later.txt", [later])
            fake = _FakeManyfold()
            fake.scan_error = PermanentKubectlError(
                "scan exited 1",
                returncode=1,
                classification="permanent",
            )
            cfg = CurateConfig(library_root=str(lib), work_dir=str(work))
            planted: Any = fake
            with self.assertRaises(PromoteHalted) as ctx:
                run_promote(
                    cfg,
                    [batch_fail, batch_later],
                    intake_root=intake,
                    do_apply=True,
                    client=planted,
                    run_id="planted-scan",
                )
            # Prove halt by effect, not a boolean we set ourselves.
            self.assertEqual(ctx.exception.receipt.halted_at.batch_file, "01-fail.txt")
            self.assertEqual(ctx.exception.receipt.halted_at.reason, "scan_permanent")
            self.assertEqual(ctx.exception.receipt.halted_at.exit_code, 1)
            self.assertEqual(fake.applies, 0)
            self.assertEqual(len(fake.scans), 0)
            # First pack moved (scan fails after move); later pack untouched.
            self.assertTrue((lib / "AnySTL" / "King's Throne").is_dir())
            self.assertTrue((intake / "Games" / "Later Pack").is_dir())
            self.assertFalse((lib / "Games" / "Later Pack").exists())
            self.assertEqual(
                ctx.exception.receipt.batches_attempted,
                [str(batch_fail)],
            )
            data = json.loads(
                (work / "promote-receipt-planted-scan.json").read_text(encoding="utf-8")
            )
            self.assertEqual(data["halted_at"]["batch_file"], "01-fail.txt")

    def test_cli_exits_nonzero_on_planted_scan_fail(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            intake = tmp / "intake"
            lib = tmp / "library"
            lib.mkdir()
            rel = "AnySTL/King's Throne"
            _write_pack(intake, rel)
            work = intake / ".spark-curate"
            work.mkdir()
            batch = _batch(work, "cli-fail.txt", [rel])
            fake = _FakeManyfold()
            fake.scan_error = PermanentKubectlError("scan exited 1", returncode=1)
            cfg = CurateConfig(library_root=str(lib), work_dir=str(work))

            args = type(
                "Args",
                (),
                {
                    "paths_files": [str(batch)],
                    "intake": str(intake),
                    "apply": True,
                    "copy": False,
                    "allow_live": False,
                    "kubectl_retries": 5,
                    "kubectl_backoff": 1.0,
                },
            )()
            planted: Any = fake
            rc = run_promote_cli(args, cfg, client=planted)
            self.assertEqual(rc, 1)

    def test_planted_apply_failure_halts(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            intake = tmp / "intake"
            lib = tmp / "library"
            lib.mkdir()
            rel = "AnySTL/King's Throne"
            _write_pack(intake, rel)
            work = intake / ".spark-curate"
            work.mkdir()
            batch = _batch(work, "batch-apply.txt", [rel])
            fake = _FakeManyfold()
            fake.apply_error = PermanentKubectlError(
                "datapackage apply exited 1",
                returncode=1,
                classification="permanent",
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
                    run_id="planted-apply",
                )
            self.assertEqual(ctx.exception.receipt.halted_at.reason, "apply_permanent")
            self.assertEqual(ctx.exception.receipt.halted_at.batch_file, "batch-apply.txt")
            self.assertEqual(len(fake.scans), 1)
            self.assertEqual(fake.applies, 0)


class TransientRetryTests(unittest.TestCase):
    """ac-6: 502 retries then STOP; 401/403 are permanent and do not retry."""

    def test_classify_502_transient_401_permanent(self) -> None:
        self.assertEqual(
            classify_kubectl_failure(
                "proxy error from 127.0.0.1:6443 while dialing "
                "192.168.11.163:10250, code 502: 502 Bad Gateway",
                1,
            ),
            "transient",
        )
        self.assertEqual(
            classify_kubectl_failure("Error from server (Unauthorized): 401", 1),
            "permanent",
        )
        self.assertEqual(
            classify_kubectl_failure("Error from server (Forbidden): 403", 1),
            "permanent",
        )
        # Permanent wins if both appear.
        self.assertEqual(
            classify_kubectl_failure("403 Forbidden ... later 502 Bad Gateway", 1),
            "permanent",
        )

    def test_planted_502_retries_then_stops(self) -> None:
        calls = {"n": 0}
        slept: list[float] = []
        logs: list[tuple[str, dict[str, Any]]] = []

        def run_fn(argv: list[str], **kwargs: Any) -> subprocess.CompletedProcess[bytes]:
            self.assertIs(kwargs.get("shell"), False)
            calls["n"] += 1
            return subprocess.CompletedProcess(
                argv,
                1,
                stdout=b"",
                stderr=(
                    b"proxy error from 127.0.0.1:6443 while dialing "
                    b"192.168.11.163:10250, code 502: 502 Bad Gateway"
                ),
            )

        def log(event: str, **fields: Any) -> None:
            logs.append((event, fields))

        client = ManyfoldClient(
            run_fn=run_fn,
            sleep_fn=slept.append,
            log=log,
            max_retries=4,
            backoff_base=1.0,
        )
        with self.assertRaises(KubectlRetriesExhausted) as ctx:
            client.enqueue_scan(["AnySTL/Pack"])
        self.assertEqual(ctx.exception.classification, "transient_exhausted")
        self.assertEqual(calls["n"], 4)
        self.assertEqual(slept, [1.0, 2.0, 4.0])
        events = [e for e, _ in logs]
        self.assertIn("kubectl_transient", events)
        self.assertIn("kubectl_retries_exhausted", events)
        self.assertNotIn("kubectl_permanent", events)

        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            intake = tmp / "intake"
            lib = tmp / "library"
            lib.mkdir()
            rel = "AnySTL/King's Throne"
            _write_pack(intake, rel)
            work = intake / ".spark-curate"
            work.mkdir()
            batch = _batch(work, "batch-502.txt", [rel])
            later = _batch(work, "batch-after.txt", ["Games/Later Pack"])
            _write_pack(intake, "Games/Later Pack")
            cfg = CurateConfig(library_root=str(lib), work_dir=str(work))
            with self.assertRaises(PromoteHalted) as halted:
                run_promote(
                    cfg,
                    [batch, later],
                    intake_root=intake,
                    do_apply=True,
                    client=client,
                    run_id="planted-502",
                    log=log,
                )
            self.assertEqual(
                halted.exception.receipt.halted_at.reason,
                "scan_retries_exhausted",
            )
            self.assertEqual(halted.exception.receipt.halted_at.batch_file, "batch-502.txt")
            self.assertTrue((intake / "Games" / "Later Pack").is_dir())

    def test_401_stops_immediately_no_retry(self) -> None:
        calls = {"n": 0}
        slept: list[float] = []
        logs: list[str] = []

        def run_fn(argv: list[str], **kwargs: Any) -> subprocess.CompletedProcess[bytes]:
            calls["n"] += 1
            return subprocess.CompletedProcess(
                argv,
                1,
                stdout=b"",
                stderr=b"Error from server (Unauthorized): 401",
            )

        client = ManyfoldClient(
            run_fn=run_fn,
            sleep_fn=slept.append,
            log=lambda event, **fields: logs.append(event),
            max_retries=5,
            backoff_base=1.0,
        )
        with self.assertRaises(PermanentKubectlError) as ctx:
            client.enqueue_scan(["AnySTL/Pack"])
        self.assertEqual(ctx.exception.classification, "permanent")
        self.assertEqual(calls["n"], 1)
        self.assertEqual(slept, [])
        self.assertIn("kubectl_permanent", logs)
        self.assertNotIn("kubectl_retries_exhausted", logs)
        self.assertNotIn("kubectl_transient", logs)

    def test_403_stops_immediately(self) -> None:
        calls = {"n": 0}

        def run_fn(argv: list[str], **kwargs: Any) -> subprocess.CompletedProcess[bytes]:
            calls["n"] += 1
            return subprocess.CompletedProcess(
                argv,
                1,
                stdout=b"",
                stderr=b"Error from server (Forbidden): 403",
            )

        client = ManyfoldClient(run_fn=run_fn, sleep_fn=lambda _s: None, max_retries=5)
        with self.assertRaises(PermanentKubectlError):
            client.apply_datapackages()
        self.assertEqual(calls["n"], 1)


class UnsafePathHaltTests(unittest.TestCase):
    """Path-safety refusal must halt via run_promote with a typed receipt.

    The Sep 4 defect class is "handler references a name it did not bind":
    a traversal refusal used to raise UnboundLocalError, skip _halt, and
    leave receipt.failed empty. Drive the unsafe path through run_promote
    (not _promote_one) so the loop, halt, and receipt write are asserted.
    """

    def test_run_promote_unsafe_path_halts_with_typed_receipt(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            intake = tmp / "intake"
            lib = tmp / "library"
            lib.mkdir()
            intake.mkdir()
            work = intake / ".spark-curate"
            work.mkdir()
            rel = "AnySTL/../escape"
            batch = _batch(work, "batch-unsafe.txt", [rel])
            cfg = CurateConfig(library_root=str(lib), work_dir=str(work))
            fake: Any = _FakeManyfold()
            with self.assertRaises(PromoteHalted) as ctx:
                run_promote(
                    cfg,
                    [batch],
                    intake_root=intake,
                    do_apply=False,
                    client=fake,
                    run_id="unsafe-path",
                )
            receipt = ctx.exception.receipt
            self.assertIsNotNone(receipt.halted_at)
            self.assertEqual(receipt.halted_at.batch_file, "batch-unsafe.txt")
            self.assertEqual(receipt.halted_at.reason, "TraversalSegmentError")
            self.assertEqual(
                receipt.failed,
                [{"path": rel, "reason": "TraversalSegmentError"}],
            )
            self.assertEqual(receipt.batches_attempted, [str(batch)])
            self.assertEqual(fake.scans, [])
            dest = work / "promote-receipt-unsafe-path.json"
            self.assertTrue(dest.is_file())
            data = json.loads(dest.read_text(encoding="utf-8"))
            self.assertEqual(data["failed"], [{"path": rel, "reason": "TraversalSegmentError"}])
            self.assertEqual(data["halted_at"]["reason"], "TraversalSegmentError")
            self.assertEqual(data["halted_at"]["batch_file"], "batch-unsafe.txt")


class NoSecondAdHocPathTests(unittest.TestCase):
    def test_promote_module_is_the_entry_point(self) -> None:
        src = inspect.getsource(main)
        self.assertIn("run_promote_cli", src)
        self.assertIn("promote", src)
