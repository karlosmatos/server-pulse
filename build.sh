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

echo "Code signing..."
codesign --force --deep --sign "-" \
    --entitlements "Resources/ServerPulse.entitlements" \
    "$APP"

echo ""
echo "Done! App bundle at: $APP"
echo "Run with: open $APP"
