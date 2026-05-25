#!/bin/bash
# Common helpers for Photo Editor scripts.
# - load_config: loads PHOTO_EDITOR_* from config/.env (env vars take precedence)
# - encode_image <path>: prints base64 (no newlines) of a local file
# - resolve_image <path-or-url>: if URL, downloads to tmp; returns local path
# - require <var>: aborts if env var is empty
# - api_request <method> <path> [json_body] [accept_header]: signed Basic Auth call to BASE_URL

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_FILE="$SKILL_ROOT/config/.env"
OUTPUT_DIR="${PHOTO_EDITOR_OUTPUT_DIR:-$HOME/.claude/output/photo-editor}"

load_config() {
  if [[ -f "$CONFIG_FILE" ]]; then
    while IFS='=' read -r key value; do
      [[ "$key" =~ ^[[:space:]]*# ]] && continue
      [[ -z "$key" ]] && continue
      key=$(printf '%s' "$key" | xargs)
      value=$(printf '%s' "$value" | sed 's/^["'\''"]//;s/["'\''"]$//')
      # Don't overwrite already-exported env vars
      if [[ -z "${!key:-}" ]]; then
        export "$key=$value"
      fi
    done < "$CONFIG_FILE"
  fi

  : "${PHOTO_EDITOR_BASE_URL:=https://mpstats.io/api/big_data/proxy}"
  if [[ -z "${PHOTO_EDITOR_TOKEN:-}" || "$PHOTO_EDITOR_TOKEN" == "your_token_here" ]]; then
    cat >&2 <<EOF
{"error":"Photo Editor token missing","hint":"Set PHOTO_EDITOR_TOKEN (X-Mpstats-TOKEN) in config/.env. See config/README.md"}
EOF
    exit 1
  fi
}

resolve_image() {
  local src="$1"
  if [[ "$src" =~ ^https?:// ]]; then
    local tmp
    tmp=$(mktemp -t photo-editor-XXXXXX)
    if ! curl -sSL --fail "$src" -o "$tmp"; then
      echo "Failed to download $src" >&2
      exit 1
    fi
    echo "$tmp"
  else
    if [[ ! -f "$src" ]]; then
      echo "File not found: $src" >&2
      exit 1
    fi
    # Expand to absolute path
    (cd "$(dirname "$src")" && printf '%s/%s\n' "$PWD" "$(basename "$src")")
  fi
}

encode_image() {
  local path="$1"
  base64 < "$path" | tr -d '\n'
}

# Build a JSON array of base64 strings from a comma-separated list of paths/URLs.
# Empty input -> "null"
# DEPRECATED for large lists — argv path can exceed ARG_MAX. Prefer encode_image_array_file.
encode_image_array() {
  local list="$1"
  if [[ -z "$list" ]]; then
    echo "null"
    return
  fi
  local out="["
  local first=1
  IFS=',' read -ra items <<< "$list"
  for it in "${items[@]}"; do
    it="${it## }"; it="${it%% }"
    [[ -z "$it" ]] && continue
    local resolved
    resolved=$(resolve_image "$it")
    local b64
    b64=$(encode_image "$resolved")
    if [[ $first -eq 1 ]]; then first=0; else out+=","; fi
    out+="\"$b64\""
  done
  out+="]"
  echo "$out"
}

# Same as encode_image_array, but writes JSON array to a tempfile and echoes the path.
# Use with `--rawfile refs "$path"` + `($refs|fromjson)` in jq. Avoids ARG_MAX on
# multi-image inputs (each base64 png is ~100-200KB; 5+ refs blow argv).
# Empty input -> file containing "null".
encode_image_array_file() {
  local list="$1"
  local f
  f=$(mktemp -t pe-refs.XXXXXX)
  if [[ -z "$list" ]]; then
    printf 'null' > "$f"
    echo "$f"
    return
  fi
  printf '[' > "$f"
  local first=1
  IFS=',' read -ra items <<< "$list"
  for it in "${items[@]}"; do
    it="${it## }"; it="${it%% }"
    [[ -z "$it" ]] && continue
    local resolved
    resolved=$(resolve_image "$it")
    if [[ $first -eq 1 ]]; then first=0; else printf ',' >> "$f"; fi
    printf '"' >> "$f"
    base64 < "$resolved" | tr -d '\n' >> "$f"
    printf '"' >> "$f"
  done
  printf ']' >> "$f"
  echo "$f"
}

api_request() {
  local method="$1"
  local path="$2"
  local body="${3:-}"
  local extra="${4:-}"

  local url="${PHOTO_EDITOR_BASE_URL%/}${path}"
  local args=(-sS --location --post301 --post302 --request "$method" "$url"
              --max-time 90
              --header 'Content-Type: application/json'
              --header 'Accept: application/json'
              --header "X-Mpstats-TOKEN: ${PHOTO_EDITOR_TOKEN}")
  if [[ -n "$body" ]]; then
    if [[ "$body" == @* ]]; then
      # @path → read body from file (avoids ARG_MAX for large base64 payloads)
      args+=(--data-binary "$body")
    else
      args+=(--data "$body")
    fi
  fi
  if [[ -n "$extra" ]]; then
    # shellcheck disable=SC2206
    local extra_arr=($extra)
    args+=("${extra_arr[@]}")
  fi
  curl "${args[@]}"
}

# Generates a default hook_url (placeholder — we use polling, not webhooks).
default_hook_url() {
  echo "https://example.com/photo-editor-noop"
}

ensure_jq() {
  if ! command -v jq >/dev/null 2>&1; then
    echo '{"error":"jq is required. Install: brew install jq"}' >&2
    exit 1
  fi
}

# Resolve "wb:<sku>" or "wb:<wb-url>" inputs into a main image path + refs list.
# Sets globals WB_MAIN and WB_REFS (comma-separated). Returns 1 if not a wb: input.
#
# Usage in subcommand:
#   if resolve_wb_input "$IMG" "$REFS"; then
#     IMG="$WB_MAIN"; REFS="$WB_REFS"
#   fi
#
# $1 — main image arg (path, url, or wb:SKU). $2 — existing refs (comma-separated).
# Behavior when $1 starts with "wb:":
#   - downloads up to PHOTO_EDITOR_WB_MAX (default 6) photos for the SKU
#   - WB_MAIN = first photo
#   - WB_REFS = rest joined with commas + any user-supplied refs appended
resolve_wb_input() {
  local raw="$1"
  local existing_refs="${2:-}"
  if [[ ! "$raw" =~ ^wb: ]]; then
    return 1
  fi
  local sku_arg="${raw#wb:}"
  local max="${PHOTO_EDITOR_WB_MAX:-6}"
  local fetch="$SCRIPT_DIR/wb-fetch-photos.sh"
  if [[ ! -x "$fetch" ]]; then
    echo "wb-fetch-photos.sh not executable: $fetch" >&2
    exit 1
  fi
  local lines
  if ! lines=$("$fetch" "$sku_arg" "$max"); then
    echo "Failed to fetch WB photos for $sku_arg" >&2
    exit 1
  fi
  local arr=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && arr+=("$line")
  done <<< "$lines"
  if [[ ${#arr[@]} -eq 0 ]]; then
    echo "No photos returned for $sku_arg" >&2
    exit 1
  fi
  WB_MAIN="${arr[0]}"
  local rest=("${arr[@]:1}")
  local joined=""
  if [[ ${#rest[@]} -gt 0 ]]; then
    joined=$(IFS=','; echo "${rest[*]}")
  fi
  if [[ -n "$existing_refs" ]]; then
    if [[ -n "$joined" ]]; then
      WB_REFS="$joined,$existing_refs"
    else
      WB_REFS="$existing_refs"
    fi
  else
    WB_REFS="$joined"
  fi
  return 0
}

# Resolve "auto" model alias to a concrete backend model.
# Backend rejects model=auto with "The model cannot be null", so we map it to
# model_1 (Standard — default for all scripts except infographics, which defaults to model_2/PRO).
resolve_model() {
  local m="${1:-auto}"
  if [[ "$m" == "auto" || -z "$m" ]]; then
    echo "model_1"
  else
    echo "$m"
  fi
}

# Build a JSON request body that includes a base64 image without hitting ARG_MAX.
# Writes b64 to a tempfile, then jq reads it via --rawfile and emits JSON to a tempfile.
# Echoes "@<path-to-json-file>" so callers pass it directly to api_request / run.sh.
#
# Usage:
#   body_ref=$(compose_body "$b64" \
#     '{main_image:$img, hook_url:$hook, model:$model, user_prompt:$p}' \
#     --arg hook "$hook" --arg model "$MODEL" --arg p "$PROMPT")
#   "$SCRIPT_DIR/run.sh" /v1/foo "$body_ref"
compose_body() {
  local b64="$1"; shift
  local prog="$1"; shift
  local b64f jsonf
  b64f=$(mktemp -t pe-b64.XXXXXX)
  jsonf=$(mktemp -t pe-body.XXXXXX)
  printf '%s' "$b64" > "$b64f"
  jq -nc --rawfile img "$b64f" "$@" "$prog" > "$jsonf"
  rm -f "$b64f"
  echo "@$jsonf"
}