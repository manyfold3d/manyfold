from __future__ import annotations

import json
import shutil
import time
from pathlib import Path
from typing import Any

from .config import CurateConfig
from .decide import Decision
from .pathsafe import PathUnsafeError, assert_jailed_destination, safe_label


def unique_dest(dest_root: Path, category: str, model_name: str) -> Path:
    cat_dir = dest_root / category
    candidate = cat_dir / model_name
    if not candidate.exists():
        return candidate
    i = 2
    while True:
        alt = cat_dir / f"{model_name} ({i})"
        if not alt.exists():
            return alt
        i += 1


def plan_destination(cfg: CurateConfig, d: Decision) -> Path | None:
    if d.action in {"skip", "keep"} and d.category == d.current_category and d.suggested_name == d.current_name:
        return None
    if d.action == "skip":
        return None
    root = Path(cfg.library_root)
    # rename within category or move
    cat = d.category if d.action in {"move", "rename", "keep"} else d.current_category
    name = d.suggested_name if d.action in {"move", "rename"} else d.current_name
    if d.action == "keep":
        return None
    dest = unique_dest(root, cat, name)
    src = Path(d.source_path)
    if dest.resolve() == src.resolve():
        return None
    return dest


def apply_decision(
    cfg: CurateConfig,
    d: Decision,
    *,
    do_apply: bool,
    log_fh,
) -> dict[str, Any]:
    """
    Rearrange only. Never deletes source data (uses move).
    Returns audit record.
    """
    rec: dict[str, Any] = {
        "ts": time.strftime("%Y-%m-%dT%H:%M:%S"),
        "source": d.source_path,
        "action": d.action,
        "confidence": d.confidence,
        "category": d.category,
        "suggested_name": d.suggested_name,
        "sensitive": d.sensitive,
        "applied": False,
        "dest": None,
        "error": d.error,
        "skipped_reason": None,
    }

    if d.error:
        rec["skipped_reason"] = "error"
        _log(log_fh, f"SKIP error {d.source_path}: {d.error}")
        return rec

    if d.confidence < cfg.min_confidence and d.action not in {"keep", "skip"}:
        rec["skipped_reason"] = f"confidence {d.confidence:.2f} < {cfg.min_confidence}"
        _log(log_fh, f"SKIP low conf {d.confidence:.2f}: {d.source_path}")
        return rec

    dest = plan_destination(cfg, d)
    if dest is None:
        rec["skipped_reason"] = "no_move_needed"
        rec["action"] = "keep"
        _log(log_fh, f"KEEP {d.source_path}")
        return rec

    rec["dest"] = str(dest)
    src = Path(d.source_path)
    if not src.is_dir():
        rec["skipped_reason"] = "source_missing"
        _log(log_fh, f"SKIP missing {src}")
        return rec

    try:
        # Move-time jail check (INIT-021/SPEC-013) — not only at plan time.
        assert_jailed_destination(dest, Path(cfg.library_root))
    except PathUnsafeError as e:
        rec["error"] = f"{type(e).__name__}: {e}"
        rec["skipped_reason"] = "unsafe_destination"
        rec["applied"] = False
        _log(log_fh, f"ERROR unsafe dest {type(e).__name__} {safe_label(str(dest))}")
        return rec

    mode = "MOVE" if do_apply else "DRY"
    _log(log_fh, f"{mode} {safe_label(str(src))} -> {safe_label(str(dest))}")

    if not do_apply:
        rec["applied"] = False
        return rec

    try:
        dest.parent.mkdir(parents=True, exist_ok=True)
        if dest.exists():
            # unique_dest should prevent this
            rec["skipped_reason"] = "dest_exists"
            return rec
        shutil.move(str(src), str(dest))
        try:
            assert_jailed_destination(dest, Path(cfg.library_root))
        except PathUnsafeError as e:
            rec["error"] = f"{type(e).__name__}: {e}"
            rec["applied"] = False
            rec["skipped_reason"] = "unsafe_destination"
            _log(log_fh, f"ERROR unsafe dest after move {type(e).__name__} {safe_label(str(dest))}")
            return rec
        rec["applied"] = True
        # Write sidecar metadata for Manyfold humans / later import
        meta = {
            "spark_curate": True,
            "tags": d.tags,
            "sensitive": d.sensitive,
            "content_type": d.content_type,
            "notes": d.notes,
            "previous_path": d.source_path,
        }
        try:
            (dest / ".spark-curate-meta.json").write_text(
                json.dumps(meta, indent=2), encoding="utf-8"
            )
        except OSError:
            pass
        # Ensure a preview.jpg if we had a thumb and none exists at dest root
        if d.thumb_path:
            _ensure_preview(Path(d.thumb_path), dest)
    except OSError as e:
        rec["error"] = str(e)
        rec["applied"] = False
        _log(log_fh, f"ERROR move {src}: {e}")

    return rec


def _ensure_preview(thumb: Path, dest: Path) -> None:
    """Copy preview into dest as preview.jpg if missing (never delete)."""
    if not thumb.is_file():
        return
    for name in ("preview.jpg", "preview.png", "preview.jpeg", "preview.webp"):
        if (dest / name).exists():
            return
    try:
        import shutil

        target = dest / "preview.jpg"
        # if thumb already inside dest after move, paths may be stale — ignore
        if thumb.exists():
            shutil.copy2(str(thumb), str(target))
    except OSError:
        pass


def _log(fh, msg: str) -> None:
    line = msg
    print(line, flush=True)
    if fh:
        fh.write(line + "\n")
        fh.flush()
