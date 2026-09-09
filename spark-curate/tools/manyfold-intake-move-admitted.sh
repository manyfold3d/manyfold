#!/usr/bin/env bash
# Slice-scoped move of verdict=new packs from Unorg → library Category/Pack.
#
# Defaults to --dry-run. Writes the reverse manifest BEFORE the first mv/cp.
# Resumable via .spark-curate/move-complete/<slice>/<rel>.done markers.
# --copy is the safer first slice (retains Unorg).
#
# Does NOT execute against Mega. Does NOT run APPLY=1 library promote.
# Free-space / inode check aborts with a typed error if margins are thin.
#
# Usage:
#   manyfold-intake-move-admitted.sh --admissions FILE --slice NAME
#       [--intake BATCH] [--library DEST] [--dry-run|--apply] [--copy]
#
# Provenance: INIT-021/SPEC-010
# Operator share: /mnt/k8s-argocd/skills/scripts/manyfold-intake-move-admitted.sh

set -euo pipefail

ADMISSIONS=""
SLICE=""
INTAKE="${INTAKE:-/mnt/backups/3D-Prints-Unorg/intake/2026-08-drive-mega}"
LIBRARY="${LIBRARY:-/mnt/backups/3D-Prints}"
DRY_RUN=1
COPY=0
WORK_DIR=""
# Overridable for fixture tests (INIT-021/SPEC-011). Production default 2 TiB.
FLOOR_BYTES="${FLOOR_BYTES:-$((2 * 1024 * 1024 * 1024 * 1024))}"
MIN_INODES="${MIN_INODES:-10000}"

usage() {
  cat <<'EOF'
Usage: manyfold-intake-move-admitted.sh --admissions FILE --slice NAME [options]

Move (or --copy) verdict=new packs for one slice. Default is --dry-run.

  --admissions FILE   admissions-*.jsonl (SPEC-008 record)
  --slice NAME        Slice prefix matched against rel_pack_root (required)
  --intake DIR        Google batch root (default: 2026-08-drive-mega)
  --library DIR       Live library root (move destination after unfreeze)
  --work-dir DIR      Where reverse manifest + markers land (default: batch .spark-curate)
  --dry-run           Print planned moves; write reverse manifest draft (default)
  --apply             Perform mv or cp. Requires unfreeze-approved-<slice> (D-7). Not for Mega.
  --copy              Safer first slice: copy, retain Unorg (documented default for slice 1)
  -h, --help

Reverse manifest is written BEFORE the first filesystem change so a slice
can be undone: `while read src dest; do mv "$dest" "$src"; done < reverse`.

Typed abort: insufficient_space | insufficient_inodes | mega_frozen |
library_jail | intake_jail | unfreeze_missing
EOF
}

log() { printf '[%s] %s\n' "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "$1"; }
die() { log "ERROR: $1" >&2; exit "${2:-1}"; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --admissions) ADMISSIONS="$2"; shift 2 ;;
    --slice) SLICE="$2"; shift 2 ;;
    --intake) INTAKE="$2"; shift 2 ;;
    --library) LIBRARY="$2"; shift 2 ;;
    --work-dir) WORK_DIR="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --apply) DRY_RUN=0; shift ;;
    --copy) COPY=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown arg: $1" ;;
  esac
done

[[ -n "$ADMISSIONS" ]] || die " --admissions is required"
[[ -n "$SLICE" ]] || die " --slice is required (slice-scoped; refuse whole-batch apply)"
[[ -f "$ADMISSIONS" ]] || die "admissions file not found: $ADMISSIONS"
[[ -d "$INTAKE" ]] || die "intake batch not found: $INTAKE"

case "$INTAKE" in
  */intake/Mega|*/intake/Mega/*|*/2026-09-mega|*/2026-09-mega/*)
    die "mega_frozen: refusing move from Mega / 2026-09-mega (INIT-018)"
    ;;
esac

WORK_DIR="${WORK_DIR:-${INTAKE}/.spark-curate}"
mkdir -p "$WORK_DIR/move-complete/${SLICE//\//_}" "$WORK_DIR/move-manifests"

# Free space + inodes (typed abort). NFS may report 0 inodes — record, do not invent.
SPACE_JSON="$(python3 - "$INTAKE" "$LIBRARY" "$FLOOR_BYTES" "$MIN_INODES" <<'PY'
import os, json, sys
intake, library, floor, min_inodes = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4])
st = os.statvfs(intake)
avail = st.f_bavail * st.f_frsize
inodes = st.f_ffree
out = {
    "mount": intake,
    "avail_bytes": avail,
    "inodes_free": inodes,
    "inodes_total": st.f_files,
    "floor_bytes": floor,
    "inodes_reported": inodes > 0 or st.f_files > 0,
}
if avail < floor:
    out["error"] = "insufficient_space"
    print(json.dumps(out))
    sys.exit(1)
if out["inodes_reported"] and inodes < min_inodes:
    out["error"] = "insufficient_inodes"
    print(json.dumps(out))
    sys.exit(1)
print(json.dumps(out))
PY
)" || die "insufficient_space or insufficient_inodes: $SPACE_JSON"
log "space-check: $SPACE_JSON"

# Plan rows: verdict=new, rel_pack_root under --slice, destination jailed Category/Pack.
PLAN_JSONL="$(mktemp)"
trap 'rm -f "$PLAN_JSONL"' EXIT
python3 - "$ADMISSIONS" "$SLICE" "$INTAKE" "$LIBRARY" "$PLAN_JSONL" <<'PY'
import json, sys
from pathlib import Path

def _under(path: Path, jail: Path) -> bool:
    """Containment — not startswith (avoids 3D-Prints vs 3D-Prints-Unorg)."""
    try:
        pr = path.resolve()
        jr = jail.resolve()
    except OSError:
        return False
    return pr == jr or pr.is_relative_to(jr)

def _two_seg(rel: str) -> bool:
    if not rel or any(ord(c) < 32 or ord(c) == 127 for c in rel):
        return False
    parts = rel.replace("\\", "/").split("/")
    if len(parts) != 2:
        return False
    return all(p and p not in {".", ".."} for p in parts)

adm, slice_name, intake, library, out_path = sys.argv[1:6]
intake_p = Path(intake).resolve()
library_p = Path(library).resolve()
n = 0
with open(adm, encoding="utf-8") as fh, open(out_path, "w", encoding="utf-8") as out:
    for line in fh:
        line = line.strip()
        if not line:
            continue
        rec = json.loads(line)
        if rec.get("verdict") != "new":
            continue
        rel = (rec.get("rel_pack_root") or "").replace("\\", "/")
        dest_rel = rec.get("destination") or ""
        slice_n = slice_name.replace("\\", "/").strip("/")
        if not (rel == slice_n or rel.startswith(slice_n + "/") or f"/{slice_n}/" in f"/{rel}/"):
            continue
        src = Path(rec.get("source_path") or (intake_p / rel))
        if not _two_seg(dest_rel):
            print(f"ERROR: dest not jailed Category/Pack: {dest_rel!r}", file=sys.stderr)
            sys.exit(2)
        dest = library_p / dest_rel
        try:
            src_r = src.resolve()
        except OSError:
            src_r = src
        if "intake/Mega" in str(src_r).replace("\\", "/"):
            print("ERROR: mega_frozen: source under intake/Mega", file=sys.stderr)
            sys.exit(2)
        if not _under(src_r, intake_p):
            print(f"ERROR: intake_jail: {src_r}", file=sys.stderr)
            sys.exit(2)
        if not _under(dest, library_p):
            print(f"ERROR: library_jail: {dest}", file=sys.stderr)
            sys.exit(2)
        out.write(json.dumps({"src": str(src_r), "dest": str(dest), "rel": rel, "dest_rel": dest_rel}) + "\n")
        n += 1
print(f"planned={n}", file=sys.stderr)
PY

SLICE_KEY="${SLICE//\//_}"
RUN_ID="$(date -u +"%Y%m%d-%H%M%S")"
REVERSE="${WORK_DIR}/move-manifests/reverse-${SLICE_KEY}-${RUN_ID}.tsv"
# Reverse manifest BEFORE first change (ac-6).
{
  echo "# reverse manifest INIT-021/SPEC-010 slice=${SLICE} copy=${COPY} dry_run=${DRY_RUN}"
  echo "# replay undo: while IFS=$'\t' read -r dest src; do [[ \$dest == \#* ]] && continue; mv -- \"\$dest\" \"\$src\"; done"
  echo "# columns: dest<TAB>src  (undo is dest → src)"
  while IFS= read -r row; do
    python3 -c 'import json,sys; r=json.loads(sys.argv[1]); print(r["dest"]+"\t"+r["src"])' "$row"
  done < "$PLAN_JSONL"
} >"$REVERSE"
log "reverse manifest written (before any mv): $REVERSE"

# D-7 box 8 / INIT-021/SPEC-011 — --apply refuses without a written unfreeze record.
UNFREEZE_RECORD="${UNFREEZE_RECORD:-${WORK_DIR}/unfreeze-approved-${SLICE_KEY}}"
if [[ "$DRY_RUN" -eq 0 ]]; then
  [[ -s "$UNFREEZE_RECORD" ]] || die "unfreeze_missing: write $UNFREEZE_RECORD (D-7 box 8) before --apply"
fi

MARKER_DIR="${WORK_DIR}/move-complete/${SLICE_KEY}"
moved=0
skipped=0
while IFS= read -r row; do
  src="$(python3 -c 'import json,sys; print(json.loads(sys.argv[1])["src"])' "$row")"
  dest="$(python3 -c 'import json,sys; print(json.loads(sys.argv[1])["dest"])' "$row")"
  rel="$(python3 -c 'import json,sys; print(json.loads(sys.argv[1])["rel"])' "$row")"
  marker="${MARKER_DIR}/$(python3 -c 'import hashlib,sys; print(hashlib.sha256(sys.argv[1].encode()).hexdigest()[:16])' "$rel").done"
  if [[ -f "$marker" ]]; then
    log "resume skip (marker): $rel"
    skipped=$((skipped + 1))
    continue
  fi
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "dry-run: would $([[ "$COPY" -eq 1 ]] && echo copy || echo mv) $src -> $dest"
    continue
  fi
  mkdir -p "$(dirname "$dest")"
  if [[ "$COPY" -eq 1 ]]; then
    cp -a -- "$src" "$dest"
  else
    mv -- "$src" "$dest"
  fi
  printf '%s\n' "$rel" >"$marker"
  moved=$((moved + 1))
done < "$PLAN_JSONL"

log "slice=$SLICE dry_run=$DRY_RUN copy=$COPY moved=$moved skipped=$skipped reverse=$REVERSE"
echo "REVERSE_MANIFEST=$REVERSE"
echo "PLANNED_JSONL=$PLAN_JSONL"
