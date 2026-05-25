#!/bin/bash
# replace-background.sh — Replace background using a server-side template.
# Usage:
#   ./replace-background.sh <image> <template_key> [model=model_2] [aspect_ratio=1:1] [user_prompt=""] [timeout=600]
#
# Get template_key from: GET /v1/templates/backgrounds (call once with curl, or via api_request).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./common.sh
source "$SCRIPT_DIR/common.sh"

IMG="${1:-}"
TEMPLATE="${2:-}"
MODEL="${3:-model_2}"
ASPECT="${4:-1:1}"
PROMPT="${5:-}"
TIMEOUT="${6:-600}"

if [[ -z "$IMG" || -z "$TEMPLATE" || "$IMG" == "--help" ]]; then
  cat <<EOF
Usage: $0 <image> <template_key> [model=model_2] [aspect_ratio=1:1] [user_prompt=""] [timeout=600]

To list templates:
  ./scripts/templates.sh backgrounds
EOF
  exit 0
fi

ensure_jq
load_config

local_path=$(resolve_image "$IMG")
b64=$(encode_image "$local_path")
hook=$(default_hook_url)

MODEL=$(resolve_model "$MODEL")
body=$(compose_body "$b64" \
  '{main_image:$img, hook_url:$hook, model:$model, aspect_ratio:$ar, template_key:$key} + (if $prompt == "" then {} else {user_prompt:$prompt} end)' \
  --arg hook "$hook" --arg model "$MODEL" --arg ar "$ASPECT" --arg key "$TEMPLATE" --arg prompt "$PROMPT")

"$SCRIPT_DIR/run.sh" /v1/images/replace-background "$body" "$TIMEOUT"
