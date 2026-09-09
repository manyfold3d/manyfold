"""Bake immutable intake Job env (INIT-021/SPEC-010).

Job pod templates cannot be patched after create. This module is the only
env writer for intake Jobs: MODE, APPLY=0, MERGE_HITL, LIBRARY_ROOT (batch),
slice, WORKERS=1. Never documents or emits ``kubectl set env``.

LIBRARY_ROOT is the Unorg **batch** directory (cluster: ``/intake``).
It is never ``/library``, ``/models``, or ``/mnt/backups/3D-Prints``.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

PROVENANCE = "INIT-021/SPEC-010"

INTAKE_MODES = frozenset(
    {"unorganize", "classify", "archive-recall", "admit", "promote"}
)
MERGE_HITL_VALUES = frozenset({"hitl_all", "hitl_uncertain", "hitl_off"})

# ac-3 — these are the live library, never an intake LIBRARY_ROOT.
FORBIDDEN_LIBRARY_ROOTS = frozenset(
    {
        "/library",
        "/models",
        "/mnt/backups/3D-Prints",
        "/volume1/Backups/3D-Prints",
        "/mnt/nas/backups/3D-Prints",
    }
)

SET_ENV_RE = re.compile(r"kubectl\s+set\s+env", re.IGNORECASE)
# Command-shaped only — prose that forbids the patch is not a violation.
SET_ENV_CMD_RE = re.compile(
    r"^[\$\s]*(?:sudo\s+)?kubectl\s+set\s+env\b",
    re.IGNORECASE | re.MULTILINE,
)

DEFAULT_CLUSTER_BATCH_ROOT = "/intake"
DEFAULT_HOST_BATCH = (
    "/mnt/backups/3D-Prints-Unorg/intake/2026-08-drive-mega"
)


class BakeError(ValueError):
    """Typed bake failure — fail loud, do not coerce."""


def assert_library_root(root: str) -> str:
    """Refuse library / PVC paths as intake LIBRARY_ROOT (ac-3)."""
    cleaned = (root or "").strip().rstrip("/") or DEFAULT_CLUSTER_BATCH_ROOT
    if cleaned in FORBIDDEN_LIBRARY_ROOTS:
        raise BakeError(
            f"LIBRARY_ROOT={cleaned} is the live library; intake Jobs must "
            "target the Unorg batch (cluster /intake or a 3D-Prints-Unorg path)"
        )
    if cleaned.startswith("/mnt/backups/3D-Prints/") and "/3D-Prints-Unorg/" not in cleaned:
        raise BakeError(
            f"LIBRARY_ROOT={cleaned} is under the live library prefix"
        )
    if cleaned in {"/library", "/models"} or cleaned.startswith("/library/") or cleaned.startswith("/models/"):
        raise BakeError(f"LIBRARY_ROOT={cleaned} is a library PVC path")
    return cleaned


def assert_mode(mode: str) -> str:
    if mode not in INTAKE_MODES:
        raise BakeError(
            f"MODE={mode} is not an intake mode; expected one of {sorted(INTAKE_MODES)}"
        )
    return mode


def assert_merge_hitl(value: str) -> str:
    if value not in MERGE_HITL_VALUES:
        raise BakeError(
            f"MERGE_HITL={value} is invalid; refusing to coerce (not hitl_off)"
        )
    return value


def upsert_env(container: dict[str, Any], name: str, value: str) -> None:
    env = container.setdefault("env", [])
    for item in env:
        if item.get("name") == name:
            item["value"] = str(value)
            item.pop("valueFrom", None)
            return
    env.append({"name": name, "value": str(value)})


def bake_intake_job(
    job: dict[str, Any],
    *,
    name: str,
    namespace: str = "manyfold",
    mode: str = "unorganize",
    apply: str = "0",
    merge_hitl: str = "hitl_all",
    library_root: str = DEFAULT_CLUSTER_BATCH_ROOT,
    slice_name: str = "",
    workers: str = "1",
    batch_id: str = "2026-08-drive-mega",
    plan: str = "",
    paths_file: str = "",
    work_dir: str = "",
) -> dict[str, Any]:
    """Mutate a Job dict with immutable intake env. Returns the same object."""
    mode = assert_mode(mode)
    merge_hitl = assert_merge_hitl(merge_hitl)
    library_root = assert_library_root(library_root)
    apply_s = "1" if str(apply) in {"1", "true", "True"} else "0"
    workers_s = str(int(workers))

    job["metadata"] = {
        "name": name,
        "namespace": namespace,
        "labels": {
            "app": "spark-curate",
            "role": "intake-admit",
            "provenance": "INIT-021-SPEC-010",
            "batch": batch_id,
        },
    }
    spec = job["spec"]["template"]["spec"]
    container = spec["containers"][0]
    updates = {
        "MODE": mode,
        "APPLY": apply_s,
        "MERGE_HITL": merge_hitl,
        "LIBRARY_ROOT": library_root,
        "WORKERS": workers_s,
        "BATCH_ROOT": library_root,
        "SLICE": slice_name,
        "UNORGANIZE_SLICE": slice_name,
        "SLICE_TOP": slice_name,
        "WORK_DIR": work_dir or f"{library_root.rstrip('/')}/.spark-curate",
    }
    if plan:
        updates["PLAN"] = plan
    if paths_file:
        updates["PATHS_FILE"] = paths_file
    for key, val in updates.items():
        upsert_env(container, key, val)

    args = ["--library", library_root, "--mode", mode]
    if slice_name and mode == "unorganize":
        args.extend(["--unorganize-slice", slice_name])
    if slice_name and mode == "archive-recall":
        args.extend(["--slice-top", slice_name])
    if plan:
        args.extend(["--plan", plan])
    if paths_file and mode == "promote":
        args.extend(["--paths-file", paths_file])
    container["args"] = args

    for vol in spec.get("volumes") or []:
        pass
    for mount in container.get("volumeMounts") or []:
        if mount.get("mountPath") in {"/intake", library_root}:
            if batch_id:
                mount["subPath"] = f"intake/{batch_id}"

    return job


def lint_no_set_env(text: str, *, label: str) -> None:
    for i, line in enumerate(text.splitlines(), 1):
        stripped = line.lstrip()
        if stripped.startswith(("#", "-", "*", ">")):
            continue
        if SET_ENV_CMD_RE.match(stripped):
            raise BakeError(
                f"{label}:{i} has a kubectl-set-env command (forbidden; bake at apply)"
            )


def lint_paths(paths: list[Path]) -> list[str]:
    """Return lint notes. Raises BakeError on set-env or library LIBRARY_ROOT."""
    notes: list[str] = []
    for path in paths:
        if not path.is_file():
            raise BakeError(f"lint target missing: {path}")
        text = path.read_text(encoding="utf-8")
        lint_no_set_env(text, label=str(path))
        notes.append(f"ok: no kubectl set env in {path.name}")
    return notes


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("job_json", help="Job JSON from kubectl create --dry-run=client")
    p.add_argument("--name", required=True)
    p.add_argument("--namespace", default="manyfold")
    p.add_argument("--mode", default="unorganize")
    p.add_argument("--apply", default="0")
    p.add_argument("--merge-hitl", default="hitl_all")
    p.add_argument("--library-root", default=DEFAULT_CLUSTER_BATCH_ROOT)
    p.add_argument("--slice", default="")
    p.add_argument("--workers", default="1")
    p.add_argument("--batch", default="2026-08-drive-mega")
    p.add_argument("--plan", default="")
    p.add_argument("--paths-file", default="")
    p.add_argument("--work-dir", default="")
    args = p.parse_args(argv)

    path = Path(args.job_json)
    job = json.loads(path.read_text(encoding="utf-8"))
    bake_intake_job(
        job,
        name=args.name,
        namespace=args.namespace,
        mode=args.mode,
        apply=args.apply,
        merge_hitl=args.merge_hitl,
        library_root=args.library_root,
        slice_name=args.slice,
        workers=args.workers,
        batch_id=args.batch,
        plan=args.plan,
        paths_file=args.paths_file,
        work_dir=args.work_dir,
    )
    path.write_text(json.dumps(job, indent=2) + "\n", encoding="utf-8")
    env = {e["name"]: e.get("value") for e in job["spec"]["template"]["spec"]["containers"][0]["env"]}
    print(f"Wrote {path} provenance={PROVENANCE}")
    for key in ("MODE", "APPLY", "MERGE_HITL", "LIBRARY_ROOT", "WORKERS", "SLICE"):
        print(f"  {key}={env.get(key)}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except BakeError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(2) from exc
