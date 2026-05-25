#!/bin/bash
# run.sh — Universal Photo Editor caller. Submits a request and polls until done.
#
# Usage:
#   ./run.sh <endpoint_path> <body_json> [timeout]
#
# Example:
#   ./run.sh /v1/images/remove_background "$(jq -n --arg img "$(base64 < photo.jpg | tr -d '\n')" \
#       '{main_image:$img, hook_url:"https://example.com/x"}')"
#
# Returns final JSON from poll.sh.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./common.sh
source "$SCRIPT_DIR/common.sh"

ENDPOINT="${1:-}"
BODY="${2:-}"
TIMEOUT="${3:-600}"

if [[ -z "$ENDPOINT" || -z "$BODY" || "$ENDPOINT" == "--help" ]]; then
  cat <<EOF
Usage: $0 <endpoint_path> <body_json> [timeout=600]

Submits a Photo Editor request and polls /v1/images/status until completion.
Saves results into output/<event_id>/, prints a JSON summary with absolute file paths.
EOF
  exit 0
fi

ensure_jq
load_config

MAX_ATTEMPTS=3
attempt=0
event_id=""
while [[ $attempt -lt $MAX_ATTEMPTS ]]; do
  attempt=$(( attempt + 1 ))
  resp=$(api_request POST "$ENDPOINT" "$BODY" 2>/dev/null) || true
  event_id=$(printf '%s' "$resp" | jq -r '.event_id // empty' 2>/dev/null || true)
  if [[ -n "$event_id" ]]; then
    break
  fi
  # Print first line of error (avoids dumping full HTML 504 pages)
  err_line=$(printf '%s' "$resp" | head -1 | tr -d '\r')
  echo "[run] attempt $attempt/$MAX_ATTEMPTS failed: ${err_line:0:120}" >&2
done
if [[ -z "$event_id" ]]; then
  echo "[run] all $MAX_ATTEMPTS attempts failed" >&2
  exit 1
fi

echo "[run] submitted, event_id=$event_id, polling..." >&2
"$SCRIPT_DIR/poll.sh" "$event_id" "$TIMEOUT"
