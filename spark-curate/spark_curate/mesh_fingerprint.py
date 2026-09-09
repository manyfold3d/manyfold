"""Gated residual mesh fingerprint stream (byte SHA-256 + trimesh identifier).

Provenance: INIT-022/SPEC-003
Honors INIT-022 ADR D-1 (identity is recall only) and D-7 (gated stream +
zip-bomb caps). Never extracts onto /models, the library PVC, or NFS.
Never admits merge — that is SPEC-004 / SPEC-005.
"""
from __future__ import annotations

import argparse
import ctypes
import hashlib
import io
import json
import logging
import os
import tempfile
import time
import zipfile
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Any, Iterator

from .config import CurateConfig
from .indexable import ARCHIVE_EXTENSIONS, is_archive_path
from .libarchive_list import (
    AE_IFDIR,
    AE_IFREG,
    ARCHIVE_EOF,
    ARCHIVE_FATAL,
    ARCHIVE_OK,
    ARCHIVE_WARN,
    LibarchiveError,
    _archive_error,
    _classify_open_error,
    _load_libarchive,
    list_archive_members,
)
from .unorganize import FROZEN_INTAKE_ROOTS, FrozenRootWriteRefused, assert_writable_work_dir

log = logging.getLogger(__name__)

PROVENANCE = "INIT-022/SPEC-003"

MAX_MEMBER_BYTES = 256 * 1024 * 1024  # 256 MiB
MAX_ARCHIVE_STREAM_BYTES = 2 * 1024 * 1024 * 1024  # 2 GiB
MAX_RATIO = 200
DEFAULT_MAX_MEMBERS = 5_000
_STREAM_CHUNK = 65_536

# Mesh parse v1 (ADR D-7). Broader MESH_EXTENSIONS stay listing-only.
PARSE_EXTENSIONS: frozenset[str] = frozenset({".stl", ".obj", ".3mf", ".ply"})
SKIP_EXTENSIONS: frozenset[str] = frozenset(
    {".gcode", ".ctb", ".lys", ".chitubox", ".step", ".stp"}
)

CACHE_FILENAME = "mesh-fingerprint-cache.jsonl"
RUN_PREFIX = "mesh-fingerprints"


class SkipReason:
    CAP_MEMBER_BYTES = "cap_member_bytes"
    CAP_ARCHIVE_STREAM_BYTES = "cap_archive_stream_bytes"
    CAP_RATIO = "cap_ratio"
    CAP_MEMBER_COUNT = "cap_member_count"
    PATH_TRAVERSAL = "path_traversal"
    SKIP_EXTENSION = "skip_extension"
    FINGERPRINT_ERROR = "fingerprint_error"
    MEGA_FENCE = "mega_fence"
    NOT_PARSE_V1 = "not_parse_v1"
    MISSING_RESIDUAL_LIST = "missing_residual_list"
    TRUNCATED_STREAM = "truncated_stream"
    IO_ERROR = "io_error"


class MeshFingerprintError(RuntimeError):
    """Typed failure for MODE=mesh-fingerprint."""


class MegaFenceRefused(MeshFingerprintError):
    """Mega / frozen intake root is refused unless the existing fence allows."""


class ResidualListRequired(MeshFingerprintError):
    """Refuse a full-library scan — residual list is required (ADR D-7)."""


@dataclass
class StreamBudget:
    """Cumulative streamed-member budget for one run (ADR D-7)."""

    max_stream_bytes: int = MAX_ARCHIVE_STREAM_BYTES
    used_bytes: int = 0

    @property
    def remaining(self) -> int:
        return max(0, self.max_stream_bytes - self.used_bytes)

    def would_exceed(self, n: int) -> bool:
        return n > self.remaining

    def consume(self, n: int) -> None:
        self.used_bytes += max(0, n)


@dataclass
class FingerprintRow:
    source_path: str
    member_path: str
    size: int
    mtime_ns: int
    byte_sha256: str | None = None
    geometry_identifier: str | None = None
    skip_reason: str | None = None
    skip_detail: str | None = None
    reused: bool = False
    provenance: str = PROVENANCE

    def cache_key(self) -> tuple[str, str, int, int]:
        return (self.source_path, self.member_path, self.size, self.mtime_ns)

    def is_identifier_row(self) -> bool:
        return (
            self.skip_reason is None
            and bool(self.byte_sha256)
            and bool(self.geometry_identifier)
        )

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)

    @classmethod
    def from_dict(cls, raw: dict[str, Any]) -> FingerprintRow:
        return cls(
            source_path=str(raw.get("source_path") or ""),
            member_path=str(raw.get("member_path") or ""),
            size=int(raw.get("size") or 0),
            mtime_ns=int(raw.get("mtime_ns") or 0),
            byte_sha256=raw.get("byte_sha256"),
            geometry_identifier=raw.get("geometry_identifier"),
            skip_reason=raw.get("skip_reason"),
            skip_detail=raw.get("skip_detail"),
            reused=bool(raw.get("reused")),
            provenance=str(raw.get("provenance") or PROVENANCE),
        )


@dataclass
class FingerprintRun:
    rows: list[FingerprintRow] = field(default_factory=list)
    cache_path: str = ""
    run_path: str = ""
    streamed_bytes: int = 0
    reused: int = 0
    skipped: int = 0
    identified: int = 0

    def to_dict(self) -> dict[str, Any]:
        return {
            "cache_path": self.cache_path,
            "run_path": self.run_path,
            "streamed_bytes": self.streamed_bytes,
            "reused": self.reused,
            "skipped": self.skipped,
            "identified": self.identified,
            "rows": len(self.rows),
            "provenance": PROVENANCE,
        }


def extension_of(name: str) -> str:
    return Path(name).suffix.lower()


def is_parse_v1(name: str) -> bool:
    return extension_of(name) in PARSE_EXTENSIONS


def is_skip_extension(name: str) -> bool:
    return extension_of(name) in SKIP_EXTENSIONS


def member_has_traversal(member_path: str) -> bool:
    """Refuse absolute members and ``..`` segments (zip-slip)."""
    if not member_path:
        return False
    norm = member_path.replace("\\", "/")
    if norm.startswith("/") or norm.startswith("~"):
        return True
    if ":" in norm.split("/", 1)[0] and len(norm) >= 2 and norm[1] == ":":
        return True
    return any(part == ".." for part in norm.split("/"))


def is_mega_path(path: Path | str) -> bool:
    """True when *path* is the frozen Mega tree (INIT-018 / INIT-022 D-8)."""
    resolved = str(path).replace("\\", "/")
    if "/intake/Mega" in resolved or resolved.rstrip("/").endswith("/intake/Mega"):
        return True
    for frozen in FROZEN_INTAKE_ROOTS:
        frozen_n = frozen.rstrip("/")
        if resolved == frozen_n or resolved.startswith(frozen_n + "/"):
            return True
    return False


def assert_mega_fence_allows(*paths: Path | str, allow_live: bool = False) -> None:
    """Refuse Mega by default. ``--allow-live`` is the existing SPEC-010 lift."""
    if allow_live:
        return
    for raw in paths:
        if raw is None:
            continue
        if is_mega_path(raw):
            raise MegaFenceRefused(
                f"refusing Mega / frozen intake root {raw} "
                "(INIT-022 D-8; existing fence stays refused by default)"
            )


def cache_key(source_path: str, member_path: str, size: int, mtime_ns: int) -> tuple[str, str, int, int]:
    return (source_path, member_path, int(size), int(mtime_ns))


def load_cache(path: Path) -> dict[tuple[str, str, int, int], FingerprintRow]:
    out: dict[tuple[str, str, int, int], FingerprintRow] = {}
    if not path.is_file():
        return out
    with path.open("r", encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            try:
                row = FingerprintRow.from_dict(json.loads(line))
            except (json.JSONDecodeError, TypeError, ValueError):
                continue
            if row.is_identifier_row():
                out[row.cache_key()] = row
    return out


def append_jsonl(path: Path, row: FingerprintRow) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as fh:
        fh.write(json.dumps(row.to_dict(), ensure_ascii=False) + "\n")


def _outer_mtime_ns(path: Path) -> int:
    try:
        st = path.stat()
        return int(getattr(st, "st_mtime_ns", int(st.st_mtime * 1_000_000_000)))
    except OSError:
        return 0


def _skip_row(
    source_path: str,
    member_path: str,
    size: int,
    mtime_ns: int,
    reason: str,
    detail: str | None = None,
) -> FingerprintRow:
    return FingerprintRow(
        source_path=source_path,
        member_path=member_path,
        size=size,
        mtime_ns=mtime_ns,
        skip_reason=reason,
        skip_detail=detail,
    )


def _ratio_exceeded(
    uncompressed: int,
    compressed: int | None,
    max_ratio: int,
) -> bool:
    if compressed is None:
        return False
    if compressed <= 0:
        return uncompressed > 0
    return (uncompressed / compressed) > max_ratio


def fingerprint_bytes(
    data: bytes,
    filename: str,
    *,
    max_member_bytes: int = MAX_MEMBER_BYTES,
) -> tuple[str, str]:
    """SHA-256 + trimesh identifier from already-buffered member bytes.

    Callers must only pass a complete read. A truncated buffer must not reach here.
    """
    if len(data) > max_member_bytes:
        raise MeshFingerprintError(SkipReason.CAP_MEMBER_BYTES)
    if not data:
        raise MeshFingerprintError("empty_mesh")
    digest = hashlib.sha256(data).hexdigest()
    ident = geometry_identifier_from_bytes(data, filename)
    return digest, ident


def geometry_identifier_from_bytes(data: bytes, filename: str) -> str:
    """trimesh ``identifier_hash`` — never invent a hash on parse failure."""
    try:
        import trimesh
    except ImportError as exc:  # pragma: no cover - gated dependency
        raise MeshFingerprintError(f"trimesh_missing:{exc}") from exc

    ext = extension_of(filename).lstrip(".")
    mesh = None
    tmp_path: Path | None = None
    try:
        try:
            mesh = trimesh.load(
                io.BytesIO(data),
                file_type=ext,
                force="mesh",
            )
        except Exception:
            # Some loaders need a real suffix; keep the file process-private.
            fd, name = tempfile.mkstemp(suffix=extension_of(filename) or ".bin")
            tmp_path = Path(name)
            os.close(fd)
            tmp_path.write_bytes(data)
            mesh = trimesh.load(str(tmp_path), force="mesh")
        mesh = _coerce_trimesh(mesh)
        ident = getattr(mesh, "identifier_hash", None)
        if not ident:
            raise MeshFingerprintError("no_identifier")
        return str(ident)
    except MeshFingerprintError:
        raise
    except Exception as exc:
        raise MeshFingerprintError(f"trimesh:{type(exc).__name__}") from exc
    finally:
        if tmp_path is not None:
            try:
                tmp_path.unlink(missing_ok=True)
            except OSError:
                pass


def _coerce_trimesh(mesh: Any) -> Any:
    import trimesh

    if mesh is None:
        raise MeshFingerprintError("empty_mesh")
    if isinstance(mesh, trimesh.Scene):
        geoms = [
            g for g in mesh.geometry.values() if isinstance(g, trimesh.Trimesh)
        ]
        if not geoms:
            raise MeshFingerprintError("empty_scene")
        mesh = trimesh.util.concatenate(geoms) if len(geoms) > 1 else geoms[0]
    if getattr(mesh, "is_empty", False):
        raise MeshFingerprintError("empty_mesh")
    faces = getattr(mesh, "faces", None)
    if faces is None or len(faces) == 0:
        raise MeshFingerprintError("empty_mesh")
    return mesh


def _stream_zipfile_member(
    path: Path,
    member_path: str,
    *,
    expected_size: int | None,
    compressed_size: int | None,
    budget: StreamBudget,
    max_member_bytes: int,
    max_ratio: int,
) -> tuple[bytes | None, str | None, str | None]:
    """Gated in-memory zip stream when libarchive is not installed (tests / slim hosts).

    Still never extracts onto NFS. Production images ship libarchive13.
    """
    if expected_size is not None and expected_size > max_member_bytes:
        return None, SkipReason.CAP_MEMBER_BYTES, str(expected_size)
    if expected_size is not None and _ratio_exceeded(
        expected_size, compressed_size, max_ratio
    ):
        return None, SkipReason.CAP_RATIO, f"{expected_size}/{compressed_size}"
    if expected_size is not None and budget.would_exceed(expected_size):
        return None, SkipReason.CAP_ARCHIVE_STREAM_BYTES, str(budget.used_bytes)
    try:
        with zipfile.ZipFile(path, "r") as zf:
            try:
                info = zf.getinfo(member_path)
            except KeyError:
                return None, SkipReason.IO_ERROR, "member_not_found"
            size = int(info.file_size)
            comp = int(info.compress_size)
            if size > max_member_bytes:
                return None, SkipReason.CAP_MEMBER_BYTES, str(size)
            if _ratio_exceeded(size, comp, max_ratio):
                return None, SkipReason.CAP_RATIO, f"{size}/{comp}"
            if budget.would_exceed(size):
                return None, SkipReason.CAP_ARCHIVE_STREAM_BYTES, str(budget.used_bytes)
            with zf.open(info, "r") as fh:
                buf = bytearray()
                while True:
                    chunk = fh.read(_STREAM_CHUNK)
                    if not chunk:
                        break
                    if len(buf) + len(chunk) > max_member_bytes:
                        return None, SkipReason.CAP_MEMBER_BYTES, str(
                            len(buf) + len(chunk)
                        )
                    if budget.would_exceed(len(chunk)):
                        return None, SkipReason.CAP_ARCHIVE_STREAM_BYTES, str(
                            budget.used_bytes
                        )
                    buf.extend(chunk)
                    budget.consume(len(chunk))
            if expected_size is not None and expected_size > 0 and len(buf) != expected_size:
                return None, SkipReason.TRUNCATED_STREAM, f"{len(buf)}/{expected_size}"
            if not buf:
                return None, SkipReason.FINGERPRINT_ERROR, "empty_member"
            return bytes(buf), None, None
    except zipfile.BadZipFile as exc:
        return None, SkipReason.IO_ERROR, str(exc)
    except OSError as exc:
        return None, SkipReason.IO_ERROR, f"{type(exc).__name__}:{exc}"


def _list_zip_members(path: Path, *, max_members: int) -> list[tuple[str, int, int]]:
    """Central-directory listing for .zip when libarchive is unavailable."""
    out: list[tuple[str, int, int]] = []
    with zipfile.ZipFile(path, "r") as zf:
        for info in zf.infolist():
            if info.is_dir():
                continue
            name = info.filename.replace("\\", "/")
            if member_has_traversal(name):
                continue
            out.append((name, int(info.file_size), int(info.compress_size)))
            if len(out) >= max_members:
                break
    return out


def _ensure_stream_binds(lib: Any) -> None:
    skip = getattr(lib, "archive_read_data_skip", None)
    if skip is not None:
        skip.argtypes = [ctypes.c_void_p]
        skip.restype = ctypes.c_int


def stream_archive_member(
    archive_path: Path | str,
    member_path: str,
    *,
    expected_size: int | None = None,
    compressed_size: int | None = None,
    budget: StreamBudget | None = None,
    max_member_bytes: int = MAX_MEMBER_BYTES,
    max_ratio: int = MAX_RATIO,
    lib_path: str | None = None,
) -> tuple[bytes | None, str | None, str | None]:
    """Gated ``archive_read_data`` of one residual member. Never extract-to-disk.

    Returns ``(bytes, skip_reason, skip_detail)``. Bytes are None on any skip —
    a truncated read is never hashed.
    """
    budget = budget if budget is not None else StreamBudget()
    path = Path(archive_path)
    want = member_path.replace("\\", "/")

    if member_has_traversal(want):
        return None, SkipReason.PATH_TRAVERSAL, want
    if expected_size is not None and expected_size > max_member_bytes:
        return None, SkipReason.CAP_MEMBER_BYTES, str(expected_size)
    if expected_size is not None and _ratio_exceeded(
        expected_size, compressed_size, max_ratio
    ):
        return None, SkipReason.CAP_RATIO, f"{expected_size}/{compressed_size}"
    if expected_size is not None and budget.would_exceed(expected_size):
        return None, SkipReason.CAP_ARCHIVE_STREAM_BYTES, str(budget.used_bytes)

    try:
        lib = _load_libarchive(lib_path)
    except LibarchiveError as exc:
        if Path(path).suffix.lower() == ".zip":
            return _stream_zipfile_member(
                path,
                want,
                expected_size=expected_size,
                compressed_size=compressed_size,
                budget=budget,
                max_member_bytes=max_member_bytes,
                max_ratio=max_ratio,
            )
        return None, SkipReason.IO_ERROR, str(exc)
    _ensure_stream_binds(lib)

    archive = lib.archive_read_new()
    if not archive:
        return None, SkipReason.IO_ERROR, "archive_read_new_failed"

    buf = bytearray()
    try:
        lib.archive_read_support_format_all(archive)
        lib.archive_read_support_filter_all(archive)
        open_rc = lib.archive_read_open_filename(
            archive, str(path).encode("utf-8"), 10240
        )
        if open_rc != ARCHIVE_OK:
            err = _archive_error(lib, archive)
            return None, _classify_open_error(err), err[:500]

        entry_ptr = ctypes.c_void_p()
        found = False
        while True:
            rc = lib.archive_read_next_header(archive, ctypes.byref(entry_ptr))
            if rc == ARCHIVE_EOF:
                break
            if rc == ARCHIVE_FATAL:
                err = _archive_error(lib, archive)
                return None, SkipReason.IO_ERROR, err[:500]
            if rc not in (ARCHIVE_OK, ARCHIVE_WARN):
                err = _archive_error(lib, archive)
                return None, SkipReason.IO_ERROR, err[:500]
            entry = entry_ptr.value
            filetype = lib.archive_entry_filetype(entry)
            if filetype & AE_IFDIR or not (filetype & AE_IFREG):
                continue
            raw_path = lib.archive_entry_pathname(entry)
            if not raw_path:
                continue
            name = raw_path.decode("utf-8", errors="replace").replace("\\", "/")
            if name != want:
                skip_fn = getattr(lib, "archive_read_data_skip", None)
                if skip_fn is not None:
                    skip_fn(archive)
                continue
            found = True
            size = int(lib.archive_entry_size(entry))
            if size < 0:
                size = expected_size if expected_size is not None else 0
            comp = compressed_size
            comp_fn = getattr(lib, "archive_entry_size_compressed", None)
            if comp_fn is not None and comp is None:
                c = comp_fn(entry)
                comp = int(c) if c >= 0 else None
            if size > max_member_bytes:
                return None, SkipReason.CAP_MEMBER_BYTES, str(size)
            if _ratio_exceeded(size, comp, max_ratio):
                return None, SkipReason.CAP_RATIO, f"{size}/{comp}"
            if size and budget.would_exceed(size):
                return None, SkipReason.CAP_ARCHIVE_STREAM_BYTES, str(budget.used_bytes)

            chunk = ctypes.create_string_buffer(_STREAM_CHUNK)
            while True:
                n = int(lib.archive_read_data(archive, chunk, _STREAM_CHUNK))
                if n == 0:
                    break
                if n < 0:
                    err = _archive_error(lib, archive)
                    return None, SkipReason.TRUNCATED_STREAM, err[:500]
                if len(buf) + n > max_member_bytes:
                    return None, SkipReason.CAP_MEMBER_BYTES, str(len(buf) + n)
                if budget.would_exceed(n):
                    return None, SkipReason.CAP_ARCHIVE_STREAM_BYTES, str(
                        budget.used_bytes
                    )
                buf.extend(chunk.raw[:n])
                budget.consume(n)
            break

        if not found:
            return None, SkipReason.IO_ERROR, "member_not_found"
        if expected_size is not None and expected_size > 0 and len(buf) != expected_size:
            return None, SkipReason.TRUNCATED_STREAM, f"{len(buf)}/{expected_size}"
        if not buf:
            return None, SkipReason.FINGERPRINT_ERROR, "empty_member"
        return bytes(buf), None, None
    except OSError as exc:
        return None, SkipReason.IO_ERROR, f"{type(exc).__name__}:{exc}"
    finally:
        lib.archive_read_close(archive)
        lib.archive_read_free(archive)


def fingerprint_loose(
    path: Path,
    *,
    budget: StreamBudget,
    cache: dict[tuple[str, str, int, int], FingerprintRow],
    max_member_bytes: int = MAX_MEMBER_BYTES,
) -> FingerprintRow:
    source = str(path)
    member = path.name
    try:
        st = path.stat()
    except OSError as exc:
        return _skip_row(source, member, 0, 0, SkipReason.IO_ERROR, str(exc))
    size = int(st.st_size)
    mtime_ns = int(getattr(st, "st_mtime_ns", int(st.st_mtime * 1_000_000_000)))
    key = cache_key(source, member, size, mtime_ns)
    hit = cache.get(key)
    if hit is not None and hit.is_identifier_row():
        reused = FingerprintRow.from_dict(hit.to_dict())
        reused.reused = True
        return reused
    if member_has_traversal(member):
        return _skip_row(source, member, size, mtime_ns, SkipReason.PATH_TRAVERSAL)
    if is_skip_extension(member):
        return _skip_row(source, member, size, mtime_ns, SkipReason.SKIP_EXTENSION)
    if not is_parse_v1(member):
        return _skip_row(source, member, size, mtime_ns, SkipReason.NOT_PARSE_V1)
    if size > max_member_bytes:
        return _skip_row(source, member, size, mtime_ns, SkipReason.CAP_MEMBER_BYTES)
    if budget.would_exceed(size):
        return _skip_row(
            source, member, size, mtime_ns, SkipReason.CAP_ARCHIVE_STREAM_BYTES
        )
    try:
        data = path.read_bytes()
    except OSError as exc:
        return _skip_row(source, member, size, mtime_ns, SkipReason.IO_ERROR, str(exc))
    if len(data) != size:
        return _skip_row(
            source, member, size, mtime_ns, SkipReason.TRUNCATED_STREAM, f"{len(data)}/{size}"
        )
    budget.consume(len(data))
    try:
        digest, ident = fingerprint_bytes(
            data, member, max_member_bytes=max_member_bytes
        )
    except MeshFingerprintError as exc:
        return _skip_row(
            source, member, size, mtime_ns, SkipReason.FINGERPRINT_ERROR, str(exc)
        )
    row = FingerprintRow(
        source_path=source,
        member_path=member,
        size=size,
        mtime_ns=mtime_ns,
        byte_sha256=digest,
        geometry_identifier=ident,
    )
    cache[key] = row
    return row


def fingerprint_archive_member(
    archive_path: Path,
    member_path: str,
    *,
    size: int,
    compressed_size: int | None,
    budget: StreamBudget,
    cache: dict[tuple[str, str, int, int], FingerprintRow],
    max_member_bytes: int = MAX_MEMBER_BYTES,
    max_ratio: int = MAX_RATIO,
    lib_path: str | None = None,
) -> FingerprintRow:
    source = str(archive_path)
    mtime_ns = _outer_mtime_ns(archive_path)
    key = cache_key(source, member_path, size, mtime_ns)
    hit = cache.get(key)
    if hit is not None and hit.is_identifier_row():
        reused = FingerprintRow.from_dict(hit.to_dict())
        reused.reused = True
        return reused
    if member_has_traversal(member_path):
        return _skip_row(
            source, member_path, size, mtime_ns, SkipReason.PATH_TRAVERSAL
        )
    name = Path(member_path).name
    if is_skip_extension(name):
        return _skip_row(
            source, member_path, size, mtime_ns, SkipReason.SKIP_EXTENSION
        )
    if not is_parse_v1(name):
        return _skip_row(
            source, member_path, size, mtime_ns, SkipReason.NOT_PARSE_V1
        )
    data, reason, detail = stream_archive_member(
        archive_path,
        member_path,
        expected_size=size,
        compressed_size=compressed_size,
        budget=budget,
        max_member_bytes=max_member_bytes,
        max_ratio=max_ratio,
        lib_path=lib_path,
    )
    if reason or data is None:
        return _skip_row(
            source, member_path, size, mtime_ns, reason or SkipReason.IO_ERROR, detail
        )
    try:
        digest, ident = fingerprint_bytes(
            data, name, max_member_bytes=max_member_bytes
        )
    except MeshFingerprintError as exc:
        return _skip_row(
            source, member_path, size, mtime_ns, SkipReason.FINGERPRINT_ERROR, str(exc)
        )
    row = FingerprintRow(
        source_path=source,
        member_path=member_path,
        size=size,
        mtime_ns=mtime_ns,
        byte_sha256=digest,
        geometry_identifier=ident,
    )
    cache[key] = row
    return row


def _iter_input_paths(paths_file: Path) -> Iterator[Path]:
    with paths_file.open("r", encoding="utf-8") as fh:
        for raw in fh:
            line = raw.strip()
            if not line or line.startswith("#"):
                continue
            yield Path(line)


def _collect_pack_files(root: Path) -> list[Path]:
    if root.is_file():
        return [root]
    if not root.is_dir():
        return []
    out: list[Path] = []
    for dirpath, dirnames, filenames in os.walk(root, followlinks=False):
        dirnames[:] = [d for d in dirnames if not d.startswith(".")]
        base = Path(dirpath)
        for name in filenames:
            p = base / name
            if p.is_symlink():
                continue
            out.append(p)
    return out


def fingerprint_paths(
    inputs: list[Path],
    *,
    work_dir: Path,
    budget: StreamBudget | None = None,
    max_member_bytes: int = MAX_MEMBER_BYTES,
    max_ratio: int = MAX_RATIO,
    max_members: int = DEFAULT_MAX_MEMBERS,
    cache_path: Path | None = None,
    run_id: str | None = None,
    lib_path: str | None = None,
    allow_live: bool = False,
) -> FingerprintRun:
    """Fingerprint residual packs + optional library candidate paths only."""
    assert_mega_fence_allows(*inputs, allow_live=allow_live)
    assert_writable_work_dir(work_dir)
    budget = budget if budget is not None else StreamBudget()
    cache_file = cache_path or (work_dir / CACHE_FILENAME)
    cache = load_cache(cache_file)
    run_id = run_id or time.strftime("%Y%m%d-%H%M%S")
    run_file = work_dir / f"{RUN_PREFIX}-{run_id}.jsonl"
    result = FingerprintRun(cache_path=str(cache_file), run_path=str(run_file))

    for src in inputs:
        if is_mega_path(src) and not allow_live:
            row = _skip_row(str(src), "", 0, 0, SkipReason.MEGA_FENCE)
            result.rows.append(row)
            result.skipped += 1
            append_jsonl(run_file, row)
            continue
        for path in _collect_pack_files(src):
            if is_archive_path(path) or path.suffix.lower() in ARCHIVE_EXTENSIONS:
                listing = list_archive_members(path, max_members=max_members, lib_path=lib_path)
                members: list[tuple[str, str, int, int | None]] = [
                    (m.member_path, m.basename, m.size, m.compressed_size)
                    for m in listing.members
                ]
                outer_mtime = listing.outer_mtime_ns or _outer_mtime_ns(path)
                if listing.skip_reason and path.suffix.lower() == ".zip":
                    try:
                        members = [
                            (name, Path(name).name, size, comp)
                            for name, size, comp in _list_zip_members(
                                path, max_members=max_members * 4
                            )
                        ]
                        outer_mtime = _outer_mtime_ns(path)
                    except (zipfile.BadZipFile, OSError):
                        pass
                mesh_seen = 0
                for member_path, name, size, compressed in members:
                    if is_skip_extension(name) or not is_parse_v1(name):
                        if is_skip_extension(name):
                            row = _skip_row(
                                str(path),
                                member_path,
                                size,
                                outer_mtime,
                                SkipReason.SKIP_EXTENSION,
                            )
                            result.rows.append(row)
                            result.skipped += 1
                            append_jsonl(run_file, row)
                        continue
                    mesh_seen += 1
                    if mesh_seen > max_members:
                        row = _skip_row(
                            str(path),
                            member_path,
                            size,
                            outer_mtime,
                            SkipReason.CAP_MEMBER_COUNT,
                        )
                        result.rows.append(row)
                        result.skipped += 1
                        append_jsonl(run_file, row)
                        continue
                    row = fingerprint_archive_member(
                        path,
                        member_path,
                        size=size,
                        compressed_size=compressed,
                        budget=budget,
                        cache=cache,
                        max_member_bytes=max_member_bytes,
                        max_ratio=max_ratio,
                        lib_path=lib_path,
                    )
                    _record(result, row, cache_file, run_file)
                continue
            row = fingerprint_loose(
                path,
                budget=budget,
                cache=cache,
                max_member_bytes=max_member_bytes,
            )
            if row.skip_reason == SkipReason.NOT_PARSE_V1:
                continue
            _record(result, row, cache_file, run_file)

    result.streamed_bytes = budget.used_bytes
    return result


def _record(
    result: FingerprintRun,
    row: FingerprintRow,
    cache_file: Path,
    run_file: Path,
) -> None:
    result.rows.append(row)
    append_jsonl(run_file, row)
    if row.reused:
        result.reused += 1
        result.identified += 1
        return
    if row.is_identifier_row():
        result.identified += 1
        append_jsonl(cache_file, row)
        return
    result.skipped += 1


def run_mesh_fingerprint_cli(args: argparse.Namespace, curate: CurateConfig) -> int:
    residual = getattr(args, "residual_list", None)
    if not residual:
        raise ResidualListRequired(
            "MODE=mesh-fingerprint requires --residual-list "
            "(residual new packs only; not a full-library scanner)"
        )
    residual_path = Path(residual)
    inputs = list(_iter_input_paths(residual_path))
    extra = getattr(args, "library_candidates", None)
    if extra:
        inputs.extend(_iter_input_paths(Path(extra)))
    allow_live = bool(getattr(args, "allow_live", False))
    work = Path(curate.work_dir) if curate.work_dir else Path(curate.library_root) / ".spark-curate"
    assert_mega_fence_allows(
        curate.library_root,
        residual_path,
        extra or "",
        *inputs,
        work,
        allow_live=allow_live,
    )
    try:
        assert_writable_work_dir(work)
    except FrozenRootWriteRefused as exc:
        raise MegaFenceRefused(str(exc)) from exc
    work.mkdir(parents=True, exist_ok=True)
    run_id = time.strftime("%Y%m%d-%H%M%S")
    max_members = max(1, int(getattr(args, "max_archive_members", DEFAULT_MAX_MEMBERS) or DEFAULT_MAX_MEMBERS))
    result = fingerprint_paths(
        inputs,
        work_dir=work,
        max_members=max_members,
        run_id=run_id,
        allow_live=allow_live,
    )
    summary = {
        "run_id": run_id,
        "mode": "mesh-fingerprint",
        "library": curate.library_root,
        **result.to_dict(),
    }
    summary_path = work / f"mesh-fingerprint-summary-{run_id}.json"
    summary_path.write_text(json.dumps(summary, indent=2), encoding="utf-8")
    print(json.dumps(summary, indent=2))
    return 0
