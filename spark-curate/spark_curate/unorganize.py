"""Unorganize pass — classify folder levels and detect pack roots (INIT-021/SPEC-004).

Plans only; never moves files. Emits ``unorganize-plan-*.jsonl`` under the intake
``.spark-curate/`` directory.
"""
from __future__ import annotations

import json
import logging
import os
import re
import time
from collections.abc import Iterator
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

from .config import DEFAULT_CATEGORIES, SKIP_TOP_LEVEL, CurateConfig
from .indexable import (
    ARCHIVE_EXTENSIONS,
    COMMON_SUBFOLDERS,
    IMAGE_EXTENSIONS,
    MESH_EXTENSIONS,
    PROVENANCE,
    bucket_name_hint,
    creator_name_hint,
    extension_of,
    group_multipart_volumes,
    is_ignored_path,
    is_indexable_filename,
    parse_multipart_volume,
    should_skip_dir_name,
)
from .pathsafe import (
    PathUnsafeError,
    TraversalSegmentError,
    check_rel_path,
)

log = logging.getLogger(__name__)

KNOWN_CATEGORIES = frozenset(c.lower() for c in DEFAULT_CATEGORIES)

# Typed errors — fail loud, never swallow.
class UnorganizeError(Exception):
    """Base for unorganize pass failures."""


class IntakeRootError(UnorganizeError):
    """Intake root missing or not a directory."""


class SymlinkEscapeRefused(UnorganizeError):
    """Symlink resolves outside the intake root."""


class PathJailRefused(UnorganizeError):
    """A planned path escapes the intake jail."""


class ControlCharInPathRefused(UnorganizeError):
    """Control character in a filesystem path."""


class FrozenRootWriteRefused(UnorganizeError):
    """A run would write artifacts into a frozen intake tree."""


# INIT-018 froze the Mega dump: it may be read and profiled, never written to.
# Scanning is allowed; landing artifacts inside it requires an explicit --work-dir
# pointing somewhere else.
FROZEN_INTAKE_ROOTS: tuple[str, ...] = (
    "/mnt/backups/3D-Prints-Unorg/intake/Mega",
)


def assert_writable_work_dir(work: Path) -> None:
    """Refuse to write run artifacts into a frozen intake tree."""
    resolved = Path(os.path.abspath(str(work)))
    for frozen in FROZEN_INTAKE_ROOTS:
        frozen_path = Path(frozen)
        if resolved == frozen_path or frozen_path in resolved.parents:
            raise FrozenRootWriteRefused(
                f"Refusing to write into frozen intake tree {frozen_path} "
                f"(would write {resolved}). The tree is read-only per INIT-018; "
                f"pass --work-dir pointing outside it to profile it."
            )


@dataclass
class LevelClassification:
    rel_path: str
    name: str
    role: str
    signals: list[str] = field(default_factory=list)
    candidate_roles: list[str] = field(default_factory=list)

    def to_dict(self) -> dict[str, Any]:
        out: dict[str, Any] = {
            "rel_path": self.rel_path,
            "name": self.name,
            "role": self.role,
            "signals": sorted(self.signals),
        }
        if self.candidate_roles:
            out["candidate_roles"] = sorted(set(self.candidate_roles))
        return out


@dataclass
class PackPlan:
    source_path: str
    pack_name: str
    rel_pack_root: str
    destination: str | None
    category: str | None
    creator: str | None
    level_classifications: list[LevelClassification]
    signals: list[str]
    flags: list[str]
    archive_files: list[str]
    multipart_sets: list[dict[str, Any]]
    status: str  # planned | hold

    def to_dict(self) -> dict[str, Any]:
        return {
            "provenance": PROVENANCE,
            "source_path": self.source_path,
            "pack_name": self.pack_name,
            "rel_pack_root": self.rel_pack_root,
            "destination": self.destination,
            "category": self.category,
            "creator": self.creator,
            "level_classifications": [lc.to_dict() for lc in self.level_classifications],
            "signals": sorted(self.signals),
            "flags": sorted(set(self.flags)),
            "archive_files": sorted(self.archive_files),
            "multipart_sets": self.multipart_sets,
            "status": self.status,
        }


@dataclass
class UnorganizeResult:
    run_id: str
    intake_root: str
    plans: list[PackPlan]
    unclassified_folders: list[dict[str, Any]]
    plan_path: Path
    summary_path: Path
    errors: list[str] = field(default_factory=list)

    def summary_dict(self) -> dict[str, Any]:
        archive_only = sum(1 for p in self.plans if _is_archive_only_pack(p))
        return {
            "provenance": PROVENANCE,
            "run_id": self.run_id,
            "intake_root": self.intake_root,
            "packs_detected": len(self.plans),
            "planned": sum(1 for p in self.plans if p.status == "planned"),
            "hold": sum(1 for p in self.plans if p.status == "hold"),
            "unclassified_folders": len(self.unclassified_folders),
            "multipart_sets": sum(len(p.multipart_sets) for p in self.plans),
            "archive_only_packs": archive_only,
            "plan_path": str(self.plan_path),
            "summary_path": str(self.summary_path),
            "errors": self.errors,
        }


def _under(path: Path, jail: Path) -> bool:
    try:
        return path == jail or path.is_relative_to(jail)
    except AttributeError:
        # Python <3.12
        try:
            path.relative_to(jail)
            return True
        except ValueError:
            return path == jail


def assert_intake_contained(path: Path, intake_root: Path) -> Path:
    """Refuse symlinks or realpaths that leave *intake_root*."""
    intake_resolved = intake_root.resolve()
    if path.is_symlink():
        try:
            target = path.resolve()
        except OSError as e:
            raise SymlinkEscapeRefused(f"cannot resolve symlink: {path}") from e
        if not _under(target, intake_resolved):
            raise SymlinkEscapeRefused(
                f"symlink escapes intake root: {path.name}"
            )
        return target
    try:
        resolved = path.resolve()
    except OSError as e:
        raise UnorganizeError(f"cannot resolve path: {path}") from e
    if not _under(resolved, intake_resolved):
        raise PathJailRefused(f"path escapes intake root: {path.name}")
    return resolved


def _scan_name_safe(name: str) -> None:
    if re.search(r"[\x00-\x1f\x7f]", name):
        raise ControlCharInPathRefused(f"control character in path name: {name!r}")
    if name == ".." or "/.." in name.replace("\\", "/"):
        raise TraversalSegmentError(f"refused traversal segment in {name!r}")


def _iter_dir_entries(dir_path: Path) -> Iterator[os.DirEntry[str]]:
    try:
        with os.scandir(dir_path) as it:
            for entry in sorted(it, key=lambda e: e.name.lower()):
                yield entry
    except OSError as e:
        log.warning("cannot scandir %s: %s", dir_path, e)


def _folder_bears_indexable(
    dir_path: Path, intake_root: Path
) -> tuple[bool, list[str], list[Path]]:
    """Indexable directly or only via common subfolders (D-2)."""
    signals: list[str] = []
    archives: list[Path] = []
    rel_base = dir_path.relative_to(intake_root).as_posix()

    for entry in _iter_dir_entries(dir_path):
        _scan_name_safe(entry.name)
        if entry.is_file(follow_symlinks=False):
            if is_ignored_path(f"{rel_base}/{entry.name}", entry.name):
                continue
            if is_indexable_filename(entry.name):
                ext = extension_of(entry.name)
                signals.append(f"direct_indexable:{ext}")
                if ext in ARCHIVE_EXTENSIONS:
                    archives.append(Path(entry.path))
            continue
        if not entry.is_dir(follow_symlinks=False):
            continue
        if should_skip_dir_name(entry.name):
            continue
        child = Path(entry.path)
        assert_intake_contained(child, intake_root)
        if entry.name.lower() in COMMON_SUBFOLDERS:
            sub_bears, sub_sig, sub_arch = _folder_bears_indexable(
                child, intake_root
            )
            if sub_bears:
                signals.append(f"indexable_via_common_subfolder:{entry.name.lower()}")
                signals.extend(sub_sig)
                archives.extend(sub_arch)
    if signals:
        return True, signals, archives
    return False, signals, archives


@dataclass
class _WalkState:
    """Per top-level slice: one pack-root sweep + cached bears checks."""

    intake_root: Path
    pack_paths: list[Path] = field(default_factory=list)
    bears_cache: dict[str, tuple[bool, list[str], list[Path]]] = field(
        default_factory=dict
    )

    def pack_count_under(self, dir_path: Path) -> int:
        resolved = dir_path.resolve()
        count = 0
        for pack in self.pack_paths:
            pr = pack.resolve()
            if pr == resolved or _under(pr, resolved):
                count += 1
        return count

    def cached_bears(
        self, dir_path: Path
    ) -> tuple[bool, list[str], list[Path]]:
        key = str(dir_path.resolve())
        if key not in self.bears_cache:
            self.bears_cache[key] = _folder_bears_indexable(
                dir_path, self.intake_root
            )
        return self.bears_cache[key]
def _collect_pack_roots(
    dir_path: Path,
    intake_root: Path,
    state: _WalkState | None = None,
) -> list[tuple[Path, list[str], list[Path]]]:
    """Depth-first pack-root discovery (streaming — one branch at a time)."""
    name_lower = dir_path.name.lower()
    if should_skip_dir_name(dir_path.name):
        return []
    if name_lower in COMMON_SUBFOLDERS:
        return []

    assert_intake_contained(dir_path, intake_root)
    found: list[tuple[Path, list[str], list[Path]]] = []

    if state is not None:
        bears, signals, archives = state.cached_bears(dir_path)
    else:
        bears, signals, archives = _folder_bears_indexable(dir_path, intake_root)
    if bears:
        found.append((dir_path, signals, archives))

    for entry in _iter_dir_entries(dir_path):
        if not entry.is_dir(follow_symlinks=False):
            continue
        if should_skip_dir_name(entry.name):
            continue
        if entry.name.lower() in COMMON_SUBFOLDERS:
            continue
        child = Path(entry.path)
        found.extend(_collect_pack_roots(child, intake_root, state))

    return found


def _classify_level(
    rel_path: str,
    name: str,
    *,
    pack_roots_below: int,
    bears_indexable: bool,
    depth_from_intake: int,
) -> LevelClassification:
    signals: list[str] = []
    candidate_roles: list[str] = []
    lower = name.lower()

    if lower in KNOWN_CATEGORIES:
        signals.append("known_category_name")
        return LevelClassification(rel_path, name, "category", signals)

    if bucket_name_hint(name):
        signals.append("bucket_name_hint")
        candidate_roles.append("bucket")

    if creator_name_hint(name):
        signals.append("creator_name_hint")
        candidate_roles.append("creator")

    if pack_roots_below >= 2:
        signals.append(f"structural:contains_{pack_roots_below}_pack_roots")
        return LevelClassification(
            rel_path, name, "bucket", signals, candidate_roles or ["bucket"]
        )

    if creator_name_hint(name) and pack_roots_below >= 1:
        signals.append("structural:creator_with_pack_child")
        return LevelClassification(rel_path, name, "creator", signals)

    if pack_roots_below == 1 and not bears_indexable:
        signals.append("structural:single_pack_child")
        if bucket_name_hint(name):
            return LevelClassification(rel_path, name, "bucket", signals)
        return LevelClassification(
            rel_path,
            name,
            "unknown",
            signals,
            ["category", "creator", "bucket"],
        )

    if depth_from_intake == 0 and pack_roots_below == 0 and not bears_indexable:
        # Top-level container with no direct indexable — likely category or unknown.
        if "category" not in candidate_roles:
            candidate_roles.append("category")

    if candidate_roles:
        role = candidate_roles[0]
        if len(candidate_roles) > 1:
            return LevelClassification(
                rel_path, name, "unknown", signals, candidate_roles
            )
        return LevelClassification(rel_path, name, role, signals)

    if bears_indexable:
        return LevelClassification(rel_path, name, "pack", ["structural:bears_indexable"])

    return LevelClassification(
        rel_path, name, "unknown", signals, ["category", "creator", "bucket"]
    )


def _ancestor_classifications(
    pack_path: Path, state: _WalkState
) -> list[LevelClassification]:
    rel = pack_path.relative_to(state.intake_root)
    parts = rel.parts[:-1]  # exclude pack folder itself
    levels: list[LevelClassification] = []
    accum = Path()
    for i, part in enumerate(parts):
        accum = accum / part
        dir_path = state.intake_root / accum
        pack_below = state.pack_count_under(dir_path)
        bears, _, _ = state.cached_bears(dir_path)
        lc = _classify_level(
            accum.as_posix(),
            part,
            pack_roots_below=pack_below,
            bears_indexable=bears,
            depth_from_intake=i,
        )
        levels.append(lc)
    return levels


def _nearest_role(levels: list[LevelClassification], role: str) -> str | None:
    for lc in reversed(levels):
        if lc.role == role:
            return lc.name
    return None


def _resolve_destination(
    pack_name: str,
    levels: list[LevelClassification],
    flags: list[str],
) -> tuple[str | None, str | None, str | None]:
    category = _nearest_role(levels, "category")
    creator = _nearest_role(levels, "creator")

    for lc in levels:
        if lc.role == "bucket":
            flags.append("bucket_dismantled")
        if lc.role == "unknown":
            flags.append("unknown_ancestor")

    if category is None:
        flags.append("unresolved_category")
        return None, None, creator

    dest_rel = f"{category}/{pack_name}"
    try:
        check_rel_path(dest_rel)
    except PathUnsafeError:
        flags.append("unsafe_destination")
        return None, None, creator

    # Never emit bucket names in destination (ac-1).
    for lc in levels:
        if lc.role == "bucket" and lc.name.lower() in dest_rel.lower():
            flags.append("bucket_in_destination")
            return None, None, creator

    return dest_rel, category, creator


def _analyze_archives(
    archive_paths: list[Path], flags: list[str], signals: list[str]
) -> tuple[list[str], list[dict[str, Any]]]:
    archive_files = [str(p) for p in archive_paths]
    sets, standalone = group_multipart_volumes(archive_paths)
    multipart_json: list[dict[str, Any]] = []

    for ms in sets:
        missing = ms.missing_middle_volume()
        entry = {
            "stem_key": ms.stem_key,
            "pattern": ms.pattern,
            "volumes": [str(v.path) for v in ms.volumes],
            "volume_numbers": list(ms.volume_numbers),
        }
        if missing is not None:
            entry["missing_volume"] = missing
            flags.append("incomplete_multipart")
            signals.append(f"incomplete_multipart:missing_{missing}")
        else:
            signals.append(f"multipart_set:{len(ms.volumes)}_volumes")
        multipart_json.append(entry)

    for path in standalone:
        if parse_multipart_volume(path) is not None:
            continue
        ext = extension_of(path.name)
        if ext in ARCHIVE_EXTENSIONS:
            signals.append(f"archive:{ext}")

    return archive_files, multipart_json


def _build_pack_plan(
    pack_path: Path,
    state: _WalkState,
    signals: list[str],
    archive_paths: list[Path],
) -> PackPlan:
    rel = pack_path.relative_to(state.intake_root).as_posix()
    pack_name = pack_path.name
    flags: list[str] = []
    levels = _ancestor_classifications(pack_path, state)

    # Pack level itself
    levels.append(
        LevelClassification(rel, pack_name, "pack", ["pack_root_detected"])
    )

    archive_files, multipart_sets = _analyze_archives(
        archive_paths, flags, signals
    )

    # Loose files at bucket root (aud-3) — pack named after folder, low confidence
    if len(levels) == 1 and levels[0].role == "pack":
        parent_levels = _ancestor_classifications(pack_path, state)
        if any(lc.role == "bucket" for lc in parent_levels):
            flags.append("low_confidence")

    destination, category, creator = _resolve_destination(
        pack_name, levels[:-1], flags
    )

    status = "planned"
    if "incomplete_multipart" in flags:
        status = "hold"
        destination = None
    elif destination is None and (
        "unresolved_category" in flags or "unsafe_destination" in flags
    ):
        status = "hold"

    # Destination collision reporting — never suffix Name (N)
    if destination and re.search(r"\(\d+\)\s*$", pack_name):
        flags.append("numeric_suffix_in_name")
        signals.append("collision:suffix_pattern_in_source_name")

    return PackPlan(
        source_path=str(pack_path.resolve()),
        pack_name=pack_name,
        rel_pack_root=rel,
        destination=destination,
        category=category,
        creator=creator,
        level_classifications=levels,
        signals=signals,
        flags=flags,
        archive_files=archive_files,
        multipart_sets=multipart_sets,
        status=status,
    )


def _is_archive_only_pack(plan: PackPlan) -> bool:
    """True when indexable content is archives only (no loose mesh/image)."""
    direct = [
        s.split(":", 1)[1]
        for s in plan.signals
        if s.startswith("direct_indexable:")
    ]
    via_common = [s for s in plan.signals if s.startswith("indexable_via_common_subfolder:")]
    if via_common:
        return False
    if not plan.archive_files:
        return False
    # A README or licence sitting beside the archives is a companion, not content:
    # only a loose mesh or image makes the pack mixed.
    return not any(
        ext in MESH_EXTENSIONS or ext in IMAGE_EXTENSIONS for ext in direct
    )


def _dedupe_plans(
    raw: list[tuple[Path, list[str], list[Path]]], state: _WalkState
) -> list[PackPlan]:
    """Deterministic ordering; one plan per pack root path."""
    seen: set[str] = set()
    plans: list[PackPlan] = []
    for pack_path, signals, archives in sorted(
        raw, key=lambda t: str(t[0]).lower()
    ):
        key = str(pack_path.resolve())
        if key in seen:
            continue
        seen.add(key)
        plans.append(_build_pack_plan(pack_path, state, list(signals), archives))
    return plans


def run_unorganize(
    cfg: CurateConfig,
    *,
    intake_root: str | Path | None = None,
    top_level_only: list[str] | None = None,
    run_id: str | None = None,
) -> UnorganizeResult:
    """Execute the unorganize planning pass (read-only)."""
    root = Path(intake_root or cfg.library_root)
    if not root.is_dir():
        raise IntakeRootError(f"Intake root not found: {root}")

    intake_resolved = root.resolve()
    run_id = run_id or time.strftime("%Y%m%d-%H%M%S")
    if cfg.work_dir:
        work = Path(cfg.work_dir)
    else:
        work = intake_resolved / ".spark-curate"
    assert_writable_work_dir(work)
    work.mkdir(parents=True, exist_ok=True)
    plan_path = work / f"unorganize-plan-{run_id}.jsonl"
    summary_path = work / f"unorganize-summary-{run_id}.json"

    errors: list[str] = []
    all_plans: list[PackPlan] = []
    unclassified: list[dict[str, Any]] = []

    slice_names = (
        {n.lower() for n in top_level_only} if top_level_only else None
    )

    for entry in _iter_dir_entries(intake_resolved):
        _scan_name_safe(entry.name)
        if entry.is_symlink():
            link = Path(entry.path)
            try:
                assert_intake_contained(link, intake_resolved)
            except (
                SymlinkEscapeRefused,
                PathJailRefused,
            ) as e:
                errors.append(f"{entry.name}: {type(e).__name__}: {e}")
            continue
        if not entry.is_dir(follow_symlinks=False):
            continue
        if entry.name in SKIP_TOP_LEVEL or should_skip_dir_name(entry.name):
            continue
        if slice_names is not None and entry.name.lower() not in slice_names:
            continue

        top_path = Path(entry.path)
        try:
            assert_intake_contained(top_path, intake_resolved)
            state = _WalkState(intake_root=intake_resolved)
            raw = _collect_pack_roots(top_path, intake_resolved, state)
            state.pack_paths = [p[0] for p in raw]
            all_plans.extend(_dedupe_plans(raw, state))

            # Report unclassified top-level folders with no packs
            if not raw:
                bears, _, _ = state.cached_bears(top_path)
                lc = _classify_level(
                    entry.name,
                    entry.name,
                    pack_roots_below=0,
                    bears_indexable=bears,
                    depth_from_intake=0,
                )
                if lc.role == "unknown":
                    unclassified.append(
                        {
                            "rel_path": entry.name,
                            "role": lc.role,
                            "candidate_roles": lc.candidate_roles,
                            "signals": lc.signals,
                        }
                    )
        except (
            SymlinkEscapeRefused,
            PathJailRefused,
            ControlCharInPathRefused,
            TraversalSegmentError,
        ) as e:
            errors.append(f"{entry.name}: {type(e).__name__}: {e}")
        except UnorganizeError as e:
            errors.append(f"{entry.name}: {e}")

    plans = sorted(all_plans, key=lambda p: p.rel_pack_root.lower())

    with plan_path.open("w", encoding="utf-8") as fh:
        for plan in plans:
            fh.write(json.dumps(plan.to_dict(), ensure_ascii=False) + "\n")

    result = UnorganizeResult(
        run_id=run_id,
        intake_root=str(intake_resolved),
        plans=plans,
        unclassified_folders=sorted(
            unclassified, key=lambda u: u["rel_path"].lower()
        ),
        plan_path=plan_path,
        summary_path=summary_path,
        errors=errors,
    )
    summary_path.write_text(
        json.dumps(result.summary_dict(), indent=2), encoding="utf-8"
    )
    return result


def run_unorganize_cli(args, cfg: CurateConfig) -> int:
    """CLI entry for MODE=unorganize."""
    intake = args.intake or args.library or cfg.library_root
    slice_folders = args.unorganize_slice if args.unorganize_slice else None

    print(f"Intake:   {intake}")
    print(f"Work dir: {Path(intake) / '.spark-curate'}")
    print("Mode:     unorganize PLAN-ONLY (no moves)")
    if slice_folders:
        print(f"Slice:    {', '.join(slice_folders)}")

    try:
        result = run_unorganize(
            cfg,
            intake_root=intake,
            top_level_only=slice_folders,
        )
    except IntakeRootError as e:
        print(f"ERROR: {e}")
        return 1

    summary = result.summary_dict()
    print(json.dumps(summary, indent=2))
    print(
        f"\nWrote plan: {result.plan_path}\n"
        "Review unorganize-plan JSONL before classify/dedup/admit."
    )
    return 0 if not result.errors else 2
