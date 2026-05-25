#!/bin/bash
# poll.sh — Wait for a Photo Editor task to finish, save outputs, print paths.
#
# Usage: ./poll.sh <event_id> [timeout_seconds=600] [interval_seconds=10]
#
# Side effects:
#   - Creates output/<event_id>/
#   - Saves images as image_1.png, image_2.png, ...
#   - Writes meta.json with the final webhook payload
#
# stdout (JSON):
#   {"status":"completed","event_id":"...","files":["/abs/path/image_1.png", ...], "kind":"image"}
#   {"status":"error|timeout","event_id":"...","error":"..."}

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./common.sh
source "$SCRIPT_DIR/common.sh"

EVENT_ID="${1:-}"
TIMEOUT="${2:-600}"
INTERVAL="${3:-10}"

if [[ -z "$EVENT_ID" || "$EVENT_ID" == "--help" ]]; then
  cat <<EOF
Usage: $0 <event_id> [timeout_seconds=600] [interval_seconds=10]

Polls POST /v1/images/status?event_id=<id> until completed/error/timeout.
Interval default: 10s. On success saves files into output/<event_id>/ and prints JSON with absolute paths.
EOF
  exit 0
fi

ensure_jq
load_config

mkdir -p "$OUTPUT_DIR/$EVENT_ID"
DIR="$OUTPUT_DIR/$EVENT_ID"

deadline=$(( $(date +%s) + TIMEOUT ))

while true; do
  resp=$(api_request POST "/v1/images/status?event_id=${EVENT_ID}" 2>/dev/null) || true
  msg=$(printf '%s' "$resp" | jq -r '.msg // empty' 2>/dev/null || true)

  case "$msg" in
    process_completed)
      printf '%s' "$resp" > "$DIR/meta.json"
      # Images: array of base64
      files_json="[]"
      i=1
      while IFS= read -r b64; do
        [[ -z "$b64" ]] && continue
        out="$DIR/image_${i}.png"
        printf '%s' "$b64" | base64 --decode > "$out"
        files_json=$(jq -nc --argjson cur "$files_json" --arg f "$out" '$cur + [$f]')
        i=$((i+1))
      done < <(printf '%s' "$resp" | jq -r '.output.image[]? // empty')
      jq -nc --arg id "$EVENT_ID" --argjson files "$files_json" \
        '{status:"completed", event_id:$id, kind:"image", files:$files}'
      exit 0
      ;;
    process_error|process_timeout)
      printf '%s' "$resp" > "$DIR/meta.json"
      err=$(printf '%s' "$resp" | jq -r '.error.message // .error // "unknown"')
      jq -nc --arg id "$EVENT_ID" --arg s "$msg" --arg e "$err" \
        '{status:$s, event_id:$id, error:$e}'
      exit 1
      ;;
    process_starts|process_waiting|process_generating|"")
      :
      ;;
    *)
      # Unknown msg — keep polling but show it
      echo "[poll] unknown msg: $msg" >&2
      ;;
  esac

  now=$(date +%s)
  if (( now >= deadline )); then
    jq -nc --arg id "$EVENT_ID" '{status:"timeout", event_id:$id, error:"Local poll timeout"}'
    exit 1
  fi
  sleep "$INTERVAL"
done
