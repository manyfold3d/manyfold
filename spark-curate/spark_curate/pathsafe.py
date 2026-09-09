"""Structural path safety for promote destinations (INIT-021/SPEC-013).

Key on structure — traversal, absolute components, control characters,
symlink escape, jail containment — never on ordinary punctuation.

A legitimate model name such as ``King's Throne`` is safe. ``..``, a leading
``/``, NUL, and a realpath that leaves the library root are not.
"""
from __future__ import annotations

import re
from pathlib import Path

# C0 controls + DEL. Apostrophe, quotes, spaces, parentheses are not here.
_CONTROL_RE = re.compile(r"[\x00-\x1f\x7f]")
_DRIVE_ABS_RE = re.compile(r"^[A-Za-z]:[\\/]")


class PathUnsafeError(ValueError):
    """Base for structural path-safety refusals."""


class TraversalSegmentError(PathUnsafeError):
    """A ``..`` segment is present."""


class AbsolutePathError(PathUnsafeError):
    """Path is absolute (drive letter, UNC, or Path.is_absolute)."""


class LeadingSlashError(PathUnsafeError):
    """Raw path starts with ``/``."""


class ControlCharacterError(PathUnsafeError):
    """NUL or other control characters present."""


class NotCategoryModelError(PathUnsafeError):
    """Promote destination is not exactly Category/Model (two segments)."""


class SymlinkEscapeError(PathUnsafeError):
    """A symlink component resolves outside the library root."""


class JailEscapeError(PathUnsafeError):
    """Destination realpath is outside the library jail."""


def safe_label(rel: str) -> str:
    """Log-safe identity: category + name length, never a deep Unorg path."""
    cleaned = rel.replace("\\", "/").strip()
    parts = [p for p in cleaned.split("/") if p]
    if len(parts) >= 2:
        return f"{parts[-2]}/<name {len(parts[-1])} chars>"
    if len(parts) == 1:
        return f"<name {len(parts[0])} chars>"
    return f"<path {len(rel)} chars>"


def check_rel_path(rel: str) -> tuple[str, str]:
    """Refuse structurally unsafe relative Category/Model paths.

    Returns ``(category, name)``. Does not touch the filesystem.
    """
    if not isinstance(rel, str):
        raise PathUnsafeError("path must be a str")
    if _CONTROL_RE.search(rel):
        raise ControlCharacterError("NUL or control character in path")
    stripped = rel.strip()
    if not stripped:
        raise PathUnsafeError("empty path")
    if stripped.startswith("/"):
        raise LeadingSlashError("path starts with '/'")
    if _DRIVE_ABS_RE.match(stripped):
        raise AbsolutePathError("absolute drive path")
    if stripped.startswith("\\\\"):
        raise AbsolutePathError("UNC path")
    normalized = stripped.replace("\\", "/")
    if Path(normalized).is_absolute():
        raise AbsolutePathError("absolute path")
    parts = normalized.split("/")
    if any(p == "" for p in parts):
        raise PathUnsafeError("empty path segment")
    if any(p == ".." for p in parts):
        raise TraversalSegmentError("'..' segment refused")
    if len(parts) != 2:
        raise NotCategoryModelError(
            "promote destination must be Category/Model (2 segments), "
            f"got {len(parts)}"
        )
    category, name = parts
    if category == "." or name == ".":
        raise PathUnsafeError("'.' is not a legal path component")
    return category, name


def _under(path: Path, jail: Path) -> bool:
    return path == jail or path.is_relative_to(jail)


def assert_jailed_destination(dest: Path, jail: Path) -> Path:
    """Refuse dest if any symlink prefix or final realpath leaves *jail*.

    Checked at move time (not only plan time) so a symlink swapped between
    plan and apply is still caught.
    """
    if not dest.is_absolute():
        dest = Path(jail) / dest
    try:
        jail_r = Path(jail).resolve()
    except OSError as e:
        raise PathUnsafeError("cannot resolve library root") from e

    parts = dest.parts
    if dest.is_absolute():
        acc = Path(parts[0])
        rest = parts[1:]
    else:
        acc = jail_r
        rest = parts

    for part in rest:
        acc = acc / part
        try:
            is_link = acc.is_symlink()
        except OSError as e:
            raise PathUnsafeError("cannot stat dest component") from e
        if is_link:
            try:
                linked = acc.resolve()
            except OSError as e:
                raise PathUnsafeError("cannot resolve symlink") from e
            if not _under(linked, jail_r):
                raise SymlinkEscapeError(
                    "symlink resolves outside the library root"
                )
        elif not acc.exists():
            break

    try:
        resolved = dest.resolve()
    except OSError as e:
        raise PathUnsafeError("cannot realpath destination") from e
    if not _under(resolved, jail_r):
        raise JailEscapeError("destination realpath escapes the library root")
    return resolved


def check_destination(rel: str, library_root: Path) -> Path:
    """Structural checks plus jail/symlink containment for *rel* under *library_root*."""
    category, name = check_rel_path(rel)
    jail = Path(library_root)
    dest = jail / category / name
    return assert_jailed_destination(dest, jail)
