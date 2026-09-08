# candidates.py — build merge candidate pairs from filesystem heuristics
# Provenance: INIT-018/SPEC-005 — archive-member signals via inverted postings (ADR D-1, D-4).
# Cross-root extension: INIT-021/SPEC-006
from __future__ import annotations

import hashlib
import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import TYPE_CHECKING, Any

from .config import CurateConfig
from .preview import ARCHIVE_EXT, IMAGE_EXT
from .walk import MODEL_EXT, ModelFolder, iter_model_folders

if TYPE_CHECKING:
    from .archive_index import ArchiveIndexResult, BatchArchiveListing, BatchPackRef
    from .library_members import LibraryMembersIndex

# Default T for archive mesh overlap — keep aligned with decide_merge.DEFAULT_MESH_OVERLAP_T (ADR D-4).
DEFAULT_MESH_OVERLAP_T = 3

# Foo (2), Foo (3), Foo_copy, Foo - Copy
_NEAR_DUPE_SUFFIX = re.compile(
    r"[\s_\-]*(?:\(\d+\)|copy(?:\s*\d+)?|copy of)\s*$",
    re.IGNORECASE,
)


@dataclass
class FolderFingerprint:
    folder: ModelFolder
    # basename.lower() -> set of sizes (bytes)
    files: dict[str, set[int]] = field(default_factory=dict)
    # quick content signatures for small non-archive files: (name, size, sha256_16)
    digests: set[str] = field(default_factory=set)


@dataclass
class MergeCandidate:
    a: ModelFolder
    b: ModelFolder
    signals: list[str]

    @property
    def pair_key(self) -> tuple[str, str]:
        paths = sorted([self.a.rel_posix.lower(), self.b.rel_posix.lower()])
        return (paths[0], paths[1])


def normalize_model_slug(name: str) -> str:
    n = name.strip().lower()
    n = _NEAR_DUPE_SUFFIX.sub("", n)
    n = re.sub(r"[^a-z0-9]+", "", n)
    return n


def _sample_file_meta(folder: Path, limit: int = 80) -> tuple[dict[str, set[int]], set[str]]:
    files: dict[str, set[int]] = {}
    digests: set[str] = set()
    count = 0
    try:
        for p in sorted(folder.rglob("*")):
            if not p.is_file():
                continue
            if any(part.startswith(".") for part in p.relative_to(folder).parts):
                continue
            ext = p.suffix.lower()
            if ext not in MODEL_EXT and ext not in IMAGE_EXT and ext not in ARCHIVE_EXT:
                continue
            try:
                size = p.stat().st_size
            except OSError:
                continue
            key = p.name.lower()
            files.setdefault(key, set()).add(size)
            # Cheap digest for small non-archives (helps true duplicates)
            if ext not in ARCHIVE_EXT and 0 < size <= 2_000_000:
                try:
                    h = hashlib.sha256(p.read_bytes()).hexdigest()[:16]
                    digests.add(f"{key}:{size}:{h}")
                except OSError:
                    pass
            count += 1
            if count >= limit:
                break
    except OSError:
        pass
    return files, digests


def fingerprint(folder: ModelFolder) -> FolderFingerprint:
    files, digests = _sample_file_meta(folder.path)
    return FolderFingerprint(folder=folder, files=files, digests=digests)


def _name_near_dupe(a: ModelFolder, b: ModelFolder) -> bool:
    if a.category.lower() != b.category.lower():
        return False
    sa, sb = normalize_model_slug(a.name), normalize_model_slug(b.name)
    if not sa or not sb:
        return False
    if sa == sb and a.name.lower() != b.name.lower():
        return True
    # One name is the other plus a near-dupe suffix already stripped → equal slug
    return sa == sb


def _shared_digests(fa: FolderFingerprint, fb: FolderFingerprint) -> set[str]:
    return fa.digests & fb.digests


def _append_shared_digest_signal(signals: list[str], shared: set[str]) -> None:
    """
    Emit counted shared_digest:N (distinct digests).

    N=1 is recall / UNCERTAIN; N≥2 is multi-file STRONG (ADR D-4 / SEC-018-02).
    """
    n = len(shared)
    if n < 1:
        return
    signals.append(f"shared_digest:{n}")


def _basename_size_overlap(fa: FolderFingerprint, fb: FolderFingerprint) -> int:
    """Count filenames that share at least one identical size in both folders."""
    n = 0
    for name, sizes_a in fa.files.items():
        sizes_b = fb.files.get(name)
        if sizes_b and (sizes_a & sizes_b):
            n += 1
    return n


def pair_mesh_overlap_counts(
    inverted_mesh: dict[str, list[str]],
) -> dict[tuple[str, str], int]:
    """
    Count distinct mesh signatures shared by each folder pair via inverted postings.

    Complexity is O(Σ C(k_s, 2)) over sigs with k_s folder postings — not nested
    loops over all folders × all members (ADR D-1 / INIT-018/SPEC-005).
    """
    counts: dict[tuple[str, str], int] = {}
    for folders in inverted_mesh.values():
        if len(folders) < 2:
            continue
        # Deterministic pair enumeration within this posting list
        for i in range(len(folders)):
            for j in range(i + 1, len(folders)):
                a, b = folders[i], folders[j]
                key = tuple(sorted((a.lower(), b.lower())))
                counts[key] = counts.get(key, 0) + 1
    return counts


def _with_archive_signals(signals: list[str], overlap: int) -> list[str]:
    """Attach shared_archive_member + archive_member_overlap:N (within-library CRC path)."""
    if overlap < 1:
        return list(signals)
    out = [s for s in signals if not s.startswith("archive_member_overlap:")]
    if "shared_archive_member" not in out:
        out.append("shared_archive_member")
    out.append(f"archive_member_overlap:{overlap}")
    return out


def _with_nocrc_overlap(signals: list[str], overlap: int) -> list[str]:
    """Cross-root mesh overlap — basename|size only (INIT-021/SPEC-006 ac-4)."""
    if overlap < 1:
        return list(signals)
    out = [
        s
        for s in signals
        if not s.startswith("archive_member_overlap_nocrc:")
        and not s.startswith("archive_member_overlap:")
    ]
    if "shared_archive_member" not in out:
        out.append("shared_archive_member")
    out.append(f"archive_member_overlap_nocrc:{overlap}")
    return out


def _origin_tag(origin: str) -> str:
    return f"origin_pair:{origin}"


def _pack_to_folder(pack: "BatchPackRef", batch_root: Path) -> ModelFolder:
    rel = pack.rel_posix.replace("\\", "/")
    parts = rel.split("/")
    if len(parts) >= 2:
        category, name = parts[0], parts[-1]
    elif parts:
        category, name = "intake", parts[0]
    else:
        category, name = "intake", pack.pack_root.name
    return ModelFolder(path=pack.pack_root, category=category, name=name)


def _library_path_to_folder(model_path: str, library_root: Path | None = None) -> ModelFolder:
    norm = model_path.replace("\\", "/")
    parts = norm.split("/")
    if len(parts) >= 2:
        category, name = parts[0], parts[-1]
    else:
        category, name = "library", parts[0] if parts else "unknown"
    path = (library_root / norm) if library_root else Path(norm)
    return ModelFolder(path=path, category=category, name=name)


def _sha512_file(path: Path, max_bytes: int = 512 * 1024 * 1024) -> str | None:
    try:
        size = path.stat().st_size
        if size <= 0 or size > max_bytes:
            return None
        h = hashlib.sha512()
        with path.open("rb") as fh:
            while True:
                chunk = fh.read(1024 * 1024)
                if not chunk:
                    break
                h.update(chunk)
        return h.hexdigest()
    except OSError:
        return None


def _append_digest_signals(
    signals: list[str],
    *,
    batch_archive: Path | None,
    library_digest: str | None,
) -> None:
    """
    ac-11: exact_file_digest when library digest exists and matches;
    digest_unavailable when absent — never treat absence as a miss.
    """
    if library_digest:
        if batch_archive is not None:
            batch_digest = _sha512_file(batch_archive)
            if batch_digest and batch_digest == library_digest:
                signals.append("exact_file_digest")
            elif batch_digest:
                signals.append("digest_mismatch")
        else:
            signals.append("digest_unavailable")
    else:
        signals.append("digest_unavailable")


def build_cross_root_candidates(
    *,
    batch_listings: list[BatchArchiveListing],
    library_index: LibraryMembersIndex,
    batch_root: Path,
    min_mesh_overlap: int = 1,
    library_root: Path | None = None,
) -> list[MergeCandidate]:
    """
    Emit recall candidates: within-batch (intake_intake) and cross-root (intake_library).

    Uses mesh basename|size signatures; cross-root signal is archive_member_overlap_nocrc:N.
    """
    from .archive_index import (
        BatchArchiveListing,
        batch_mesh_sigs,
        member_signature_nocrc,
    )

    # pack rel -> mesh sigs (nocrc)
    pack_sigs: dict[str, set[str]] = {}
    pack_by_rel: dict[str, BatchPackRef] = {}
    pack_archive: dict[str, Path] = {}
    for bl in batch_listings:
        if bl.skip_reason or bl.pack.incomplete_multipart:
            continue
        rel = bl.pack.rel_posix
        pack_by_rel[rel] = bl.pack
        if bl.pack.archive_paths:
            pack_archive[rel] = Path(bl.pack.archive_paths[0])
        sigs = set(batch_mesh_sigs(bl))
        if sigs:
            pack_sigs[rel] = sigs

    # Within-batch inverted index (CRC-capable path uses full sig from members for intake_intake)
    batch_inverted: dict[str, list[str]] = {}
    for bl in batch_listings:
        if bl.skip_reason or bl.pack.incomplete_multipart:
            continue
        rel = bl.pack.rel_posix
        for m in bl.members:
            if not m.is_mesh:
                continue
            nocrc = member_signature_nocrc(m.basename, m.uncompressed_size)
            batch_inverted.setdefault(nocrc, []).append(rel)

    seen: set[tuple[str, str]] = set()
    out: list[MergeCandidate] = []

    pack_crc_sigs: dict[str, set[str]] = {}
    for bl in batch_listings:
        if bl.skip_reason or bl.pack.incomplete_multipart:
            continue
        rel = bl.pack.rel_posix
        pack_crc_sigs[rel] = {m.sig for m in bl.members if m.is_mesh}

    # Within-batch pairs — CRC sigs when both sides are batch (ac-12)
    batch_rels = sorted(pack_sigs.keys())
    for i in range(len(batch_rels)):
        for j in range(i + 1, len(batch_rels)):
            ra, rb = batch_rels[i], batch_rels[j]
            pa = pack_by_rel[ra]
            pb = pack_by_rel[rb]
            fa = _pack_to_folder(pa, batch_root)
            fb = _pack_to_folder(pb, batch_root)
            key = tuple(sorted((fa.rel_posix.lower(), fb.rel_posix.lower())))
            if key in seen:
                continue
            crc_overlap = len(pack_crc_sigs.get(ra, set()) & pack_crc_sigs.get(rb, set()))
            nocrc_overlap = len(pack_sigs.get(ra, set()) & pack_sigs.get(rb, set()))
            overlap = crc_overlap if crc_overlap else nocrc_overlap
            if overlap < min_mesh_overlap:
                continue
            signals = [_origin_tag("intake_intake")]
            if crc_overlap:
                signals = _with_archive_signals(signals, crc_overlap)
            else:
                signals = _with_nocrc_overlap(signals, nocrc_overlap)
            cand = MergeCandidate(a=fa, b=fb, signals=signals)
            seen.add(cand.pair_key)
            out.append(cand)

    # Cross-root: batch pack vs library model
    for pack_rel, sigs in sorted(pack_sigs.items()):
        pack = pack_by_rel[pack_rel]
        lib_hits: dict[str, int] = {}
        lib_digest: dict[str, str | None] = {}
        for sig in sigs:
            for post in library_index.models_for_sig(sig):
                lib_hits[post.model_path] = lib_hits.get(post.model_path, 0) + 1
                lib_digest.setdefault(post.model_path, post.digest)
        for model_path, overlap in sorted(lib_hits.items(), key=lambda kv: (-kv[1], kv[0].lower())):
            if overlap < min_mesh_overlap:
                continue
            fb = _library_path_to_folder(model_path, library_root)
            fa = _pack_to_folder(pack, batch_root)
            key = tuple(sorted((fa.rel_posix.lower(), fb.rel_posix.lower())))
            if key in seen:
                continue
            signals = [_origin_tag("intake_library")]
            signals = _with_nocrc_overlap(signals, overlap)
            _append_digest_signals(
                signals,
                batch_archive=pack_archive.get(pack_rel),
                library_digest=lib_digest.get(model_path),
            )
            cand = MergeCandidate(a=fa, b=fb, signals=signals)
            seen.add(cand.pair_key)
            out.append(cand)

    out.sort(key=lambda c: (c.a.rel_posix.lower(), c.b.rel_posix.lower()))
    return out


def _apply_archive_postings(
    out: list[MergeCandidate],
    seen: set[tuple[str, str]],
    fps: list[FolderFingerprint],
    inverted_mesh: dict[str, list[str]],
    *,
    mesh_overlap_t: int,
    cap: int,
) -> list[MergeCandidate]:
    """
    Enrich existing pairs with archive signals; emit new pairs only when overlap ≥ T.

    Single shared mesh CRC alone never creates a candidate (ADR D-3 / ac-2).
    ≥1 mesh + name_near_dupe stays UNCERTAIN at decide time — not a new STRONG admission.
    """
    overlaps = pair_mesh_overlap_counts(inverted_mesh)
    if not overlaps:
        return out

    by_rel_lower: dict[str, FolderFingerprint] = {
        fp.folder.rel_posix.lower(): fp for fp in fps
    }

    # Enrich candidates already admitted by name/digest passes
    for cand in out:
        n = overlaps.get(cand.pair_key, 0)
        if n >= 1:
            cand.signals = _with_archive_signals(cand.signals, n)

    # New candidates only for STRONG-threshold mesh overlap (≥ T)
    t = max(1, int(mesh_overlap_t))
    for key, n in sorted(overlaps.items()):
        if n < t:
            continue
        if key in seen:
            continue
        fa = by_rel_lower.get(key[0])
        fb = by_rel_lower.get(key[1])
        if fa is None or fb is None:
            continue
        signals = _with_archive_signals([], n)
        cand = MergeCandidate(a=fa.folder, b=fb.folder, signals=signals)
        seen.add(cand.pair_key)
        out.append(cand)
        if len(out) >= cap:
            break
    return out


def build_merge_candidates(
    cfg: CurateConfig,
    *,
    max_pairs: int | None = None,
    archive_index: ArchiveIndexResult | None = None,
    scan_archives: bool = True,
    mesh_overlap_t: int = DEFAULT_MESH_OVERLAP_T,
) -> list[MergeCandidate]:
    """
    Build candidate pairs. Same franchise/name alone is NOT enough —
    we require name_near_dupe and/or file overlap signals and/or ≥T mesh
    archive overlaps (INIT-018/SPEC-005).
    """
    folders = iter_model_folders(cfg)
    fps = [fingerprint(f) for f in folders]
    by_slug: dict[tuple[str, str], list[FolderFingerprint]] = {}
    for fp in fps:
        slug = normalize_model_slug(fp.folder.name)
        key = (fp.folder.category.lower(), slug)
        by_slug.setdefault(key, []).append(fp)

    seen: set[tuple[str, str]] = set()
    out: list[MergeCandidate] = []
    cap = max_pairs if max_pairs is not None else (cfg.max_merge_pairs or 200)

    # Pass 1: name near-dupes in same category
    for group in by_slug.values():
        if len(group) < 2:
            continue
        for i in range(len(group)):
            for j in range(i + 1, len(group)):
                fa, fb = group[i], group[j]
                if not _name_near_dupe(fa.folder, fb.folder):
                    # same slug after normalize always near-dupe if names differ
                    if normalize_model_slug(fa.folder.name) != normalize_model_slug(fb.folder.name):
                        continue
                    if fa.folder.name.lower() == fb.folder.name.lower():
                        continue
                signals = ["name_near_dupe"]
                _append_shared_digest_signal(signals, _shared_digests(fa, fb))
                overlap = _basename_size_overlap(fa, fb)
                if overlap >= 1:
                    signals.append(f"basename_size_overlap:{overlap}")
                cand = MergeCandidate(a=fa.folder, b=fb.folder, signals=signals)
                if cand.pair_key in seen:
                    continue
                seen.add(cand.pair_key)
                out.append(cand)
                if len(out) >= cap:
                    return out

    # Pass 2: strong file overlap without name match (true re-downloads with different folder names)
    # Note: still O(folders²) on *folder* fingerprints — must not nest raw zip members here.
    for i in range(len(fps)):
        for j in range(i + 1, len(fps)):
            fa, fb = fps[i], fps[j]
            cand = MergeCandidate(a=fa.folder, b=fb.folder, signals=[])
            if cand.pair_key in seen:
                continue
            shared = _shared_digests(fa, fb)
            overlap = _basename_size_overlap(fa, fb)
            signals: list[str] = []
            _append_shared_digest_signal(signals, shared)
            if overlap >= 3:
                signals.append(f"basename_size_overlap:{overlap}")
            # Require strong overlap — never pair solely on category/franchise
            if not signals:
                continue
            if not any(s.startswith("shared_digest:") for s in signals) and overlap < 3:
                continue
            cand.signals = signals
            seen.add(cand.pair_key)
            out.append(cand)
            if len(out) >= cap:
                return out

    # Pass 3: archive-member recall from inverted mesh postings (not member×folder nested loops)
    index = archive_index
    if index is None and scan_archives:
        from .archive_index import build_archive_index

        index = build_archive_index(
            cfg,
            folders=folders,
            write_artifacts=False,
        )
    if index is not None and len(out) < cap:
        out = _apply_archive_postings(
            out,
            seen,
            fps,
            index.inverted_mesh,
            mesh_overlap_t=mesh_overlap_t,
            cap=cap,
        )

    return out
