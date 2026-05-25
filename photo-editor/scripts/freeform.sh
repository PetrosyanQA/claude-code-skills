#!/bin/bash
# freeform.sh — Free-form prompt-based edit of an image.
# Usage:
#   ./freeform.sh <image_path_or_url> "<prompt>" [model=auto] [aspect_ratio=1:1] [refs=path1,path2,...] [timeout=600]
#
# model: model_1 | model_2 | model_3 | model_4 | model_5 | auto (default)
# aspect_ratio: 1:1 | 2:3 | 3:4 | 3:2 | 4:3
# refs: optional comma-separated list of reference images (paths or URLs)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./common.sh
source "$SCRIPT_DIR/common.sh"

IMG="${1:-}"
PROMPT="${2:-}"
MODEL_RAW="${3:-auto}"
ASPECT="${4:-1:1}"
REFS="${5:-}"
TIMEOUT="${6:-600}"

if [[ -z "$IMG" || -z "$PROMPT" || "$IMG" == "--help" ]]; then
  cat <<EOF
Usage: $0 <image_path_or_url> "<prompt>" [model=auto] [aspect_ratio=1:1] [refs=p1,p2,...] [timeout=600]

Models: model_1 model_2 model_3 model_4 model_5 auto
Aspect: 1:1 2:3 3:4 3:2 4:3
EOF
  exit 0
fi

ensure_jq
load_config

MODEL=$(resolve_model "$MODEL_RAW")
local_path=$(resolve_image "$IMG")
b64=$(encode_image "$local_path")
refs_json=$(encode_image_array "$REFS")
hook=$(default_hook_url)

body=$(compose_body "$b64" \
  '{main_image:$img, hook_url:$hook, model:$model, aspect_ratio:$ar, user_prompt:$prompt, reference_images:$refs}' \
  --arg hook "$hook" --arg model "$MODEL" --arg ar "$ASPECT" --arg prompt "$PROMPT" --argjson refs "$refs_json")

"$SCRIPT_DIR/run.sh" /v1/images/freeform "$body" "$TIMEOUT"
