# libarchive central-directory listing — zip, rar, 7z via ctypes (no extract).
# Provenance: INIT-021/SPEC-006
from __future__ import annotations

import ctypes
import logging
import os
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Iterator

log = logging.getLogger(__name__)

PROVENANCE = "INIT-021/SPEC-006"

ARCHIVE_OK = 0
ARCHIVE_EOF = 1
ARCHIVE_WARN = -20
ARCHIVE_RETRY = -10
ARCHIVE_FATAL = -25

AE_IFREG = 0x8000
AE_IFDIR = 0x4000

DEFAULT_LIBARCHIVE_PATHS = (
    "archive",
    "/usr/lib/x86_64-linux-gnu/libarchive.so.13",
    "/usr/lib/libarchive.so.13",
)


class LibarchiveError(RuntimeError):
    """libarchive could not be loaded or used."""


class ArchiveSkipReason:
    CORRUPT = "corrupt_archive"
    ENCRYPTED = "encrypted_archive"
    TRUNCATED = "truncated_archive"
    IO_ERROR = "io_error"
    UNSUPPORTED = "unsupported_format"
    EMPTY = "empty_archive"
    ENTRY_CAP = "entry_cap_exceeded"


@dataclass(frozen=True)
class ListedMember:
    member_path: str
    basename: str
    size: int
    compressed_size: int | None
    crc32: int | None
    is_mesh: bool
    is_image: bool
    is_junk: bool

    @property
    def sig_nocrc(self) -> str:
        from .archive_index import member_signature_nocrc

        return member_signature_nocrc(self.basename, self.size)

    @property
    def sig_crc(self) -> str | None:
        if self.crc32 is None:
            return None
        from .archive_index import member_signature

        return member_signature(self.basename, self.size, self.crc32)

@dataclass
class ArchiveListing:
    archive_path: str
    members: list[ListedMember] = field(default_factory=list)
    skip_reason: str | None = None
    skip_detail: str | None = None
    truncated: bool = False
    max_members: int = 5_000
    outer_size: int | None = None
    outer_mtime_ns: int | None = None
    format_name: str | None = None
    part_paths: tuple[str, ...] = ()

    def to_dict(self) -> dict[str, Any]:
        return {
            "archive_path": self.archive_path,
            "part_paths": list(self.part_paths),
            "member_count": len(self.members),
            "mesh_count": sum(1 for m in self.members if m.is_mesh),
            "skip_reason": self.skip_reason,
            "skip_detail": self.skip_detail,
            "truncated": self.truncated,
            "max_members": self.max_members,
            "outer_size": self.outer_size,
            "outer_mtime_ns": self.outer_mtime_ns,
            "format_name": self.format_name,
            "members": [
                {
                    "member_path": m.member_path,
                    "basename": m.basename,
                    "size": m.size,
                    "compressed_size": m.compressed_size,
                    "crc32": m.crc32,
                    "is_mesh": m.is_mesh,
                    "is_image": m.is_image,
                    "sig_nocrc": m.sig_nocrc,
                    "sig_crc": m.sig_crc,
                }
                for m in self.members
            ],
        }


_lib: ctypes.CDLL | None = None


def _load_libarchive(explicit_path: str | None = None) -> ctypes.CDLL:
    global _lib
    if _lib is not None:
        return _lib
    env_path = os.environ.get("SPARK_CURATE_LIBARCHIVE")
    candidates = []
    if explicit_path:
        candidates.append(explicit_path)
    if env_path:
        candidates.append(env_path)
    candidates.extend(DEFAULT_LIBARCHIVE_PATHS)
    last_err: Exception | None = None
    for name in candidates:
        try:
            _lib = ctypes.CDLL(name)
            break
        except OSError as exc:
            last_err = exc
            continue
    if _lib is None:
        raise LibarchiveError(
            f"libarchive shared library not found (tried {candidates!r}): {last_err}"
        )
    _bind(_lib)
    return _lib


def _bind(lib: ctypes.CDLL) -> None:
    lib.archive_read_new.restype = ctypes.c_void_p
    lib.archive_read_support_format_all.argtypes = [ctypes.c_void_p]
    lib.archive_read_support_filter_all.argtypes = [ctypes.c_void_p]
    lib.archive_read_open_filename.argtypes = [
        ctypes.c_void_p,
        ctypes.c_char_p,
        ctypes.c_size_t,
    ]
    lib.archive_read_next_header.argtypes = [
        ctypes.c_void_p,
        ctypes.POINTER(ctypes.c_void_p),
    ]
    lib.archive_read_free.argtypes = [ctypes.c_void_p]
    lib.archive_read_close.argtypes = [ctypes.c_void_p]
    lib.archive_read_data.argtypes = [ctypes.c_void_p, ctypes.c_void_p, ctypes.c_size_t]
    lib.archive_entry_pathname.restype = ctypes.c_char_p
    lib.archive_entry_size.restype = ctypes.c_int64
    lib.archive_entry_filetype.restype = ctypes.c_uint
    lib.archive_format_name.restype = ctypes.c_char_p
    lib.archive_error_string.restype = ctypes.c_char_p


def _archive_error(lib: ctypes.CDLL, archive: ctypes.c_void_p) -> str:
    msg = lib.archive_error_string(archive)
    if msg:
        return msg.decode("utf-8", errors="replace")
    return "unknown libarchive error"


def _classify_open_error(message: str) -> str:
    lower = message.lower()
    if "passphrase" in lower or "encrypted" in lower or "password" in lower:
        return ArchiveSkipReason.ENCRYPTED
    if "truncated" in lower or "unexpected eof" in lower:
        return ArchiveSkipReason.TRUNCATED
    if "unsupported" in lower or "unrecognized" in lower:
        return ArchiveSkipReason.UNSUPPORTED
    return ArchiveSkipReason.CORRUPT


def _outer_stat(path: Path) -> tuple[int | None, int | None]:
    try:
        st = path.stat()
        return st.st_size, getattr(st, "st_mtime_ns", int(st.st_mtime * 1_000_000_000))
    except OSError:
        return None, None


def list_archive_members(
    archive_path: Path | str,
    *,
    folder_rel: str = "",
    max_members: int = 5_000,
    lib_path: str | None = None,
    part_paths: tuple[str, ...] = (),
    is_junk_fn=None,
    is_mesh_fn=None,
    is_image_fn=None,
) -> ArchiveListing:
    """
    List members via libarchive. Never calls archive_read_data (no extract).

    Raises LibarchiveError only when the shared library cannot load.
    Unreadable archives return skip_reason on the listing.
    """
    from .indexable import is_ignored_path, is_image_extension, is_mesh_extension

    path = Path(archive_path)
    outer_size, outer_mtime_ns = _outer_stat(path)
    listing = ArchiveListing(
        archive_path=str(path),
        max_members=max_members,
        outer_size=outer_size,
        outer_mtime_ns=outer_mtime_ns,
        part_paths=part_paths or (str(path),),
    )
    if max_members < 1:
        listing.skip_reason = ArchiveSkipReason.ENTRY_CAP
        listing.skip_detail = "max_members_lt_1"
        return listing
    if not path.is_file():
        listing.skip_reason = ArchiveSkipReason.IO_ERROR
        listing.skip_detail = "not_a_file"
        return listing

    junk_fn = is_junk_fn or (
        lambda member_path, basename: is_ignored_path(member_path, basename)
    )
    mesh_fn = is_mesh_fn or is_mesh_extension
    image_fn = is_image_fn or is_image_extension

    try:
        lib = _load_libarchive(lib_path)
    except LibarchiveError as exc:
        listing.skip_reason = ArchiveSkipReason.IO_ERROR
        listing.skip_detail = str(exc)
        return listing

    archive = lib.archive_read_new()
    if not archive:
        listing.skip_reason = ArchiveSkipReason.IO_ERROR
        listing.skip_detail = "archive_read_new_failed"
        return listing

    try:
        lib.archive_read_support_format_all(archive)
        lib.archive_read_support_filter_all(archive)
        block_size = 10240
        open_rc = lib.archive_read_open_filename(
            archive,
            str(path).encode("utf-8"),
            block_size,
        )
        if open_rc != ARCHIVE_OK:
            err = _archive_error(lib, archive)
            listing.skip_reason = _classify_open_error(err)
            listing.skip_detail = err[:500]
            return listing

        fmt = lib.archive_format_name(archive)
        if fmt:
            listing.format_name = fmt.decode("utf-8", errors="replace")

        entry_ptr = ctypes.c_void_p()
        kept = 0
        while True:
            rc = lib.archive_read_next_header(
                archive, ctypes.byref(entry_ptr)
            )
            if rc == ARCHIVE_EOF:
                break
            if rc == ARCHIVE_FATAL:
                err = _archive_error(lib, archive)
                if listing.members:
                    listing.skip_detail = f"header_fatal:{err[:200]}"
                    break
                listing.skip_reason = _classify_open_error(err)
                listing.skip_detail = err[:500]
                listing.members.clear()
                return listing
            if rc not in (ARCHIVE_OK, ARCHIVE_WARN):
                err = _archive_error(lib, archive)
                listing.skip_reason = ArchiveSkipReason.CORRUPT
                listing.skip_detail = err[:500]
                listing.members.clear()
                return listing

            entry = entry_ptr.value
            enc_fn = getattr(lib, "archive_entry_is_encrypted", None)
            if enc_fn is not None and enc_fn(entry):
                listing.skip_reason = ArchiveSkipReason.ENCRYPTED
                listing.skip_detail = "entry_encrypted"
                listing.members.clear()
                return listing

            filetype = lib.archive_entry_filetype(entry)
            if filetype & AE_IFDIR:
                continue
            if not (filetype & AE_IFREG):
                continue

            raw_path = lib.archive_entry_pathname(entry)
            if not raw_path:
                continue
            member_path = raw_path.decode("utf-8", errors="replace").replace("\\", "/")
            basename = Path(member_path).name
            if not basename:
                continue
            if junk_fn(member_path, basename):
                continue

            size = int(lib.archive_entry_size(entry))
            if size < 0:
                size = 0
            compressed_size = None
            comp_fn = getattr(lib, "archive_entry_size_compressed", None)
            if comp_fn is not None:
                comp = comp_fn(entry)
                compressed_size = int(comp) if comp >= 0 else None

            if kept >= max_members:
                listing.truncated = True
                break

            mesh = mesh_fn(basename)
            image = image_fn(basename)
            listing.members.append(
                ListedMember(
                    member_path=member_path,
                    basename=basename,
                    size=size,
                    compressed_size=compressed_size,
                    crc32=None,
                    is_mesh=mesh,
                    is_image=image,
                    is_junk=False,
                )
            )
            kept += 1

        if not listing.members and listing.skip_reason is None:
            listing.skip_reason = ArchiveSkipReason.EMPTY
    except OSError as exc:
        listing.skip_reason = ArchiveSkipReason.IO_ERROR
        listing.skip_detail = f"{type(exc).__name__}:{exc}"
        listing.members.clear()
    finally:
        lib.archive_read_close(archive)
        lib.archive_read_free(archive)

    return listing


def iter_listings_no_extract(
    paths: Iterator[Path],
    **kwargs: Any,
) -> Iterator[ArchiveListing]:
    """Convenience iterator — listing only."""
    for path in paths:
        yield list_archive_members(path, **kwargs)
