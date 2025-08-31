#!/usr/bin/env bash
set -euo pipefail

# Run the manual -> JSON scan using the local LLM and write results
# into a dated subdirectory under /tmp/algorithms.
#
# Usage examples:
#   bash scripts/run_manual_scan.sh
#   bash scripts/run_manual_scan.sh --only-guid vcop
#   LLM_URL=http://dev.local:1234/v1 bash scripts/run_manual_scan.sh
#   LLM_MODEL=my-model bash scripts/run_manual_scan.sh --overwrite
#   DRY_RUN=1 bash scripts/run_manual_scan.sh   # write fragments only
#
# Environment variables:
#   LLM_URL   - Base URL for OpenAI-compatible API (default: http://dev.local:1234/v1)
#   LLM_MODEL - Preferred model id (default: local-model; will auto-resolve if not present)
#   MANUAL    - Path to the manual (default: docs/manual-1.10.0.md)
#   OUT_ROOT  - Root output directory (default: /tmp/algorithms)
#   DRY_RUN   - If set to 1, only extract fragments, skip LLM calls (default: 0)

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
MANUAL_PATH=${MANUAL:-"${ROOT_DIR}/docs/manual-1.10.0.md"}
BASE_URL=${LLM_URL:-"http://dev.local:1234/v1"}
MODEL=${LLM_MODEL:-"local-model"}
OUT_ROOT=${OUT_ROOT:-"/tmp/algorithms"}
TS=$(date +%Y%m%d-%H%M%S)
OUT_DIR="${OUT_ROOT}/${TS}"
DRY_RUN_FLAG=${DRY_RUN:-0}

echo "Manual:   ${MANUAL_PATH}"
echo "LLM URL:  ${BASE_URL}"
echo "Model:    ${MODEL} (will auto-resolve if unavailable)"
echo "Output:   ${OUT_DIR}"

# Ensure venv with requests
if [[ ! -d "${ROOT_DIR}/.venv" ]]; then
  echo "Creating venv at .venv ..."
  python3 -m venv "${ROOT_DIR}/.venv"
fi
source "${ROOT_DIR}/.venv/bin/activate"
python - <<'PY' >/dev/null 2>&1 || pip install --upgrade pip requests >/dev/null
import requests
PY

mkdir -p "${OUT_DIR}"

# Optional: probe models endpoint and show available models
echo "Probing ${BASE_URL}/models ..."
python - "$BASE_URL" <<'PY' || true
import sys, json
import requests
base=sys.argv[1].rstrip('/')
url=f"{base}/models"
try:
    r=requests.get(url, timeout=10)
    if r.status_code==200:
        data=r.json()
        models=[m.get('id') for m in data.get('data',[]) if m.get('id')]
        print("Available models:", ", ".join(models) or "<none>")
    else:
        print(f"GET {url} ->", r.status_code, r.text[:200])
except Exception as e:
    print("Model probe error:", e)
PY

EXTRACTOR="${ROOT_DIR}/scripts/extract_algorithms_with_llm.py"
[[ -f "${EXTRACTOR}" ]] || { echo "Extractor not found: ${EXTRACTOR}"; exit 1; }

ARGS=(
  "--manual" "${MANUAL_PATH}"
  "--out-dir" "${OUT_DIR}"
  "--base-url" "${BASE_URL}"
  "--model" "${MODEL}"
)

if [[ "${DRY_RUN_FLAG}" == "1" ]]; then
  echo "Running in DRY RUN mode (fragments only)..."
  ARGS+=("--dry-run")
fi

echo "Running extractor ..."
python "${EXTRACTOR}" "${ARGS[@]}" "$@"

echo
echo "Done. Review outputs in: ${OUT_DIR}"
if [[ -d "${OUT_DIR}/fragments" ]]; then
  echo "Fragments (count): $(ls -1 "${OUT_DIR}/fragments" | wc -l)"
fi
if compgen -G "${OUT_DIR}/*.json" > /dev/null; then
  echo "JSON files (count): $(ls -1 "${OUT_DIR}"/*.json | wc -l)"
fi

