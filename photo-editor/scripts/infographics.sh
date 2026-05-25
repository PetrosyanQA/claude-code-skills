#!/bin/bash
# infographics.sh — Two-step infographics pipeline for marketplace cards.
#
# Subcommands:
#   test     <image> "<prompt>" [model=model_2] [aspect=3:4] [refs=p1,...,p5] [timeout=600]
#   generate <approved_image> "<prompt>" <count> [model=model_2] [aspect=3:4] [refs=p1,...,p5] [timeout=900]
#   auto     <image> "<prompt>" <count> [model=model_2] [aspect=3:4] [refs=p1,...,p5]
#
# Models: model_1, model_2 (PRO, default), model_3, model_4
# Aspect ratios: 1:1, 3:4, 4:3, 2:3, 3:2
# count: 1..6   refs: max 5

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./common.sh
source "$SCRIPT_DIR/common.sh"

CMD="${1:-}"
shift || true

usage() {
  cat <<EOF
Usage:
  $0 test     <image> "<prompt>" [model=model_2] [aspect=3:4] [refs=p1,...,p5] [timeout=600]
  $0 generate <approved_image> "<prompt>" <count> [model=model_2] [aspect=3:4] [refs=p1,...,p5] [timeout=900]
  $0 auto     <image> "<prompt>" <count> [model=model_2] [aspect=3:4] [refs=p1,...,p5]

count: 1..6  |  refs: max 5  |  models: model_1 model_2(PRO) model_3 model_4
aspect: 1:1 3:4 4:3 2:3 3:2
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
    MODEL=$(resolve_model "${3:-model_2}"); ASPECT="${4:-3:4}"; REFS="${5:-}"; TIMEOUT="${6:-600}"
    if resolve_wb_input "$IMG" "$REFS"; then
      IMG="$WB_MAIN"; REFS="$WB_REFS"
      echo "[infographics] wb input expanded: main=$IMG refs=$REFS" >&2
    fi
    local_path=$(resolve_image "$IMG"); b64=$(encode_image "$local_path")
    refs_file=$(encode_image_array_file "$REFS"); hook=$(default_hook_url)
    body=$(compose_body "$b64" \
      '{main_image:$img, hook_url:$hook, model:$model, aspect_ratio:$ar, user_prompt:$p, reference_images:($refs|fromjson)}' \
      --arg hook "$hook" --arg model "$MODEL" --arg ar "$ASPECT" --arg p "$PROMPT" --rawfile refs "$refs_file")
    "$SCRIPT_DIR/run.sh" /v1/infographics/test "$body" "$TIMEOUT"
    ;;

  generate)
    IMG="${1:?approved image required}"; PROMPT="${2:?prompt required}"; COUNT="${3:?count required}"
    MODEL=$(resolve_model "${4:-model_2}"); ASPECT="${5:-3:4}"; REFS="${6:-}"; TIMEOUT="${7:-900}"
    if [[ "$COUNT" -gt 6 ]]; then echo "error: image_count max is 6 (got $COUNT)" >&2; exit 1; fi
    if resolve_wb_input "$IMG" "$REFS"; then
      IMG="$WB_MAIN"; REFS="$WB_REFS"
      echo "[infographics] wb input expanded: main=$IMG refs=$REFS" >&2
    fi
    local_path=$(resolve_image "$IMG"); b64=$(encode_image "$local_path")
    refs_file=$(encode_image_array_file "$REFS"); hook=$(default_hook_url)
    body=$(compose_body "$b64" \
      '{main_image:$img, hook_url:$hook, model:$model, aspect_ratio:$ar, user_prompt:$p, reference_images:($refs|fromjson), image_count:$count}' \
      --arg hook "$hook" --arg model "$MODEL" --arg ar "$ASPECT" --arg p "$PROMPT" --rawfile refs "$refs_file" --argjson count "$COUNT")
    result=$("$SCRIPT_DIR/run.sh" /v1/infographics/generate "$body" "$TIMEOUT")
    actual=$(printf '%s' "$result" | jq -r '.files | length // 0' 2>/dev/null || echo 0)
    effective=$(( COUNT > 4 ? COUNT : 4 ))  # endpoint returns max(4, image_count)
    if [[ "$actual" -lt "$effective" ]]; then
      echo "[infographics] warning: expected $effective frames, got $actual (content filter may have removed some)" >&2
    fi
    printf '%s\n' "$result"
    ;;

  auto)
    IMG="${1:?image required}"; PROMPT="${2:?prompt required}"; COUNT="${3:?count required}"
    MODEL="${4:-model_2}"; ASPECT="${5:-3:4}"; REFS="${6:-}"
    TIMEOUT="${INFOGRAPHICS_TIMEOUT:-900}"
    if [[ "$COUNT" -gt 6 ]]; then echo "error: image_count max is 6 (got $COUNT)" >&2; exit 1; fi
    if resolve_wb_input "$IMG" "$REFS"; then
      IMG="$WB_MAIN"; REFS="$WB_REFS"
      echo "[infographics] wb input expanded: main=$IMG refs=$REFS" >&2
    fi
    echo "[infographics] step 1/2: test shot..." >&2
    test_result=$("$SCRIPT_DIR/infographics.sh" test "$IMG" "$PROMPT" "$MODEL" "$ASPECT" "$REFS" "$TIMEOUT")
    echo "$test_result"
    approved=$(printf '%s' "$test_result" | jq -r '.files[0] // empty')
    if [[ -z "$approved" ]]; then
      echo "[infographics] test step failed, aborting" >&2
      exit 1
    fi
    echo "[infographics] step 2/2: generating $COUNT images from $approved" >&2
    # Do NOT pass refs to generate: main_image is already the approved test frame
    # that incorporates product identity; extra refs would be redundant and may skew output.
    "$SCRIPT_DIR/infographics.sh" generate "$approved" "$PROMPT" "$COUNT" "$MODEL" "$ASPECT" "" "$TIMEOUT"
    ;;

  ""|--help|-h|help)
    usage
    ;;
  *)
    echo "Unknown subcommand: $CMD" >&2
    usage; exit 1
    ;;
esac
