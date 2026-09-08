"""Version-controlled intake promote (INIT-021/SPEC-013).

Supersedes the ad-hoc Sep 4–5 loop: structural path safety, argv kubectl,
halt-on-nonzero scan/apply, DB tag verification, per-run receipt.

A promote is not done when files are on disk. On-disk datapackage.json is
not evidence of import.
"""
from __future__ import annotations

import json
import shutil
import time
from collections.abc import Callable, Iterator, Sequence
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

from .config import CurateConfig
from .manyfold_client import (
    KubectlError,
    KubectlRetriesExhausted,
    ManyfoldClient,
    PermanentKubectlError,
    default_log,
)
from .pathsafe import (
    PathUnsafeError,
    assert_jailed_destination,
    check_destination,
    check_rel_path,
    safe_label,
)

PROVENANCE = "INIT-021/SPEC-013"

# Live trees this spec must not write. SPEC-010 may pass allow_live after gate.
_LIVE_LIBRARY_PREFIXES = (
    "/mnt/backups/3D-Prints",
    "/volume1/Backups/3D-Prints",
)

RECEIPT_FIELD_NOTES = {
    "batches_attempted": (
        "Batch path-list files this run opened, in deterministic (sorted) order."
    ),
    "promoted": (
        "Relative Category/Model paths this run moved or treated as already "
        "landed, then handed to Phase A. Not a claim they imported."
    ),
    "verified_in_db": (
        "Paths Manyfold reported as a model row with a non-empty tag list. "
        "On-disk datapackage.json is not evidence and is never consulted."
    ),
    "failed": (
        "Paths that did not verify (absent or untagged), failed path safety, "
        "or failed to move. Each entry has a typed reason."
    ),
    "halted_at": (
        "If not null, the loop stopped at this batch (index, file, reason). "
        "Later batches were not attempted."
    ),
}


class PromoteError(Exception):
    """Base for promote-loop failures."""


class LiveTreeGuardError(PromoteError):
    """Refuses writes that would touch the live library or intake/Mega."""


class DestinationCollisionError(PromoteError):
    """Dest exists and is not the same pack. Never suffix Name (N)."""


class PromoteHalted(PromoteError):
    """Scan, apply, verify, or kubectl failed — loop stopped."""

    def __init__(self, receipt: PromoteReceipt, reason: str) -> None:
        super().__init__(reason)
        self.receipt = receipt
        self.reason = reason


class ScanFailedError(PromoteError):
    """Phase A scan exited non-zero."""


class ApplyFailedError(PromoteError):
    """datapackage apply exited non-zero."""


class VerifyFailedError(PromoteError):
    """One or more promoted paths are absent or untagged in the DB."""


@dataclass
class HaltInfo:
    batch_index: int
    batch_file: str
    reason: str
    exit_code: int | None = None

    def to_dict(self) -> dict[str, Any]:
        return {
            "batch_index": self.batch_index,
            "batch_file": self.batch_file,
            "reason": self.reason,
            "exit_code": self.exit_code,
        }


@dataclass
class PromoteReceipt:
    """Per-run receipt under the batch ``.spark-curate/``."""

    run_id: str
    apply: bool
    batches_attempted: list[str] = field(default_factory=list)
    promoted: list[str] = field(default_factory=list)
    verified_in_db: list[str] = field(default_factory=list)
    failed: list[dict[str, str]] = field(default_factory=list)
    halted_at: HaltInfo | None = None
    planned: list[str] = field(default_factory=list)

    def to_dict(self) -> dict[str, Any]:
        return {
            "provenance": PROVENANCE,
            "run_id": self.run_id,
            "apply": self.apply,
            "batches_attempted": list(self.batches_attempted),
            "promoted": list(self.promoted),
            "verified_in_db": list(self.verified_in_db),
            "failed": list(self.failed),
            "halted_at": self.halted_at.to_dict() if self.halted_at else None,
            "planned": list(self.planned),
            "field_notes": dict(RECEIPT_FIELD_NOTES),
        }

    def write(self, path: Path) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(
            json.dumps(self.to_dict(), indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )


def receipt_path(work_dir: Path, run_id: str) -> Path:
    return Path(work_dir) / f"promote-receipt-{run_id}.json"


def _path_str(path: Path) -> str:
    try:
        return str(path.resolve()) if path.exists() else str(path)
    except OSError:
        return str(path)


def _is_under_prefix(resolved: str, prefix: str) -> bool:
    r = resolved.rstrip("/")
    p = prefix.rstrip("/")
    return r == p or r.startswith(p + "/")


def assert_not_live_tree(path: Path, *, allow_live: bool) -> None:
    """Refuse the live library and ``intake/Mega/**`` unless SPEC-010 gated."""
    if allow_live:
        return
    resolved = _path_str(path).replace("\\", "/")
    # Unorg is a sibling of the library — do not treat 3D-Prints-Unorg as the library.
    in_unorg = "/3D-Prints-Unorg/" in resolved or resolved.endswith("/3D-Prints-Unorg")
    if not in_unorg:
        for prefix in _LIVE_LIBRARY_PREFIXES:
            if _is_under_prefix(resolved, prefix):
                raise LiveTreeGuardError(
                    "refusing live library path (SPEC-013 tests/dry-runs use a temp tree; "
                    "SPEC-010 owns gated APPLY=1)"
                )
    if "/intake/Mega" in resolved or resolved.endswith("/intake/Mega"):
        raise LiveTreeGuardError(
            "refusing intake/Mega (SPEC-013 must not touch that tree)"
        )


def iter_batch_lines(batch_file: Path) -> Iterator[str]:
    """Stream a path-list. Skip blank lines. Do not load the pack tree."""
    with batch_file.open("r", encoding="utf-8") as fh:
        for raw in fh:
            line = raw.rstrip("\r\n").strip()
            if not line:
                continue
            yield line


def _record_fail(receipt: PromoteReceipt, rel: str, reason: str) -> None:
    receipt.failed.append({"path": rel, "reason": reason})


def _same_pack(src: Path, dest: Path) -> bool:
    try:
        if src.exists() and dest.exists():
            return src.resolve() == dest.resolve()
    except OSError:
        return False
    return False


def _move_or_copy(
    src: Path,
    dest: Path,
    *,
    copy: bool,
    library_root: Path,
) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    if copy:
        shutil.copytree(src, dest, symlinks=False)
    else:
        shutil.move(str(src), str(dest))
    # Re-check after the write — a swapped symlink between plan and move is caught.
    assert_jailed_destination(dest, library_root)


def _promote_one(
    rel: str,
    *,
    intake_root: Path,
    library_root: Path,
    do_apply: bool,
    copy: bool,
    receipt: PromoteReceipt,
) -> str:
    """Validate and optionally move one pack. Returns rel if it should be scanned."""
    try:
        category, name = check_rel_path(rel)
    except PathUnsafeError:
        _record_fail(receipt, rel, type(e).__name__)
        raise

    dest = library_root / category / name
    src = intake_root / category / name

    try:
        check_destination(rel, library_root)
        if src.exists():
            check_destination(rel, intake_root)
    except PathUnsafeError as e:
        _record_fail(receipt, rel, type(e).__name__)
        raise

    if dest.exists() and (not src.exists() or _same_pack(src, dest)):
        # Already landed — verify later, do not re-move, do not suffix.
        receipt.promoted.append(rel)
        return rel

    if dest.exists() and src.exists():
        _record_fail(receipt, rel, "destination_exists")
        raise DestinationCollisionError(
            f"destination exists for {safe_label(rel)}; never suffix Name (N)"
        )

    if not src.exists():
        _record_fail(receipt, rel, "source_missing")
        raise PromoteError(f"source missing for {safe_label(rel)}")

    receipt.planned.append(rel)
    if not do_apply:
        return rel

    _move_or_copy(src, dest, copy=copy, library_root=library_root)
    receipt.promoted.append(rel)
    return rel


def _halt(
    receipt: PromoteReceipt,
    *,
    work_dir: Path,
    batch_index: int,
    batch_file: Path,
    reason: str,
    exit_code: int | None,
    log: Callable[..., None],
) -> PromoteHalted:
    receipt.halted_at = HaltInfo(
        batch_index=batch_index,
        batch_file=batch_file.name,
        reason=reason,
        exit_code=exit_code,
    )
    dest = receipt_path(work_dir, receipt.run_id)
    receipt.write(dest)
    log(
        "halted",
        batch_index=batch_index,
        batch_file=batch_file.name,
        reason=reason,
        exit_code=exit_code,
        receipt=str(dest),
    )
    # Unmissable human line — batch file only, no pack paths.
    print(
        f"HALTED at batch {batch_index} file={batch_file.name} "
        f"reason={reason} exit={exit_code}",
        flush=True,
    )
    return PromoteHalted(receipt, reason)


def _verify_batch(
    client: ManyfoldClient,
    paths: Sequence[str],
    receipt: PromoteReceipt,
) -> None:
    """DB is the system of record. On-disk datapackage files are not consulted."""
    rows = client.verify_tagged(paths)
    by_path = {row.path: row for row in rows}
    missing_rows = [p for p in paths if p not in by_path]
    for rel in missing_rows:
        _record_fail(receipt, rel, "verify_row_missing")
    for rel in paths:
        row = by_path.get(rel)
        if row is None:
            continue
        if row.status == "tagged" and row.tag_count > 0:
            receipt.verified_in_db.append(rel)
            continue
        if row.status == "absent":
            _record_fail(receipt, rel, "absent_in_db")
        elif row.status == "untagged":
            _record_fail(receipt, rel, "untagged_in_db")
        else:
            _record_fail(receipt, rel, f"verify_{row.status}")
    bad = [f for f in receipt.failed if f.get("path") in set(paths)]
    if bad:
        raise VerifyFailedError(
            "promote verify failed: pack(s) on disk but absent or untagged in DB"
        )


def run_promote(
    cfg: CurateConfig,
    batch_files: Sequence[Path],
    *,
    intake_root: Path,
    do_apply: bool,
    copy: bool = False,
    allow_live: bool = False,
    client: ManyfoldClient | None = None,
    run_id: str | None = None,
    log: Callable[..., None] | None = None,
) -> PromoteReceipt:
    """Promote batches in deterministic order. Halt on first scan/apply/verify failure."""
    log_fn = log or default_log
    library_root = Path(cfg.library_root)
    intake = Path(intake_root)
    work = cfg.resolved_work_dir()
    if not cfg.work_dir:
        work = intake / ".spark-curate"

    assert_not_live_tree(work, allow_live=allow_live)
    assert_not_live_tree(intake, allow_live=allow_live)
    if do_apply:
        assert_not_live_tree(library_root, allow_live=allow_live)

    ordered = tuple(
        sorted((Path(p) for p in batch_files), key=lambda p: p.as_posix().lower())
    )
    rid = run_id or time.strftime("%Y%m%d-%H%M%S")
    receipt = PromoteReceipt(run_id=rid, apply=do_apply)
    mf = client or ManyfoldClient()
    work.mkdir(parents=True, exist_ok=True)

    log_fn(
        "promote_start",
        run_id=rid,
        apply=do_apply,
        batches=len(ordered),
        copy=copy,
    )

    try:
        for index, batch in enumerate(ordered):
            receipt.batches_attempted.append(str(batch))
            log_fn("batch_start", batch_index=index, batch_file=batch.name)
            to_scan: list[str] = []
            try:
                for rel in iter_batch_lines(batch):
                    to_scan.append(
                        _promote_one(
                            rel,
                            intake_root=intake,
                            library_root=library_root,
                            do_apply=do_apply,
                            copy=copy,
                            receipt=receipt,
                        )
                    )
            except PathUnsafeError as e:
                raise _halt(
                    receipt,
                    work_dir=work,
                    batch_index=index,
                    batch_file=batch,
                    reason=type(e).__name__,
                    exit_code=2,
                    log=log_fn,
                ) from e
            except DestinationCollisionError as e:
                raise _halt(
                    receipt,
                    work_dir=work,
                    batch_index=index,
                    batch_file=batch,
                    reason="destination_exists",
                    exit_code=2,
                    log=log_fn,
                ) from e
            except PromoteError as e:
                raise _halt(
                    receipt,
                    work_dir=work,
                    batch_index=index,
                    batch_file=batch,
                    reason=type(e).__name__,
                    exit_code=2,
                    log=log_fn,
                ) from e

            if not do_apply:
                continue

            paths_out = work / f"promoted-paths-{rid}-batch-{index:03d}.txt"
            paths_out.write_text(
                "".join(f"{p}\n" for p in to_scan),
                encoding="utf-8",
            )

            try:
                mf.enqueue_scan(to_scan)
            except KubectlRetriesExhausted as e:
                raise _halt(
                    receipt,
                    work_dir=work,
                    batch_index=index,
                    batch_file=batch,
                    reason="scan_retries_exhausted",
                    exit_code=e.returncode,
                    log=log_fn,
                ) from e
            except PermanentKubectlError as e:
                raise _halt(
                    receipt,
                    work_dir=work,
                    batch_index=index,
                    batch_file=batch,
                    reason="scan_permanent",
                    exit_code=e.returncode,
                    log=log_fn,
                ) from e
            except KubectlError as e:
                raise _halt(
                    receipt,
                    work_dir=work,
                    batch_index=index,
                    batch_file=batch,
                    reason="scan_nonzero",
                    exit_code=e.returncode,
                    log=log_fn,
                ) from e

            try:
                mf.apply_datapackages()
            except KubectlRetriesExhausted as e:
                raise _halt(
                    receipt,
                    work_dir=work,
                    batch_index=index,
                    batch_file=batch,
                    reason="apply_retries_exhausted",
                    exit_code=e.returncode,
                    log=log_fn,
                ) from e
            except PermanentKubectlError as e:
                raise _halt(
                    receipt,
                    work_dir=work,
                    batch_index=index,
                    batch_file=batch,
                    reason="apply_permanent",
                    exit_code=e.returncode,
                    log=log_fn,
                ) from e
            except KubectlError as e:
                raise _halt(
                    receipt,
                    work_dir=work,
                    batch_index=index,
                    batch_file=batch,
                    reason="apply_nonzero",
                    exit_code=e.returncode,
                    log=log_fn,
                ) from e

            try:
                _verify_batch(mf, to_scan, receipt)
            except VerifyFailedError as e:
                raise _halt(
                    receipt,
                    work_dir=work,
                    batch_index=index,
                    batch_file=batch,
                    reason="verify_failed",
                    exit_code=1,
                    log=log_fn,
                ) from e
            except KubectlRetriesExhausted as e:
                raise _halt(
                    receipt,
                    work_dir=work,
                    batch_index=index,
                    batch_file=batch,
                    reason="verify_retries_exhausted",
                    exit_code=e.returncode,
                    log=log_fn,
                ) from e
            except PermanentKubectlError as e:
                raise _halt(
                    receipt,
                    work_dir=work,
                    batch_index=index,
                    batch_file=batch,
                    reason="verify_permanent",
                    exit_code=e.returncode,
                    log=log_fn,
                ) from e
            except KubectlError as e:
                raise _halt(
                    receipt,
                    work_dir=work,
                    batch_index=index,
                    batch_file=batch,
                    reason="verify_nonzero",
                    exit_code=e.returncode,
                    log=log_fn,
                ) from e

            log_fn("batch_ok", batch_index=index, batch_file=batch.name)
    finally:
        receipt.write(receipt_path(work, rid))

    return receipt


def run_promote_cli(
    args: Any,
    curate: CurateConfig,
    *,
    client: ManyfoldClient | None = None,
) -> int:
    """CLI adapter for ``MODE=promote`` / ``--mode promote``."""
    paths_files = [Path(p) for p in (getattr(args, "paths_files", None) or [])]
    if not paths_files:
        print(
            "MODE=promote requires --paths-file (batch path-list). "
            "The ad-hoc promote loop is superseded by this entry point.",
            flush=True,
        )
        return 2
    missing = [p for p in paths_files if not p.is_file()]
    if missing:
        print(f"path-list not found: {missing[0]}", flush=True)
        return 2

    intake = Path(args.intake) if getattr(args, "intake", None) else Path(curate.library_root)
    if getattr(args, "intake", None):
        curate.work_dir = str(intake / ".spark-curate")

    retries = int(getattr(args, "kubectl_retries", 5) or 5)
    backoff = float(getattr(args, "kubectl_backoff", 1.0) or 1.0)
    mf = client or ManyfoldClient(max_retries=retries, backoff_base=backoff)

    try:
        receipt = run_promote(
            curate,
            paths_files,
            intake_root=intake,
            do_apply=bool(args.apply),
            copy=bool(getattr(args, "copy", False)),
            allow_live=bool(getattr(args, "allow_live", False)),
            client=mf,
        )
    except PromoteHalted as e:
        print(json.dumps(e.receipt.to_dict(), indent=2, ensure_ascii=False))
        return 1
    except LiveTreeGuardError as e:
        print(f"ERROR: {e}", flush=True)
        return 2

    print(json.dumps(receipt.to_dict(), indent=2, ensure_ascii=False))
    if receipt.failed or receipt.halted_at:
        return 1
    return 0
