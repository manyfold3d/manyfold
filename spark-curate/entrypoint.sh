#!/usr/bin/env bash
set -euo pipefail

# Standalone curator container entrypoint.
# Env (see .env.example) configures Spark endpoints and library policy.

export PYTHONPATH="/app:${PYTHONPATH:-}"

# Map common env overrides into CLI-friendly defaults via a generated config if needed.
CONFIG_PATH="${CONFIG_PATH:-/app/runtime-config.json}"

python - <<'PY'
import json, os
from pathlib import Path

spark = {
    "gemma_url": os.environ.get("GEMMA_URL", "http://192.168.11.161:11435/v1"),
    "gemma_model": os.environ.get("GEMMA_MODEL", "gemma4-uncensored"),
    "curator_url": os.environ.get("CURATOR_URL", "http://192.168.11.161:11436/v1"),
    "curator_model": os.environ.get("CURATOR_MODEL", "qwen2.5-1.5b-instruct"),
    "nudenet_url": os.environ.get("NUDENET_URL", "http://192.168.11.161:8090"),
    "embed_url": os.environ.get("EMBED_URL", "http://192.168.11.161:8000/v1"),
    "embed_model": os.environ.get("EMBED_MODEL", "BAAI/bge-m3"),
    "vision_timeout": float(os.environ.get("VISION_TIMEOUT", "180")),
    "curator_timeout": float(os.environ.get("CURATOR_TIMEOUT", "60")),
    "nudenet_timeout": float(os.environ.get("NUDENET_TIMEOUT", "30")),
    "max_tokens_vision": int(os.environ.get("MAX_TOKENS_VISION", "1200")),
    "max_tokens_curator": int(os.environ.get("MAX_TOKENS_CURATOR", "800")),
    "temperature": float(os.environ.get("TEMPERATURE", "0.15")),
}
curate = {
    "library_root": os.environ.get("LIBRARY_ROOT", "/library"),
    "work_dir": os.environ.get("WORK_DIR", ""),
    "min_confidence": float(os.environ.get("MIN_CONFIDENCE", "0.55")),
    "min_merge_confidence": float(os.environ.get("MIN_MERGE_CONFIDENCE", "0.80")),
    "max_merge_pairs": int(os.environ.get("MAX_MERGE_PAIRS", "200")),
    "merge_hitl": os.environ.get("MERGE_HITL", "hitl_all"),
    "never_delete": True,
    "workers": int(os.environ.get("WORKERS", "2")),
    "limit": int(os.environ.get("LIMIT", "0")),
    "only_categories": [c.strip() for c in os.environ.get("ONLY_CATEGORIES", "").split(",") if c.strip()],
    "skip_if_has_preview_and_known_category": os.environ.get("SKIP_GOOD", "0") in ("1", "true", "yes"),
    "nudenet_sensitive_threshold": float(os.environ.get("NUDENET_SENSITIVE_THRESHOLD", "0.6")),
    "max_image_edge": int(os.environ.get("MAX_IMAGE_EDGE", "1024")),
    "jpeg_quality": int(os.environ.get("JPEG_QUALITY", "85")),
}
path = Path(os.environ.get("CONFIG_PATH", "/app/runtime-config.json"))
path.write_text(json.dumps({"spark": spark, "curate": curate}, indent=2), encoding="utf-8")
print(f"Wrote {path}")
print(
    f"library_root={curate['library_root']} workers={curate['workers']} "
    f"min_confidence={curate['min_confidence']} mode={os.environ.get('MODE', 'organize')} "
    f"merge_hitl={curate['merge_hitl']}"
)
PY

# Loop mode: re-run periodically (seconds). 0 = run once and exit.
INTERVAL="${RUN_INTERVAL_SECONDS:-0}"

ARGS=("$@")

if [[ "${1:-}" == "smoke" ]]; then
  exec python -m spark_curate --config "${CONFIG_PATH}" --smoke
fi

# If user passed no args (or only image default), build from env.
if [[ ${#ARGS[@]} -eq 0 ]] || [[ "${ARGS[*]}" == "--library /library" ]]; then
  ARGS=(--library "${LIBRARY_ROOT:-/library}" --config "${CONFIG_PATH}")
  MODE="${MODE:-organize}"
  ARGS+=(--mode "${MODE}")
  if [[ -n "${LIMIT:-}" && "${LIMIT}" != "0" ]]; then
    ARGS+=(--limit "${LIMIT}")
  fi
  if [[ -n "${ONLY_CATEGORIES:-}" ]]; then
    IFS=',' read -ra CATS <<< "${ONLY_CATEGORIES}"
    for c in "${CATS[@]}"; do
      c="$(echo "$c" | xargs)"
      [[ -n "$c" ]] && ARGS+=(--category "$c")
    done
  fi
  if [[ "${SKIP_GOOD:-0}" == "1" || "${SKIP_GOOD:-}" == "true" ]]; then
    ARGS+=(--skip-good)
  fi
  if [[ -n "${MIN_MERGE_CONFIDENCE:-}" ]]; then
    ARGS+=(--min-merge-confidence "${MIN_MERGE_CONFIDENCE}")
  fi
  if [[ -n "${MAX_MERGE_PAIRS:-}" ]]; then
    ARGS+=(--max-merge-pairs "${MAX_MERGE_PAIRS}")
  fi
  if [[ -n "${PATHS_FILE:-}" ]]; then
    IFS=',' read -ra PFS <<< "${PATHS_FILE}"
    for pf in "${PFS[@]}"; do
      pf="$(echo "$pf" | xargs)"
      [[ -n "$pf" ]] && ARGS+=(--paths-file "$pf")
    done
  fi
  if [[ -n "${INTAKE:-}" ]]; then
    ARGS+=(--intake "${INTAKE}")
  fi
  if [[ "${PROMOTE_COPY:-0}" == "1" || "${PROMOTE_COPY:-}" == "true" ]]; then
    ARGS+=(--copy)
  fi
  if [[ -n "${WORK_DIR:-}" ]]; then
    ARGS+=(--work-dir "${WORK_DIR}")
  fi
  if [[ -n "${BATCH_ROOT:-}" ]]; then
    ARGS+=(--batch-root "${BATCH_ROOT}")
  fi
  if [[ -n "${PLAN:-}" ]]; then
    ARGS+=(--plan "${PLAN}")
  fi
  SLICE_VAL="${UNORGANIZE_SLICE:-${SLICE:-}}"
  if [[ -n "$SLICE_VAL" ]]; then
    IFS=',' read -ra SLICES <<< "$SLICE_VAL"
    for s in "${SLICES[@]}"; do
      s="$(echo "$s" | xargs)"
      [[ -n "$s" ]] && ARGS+=(--unorganize-slice "$s")
    done
  fi
  if [[ -n "${SLICE_TOP:-}" ]]; then
    ARGS+=(--slice-top "${SLICE_TOP}")
  fi
else
  has_config=0
  for a in "${ARGS[@]}"; do
    [[ "$a" == "--config" ]] && has_config=1
  done
  if [[ $has_config -eq 0 ]]; then
    ARGS+=(--config "${CONFIG_PATH}")
  fi
fi

# APPLY=1 always injects --apply unless already present
if [[ "${APPLY:-0}" == "1" || "${APPLY:-}" == "true" ]]; then
  has_apply=0
  for a in "${ARGS[@]}"; do
    [[ "$a" == "--apply" ]] && has_apply=1
  done
  [[ $has_apply -eq 0 ]] && ARGS+=(--apply)
fi

echo "[spark-curate] python -m spark_curate ${ARGS[*]}"

if [[ "${INTERVAL}" == "0" || -z "${INTERVAL}" ]]; then
  exec python -m spark_curate "${ARGS[@]}"
else
  echo "[spark-curate] loop every ${INTERVAL}s"
  while true; do
    python -m spark_curate "${ARGS[@]}" || echo "[spark-curate] run failed (exit $?) — will retry"
    echo "[spark-curate] sleeping ${INTERVAL}s"
    sleep "${INTERVAL}"
  done
fi
