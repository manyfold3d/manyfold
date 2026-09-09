#!/usr/bin/env python3
"""Record live curator responses for the SPEC-005 fixture set (INIT-021/SPEC-005).

Read-only against the Unorg tree; writes only into ``tests/fixtures/``. Re-run to
refresh the recording after a prompt change, then commit the result.

    python3 tools/record_curator_fixtures.py [--mega-root PATH]
"""
from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from spark_curate.classify import (  # noqa: E402
    build_level_prompt,
    build_name_prompt,
    load_category_vocabulary,
    make_chat_fn,
    resolve_curator_endpoint,
)
from spark_curate.config import SparkConfig  # noqa: E402

DEFAULT_MEGA_ROOT = "/mnt/backups/3D-Prints-Unorg/intake/Mega"
DEFAULT_LIBRARY_ROOT = "/mnt/backups/3D-Prints"

# The ≥15 real top-level names ac-3 pins, taken verbatim from the live Mega dump.
FIXTURE_NAMES = [
    "3DXM Art",
    "APRIL 2024",
    "AUGUST 2023",
    "Anime",
    "AnySTL",
    "Articulated Figures",
    "B3Dserk Studios Art",
    "CFD Art",
    "CGTrader Models",
    "Cartoons",
    "Chibi",
    "Cosplay",
    "Cults3D",
    "D&D",
    "DC",
    "DECEMBER 2024",
    "DTR",
    "Dragon Ball",
    "Gumroad",
    "Movie TV",
    "Rober Rollin Art",
    "Star Wars",
    "Wicked Art",
]

NAME_FIXTURES = [
    "Nezuko_FINAL_v2",
    "Batman Bust (1)",
    "Goku [Patreon] 2024-05",
    "Articulated 1000+ STL files",
]


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--mega-root", default=DEFAULT_MEGA_ROOT)
    ap.add_argument("--library-root", default=DEFAULT_LIBRARY_ROOT)
    ap.add_argument(
        "--out",
        default=str(Path(__file__).resolve().parent.parent / "tests" / "fixtures"),
    )
    args = ap.parse_args()

    spark = SparkConfig()
    endpoint = resolve_curator_endpoint(spark)
    vocab = load_category_vocabulary(args.library_root)
    chat = make_chat_fn(spark)

    present = set()
    if os.path.isdir(args.mega_root):
        present = {e.name for e in os.scandir(args.mega_root) if e.is_dir()}
    missing = [n for n in FIXTURE_NAMES if present and n not in present]
    if missing:
        print(f"WARNING: not present in {args.mega_root}: {missing}", file=sys.stderr)

    recording = {
        "provenance": "INIT-021/SPEC-005",
        "recorded_from": endpoint.chat_url,
        "model": endpoint.model,
        "source_tree": args.mega_root,
        "vocabulary": list(vocab.categories),
        "levels": {},
        "names": {},
    }
    for name in FIXTURE_NAMES:
        system, user = build_level_prompt(name, vocab)
        try:
            recording["levels"][name] = chat(endpoint, system, user)
        except Exception as e:  # noqa: BLE001
            print(f"FAIL {name}: {e}", file=sys.stderr)
            return 1
        print(f"  {name!r} -> {recording['levels'][name][:120]}")
    for name in NAME_FIXTURES:
        system, user = build_name_prompt(name, vocab)
        try:
            recording["names"][name] = chat(endpoint, system, user)
        except Exception as e:  # noqa: BLE001
            print(f"FAIL {name}: {e}", file=sys.stderr)
            return 1
        print(f"  {name!r} -> {recording['names'][name][:120]}")

    out_dir = Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)
    out = out_dir / "curator_recordings.json"
    out.write_text(json.dumps(recording, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"Wrote {out} ({len(recording['levels'])} level recordings)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
