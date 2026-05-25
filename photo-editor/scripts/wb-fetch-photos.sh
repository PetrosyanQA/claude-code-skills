#!/bin/bash
# wb-fetch-photos.sh — fetch all WB product photos for a given SKU and convert to PNG.
#
# Usage:
#   wb-fetch-photos.sh <sku-or-url> [max_count]
#
# Output: prints absolute PNG paths, one per line. First line = primary photo (main),
# remaining lines = additional refs. Photos cached under
# ~/.claude/cache/photo-editor/wb-photos/<sku>/ so repeated calls are instant.
#
# Requires: curl, jq, dwebp (brew install webp).

set -euo pipefail

SKU_ARG="${1:?sku or wb url required}"
MAX="${2:-8}"

# Extract numeric SKU from either bare id or WB catalog URL.
SKU=$(printf '%s' "$SKU_ARG" | grep -oE '[0-9]{6,}' | head -1)
if [[ -z "$SKU" ]]; then
  echo "Could not parse SKU from: $SKU_ARG" >&2
  exit 1
fi

CACHE_DIR="${PHOTO_EDITOR_CACHE_DIR:-$HOME/.claude/cache/photo-editor/wb-photos}/$SKU"
mkdir -p "$CACHE_DIR"

# Build basket-N candidates from SKU. WB CDN routes by SKU range — we just probe
# until one responds, then reuse for all photos.
sku_int=$SKU
# WB pattern: vol = SKU/100000, part = SKU/1000
vol=$((sku_int / 100000))
part=$((sku_int / 1000))

find_basket() {
  for n in 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40; do
    local url="https://basket-${n}.wbbasket.ru/vol${vol}/part${part}/${SKU}/images/big/1.webp"
    if curl -sfI -o /dev/null "$url"; then
      echo "$n"
      return 0
    fi
  done
  return 1
}

BASKET=$(find_basket || true)
if [[ -z "$BASKET" ]]; then
  echo "Failed to locate WB basket for SKU $SKU" >&2
  exit 1
fi

BASE="https://basket-${BASKET}.wbbasket.ru/vol${vol}/part${part}/${SKU}/images/big"

paths=()
for n in $(seq 1 "$MAX"); do
  local_webp="$CACHE_DIR/${n}.webp"
  local_png="$CACHE_DIR/${n}.png"
  if [[ ! -f "$local_png" ]]; then
    if curl -sfL "$BASE/${n}.webp" -o "$local_webp" 2>/dev/null; then
      if command -v dwebp >/dev/null 2>&1; then
        dwebp -quiet "$local_webp" -o "$local_png" || { rm -f "$local_webp"; continue; }
      else
        echo "dwebp not installed (brew install webp)" >&2
        exit 1
      fi
    else
      # No more photos
      break
    fi
  fi
  paths+=("$local_png")
done

if [[ ${#paths[@]} -eq 0 ]]; then
  echo "No photos fetched for SKU $SKU" >&2
  exit 1
fi

printf '%s\n' "${paths[@]}"
