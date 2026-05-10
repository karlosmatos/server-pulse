#!/bin/bash
set -e

echo "Building ServerPulse..."
swift build -c release 2>&1

BINARY=".build/release/ServerPulse"
APP="build/ServerPulse.app"
CONTENTS="$APP/Contents"

echo "Creating app bundle..."
rm -rf "$APP"
mkdir -p "$CONTENTS/MacOS"
mkdir -p "$CONTENTS/Resources"

cp "$BINARY" "$CONTENTS/MacOS/ServerPulse"
cp "Resources/Info.plist" "$CONTENTS/Info.plist"
cp "Resources/AppIcon.icns" "$CONTENTS/Resources/AppIcon.icns"

echo "Code signing..."
codesign --force --deep --sign "-" \
    --entitlements "Resources/ServerPulse.entitlements" \
    "$APP"

INSTALLED="/Applications/ServerPulse.app"

echo "Installing to $INSTALLED..."
pkill -x ServerPulse 2>/dev/null || true
sleep 0.5
rm -rf "$INSTALLED"
cp -R "$APP" "$INSTALLED"
open "$INSTALLED"

echo ""
echo "Done! Installed and launched."
