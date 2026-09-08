"""Manyfold-aligned indexable extensions and pack-root helpers (INIT-021/SPEC-004).

Ground truth:
- ``ApplicationJob.common_subfolders`` — fifteen closed folder names
- ``SupportedMimeTypes.indexable_extensions`` — image + model + video + document + archive
- ``SiteSettings.model_ignored_files`` — junk path semantics
"""
from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path

PROVENANCE = "INIT-021/SPEC-004"

COMMON_SUBFOLDERS: frozenset[str] = frozenset(
    {
        "3mf",
        "fdm",
        "files",
        "images",
        "lychee",
        "lys",
        "model",
        "obj",
        "parts",
        "presupported",
        "resin",
        "stl",
        "sup",
        "supported",
        "unsupported",
    }
)

ARCHIVE_EXTENSIONS: frozenset[str] = frozenset(
    {
        ".7z",
        ".bz2",
        ".gz",
        ".gzip",
        ".rar",
        ".sevenz",
        ".zip",
        ".cbz",
    }
)

MESH_EXTENSIONS: frozenset[str] = frozenset(
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
        ".gcode",
        ".lys",
        ".lyt",
        ".chitubox",
        ".ctb",
        ".sl1s",
        ".3dm",
    }
)

IMAGE_EXTENSIONS: frozenset[str] = frozenset(
    {".jpg", ".jpeg", ".png", ".webp", ".gif", ".bmp", ".tif", ".tiff"}
)

VIDEO_EXTENSIONS: frozenset[str] = frozenset(
    {".mp4", ".webm", ".mov", ".avi", ".mkv", ".m4v", ".wmv"}
)

DOCUMENT_EXTENSIONS: frozenset[str] = frozenset(
    {".pdf", ".txt", ".md", ".html", ".htm", ".doc", ".docx"}
)

INDEXABLE_EXTENSIONS: frozenset[str] = (
    MESH_EXTENSIONS
    | IMAGE_EXTENSIONS
    | VIDEO_EXTENSIONS
    | DOCUMENT_EXTENSIONS
    | ARCHIVE_EXTENSIONS
)

_HIDDEN_FILE_RE = re.compile(r"^\.[^.]")
_MACOSX_RE = re.compile(r"__MACOSX", re.I)
_EADIR_RE = re.compile(r".*/@eaDir/.*")
_DATAPACKAGE_RE = re.compile(r"^datapackage\.json$", re.I)

_MULTIPART_PART_RAR = re.compile(r"^(.+)\.part(\d+)\.rar$", re.I)
_MULTIPART_Z_SPLIT = re.compile(r"^(.+)\.z(\d+)$", re.I)
_MULTIPART_7Z = re.compile(r"^(.+)\.7z\.(\d+)$", re.I)

_BUCKET_MONTH_YEAR = re.compile(
    r"^(january|february|march|april|may|june|july|august|september|october|"
    r"november|december)\s+\d{4}$",
    re.I,
)
_BUCKET_MARKETPLACE = frozenset(
    {
        "cults3d",
        "cgtrader models",
        "cgtrader",
        "myminifactory",
        "thingiverse",
        "patreon",
        "gumroad",
    }
)
_CREATOR_SUFFIX = re.compile(r"\s+(art|studios?)\s*$", re.I)


@dataclass(frozen=True)
class MultipartVolume:
    path: Path
    stem_key: str
    volume_num: int
    pattern: str


@dataclass(frozen=True)
class MultipartSet:
    stem_key: str
    pattern: str
    volumes: tuple[MultipartVolume, ...]

    @property
    def volume_numbers(self) -> tuple[int, ...]:
        return tuple(v.volume_num for v in self.volumes)

    def missing_middle_volume(self) -> int | None:
        nums = sorted(self.volume_numbers)
        if len(nums) < 2:
            return None
        missing = [n for n in range(nums[0], nums[-1] + 1) if n not in nums]
        if missing:
            return missing[0]
        return None


def extension_of(name: str) -> str:
    lower = name.lower()
    for ext in sorted(INDEXABLE_EXTENSIONS, key=len, reverse=True):
        if lower.endswith(ext):
            return ext
    return Path(name).suffix.lower()


def is_indexable_filename(name: str) -> bool:
    return extension_of(name) in INDEXABLE_EXTENSIONS


def is_ignored_path(rel_posix: str, basename: str) -> bool:
    if _HIDDEN_FILE_RE.match(basename):
        return True
    if _DATAPACKAGE_RE.match(basename):
        return True
    norm = rel_posix.replace("\\", "/")
    if _MACOSX_RE.search(norm):
        return True
    if _EADIR_RE.match(norm):
        return True
    return False


def should_skip_dir_name(name: str) -> bool:
    if name.startswith("."):
        return True
    if name.lower() == "__macosx":
        return True
    if name == "@eaDir":
        return True
    return False


def bucket_name_hint(name: str) -> bool:
    lower = name.strip().lower()
    if _BUCKET_MONTH_YEAR.match(lower):
        return True
    return lower in _BUCKET_MARKETPLACE


def creator_name_hint(name: str) -> bool:
    return bool(_CREATOR_SUFFIX.search(name.strip()))


def parse_multipart_volume(path: Path) -> MultipartVolume | None:
    name = path.name
    for pattern, rx in (
        ("partNN.rar", _MULTIPART_PART_RAR),
        ("zNN", _MULTIPART_Z_SPLIT),
        ("7z.NNN", _MULTIPART_7Z),
    ):
        m = rx.match(name)
        if m:
            return MultipartVolume(
                path=path,
                stem_key=m.group(1).lower(),
                volume_num=int(m.group(2)),
                pattern=pattern,
            )
    return None


def group_multipart_volumes(files: list[Path]) -> tuple[list[MultipartSet], list[Path]]:
    by_key: dict[tuple[str, str], list[MultipartVolume]] = {}
    standalone: list[Path] = []
    for f in files:
        vol = parse_multipart_volume(f)
        if vol is None:
            standalone.append(f)
            continue
        key = (vol.stem_key, vol.pattern)
        by_key.setdefault(key, []).append(vol)
    sets: list[MultipartSet] = []
    for (stem_key, pattern), vols in sorted(by_key.items()):
        ordered = tuple(sorted(vols, key=lambda v: v.volume_num))
        if len(ordered) == 1:
            standalone.append(ordered[0].path)
            continue
        sets.append(MultipartSet(stem_key=stem_key, pattern=pattern, volumes=ordered))
    return sets, standalone
