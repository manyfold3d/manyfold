# Archive-member recall scanner — zip central-directory listing + inverted index.
# Provenance: INIT-018/SPEC-004; cross-root extension INIT-021/SPEC-006
#
# Matching lists archive central directories only. Member extract is forbidden
# on this path (zip-bomb / NFS). CRC+size+basename is recall for within-library
# pairs; cross-root uses basename|size (no CRC) — archive_member_overlap_nocrc:N.
from __future__ import annotations

import hashlib
import json
import logging
import re
import time
import zipfile
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Callable, Iterable, Iterator, Protocol

from .config import CurateConfig
from .indexable import (
    MultipartSet,
    group_multipart_volumes,
    is_admission_relevant_member,
    is_archive_path,
    is_ignored_path,
)
from .walk import ModelFolder, iter_model_folders

log = logging.getLogger(__name__)

# Mesh extensions preferred for STRONG overlap (ADR D-2 / D-4). Archives/images
# are listed when present but mesh-prefer filters drive apply admission later.
MESH_EXT = frozenset(
    {
        ".stl",
        ".obj",
        ".3mf",
        ".ply",
        ".gltf",
        ".glb",
        ".step",
        ".stp",
        ".fbx",
        ".lys",
        ".lyt",
        ".chitubox",
        ".ctb",
        ".sl1s",
        ".3dm",
    }
)

ZIP_EXT = frozenset({".zip"})

# All archive formats handled on batch listing path (libarchive).
BATCH_ARCHIVE_EXT = frozenset({".zip", ".rar", ".7z", ".sevenz", ".cbz"})

# Cap central-directory enumeration per archive (DoS / pathological zips).
DEFAULT_MAX_MEMBERS_PER_ARCHIVE = 5_000

# Artifact filename prefixes under .spark-curate/ (do not mix with organize plans).
ARCHIVE_INDEX_PREFIX = "archive-index"
ARCHIVE_INVERT_PREFIX = "archive-invert"
CROSS_ROOT_INDEX_PREFIX = "cross-root-batch-index"
CROSS_ROOT_CANDIDATES_PREFIX = "cross-root-candidates"
CROSS_ROOT_SUMMARY_PREFIX = "cross-root-recall-summary"

_JUNK_BASENAMES = frozenset(
    {
        ".ds_store",
        "thumbs.db",
        "desktop.ini",
        ".spotlight-v100",
        ".trashes",
    }
)


@dataclass(frozen=True)
class MemberSig:
    """One zip central-directory entry used for recall."""

    basename: str
    uncompressed_size: int
    crc32: int
    is_mesh: bool
    member_path: str

    @property
    def sig(self) -> str:
        return member_signature(self.basename, self.uncompressed_size, self.crc32)


@dataclass
class ZipListing:
    """Result of listing one outer zip (never extracts members)."""

    zip_path: str
    folder_rel: str
    members: list[MemberSig] = field(default_factory=list)
    mesh_count: int = 0
    truncated: bool = False
    max_members: int = DEFAULT_MAX_MEMBERS_PER_ARCHIVE
    skip_reason: str | None = None
    outer_size: int | None = None
    outer_mtime_ns: int | None = None

    def to_dict(self) -> dict[str, Any]:
        return {
            "zip_path": self.zip_path,
            "folder_rel": self.folder_rel,
            "member_count": len(self.members),
            "mesh_count": self.mesh_count,
            "truncated": self.truncated,
            "max_members": self.max_members,
            "skip_reason": self.skip_reason,
            "outer_size": self.outer_size,
            "outer_mtime_ns": self.outer_mtime_ns,
            "members": [
                {
                    "basename": m.basename,
                    "uncompressed_size": m.uncompressed_size,
                    "crc32": m.crc32,
                    "is_mesh": m.is_mesh,
                    "member_path": m.member_path,
                    "sig": m.sig,
                }
                for m in self.members
            ],
        }


@dataclass
class ArchiveIndexResult:
    """
    Export surface for SPEC-005: inverted sig→folders plus per-zip listings.

    Postings are mesh-prefer by default (non-mesh still listed in ZipListing).
    """

    listings: list[ZipListing] = field(default_factory=list)
    # sig -> sorted unique folder_rel postings (mesh members only)
    inverted_mesh: dict[str, list[str]] = field(default_factory=dict)
    # sig -> sorted unique folder_rel (all non-junk members)
    inverted_all: dict[str, list[str]] = field(default_factory=dict)
    folders_scanned: int = 0
    zips_scanned: int = 0
    zips_skipped: int = 0
    zips_truncated: int = 0
    index_jsonl_path: str | None = None
    invert_jsonl_path: str | None = None

    def folders_for_sig(self, sig: str, *, mesh_only: bool = True) -> list[str]:
        table = self.inverted_mesh if mesh_only else self.inverted_all
        return list(table.get(sig, []))

    def shared_mesh_sigs(self, folder_a: str, folder_b: str) -> list[str]:
        """Distinct mesh signatures posted under both folders (deterministic order)."""
        a = folder_a.replace("\\", "/")
        b = folder_b.replace("\\", "/")
        out: list[str] = []
        for sig, folders in sorted(self.inverted_mesh.items()):
            if a in folders and b in folders:
                out.append(sig)
        return out


def member_signature(basename: str, uncompressed_size: int, crc32: int) -> str:
    """Canonical within-root recall key: basename|uncompressed_size|crc32 (ADR D-2)."""
    base = Path(basename.replace("\\", "/")).name
    return f"{base}|{int(uncompressed_size)}|{int(crc32) & 0xFFFFFFFF}"


def member_signature_nocrc(basename: str, size: int) -> str:
    """Cross-root recall key — library archive_entries has no CRC (INIT-021/SPEC-006)."""
    base = Path(basename.replace("\\", "/")).name
    return f"{base}|{int(size)}"


def is_mesh_path(member_path: str) -> bool:
    return Path(member_path.replace("\\", "/")).suffix.lower() in MESH_EXT


def is_junk_member(member_path: str) -> bool:
    """Skip AppleDouble / OS junk paths (never contribute to overlap)."""
    norm = member_path.replace("\\", "/").strip("/")
    if not norm:
        return True
    parts = [p for p in norm.split("/") if p]
    lower_parts = [p.lower() for p in parts]
    if any(p == "__macosx" or p.startswith(".__") for p in lower_parts):
        return True
    base = lower_parts[-1] if lower_parts else ""
    if base in _JUNK_BASENAMES:
        return True
    if base.startswith("._"):
        return True
    return False


def _outer_zip_stat(path: Path) -> tuple[int | None, int | None]:
    try:
        st = path.stat()
        return st.st_size, getattr(st, "st_mtime_ns", int(st.st_mtime * 1_000_000_000))
    except OSError:
        return None, None


def list_zip_members(
    zip_path: Path,
    *,
    folder_rel: str,
    max_members: int = DEFAULT_MAX_MEMBERS_PER_ARCHIVE,
) -> ZipListing:
    """
    List central-directory entries for one zip. Never calls ZipFile.read.

    Bad / unreadable zips return skip_reason and empty members.
    """
    outer_size, outer_mtime_ns = _outer_zip_stat(zip_path)
    listing = ZipListing(
        zip_path=str(zip_path),
        folder_rel=folder_rel.replace("\\", "/"),
        max_members=max_members,
        outer_size=outer_size,
        outer_mtime_ns=outer_mtime_ns,
    )
    if max_members < 1:
        listing.skip_reason = "max_members_lt_1"
        return listing

    try:
        # ZipFile context — infolist only; no .read on this path.
        with zipfile.ZipFile(zip_path, "r") as zf:
            infos = zf.infolist()
            kept = 0
            for info in infos:
                if info.is_dir():
                    continue
                name = info.filename or ""
                if is_junk_member(name):
                    continue
                if kept >= max_members:
                    listing.truncated = True
                    break
                basename = Path(name.replace("\\", "/")).name
                if not basename:
                    continue
                mesh = is_mesh_path(name)
                member = MemberSig(
                    basename=basename,
                    uncompressed_size=int(info.file_size),
                    crc32=int(info.CRC) & 0xFFFFFFFF,
                    is_mesh=mesh,
                    member_path=name.replace("\\", "/"),
                )
                listing.members.append(member)
                if mesh:
                    listing.mesh_count += 1
                kept += 1
    except zipfile.BadZipFile:
        listing.skip_reason = "bad_zip"
        listing.members.clear()
        listing.mesh_count = 0
        listing.truncated = False
    except (OSError, RuntimeError) as exc:
        listing.skip_reason = f"io_error:{type(exc).__name__}"
        listing.members.clear()
        listing.mesh_count = 0
        listing.truncated = False
        log.warning(
            "archive_index skip zip path=%s reason=%s",
            zip_path.name,
            listing.skip_reason,
        )
    return listing


def iter_folder_zips(folder: Path) -> Iterator[Path]:
    """Deterministic zip discovery under a model folder (depth-limited, skip dot dirs)."""
    if not folder.is_dir():
        return
    found: list[Path] = []
    try:
        for p in folder.rglob("*"):
            if not p.is_file():
                continue
            if p.suffix.lower() not in ZIP_EXT:
                continue
            try:
                rel = p.relative_to(folder)
            except ValueError:
                continue
            if any(part.startswith(".") for part in rel.parts[:-1]):
                continue
            found.append(p)
    except OSError:
        return
    for p in sorted(found, key=lambda q: str(q).lower()):
        yield p


def _post(
    table: dict[str, set[str]],
    sig: str,
    folder_rel: str,
) -> None:
    table.setdefault(sig, set()).add(folder_rel)


def _freeze_inverted(raw: dict[str, set[str]]) -> dict[str, list[str]]:
    return {sig: sorted(folders) for sig, folders in sorted(raw.items())}


def build_archive_index(
    cfg: CurateConfig,
    *,
    max_members_per_archive: int = DEFAULT_MAX_MEMBERS_PER_ARCHIVE,
    folders: Iterable[ModelFolder] | None = None,
    write_artifacts: bool = True,
    run_id: str | None = None,
) -> ArchiveIndexResult:
    """
    Walk model folders, list zip interiors, invert sig→folders.

    Export for SPEC-005: use ``result.inverted_mesh`` / ``folders_for_sig`` /
    ``shared_mesh_sigs``. Does not call ``build_merge_candidates``.
    """
    model_folders = list(folders) if folders is not None else iter_model_folders(cfg)
    # Deterministic walk order
    model_folders.sort(key=lambda f: f.rel_posix.lower())

    result = ArchiveIndexResult(folders_scanned=len(model_folders))
    invert_mesh: dict[str, set[str]] = {}
    invert_all: dict[str, set[str]] = {}

    for folder in model_folders:
        rel = folder.rel_posix
        for zpath in iter_folder_zips(folder.path):
            listing = list_zip_members(
                zpath,
                folder_rel=rel,
                max_members=max_members_per_archive,
            )
            result.listings.append(listing)
            if listing.skip_reason:
                result.zips_skipped += 1
                continue
            result.zips_scanned += 1
            if listing.truncated:
                result.zips_truncated += 1
            for member in listing.members:
                _post(invert_all, member.sig, rel)
                if member.is_mesh:
                    _post(invert_mesh, member.sig, rel)

    result.inverted_mesh = _freeze_inverted(invert_mesh)
    result.inverted_all = _freeze_inverted(invert_all)

    if write_artifacts:
        work = cfg.resolved_work_dir()
        work.mkdir(parents=True, exist_ok=True)
        rid = run_id or time.strftime("%Y%m%d-%H%M%S")
        index_path = work / f"{ARCHIVE_INDEX_PREFIX}-{rid}.jsonl"
        invert_path = work / f"{ARCHIVE_INVERT_PREFIX}-{rid}.jsonl"
        write_archive_index_artifacts(result, index_path=index_path, invert_path=invert_path)
        result.index_jsonl_path = str(index_path)
        result.invert_jsonl_path = str(invert_path)
        log.info(
            "archive_index wrote index=%s invert=%s zips=%s skipped=%s truncated=%s",
            index_path.name,
            invert_path.name,
            result.zips_scanned,
            result.zips_skipped,
            result.zips_truncated,
        )

    return result


def write_archive_index_artifacts(
    result: ArchiveIndexResult,
    *,
    index_path: Path,
    invert_path: Path,
) -> None:
    """Write archive-index + archive-invert JSONL under .spark-curate/."""
    index_path.parent.mkdir(parents=True, exist_ok=True)
    with index_path.open("w", encoding="utf-8") as fh:
        for listing in result.listings:
            fh.write(json.dumps(listing.to_dict(), ensure_ascii=False) + "\n")

    with invert_path.open("w", encoding="utf-8") as fh:
        # Mesh-prefer inverted postings (SPEC-005 consumption surface).
        for sig, folders in result.inverted_mesh.items():
            fh.write(
                json.dumps(
                    {
                        "sig": sig,
                        "folders": folders,
                        "folder_count": len(folders),
                        "mesh": True,
                    },
                    ensure_ascii=False,
                )
                + "\n"
            )


def run_archive_match(
    cfg: CurateConfig,
    *,
    max_members_per_archive: int = DEFAULT_MAX_MEMBERS_PER_ARCHIVE,
    run_id: str | None = None,
) -> ArchiveIndexResult:
    """MODE=match entrypoint: build index artifacts; no merge apply."""
    return build_archive_index(
        cfg,
        max_members_per_archive=max_members_per_archive,
        write_artifacts=True,
        run_id=run_id,
    )


def summary_dict(result: ArchiveIndexResult) -> dict[str, Any]:
    multi = sum(1 for folders in result.inverted_mesh.values() if len(folders) >= 2)
    return {
        "mode": "match",
        "folders_scanned": result.folders_scanned,
        "zips_scanned": result.zips_scanned,
        "zips_skipped": result.zips_skipped,
        "zips_truncated": result.zips_truncated,
        "mesh_sigs": len(result.inverted_mesh),
        "mesh_sigs_multi_folder": multi,
        "index_jsonl_path": result.index_jsonl_path,
        "invert_jsonl_path": result.invert_jsonl_path,
    }


# ---------------------------------------------------------------------------
# INIT-021/SPEC-006 — batch libarchive listing + cross-root recall
# ---------------------------------------------------------------------------


@dataclass(frozen=True)
class BatchPackRef:
    pack_root: Path
    rel_posix: str
    archive_paths: tuple[str, ...]
    incomplete_multipart: bool = False


@dataclass
class BatchArchiveListing:
    pack: BatchPackRef
    listing_path: str
    members: list[MemberSig] = field(default_factory=list)
    mesh_count: int = 0
    skip_reason: str | None = None
    skip_detail: str | None = None
    truncated: bool = False
    cache_hit: bool = False
    format_name: str | None = None

    def to_dict(self) -> dict[str, Any]:
        return {
            "pack_rel": self.pack.rel_posix,
            "archive_paths": list(self.pack.archive_paths),
            "incomplete_multipart": self.pack.incomplete_multipart,
            "listing_path": self.listing_path,
            "member_count": len(self.members),
            "mesh_count": self.mesh_count,
            "skip_reason": self.skip_reason,
            "skip_detail": self.skip_detail,
            "truncated": self.truncated,
            "cache_hit": self.cache_hit,
            "format_name": self.format_name,
            "members": [
                {
                    "basename": m.basename,
                    "uncompressed_size": m.uncompressed_size,
                    "crc32": m.crc32,
                    "is_mesh": m.is_mesh,
                    "member_path": m.member_path,
                    "sig": m.sig,
                    "sig_nocrc": member_signature_nocrc(m.basename, m.uncompressed_size),
                }
                for m in self.members
            ],
        }


@dataclass
class CrossRootRecallResult:
    batch_listings: list[BatchArchiveListing] = field(default_factory=list)
    candidates: list[Any] = field(default_factory=list)
    library_coverage: dict[str, Any] = field(default_factory=dict)
    batch_index_path: str | None = None
    candidates_path: str | None = None
    summary_path: str | None = None
    archives_listed: int = 0
    archives_skipped: int = 0
    skip_counts: dict[str, int] = field(default_factory=dict)
    cache_hits: int = 0
    mesh_sigs_batch: int = 0
    candidates_cross_root: int = 0
    candidates_within_batch: int = 0


def _cache_key(path: Path) -> str | None:
    try:
        st = path.stat()
        return f"{st.st_size}:{getattr(st, 'st_mtime_ns', int(st.st_mtime * 1_000_000_000))}"
    except OSError:
        return None


def _cache_path(work_dir: Path, path: Path, key: str) -> Path:
    digest = hashlib.sha256(f"{path}|{key}".encode()).hexdigest()[:24]
    return work_dir / "archive-list-cache" / f"{digest}.json"


def _load_cached_listing(cache_file: Path) -> dict[str, Any] | None:
    if not cache_file.is_file():
        return None
    try:
        return json.loads(cache_file.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return None


def _save_cached_listing(cache_file: Path, payload: dict[str, Any]) -> None:
    cache_file.parent.mkdir(parents=True, exist_ok=True)
    cache_file.write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")


def _zip_crc_map(zip_path: Path) -> dict[str, tuple[int, int]]:
    """Central-directory CRC lookup for zip — infolist only, no read."""
    out: dict[str, tuple[int, int]] = {}
    try:
        with zipfile.ZipFile(zip_path, "r") as zf:
            for info in zf.infolist():
                if info.is_dir():
                    continue
                norm = info.filename.replace("\\", "/")
                out[norm] = (int(info.file_size), int(info.CRC) & 0xFFFFFFFF)
                base = Path(norm).name
                if base:
                    out.setdefault(base, (int(info.file_size), int(info.CRC) & 0xFFFFFFFF))
    except (zipfile.BadZipFile, OSError):
        pass
    return out


def list_batch_archive(
    archive_path: Path,
    *,
    pack: BatchPackRef,
    max_members: int = DEFAULT_MAX_MEMBERS_PER_ARCHIVE,
    cache_dir: Path | None = None,
    cache_stats: dict[str, int] | None = None,
) -> BatchArchiveListing:
    """List one batch archive via libarchive; zip CRC merged from infolist when available."""
    from .libarchive_list import ArchiveSkipReason, list_archive_members

    listing = BatchArchiveListing(
        pack=pack,
        listing_path=str(archive_path),
    )
    cache_file: Path | None = None
    if cache_dir is not None:
        key = _cache_key(archive_path)
        if key:
            cache_file = _cache_path(cache_dir, archive_path, key)
            cached = _load_cached_listing(cache_file)
            if cached is not None:
                listing.cache_hit = True
                if cache_stats is not None:
                    cache_stats["hits"] = cache_stats.get("hits", 0) + 1
                listing.skip_reason = cached.get("skip_reason")
                listing.skip_detail = cached.get("skip_detail")
                listing.truncated = bool(cached.get("truncated"))
                listing.format_name = cached.get("format_name")
                for row in cached.get("members") or []:
                    if not isinstance(row, dict):
                        continue
                    mesh = bool(row.get("is_mesh"))
                    crc = row.get("crc32")
                    member = MemberSig(
                        basename=str(row.get("basename") or ""),
                        uncompressed_size=int(row.get("uncompressed_size") or 0),
                        crc32=int(crc) if crc is not None else 0,
                        is_mesh=mesh,
                        member_path=str(row.get("member_path") or ""),
                    )
                    listing.members.append(member)
                    if mesh:
                        listing.mesh_count += 1
                return listing

    la = list_archive_members(
        archive_path,
        max_members=max_members,
        part_paths=pack.archive_paths,
    )
    listing.skip_reason = la.skip_reason
    listing.skip_detail = la.skip_detail
    listing.truncated = la.truncated
    listing.format_name = la.format_name

    crc_map: dict[str, tuple[int, int]] = {}
    if archive_path.suffix.lower() == ".zip":
        crc_map = _zip_crc_map(archive_path)

    for lm in la.members:
        if not is_admission_relevant_member(
            lm.basename, is_mesh=lm.is_mesh, is_image=lm.is_image
        ):
            continue
        crc = lm.crc32 or 0
        if lm.member_path in crc_map:
            size, crc_val = crc_map[lm.member_path]
            crc = crc_val
            size = size
        elif lm.basename in crc_map:
            size, crc_val = crc_map[lm.basename]
            crc = crc_val
        else:
            size = lm.size
        member = MemberSig(
            basename=lm.basename,
            uncompressed_size=size,
            crc32=crc,
            is_mesh=lm.is_mesh,
            member_path=lm.member_path,
        )
        listing.members.append(member)
        if lm.is_mesh:
            listing.mesh_count += 1

    if cache_file is not None and not listing.cache_hit:
        payload = {
            "skip_reason": listing.skip_reason,
            "skip_detail": listing.skip_detail,
            "truncated": listing.truncated,
            "format_name": listing.format_name,
            "members": [
                {
                    "basename": m.basename,
                    "uncompressed_size": m.uncompressed_size,
                    "crc32": m.crc32,
                    "is_mesh": m.is_mesh,
                    "member_path": m.member_path,
                }
                for m in listing.members
            ],
        }
        _save_cached_listing(cache_file, payload)
    return listing


def iter_batch_archives(
    batch_root: Path,
    *,
    slice_top: str | None = None,
) -> Iterator[tuple[BatchPackRef, Path]]:
    """
    Discover archive-bearing pack folders under a batch intake root.

    Yields (pack_ref, primary_archive_path) — one yield per listable unit
    (multipart sets grouped; listed from first volume).
    """
    root = batch_root.resolve()
    scan_root = root / slice_top if slice_top else root
    if not scan_root.is_dir():
        return

    archives_by_parent: dict[Path, list[Path]] = {}
    for path in sorted(scan_root.rglob("*")):
        if not path.is_file():
            continue
        if any(part.startswith(".") for part in path.relative_to(scan_root).parts[:-1]):
            continue
        if not is_archive_path(path):
            continue
        pack_root = _infer_pack_root(path, batch_root=root)
        archives_by_parent.setdefault(pack_root, []).append(path)

    for pack_root in sorted(archives_by_parent.keys(), key=lambda p: str(p).lower()):
        files = sorted(archives_by_parent[pack_root], key=lambda p: str(p).lower())
        rel = pack_root.relative_to(root).as_posix()
        mp_sets, standalone = group_multipart_volumes(files)
        for mps in mp_sets:
            missing = mps.missing_middle_volume()
            pack = BatchPackRef(
                pack_root=pack_root,
                rel_posix=rel,
                archive_paths=mps.all_part_paths,
                incomplete_multipart=missing is not None,
            )
            yield pack, mps.first_volume_path
        for arch in standalone:
            pack = BatchPackRef(
                pack_root=pack_root,
                rel_posix=rel,
                archive_paths=(str(arch),),
                incomplete_multipart=False,
            )
            yield pack, arch


def _infer_pack_root(archive_path: Path, *, batch_root: Path) -> Path:
    """Pack root = parent folder of the outer archive (batch lane convention)."""
    parent = archive_path.parent
    try:
        parent.relative_to(batch_root)
    except ValueError:
        return archive_path.parent
    return parent


def batch_mesh_sigs(listing: BatchArchiveListing) -> list[str]:
    out: list[str] = []
    for m in listing.members:
        if m.is_mesh:
            out.append(member_signature_nocrc(m.basename, m.uncompressed_size))
    return out


def run_cross_root_archive_recall(
    *,
    batch_root: str | Path,
    work_dir: str | Path,
    library_index: Any,
    max_members_per_archive: int = DEFAULT_MAX_MEMBERS_PER_ARCHIVE,
    slice_top: str | None = None,
    run_id: str | None = None,
    build_candidates_fn: Callable[..., list[Any]] | None = None,
) -> CrossRootRecallResult:
    """
    List batch archives (libarchive), match against library mesh index, emit candidates.

    Does not extract members, enqueue scans, or construct image-embed clients.
    """
    from .candidates import build_cross_root_candidates

    batch_path = Path(batch_root)
    work = Path(work_dir)
    work.mkdir(parents=True, exist_ok=True)
    rid = run_id or time.strftime("%Y%m%d-%H%M%S")
    cache_dir = work / "archive-list-cache"

    result = CrossRootRecallResult(
        library_coverage=dict(getattr(library_index, "coverage", {}) or {}),
    )
    batch_listings: list[BatchArchiveListing] = []
    cache_stats: dict[str, int] = {"hits": 0}

    for pack, arch_path in iter_batch_archives(batch_path, slice_top=slice_top):
        if pack.incomplete_multipart:
            bl = BatchArchiveListing(
                pack=pack,
                listing_path=str(arch_path),
                skip_reason="incomplete_multipart",
                skip_detail="missing_middle_volume",
            )
            batch_listings.append(bl)
            result.archives_skipped += 1
            result.skip_counts["incomplete_multipart"] = (
                result.skip_counts.get("incomplete_multipart", 0) + 1
            )
            continue
        bl = list_batch_archive(
            arch_path,
            pack=pack,
            max_members=max_members_per_archive,
            cache_dir=cache_dir,
            cache_stats=cache_stats,
        )
        batch_listings.append(bl)
        if bl.cache_hit:
            result.cache_hits += 1
        if bl.skip_reason:
            result.archives_skipped += 1
            result.skip_counts[bl.skip_reason] = result.skip_counts.get(bl.skip_reason, 0) + 1
        else:
            result.archives_listed += 1
            result.mesh_sigs_batch += bl.mesh_count

    result.batch_listings = batch_listings
    build_fn = build_candidates_fn or build_cross_root_candidates
    candidates = build_fn(
        batch_listings=batch_listings,
        library_index=library_index,
        batch_root=batch_path,
    )
    result.candidates = candidates
    for c in candidates:
        origin = next(
            (s for s in c.signals if s.startswith("origin_pair:")),
            "",
        )
        if "intake_library" in origin:
            result.candidates_cross_root += 1
        elif "intake_intake" in origin:
            result.candidates_within_batch += 1

    index_path = work / f"{CROSS_ROOT_INDEX_PREFIX}-{rid}.jsonl"
    cand_path = work / f"{CROSS_ROOT_CANDIDATES_PREFIX}-{rid}.jsonl"
    summary_path = work / f"{CROSS_ROOT_SUMMARY_PREFIX}-{rid}.json"

    with index_path.open("w", encoding="utf-8") as fh:
        for bl in batch_listings:
            fh.write(json.dumps(bl.to_dict(), ensure_ascii=False) + "\n")

    with cand_path.open("w", encoding="utf-8") as fh:
        for c in candidates:
            fh.write(
                json.dumps(
                    {
                        "a": c.a.rel_posix,
                        "b": c.b.rel_posix,
                        "signals": c.signals,
                        "pair_key": list(c.pair_key),
                    },
                    ensure_ascii=False,
                )
                + "\n"
            )

    summary = {
        "provenance": "INIT-021/SPEC-006",
        "run_id": rid,
        "batch_root": str(batch_path),
        "slice_top": slice_top,
        "archives_listed": result.archives_listed,
        "archives_skipped": result.archives_skipped,
        "skip_counts": result.skip_counts,
        "cache_hits": result.cache_hits,
        "mesh_member_sigs_batch": result.mesh_sigs_batch,
        "candidates_total": len(candidates),
        "candidates_cross_root": result.candidates_cross_root,
        "candidates_within_batch": result.candidates_within_batch,
        "library_coverage": result.library_coverage,
        "library_coverage_caveat": _coverage_caveat(result.library_coverage),
        "batch_index_path": str(index_path),
        "candidates_path": str(cand_path),
    }
    summary_path.write_text(json.dumps(summary, indent=2), encoding="utf-8")

    result.batch_index_path = str(index_path)
    result.candidates_path = str(cand_path)
    result.summary_path = str(summary_path)
    log.info(
        "cross_root_recall listed=%s skipped=%s candidates=%s cache_hits=%s",
        result.archives_listed,
        result.archives_skipped,
        len(candidates),
        result.cache_hits,
    )
    return result


def _coverage_caveat(coverage: dict[str, Any]) -> str | None:
    unindexed = coverage.get("library_archives_unindexed")
    total = coverage.get("library_archives_total")
    if isinstance(unindexed, int) and isinstance(total, int) and unindexed > 0:
        return (
            f"{unindexed} of {total} library archive files lack archive_entries — "
            "a new verdict against a partly-indexed library is weaker than a clean miss"
        )
    return None

