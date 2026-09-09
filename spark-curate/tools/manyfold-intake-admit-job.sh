#!/usr/bin/env bash
# Bake an Unorg intake Job (unorganize / classify / archive-recall / admit / promote).
# Env is immutable at kubectl apply. Never kubectl set env after create.
# Never retargets weekly CronJob spark-curate (stays organize on PVC 3d-prints /library).
#
# Usage:
#   manyfold-intake-admit-job.sh [--dry-run|--apply-job] [--mode MODE]
#                                [--slice NAME] [--job-name NAME] [--batch ID]
#
# Defaults (fail-secure): MODE=unorganize APPLY=0 MERGE_HITL=hitl_all
#   LIBRARY_ROOT=/intake (CronJob subPath = the Google batch) WORKERS=1
#
# Primary batch: 2026-08-drive-mega (Google). Mega is FROZEN — do not --apply-job
# against intake/Mega or batch 2026-09-mega without a written unfreeze record.
#
# Provenance: INIT-021/SPEC-010
# Operator share: /mnt/k8s-argocd/skills/scripts/manyfold-intake-admit-job.sh

set -euo pipefail

NS="${NS:-manyfold}"
JOB_NAME="${JOB_NAME:-spark-curate-intake-admit}"
DRY_RUN=1
APPLY_JOB=0
APPLY="${APPLY:-0}"
MODE="${MODE:-unorganize}"
MERGE_HITL="${MERGE_HITL:-hitl_all}"
LIBRARY_ROOT="${LIBRARY_ROOT:-/intake}"
SLICE="${SLICE:-}"
WORKERS="${WORKERS:-1}"
BATCH="${BATCH:-2026-08-drive-mega}"
PLAN="${PLAN:-}"
PATHS_FILE="${PATHS_FILE:-}"
OUT_JSON="${OUT_JSON:-/tmp/${JOB_NAME}.json}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BAKE_PY="${BAKE_PY:-${SCRIPT_DIR}/bake_intake_job.py}"

usage() {
  cat <<'EOF'
Usage: manyfold-intake-admit-job.sh [options]

Bake a NEW Job from cronjob/spark-curate-intake with env frozen at apply.
Do not kubectl set env after create. Do not retarget weekly CronJob spark-curate.

  --dry-run         kubectl create --dry-run=client only (default); write JSON
  --apply-job       kubectl apply the baked Job (still APPLY=0 unless --apply)
  --apply           Bake APPLY=1 (intake tree only; requires plans reviewed)
  --mode MODE       unorganize|classify|archive-recall|admit|promote
  --slice NAME      Named slice (unorganize-slice / slice-top)
  --job-name NAME   New name per env change (default: spark-curate-intake-admit)
  --batch ID        Default: 2026-08-drive-mega (Google). Not Mega.
  --library-root P  Cluster batch mount. Default /intake. Never /library|/models
  --merge-hitl M    Default hitl_all
  --workers N       Default 1
  --plan PATH       classify/admit --plan
  --paths-file PATH promote --paths-file
  --out PATH        Baked Job JSON
  -h, --help

Forbidden:
  - kubectl set env on a created Job
  - LIBRARY_ROOT=/library, /models, or /mnt/backups/3D-Prints
  - Retargeting weekly CronJob spark-curate
  - APPLY=1 library promote (this script never sets that)
  - Baking a Mega unfreeze Job from this wrapper

Vault (path name only): kv/apps/production/ibhacked-us/manyfold-intake
EOF
}

log() { printf '[%s] %s\n' "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "$1"; }
die() { log "ERROR: $1" >&2; exit "${2:-1}"; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; APPLY_JOB=0; shift ;;
    --apply-job) APPLY_JOB=1; DRY_RUN=0; shift ;;
    --apply) APPLY=1; shift ;;
    --mode) MODE="$2"; shift 2 ;;
    --slice) SLICE="$2"; shift 2 ;;
    --job-name) JOB_NAME="$2"; OUT_JSON="/tmp/${JOB_NAME}.json"; shift 2 ;;
    --batch) BATCH="$2"; shift 2 ;;
    --library-root) LIBRARY_ROOT="$2"; shift 2 ;;
    --merge-hitl) MERGE_HITL="$2"; shift 2 ;;
    --workers) WORKERS="$2"; shift 2 ;;
    --plan) PLAN="$2"; shift 2 ;;
    --paths-file) PATHS_FILE="$2"; shift 2 ;;
    --out) OUT_JSON="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown arg: $1" ;;
  esac
done

if [[ "$BATCH" == "2026-09-mega" || "$BATCH" == "Mega" || "$SLICE" == Mega || "$SLICE" == Mega/* ]]; then
  die "Mega batch is FROZEN (INIT-018). Do not bake a Mega Job. Google batch only."
fi

command -v kubectl >/dev/null 2>&1 || die "kubectl not found"
command -v python3 >/dev/null 2>&1 || die "python3 required to bake Job env"
[[ -f "$BAKE_PY" ]] || die "bake_intake_job.py not found at $BAKE_PY"

log "Baking Job $JOB_NAME from cronjob/spark-curate-intake (MODE=$MODE APPLY=$APPLY SLICE=$SLICE BATCH=$BATCH WORKERS=$WORKERS)"

kubectl create job -n "$NS" "$JOB_NAME" --from=cronjob/spark-curate-intake --dry-run=client -o json \
  >"$OUT_JSON"

python3 "$BAKE_PY" "$OUT_JSON" \
  --name "$JOB_NAME" \
  --namespace "$NS" \
  --mode "$MODE" \
  --apply "$APPLY" \
  --merge-hitl "$MERGE_HITL" \
  --library-root "$LIBRARY_ROOT" \
  --slice "$SLICE" \
  --workers "$WORKERS" \
  --batch "$BATCH" \
  --plan "$PLAN" \
  --paths-file "$PATHS_FILE"

if [[ "$DRY_RUN" -eq 1 ]]; then
  log "dry-run: Job JSON at $OUT_JSON (not applied). New Job name required for any env change."
  echo "JOB_JSON=$OUT_JSON"
  exit 0
fi

if [[ "$APPLY_JOB" -eq 1 ]]; then
  kubectl apply -f "$OUT_JSON"
  log "applied Job $JOB_NAME — bake was immutable (do not kubectl set env after create)"
  echo "JOB_JSON=$OUT_JSON"
  echo "Follow logs: kubectl logs -n $NS job/$JOB_NAME -f"
fi
