#!/bin/bash
# templates.sh — List available server-side templates.
# Usage:
#   ./templates.sh backgrounds          # list all background templates (grouped)
#   ./templates.sh backgrounds <key>    # one background template
#   ./templates.sh in-action            # list all "in action" templates
#   ./templates.sh in-action <key>      # one in-action template

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./common.sh
source "$SCRIPT_DIR/common.sh"

KIND="${1:-}"
KEY="${2:-}"

if [[ -z "$KIND" || "$KIND" == "--help" ]]; then
  echo "Usage: $0 backgrounds|in-action [key]"
  exit 0
fi

load_config

case "$KIND" in
  backgrounds)
    if [[ -z "$KEY" ]]; then
      api_request GET /v1/templates/backgrounds
    else
      api_request GET "/v1/templates/backgrounds/$KEY"
    fi
    ;;
  in-action)
    if [[ -z "$KEY" ]]; then
      api_request GET /v1/templates/in-action
    else
      api_request GET "/v1/templates/in-action/$KEY"
    fi
    ;;
  *)
    echo "Unknown kind: $KIND (use backgrounds or in-action)" >&2
    exit 1
    ;;
esac
echo
