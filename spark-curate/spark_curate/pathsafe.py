"""Structural path safety for plan destinations (INIT-021/SPEC-004).

Minimal subset — full promote jail checks ship in SPEC-013.
"""
from __future__ import annotations

import re
from pathlib import Path

_CONTROL_RE = re.compile(r"[\x00-\x1f\x7f]")
_DRIVE_ABS_RE = re.compile(r"^[A-Za-z]:[\\/]")


class PathUnsafeError(ValueError):
    """Base for structural path-safety refusals."""


class TraversalSegmentError(PathUnsafeError):
    """A ``..`` segment is present."""


class AbsolutePathError(PathUnsafeError):
    """Path is absolute."""


class LeadingSlashError(PathUnsafeError):
    """Raw path starts with ``/``."""


class ControlCharacterError(PathUnsafeError):
    """NUL or other control characters present."""


class NotCategoryModelError(PathUnsafeError):
    """Destination is not exactly Category/Model (two segments)."""


class SymlinkEscapeError(PathUnsafeError):
    """A symlink component resolves outside the jail."""


class JailEscapeError(PathUnsafeError):
    """Destination realpath is outside the jail."""


def check_rel_path(rel: str) -> tuple[str, str]:
    """Refuse structurally unsafe relative Category/Model paths."""
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
            f"destination must be Category/Model (2 segments), got {len(parts)}"
        )
    category, name = parts
    if category == "." or name == ".":
        raise PathUnsafeError("'.' is not a legal path component")
    return category, name
