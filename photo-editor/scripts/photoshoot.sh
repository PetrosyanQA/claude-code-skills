#!/bin/bash
# photoshoot.sh — Two-step photoshoot pipeline.
#
# Subcommands:
#   test     <image> "<prompt>" [model=model_1] [aspect=3:4] [refs=p1,...,p5] [timeout=600]
#   generate <approved_image> "<prompt>" <count> [model=model_1] [aspect=3:4] [timeout=900]
#   auto     <image> "<prompt>" <count> [model=model_1] [aspect=3:4] [refs=p1,...,p5]
#            (test → take first result → generate <count>; pass timeout via PHOTOSHOOT_TIMEOUT env)
#
# count: 1..6  |  refs: max 5 (test/auto only)
# Use case: generate a multi-shot product photoshoot for a marketplace seller.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./common.sh
source "$SCRIPT_DIR/common.sh"

CMD="${1:-}"
shift || true

usage() {
  cat <<EOF
Usage:
  $0 test     <image> "<prompt>" [model=model_1] [aspect=3:4] [refs=p1,...,p5] [timeout=600]
  $0 generate <approved_image> "<prompt>" <count> [model=model_1] [aspect=3:4] [timeout=900]
  $0 auto     <image> "<prompt>" <count> [model=model_1] [aspect=3:4] [refs=p1,...,p5]

count: 1..6  |  refs: max 5 (test/auto only)
EOF
}

case "$CMD" in
  ""|--help|-h|help)
    usage; exit 0 ;;
esac

ensure_jq
load_config

case "$CMD" in
  test)
    IMG="${1:?image required}"; PROMPT="${2:?prompt required}"
    MODEL=$(resolve_model "${3:-auto}"); ASPECT="${4:-3:4}"; REFS="${5:-}"; TIMEOUT="${6:-600}"
    if resolve_wb_input "$IMG" "$REFS"; then
      IMG="$WB_MAIN"; REFS="$WB_REFS"
      echo "[photoshoot] wb input expanded: main=$IMG refs=$REFS" >&2
    fi
    local_path=$(resolve_image "$IMG"); b64=$(encode_image "$local_path")
    refs_file=$(encode_image_array_file "$REFS"); hook=$(default_hook_url)
    body=$(compose_body "$b64" \
      '{main_image:$img, hook_url:$hook, model:$model, aspect_ratio:$ar, user_prompt:$p, reference_images:($refs|fromjson)}' \
      --arg hook "$hook" --arg model "$MODEL" --arg ar "$ASPECT" --arg p "$PROMPT" --rawfile refs "$refs_file")
    "$SCRIPT_DIR/run.sh" /v1/photoshoot/test "$body" "$TIMEOUT"
    ;;

  generate)
    IMG="${1:?approved image required}"; PROMPT="${2:?prompt required}"; COUNT="${3:?count required}"
    MODEL=$(resolve_model "${4:-auto}"); ASPECT="${5:-3:4}"; TIMEOUT="${6:-900}"
    if [[ "$COUNT" -gt 6 ]]; then echo "error: image_count max is 6 (got $COUNT)" >&2; exit 1; fi
    local_path=$(resolve_image "$IMG"); b64=$(encode_image "$local_path")
    hook=$(default_hook_url)
    body=$(compose_body "$b64" \
      '{main_image:$img, hook_url:$hook, model:$model, aspect_ratio:$ar, user_prompt:$p, image_count:$count}' \
      --arg hook "$hook" --arg model "$MODEL" --arg ar "$ASPECT" --arg p "$PROMPT" --argjson count "$COUNT")
    result=$("$SCRIPT_DIR/run.sh" /v1/photoshoot/generate "$body" "$TIMEOUT")
    actual=$(printf '%s' "$result" | jq -r '.files | length // 0' 2>/dev/null || echo 0)
    if [[ "$actual" -lt "$COUNT" ]]; then
      echo "[photoshoot] warning: requested $COUNT frames, got $actual (content filter may have removed some)" >&2
    fi
    printf '%s\n' "$result"
    ;;

  auto)
    IMG="${1:?image required}"; PROMPT="${2:?prompt required}"; COUNT="${3:?count required}"
    MODEL="${4:-auto}"; ASPECT="${5:-3:4}"; REFS="${6:-}"
    TIMEOUT="${PHOTOSHOOT_TIMEOUT:-900}"
    if [[ "$COUNT" -gt 6 ]]; then echo "error: image_count max is 6 (got $COUNT)" >&2; exit 1; fi
    if resolve_wb_input "$IMG" "$REFS"; then
      IMG="$WB_MAIN"; REFS="$WB_REFS"
      echo "[photoshoot] wb input expanded: main=$IMG refs=$REFS" >&2
    fi
    echo "[photoshoot] step 1/2: test shot..." >&2
    test_result=$("$SCRIPT_DIR/photoshoot.sh" test "$IMG" "$PROMPT" "$MODEL" "$ASPECT" "$REFS" "$TIMEOUT")
    echo "$test_result"
    approved=$(printf '%s' "$test_result" | jq -r '.files[0] // empty')
    if [[ -z "$approved" ]]; then
      echo "[photoshoot] test step failed, aborting" >&2
      exit 1
    fi
    echo "[photoshoot] step 2/2: generating $COUNT images from $approved" >&2
    "$SCRIPT_DIR/photoshoot.sh" generate "$approved" "$PROMPT" "$COUNT" "$MODEL" "$ASPECT" "$TIMEOUT"
    ;;

  ""|--help|-h|help)
    usage
    ;;
  *)
    echo "Unknown subcommand: $CMD" >&2
    usage; exit 1
    ;;
esac
