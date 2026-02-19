#!/bin/bash
# Convert AppIcon.png (1024x1024) to AppIcon.icns using iconutil
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SOURCE_PNG="$PROJECT_DIR/Resources/AppIcon.png"
ICONSET_DIR="$PROJECT_DIR/Resources/AppIcon.iconset"
OUTPUT_ICNS="$PROJECT_DIR/Resources/AppIcon.icns"

echo "Source: $SOURCE_PNG"

# Create iconset directory
rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"

# Generate all required sizes using sips
# macOS iconset requires these specific sizes:
sizes=(16 32 128 256 512)
for size in "${sizes[@]}"; do
    double=$((size * 2))

    echo "  Generating ${size}x${size}..."
    sips -z $size $size "$SOURCE_PNG" --out "$ICONSET_DIR/icon_${size}x${size}.png" > /dev/null 2>&1

    echo "  Generating ${size}x${size}@2x (${double}x${double})..."
    sips -z $double $double "$SOURCE_PNG" --out "$ICONSET_DIR/icon_${size}x${size}@2x.png" > /dev/null 2>&1
done

echo "Converting iconset to icns..."
iconutil -c icns "$ICONSET_DIR" -o "$OUTPUT_ICNS"

# Clean up iconset directory
rm -rf "$ICONSET_DIR"

echo "Done! Icon saved to $OUTPUT_ICNS"
ls -la "$OUTPUT_ICNS"
