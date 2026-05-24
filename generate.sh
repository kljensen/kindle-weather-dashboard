#!/bin/sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
DATA_FILE="$SCRIPT_DIR/weather_data.json"
OUTPUT_PNG="${OUTPUT_PNG:-$SCRIPT_DIR/dashboard.png}"

export TYPST_PACKAGE_CACHE_PATH="${TYPST_PACKAGE_CACHE_PATH:-$SCRIPT_DIR/.typst-cache}"
mkdir -p "$(dirname "$OUTPUT_PNG")" "$TYPST_PACKAGE_CACHE_PATH"

# Typst loads weather_data.json relative to dashboard.typ, so keep the generated
# data beside the Typst source.
echo "Fetching weather data..."
"$SCRIPT_DIR/scripts/fetch-weather.sh" > "${DATA_FILE}.tmp"
mv "${DATA_FILE}.tmp" "$DATA_FILE"

echo "Generating dashboard..."
typst compile "$SCRIPT_DIR/dashboard.typ" "$OUTPUT_PNG" \
  --format png \
  --ppi "${TYPST_PPI:-72}" \
  --font-path "$SCRIPT_DIR/fonts"

# Kindle eips handles plain 8-bit grayscale PNGs much more reliably than RGBA.
if command -v magick >/dev/null 2>&1; then
  TMP_PNG="${OUTPUT_PNG}.tmp.png"
  magick "$OUTPUT_PNG" -alpha remove -alpha off -colorspace Gray -depth 8 -type Grayscale "$TMP_PNG"
  mv "$TMP_PNG" "$OUTPUT_PNG"
fi

echo "Done: $OUTPUT_PNG"
