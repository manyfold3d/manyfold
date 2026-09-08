from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from .config import SKIP_TOP_LEVEL, CurateConfig
from .indexable import should_skip_dir_name as _should_skip_dir_name
from .preview import ARCHIVE_EXT, IMAGE_EXT


MODEL_EXT = {
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
} | ARCHIVE_EXT


def should_skip_walk_dir(name: str) -> bool:
    """Shared skip semantics for organize and unorganize walks (SPEC-004 / ac-9)."""
    return name in SKIP_TOP_LEVEL or _should_skip_dir_name(name)


@dataclass
class ModelFolder:
    path: Path
    category: str  # current top-level category
    name: str  # current folder name

    @property
    def rel_posix(self) -> str:
        return f"{self.category}/{self.name}"


def _has_model_files(folder: Path) -> bool:
    try:
        for p in folder.iterdir():
            if p.is_file() and p.suffix.lower() in MODEL_EXT:
                return True
            if p.is_dir() and p.name.lower() in {
                "files",
                "stl",
                "stls",
                "models",
                "3d",
                "print files",
                "print_files",
            }:
                for q in p.iterdir():
                    if q.is_file() and q.suffix.lower() in MODEL_EXT:
                        return True
    except OSError:
        return False
    return False


def _has_any_interesting(folder: Path) -> bool:
    try:
        for p in folder.iterdir():
            if p.is_file() and (p.suffix.lower() in MODEL_EXT or p.suffix.lower() in IMAGE_EXT):
                return True
    except OSError:
        return False
    return False


def iter_model_folders(cfg: CurateConfig) -> list[ModelFolder]:
    """
    Manyfold layout: <library>/<Category>/<ModelName>/
    """
    root = Path(cfg.library_root)
    if not root.is_dir():
        raise FileNotFoundError(f"Library root not found: {root}")

    only = {c.lower() for c in cfg.only_categories} if cfg.only_categories else None
    out: list[ModelFolder] = []

    for cat_dir in sorted(root.iterdir(), key=lambda p: p.name.lower()):
        if not cat_dir.is_dir():
            continue
        if cat_dir.name in SKIP_TOP_LEVEL or cat_dir.name.startswith("."):
            continue
        if _should_skip_dir_name(cat_dir.name):
            continue
        if only is not None and cat_dir.name.lower() not in only:
            continue

        # Category itself might be mis-nested; still scan children as models
        try:
            children = list(cat_dir.iterdir())
        except OSError:
            continue

        for child in sorted(children, key=lambda p: p.name.lower()):
            if not child.is_dir():
                continue
            if child.name.startswith(".") or child.name in SKIP_TOP_LEVEL:
                continue
            if not (_has_model_files(child) or _has_any_interesting(child)):
                continue
            out.append(ModelFolder(path=child, category=cat_dir.name, name=child.name))
            if cfg.limit and len(out) >= cfg.limit:
                return out

    return out
