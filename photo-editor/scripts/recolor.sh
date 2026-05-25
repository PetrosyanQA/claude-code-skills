#!/bin/bash
# recolor.sh — Recolor product to a target hex color.
# Usage: ./recolor.sh <image> <#RRGGBB> [model=model_2] [aspect_ratio=1:1] [timeout=600]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./common.sh
source "$SCRIPT_DIR/common.sh"

IMG="${1:-}"
COLOR="${2:-}"
MODEL="${3:-model_2}"
ASPECT="${4:-1:1}"
TIMEOUT="${5:-600}"

if [[ -z "$IMG" || -z "$COLOR" || "$IMG" == "--help" ]]; then
  echo "Usage: $0 <image> <#RRGGBB> [model=model_2] [aspect_ratio=1:1] [timeout=600]"
  exit 0
fi

ensure_jq
load_config

local_path=$(resolve_image "$IMG")
b64=$(encode_image "$local_path")
hook=$(default_hook_url)

MODEL=$(resolve_model "$MODEL")
body=$(compose_body "$b64" \
  '{main_image:$img, hook_url:$hook, model:$model, aspect_ratio:$ar, color_code:$color}' \
  --arg hook "$hook" --arg model "$MODEL" --arg ar "$ASPECT" --arg color "$COLOR")

"$SCRIPT_DIR/run.sh" /v1/images/recolor "$body" "$TIMEOUT"
