#!/bin/bash
# upscale.sh — Upscale an image.
# Usage: ./upscale.sh <image_path_or_url> [timeout]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./common.sh
source "$SCRIPT_DIR/common.sh"

IMG="${1:-}"
TIMEOUT="${2:-600}"

if [[ -z "$IMG" || "$IMG" == "--help" ]]; then
  echo "Usage: $0 <image_path_or_url> [timeout=600]"
  exit 0
fi

ensure_jq
load_config

local_path=$(resolve_image "$IMG")
b64=$(encode_image "$local_path")
hook=$(default_hook_url)

body=$(compose_body "$b64" '{main_image:$img, hook_url:$hook}' --arg hook "$hook")
"$SCRIPT_DIR/run.sh" /v1/images/upscale "$body" "$TIMEOUT"
