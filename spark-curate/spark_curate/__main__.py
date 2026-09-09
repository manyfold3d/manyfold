from __future__ import annotations

import argparse
import json
import sys
import time
import traceback
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

# Package root on PYTHONPATH (/app in Docker, or parent of package on host)
_PKG_ROOT = Path(__file__).resolve().parent.parent
if str(_PKG_ROOT) not in sys.path:
    sys.path.insert(0, str(_PKG_ROOT))

from spark_curate.apply_merges import write_merge_plans  # noqa: E402
from spark_curate.apply_moves import apply_decision  # noqa: E402
from spark_curate.archive_index import (  # noqa: E402
    DEFAULT_MAX_MEMBERS_PER_ARCHIVE,
    build_archive_index,
    run_archive_match,
    run_cross_root_archive_recall,
    summary_dict as archive_match_summary,
)
from spark_curate.candidates import build_merge_candidates  # noqa: E402
from spark_curate.admission import run_admit_cli  # noqa: E402
from spark_curate.classify import run_classify_cli  # noqa: E402
from spark_curate.config import CurateConfig, SparkConfig, load_config, save_example_config  # noqa: E402
from spark_curate.decide import decide_one  # noqa: E402
from spark_curate.decide_merge import decide_merge_pair_safe  # noqa: E402
from spark_curate.unorganize import run_unorganize_cli  # noqa: E402
from spark_curate.walk import iter_model_folders  # noqa: E402


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        description=(
            "Organize a Manyfold 3D-Prints library using DGX Spark "
            "(Gemma vision + Qwen curator + NudeNet). "
            "Never deletes; only rearranges or queues merges. Default is dry-run."
        )
    )
    p.add_argument(
        "--library",
        default=None,
        help=r"Library root (default: \\192.168.11.102\Backups\3D-Prints)",
    )
    p.add_argument("--config", default=None, help="JSON config path")
    p.add_argument(
        "--write-example-config",
        metavar="PATH",
        help="Write example config JSON and exit",
    )
    p.add_argument(
        "--mode",
        choices=(
            "organize",
            "merge",
            "match",
            "unorganize",
            "classify",
            "archive-recall",
            "admit",
        ),
        default="organize",
        help=(
            "organize=folder rearrange (default); merge=duplicate pack merge plans; "
            "match=archive-member inverted index (zip infolist only, INIT-018/SPEC-004); "
            "unorganize=intake bucket dismantle + pack-root plan (INIT-021/SPEC-004); "
            "classify=curator category/creator/name pass over an unorganize plan "
            "(INIT-021/SPEC-005); "
            "archive-recall=cross-root batch↔library recall (INIT-021/SPEC-006); "
            "admit=new|hold verdicts into admissions JSONL (INIT-021/SPEC-008)"
        ),
    )
    p.add_argument(
        "--plan",
        default=None,
        help="classify-plan-*.jsonl for --mode admit, or unorganize-plan for --mode classify",
    )
    p.add_argument(
        "--batch-root",
        default=None,
        help="Intake batch root for MODE=archive-recall / MODE=admit",
    )
    p.add_argument(
        "--slice-top",
        default=None,
        help="Optional top-level folder under --batch-root for archive-recall slice",
    )
    p.add_argument(
        "--candidates",
        default=None,
        help="Precomputed cross-root-candidates-*.jsonl for --mode admit (hermetic)",
    )
    p.add_argument(
        "--work-dir",
        default=None,
        help=(
            "Where run artifacts are written (default: alongside the input plan). "
            "Required when the input tree is frozen read-only."
        ),
    )
    p.add_argument(
        "--vocabulary-root",
        default=None,
        help=(
            "Live library root whose top-level folders are the category "
            "vocabulary for --mode classify (default: --library)"
        ),
    )
    p.add_argument(
        "--category-extension",
        action="append",
        dest="category_extensions",
        default=[],
        help="Operator-added category beyond the live library's folders (repeatable)",
    )
    p.add_argument(
        "--intake",
        default=None,
        help="Intake/Unorg root for MODE=unorganize (defaults to --library)",
    )
    p.add_argument(
        "--unorganize-slice",
        action="append",
        dest="unorganize_slice",
        default=[],
        help="Limit unorganize pass to these top-level folder names (repeatable)",
    )
    p.add_argument(
        "--max-archive-members",
        type=int,
        default=DEFAULT_MAX_MEMBERS_PER_ARCHIVE,
        help=(
            "Cap central-directory members listed per zip in MODE=match "
            f"(default {DEFAULT_MAX_MEMBERS_PER_ARCHIVE})"
        ),
    )
    p.add_argument("--apply", action="store_true", help="Perform moves / queue merges (default: dry-run)")
    p.add_argument("--limit", type=int, default=0, help="Max model folders (0=all)")
    p.add_argument(
        "--category",
        action="append",
        dest="categories",
        default=[],
        help="Only process this top-level category (repeatable)",
    )
    p.add_argument("--workers", type=int, default=None, help="Parallel vision workers (default 2)")
    p.add_argument(
        "--min-confidence",
        type=float,
        default=None,
        help="Min confidence to auto-move (organize mode, default 0.55)",
    )
    p.add_argument(
        "--min-merge-confidence",
        type=float,
        default=None,
        help="Min confidence to queue merge for Manyfold (default 0.80)",
    )
    p.add_argument(
        "--max-merge-pairs",
        type=int,
        default=None,
        help="Cap merge candidate pairs (default 200)",
    )
    p.add_argument(
        "--merge-hitl",
        default=None,
        choices=("hitl_all", "hitl_uncertain", "hitl_off"),
        help=(
            "MERGE_HITL apply mode (default hitl_all). "
            "hitl_uncertain auto-queues STRONG; hitl_off also UNCERTAIN when approved. "
            "Invalid values fail loud via env/config parse."
        ),
    )
    p.add_argument(
        "--skip-good",
        action="store_true",
        help="Skip folders that already have preview.jpg and are not under Unknown",
    )
    p.add_argument(
        "--smoke",
        action="store_true",
        help="Ping Spark endpoints and exit",
    )
    return p


def smoke(spark: SparkConfig) -> int:
    import urllib.request

    ok = 0
    for name, url in [
        ("gemma models", spark.gemma_url.rstrip("/") + "/models"),
        ("curator models", spark.curator_url.rstrip("/") + "/models"),
        ("nudenet health", spark.nudenet_url.rstrip("/") + "/health"),
    ]:
        try:
            with urllib.request.urlopen(url, timeout=15) as r:
                print(f"OK  {name}: HTTP {r.status}")
                ok += 1
        except Exception as e:  # noqa: BLE001
            print(f"FAIL {name}: {e}")
    return 0 if ok == 3 else 1


def run_organize(args: argparse.Namespace, spark: SparkConfig, curate: CurateConfig) -> int:
    work = curate.resolved_work_dir()
    work.mkdir(parents=True, exist_ok=True)
    thumb_cache = work / "thumbs"
    thumb_cache.mkdir(exist_ok=True)
    run_id = time.strftime("%Y%m%d-%H%M%S")
    decisions_path = work / f"decisions-{run_id}.jsonl"
    audit_path = work / f"audit-{run_id}.jsonl"
    log_path = work / f"run-{run_id}.log"

    print(f"Library:  {curate.library_root}")
    print(f"Work dir: {work}")
    print(f"Mode:     organize {'APPLY' if args.apply else 'DRY-RUN'}")
    print(f"Min conf: {curate.min_confidence}")
    print(f"Workers:  {curate.workers}")

    folders = iter_model_folders(curate)
    print(f"Found {len(folders)} model folders")

    if curate.skip_if_has_preview_and_known_category:
        filtered = []
        for f in folders:
            preview = f.path / "preview.jpg"
            if preview.is_file() and f.category.lower() != "unknown":
                continue
            filtered.append(f)
        print(f"After --skip-good: {len(filtered)} folders")
        folders = filtered

    if not folders:
        print("Nothing to do.")
        return 0

    def job(folder):
        try:
            return decide_one(folder, spark, curate, thumb_cache)
        except Exception as e:  # noqa: BLE001
            from spark_curate.decide import Decision

            return Decision(
                source_path=str(folder.path),
                current_category=folder.category,
                current_name=folder.name,
                suggested_name=folder.name,
                category=folder.category,
                tags=[],
                has_usable_preview=False,
                content_type="other",
                is_junk=False,
                junk_reason=None,
                confidence=0.0,
                action="skip",
                notes="",
                sensitive=False,
                nudenet={},
                thumb_path=None,
                error=f"{e}\n{traceback.format_exc()[-500:]}",
            )

    decisions = []
    with ThreadPoolExecutor(max_workers=curate.workers) as ex:
        futs = {ex.submit(job, f): f for f in folders}
        done = 0
        for fut in as_completed(futs):
            d = fut.result()
            decisions.append(d)
            done += 1
            if done % 5 == 0 or done == len(folders):
                print(f"  decided {done}/{len(folders)} …", flush=True)

    decisions.sort(key=lambda d: d.source_path.lower())

    with decisions_path.open("w", encoding="utf-8") as fh:
        for d in decisions:
            fh.write(json.dumps(d.to_dict(), ensure_ascii=False) + "\n")
    print(f"Wrote decisions: {decisions_path}")

    moved = kept = skipped = errors = 0
    with log_path.open("w", encoding="utf-8") as log_fh, audit_path.open(
        "w", encoding="utf-8"
    ) as audit_fh:
        log_fh.write(f"run={run_id} apply={args.apply} mode=organize\n")
        for d in decisions:
            rec = apply_decision(curate, d, do_apply=args.apply, log_fh=log_fh)
            audit_fh.write(json.dumps(rec, ensure_ascii=False) + "\n")
            if rec.get("error") and not rec.get("applied"):
                errors += 1
            elif rec.get("applied") or (
                not args.apply and rec.get("dest") and not rec.get("skipped_reason")
            ):
                moved += 1
            elif rec.get("skipped_reason") in {None, "no_move_needed"} and rec.get("action") == "keep":
                kept += 1
            else:
                skipped += 1

    summary = {
        "run_id": run_id,
        "mode": "organize",
        "library": curate.library_root,
        "apply": args.apply,
        "folders": len(folders),
        "decisions": len(decisions),
        "moves_or_planned": moved,
        "kept": kept,
        "skipped": skipped,
        "errors": errors,
        "decisions_path": str(decisions_path),
        "audit_path": str(audit_path),
        "log_path": str(log_path),
    }
    summary_path = work / f"summary-{run_id}.json"
    summary_path.write_text(json.dumps(summary, indent=2), encoding="utf-8")
    print(json.dumps(summary, indent=2))
    print(
        "\nNext: review decisions JSONL, then re-run with --apply to rearrange.\n"
        "Then in Manyfold: Scan for new files / Detect filesystem changes."
    )
    return 0 if errors == 0 else 2


def run_match(args: argparse.Namespace, curate: CurateConfig) -> int:
    """MODE=match — zip infolist → archive-index / archive-invert JSONL (no extract)."""
    work = curate.resolved_work_dir()
    work.mkdir(parents=True, exist_ok=True)
    run_id = time.strftime("%Y%m%d-%H%M%S")
    max_members = max(1, int(args.max_archive_members))

    print(f"Library:  {curate.library_root}")
    print(f"Work dir: {work}")
    print(f"Mode:     match (archive-index; no ZipFile.read)")
    print(f"Max members/zip: {max_members}")

    result = run_archive_match(
        curate,
        max_members_per_archive=max_members,
        run_id=run_id,
    )
    summary = {
        "run_id": run_id,
        **archive_match_summary(result),
        "library": curate.library_root,
        "max_archive_members": max_members,
    }
    summary_path = work / f"archive-match-summary-{run_id}.json"
    summary_path.write_text(json.dumps(summary, indent=2), encoding="utf-8")
    print(json.dumps(summary, indent=2))
    print(
        "\nArchive index ready for merge pre-pass (INIT-018/SPEC-005).\n"
        "Index artifacts use archive-index-* / archive-invert-* under .spark-curate/."
    )
    return 0


def run_merge(args: argparse.Namespace, spark: SparkConfig, curate: CurateConfig) -> int:
    work = curate.resolved_work_dir()
    work.mkdir(parents=True, exist_ok=True)
    thumb_cache = work / "thumbs"
    thumb_cache.mkdir(exist_ok=True)
    run_id = time.strftime("%Y%m%d-%H%M%S")
    log_path = work / f"merge-run-{run_id}.log"

    print(f"Library:  {curate.library_root}")
    print(f"Work dir: {work}")
    print(f"Mode:     merge {'APPLY(queue pending)' if args.apply else 'DRY-RUN'}")
    print(f"MERGE_HITL: {curate.merge_hitl}")
    print(f"Min merge conf: {curate.min_merge_confidence}")
    print(f"Max pairs: {curate.max_merge_pairs}")
    print(f"Workers:  {curate.workers}")

    # Merge pre-pass: inverted archive postings → build_merge_candidates (INIT-018/SPEC-005)
    max_members = max(1, int(getattr(args, "max_archive_members", 5000) or 5000))
    archive = build_archive_index(
        curate,
        max_members_per_archive=max_members,
        write_artifacts=True,
        run_id=run_id,
    )
    print(
        f"Archive index: zips={archive.zips_scanned} "
        f"mesh_sigs={len(archive.inverted_mesh)} "
        f"truncated={archive.zips_truncated}"
    )
    candidates = build_merge_candidates(
        curate,
        max_pairs=curate.max_merge_pairs,
        archive_index=archive,
        scan_archives=False,
    )
    print(f"Found {len(candidates)} merge candidate pairs")
    if not candidates:
        print("Nothing to do.")
        return 0

    decisions = []
    with ThreadPoolExecutor(max_workers=curate.workers) as ex:
        futs = {
            ex.submit(decide_merge_pair_safe, c, spark, curate, thumb_cache): c
            for c in candidates
        }
        done = 0
        for fut in as_completed(futs):
            decisions.append(fut.result())
            done += 1
            if done % 5 == 0 or done == len(candidates):
                print(f"  decided {done}/{len(candidates)} …", flush=True)

    decisions.sort(key=lambda d: (d.rel_a.lower(), d.rel_b.lower()))

    with log_path.open("w", encoding="utf-8") as log_fh:
        log_fh.write(
            f"run={run_id} apply={args.apply} mode=merge "
            f"merge_hitl={curate.merge_hitl} "
            f"min_merge_confidence={curate.min_merge_confidence}\n"
        )
        result = write_merge_plans(
            curate,
            decisions,
            do_apply=args.apply,
            run_id=run_id,
            log_fh=log_fh,
        )

    merge_n = sum(1 for d in decisions if d.decision == "merge")
    approved = sum(1 for d in decisions if d.approved_for_apply)
    summary = {
        "run_id": run_id,
        "mode": "merge",
        "library": curate.library_root,
        "apply": args.apply,
        "candidates": len(candidates),
        "merge_suggested": merge_n,
        "approved_ge_threshold": approved,
        "log_path": str(log_path),
        **result,
    }
    summary_path = work / f"merge-summary-{run_id}.json"
    summary_path.write_text(json.dumps(summary, indent=2), encoding="utf-8")
    print(json.dumps(summary, indent=2))
    print(
        "\nNext: review merges-*.jsonl. Under MERGE_HITL=hitl_all, APPLY queues nothing "
        "(plans only). hitl_uncertain auto-queues STRONG; hitl_off also UNCERTAIN when "
        "approved. Pending → Manyfold:\n"
        "  rake manyfold:apply_spark_merges\n"
        "Same character alone never merges; structural signals + vision gate apply."
    )
    return 0 if result.get("errors", 0) == 0 else 2


def run_archive_recall(args: argparse.Namespace, curate: CurateConfig) -> int:
    """MODE=archive-recall — batch libarchive listing + library archive_entries recall."""
    from spark_curate.library_members import load_library_members_index
    from spark_curate.manyfold_client import ManyfoldClient

    batch_root = args.batch_root or curate.library_root
    work = Path(curate.work_dir) if curate.work_dir else Path(batch_root) / ".spark-curate"
    work.mkdir(parents=True, exist_ok=True)
    run_id = time.strftime("%Y%m%d-%H%M%S")
    max_members = max(1, int(args.max_archive_members))
    workers = max(1, int(getattr(args, "workers", None) or 1))

    print(f"Batch:    {batch_root}")
    print(f"Work dir: {work}")
    print(f"Mode:     archive-recall (listing only; INIT-021/SPEC-006)")
    print(f"Workers:  {workers} (NFS archive open cap)")
    if args.slice_top:
        print(f"Slice:    {args.slice_top}")

    client = ManyfoldClient(timeout=180.0)
    library_index = load_library_members_index(client)
    result = run_cross_root_archive_recall(
        batch_root=batch_root,
        work_dir=work,
        library_index=library_index,
        max_members_per_archive=max_members,
        slice_top=args.slice_top,
        run_id=run_id,
    )
    print(json.dumps(json.loads(Path(result.summary_path or "").read_text()), indent=2))
    return 0


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)

    if args.write_example_config:
        path = Path(args.write_example_config)
        save_example_config(path)
        print(f"Wrote {path}")
        return 0

    spark, curate = load_config(args.config)
    if args.library:
        curate.library_root = args.library
    if args.work_dir:
        curate.work_dir = args.work_dir
    if getattr(args, "batch_root", None):
        curate.library_root = args.batch_root
    if args.limit:
        curate.limit = args.limit
    if args.categories:
        curate.only_categories = args.categories
    if args.workers is not None:
        curate.workers = max(1, args.workers)
    if args.min_confidence is not None:
        curate.min_confidence = args.min_confidence
    if args.min_merge_confidence is not None:
        curate.min_merge_confidence = args.min_merge_confidence
    if args.max_merge_pairs is not None:
        curate.max_merge_pairs = max(1, args.max_merge_pairs)
    if args.merge_hitl is not None:
        curate.merge_hitl = args.merge_hitl
    # Fail loud on invalid MERGE_HITL before any library work (INIT-018/SPEC-006)
    curate.merge_hitl = curate.validated_merge_hitl()
    if args.skip_good:
        curate.skip_if_has_preview_and_known_category = True

    if args.smoke:
        return smoke(spark)

    if args.mode == "match":
        return run_match(args, curate)
    if args.mode == "archive-recall":
        return run_archive_recall(args, curate)
    if args.mode == "merge":
        return run_merge(args, spark, curate)
    if args.mode == "unorganize":
        return run_unorganize_cli(args, curate)
    if args.mode == "classify":
        return run_classify_cli(args, spark, curate)
    if args.mode == "admit":
        return run_admit_cli(args, spark, curate)
    return run_organize(args, spark, curate)


if __name__ == "__main__":
    raise SystemExit(main())
