#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Build a signed/notarized macOS app DMG for ServerPulse.

Environment variables:
  APP_NAME               App/binary name (default: ServerPulse)
  CONFIGURATION          Swift build config (default: release)
  BUILD_DIR              Output dir (default: ./build)
  DEV_ID_APP_CERT        Developer ID Application identity string
  NOTARY_PROFILE         notarytool keychain profile (default: AC_NOTARY)
  VERSION                Version suffix used in DMG filename
  SKIP_SIGNING           Set to 1 to skip codesign
  SKIP_NOTARIZATION      Set to 1 to skip notarization/stapling

Flags:
  --identity <value>       Developer ID identity override
  --notary-profile <value> notarytool profile override
  --version <value>        Version override for DMG name
  --skip-signing           Skip codesign
  --skip-notarization      Skip notarization/stapling
  -h, --help               Show this help

Output:
  build/ServerPulse-<version>.dmg
EOF
}

log() {
    echo
    echo "==> $*"
}

require_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Missing required command: $1" >&2
        exit 1
    fi
}

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

APP_NAME="${APP_NAME:-ServerPulse}"
CONFIGURATION="${CONFIGURATION:-release}"
BUILD_DIR="${BUILD_DIR:-$ROOT_DIR/build}"
INFO_PLIST_PATH="${INFO_PLIST_PATH:-$ROOT_DIR/Resources/Info.plist}"
ICON_PATH="${ICON_PATH:-$ROOT_DIR/Resources/AppIcon.icns}"
ENTITLEMENTS_PATH="${ENTITLEMENTS_PATH:-$ROOT_DIR/Resources/ServerPulse.entitlements}"
NOTARY_PROFILE="${NOTARY_PROFILE:-AC_NOTARY}"
DEV_ID_APP_CERT="${DEV_ID_APP_CERT:-}"
SKIP_SIGNING="${SKIP_SIGNING:-0}"
SKIP_NOTARIZATION="${SKIP_NOTARIZATION:-0}"
VERSION="${VERSION:-}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --identity)
            DEV_ID_APP_CERT="${2:?missing value for --identity}"
            shift
            ;;
        --notary-profile)
            NOTARY_PROFILE="${2:?missing value for --notary-profile}"
            shift
            ;;
        --version)
            VERSION="${2:?missing value for --version}"
            shift
            ;;
        --skip-signing)
            SKIP_SIGNING=1
            ;;
        --skip-notarization)
            SKIP_NOTARIZATION=1
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage
            exit 1
            ;;
    esac
    shift
done

if [[ -z "$VERSION" ]]; then
    if TAG="$(git describe --tags --exact-match 2>/dev/null)"; then
        VERSION="${TAG#v}"
    else
        VERSION="$(date +%Y%m%d-%H%M%S)"
    fi
fi

if [[ "$SKIP_NOTARIZATION" != "1" && "$SKIP_SIGNING" == "1" ]]; then
    echo "Notarization requires signing. Remove --skip-signing or use --skip-notarization." >&2
    exit 1
fi

if [[ "$SKIP_SIGNING" != "1" && -z "$DEV_ID_APP_CERT" ]]; then
    DEV_ID_APP_CERT="$(security find-identity -v -p codesigning | awk -F'"' '/Developer ID Application/ {print $2; exit}')"
fi

if [[ "$SKIP_SIGNING" != "1" && -z "$DEV_ID_APP_CERT" ]]; then
    echo "No Developer ID Application identity found." >&2
    echo "Set DEV_ID_APP_CERT or import your signing certificate." >&2
    exit 1
fi

require_cmd swift
require_cmd hdiutil
require_cmd ditto
if [[ "$SKIP_SIGNING" != "1" ]]; then
    require_cmd codesign
fi
if [[ "$SKIP_NOTARIZATION" != "1" ]]; then
    require_cmd xcrun
fi

BINARY_PATH="$ROOT_DIR/.build/$CONFIGURATION/$APP_NAME"
APP_PATH="$BUILD_DIR/$APP_NAME.app"
CONTENTS_PATH="$APP_PATH/Contents"
ZIP_PATH="$BUILD_DIR/$APP_NAME.zip"
DMG_ROOT_PATH="$BUILD_DIR/dmg-root"
DMG_PATH="$BUILD_DIR/$APP_NAME-$VERSION.dmg"

log "Building Swift executable ($CONFIGURATION)"
swift build -c "$CONFIGURATION"

if [[ ! -f "$BINARY_PATH" ]]; then
    echo "Binary not found at $BINARY_PATH" >&2
    exit 1
fi

log "Creating .app bundle"
rm -rf "$APP_PATH" "$ZIP_PATH" "$DMG_ROOT_PATH" "$DMG_PATH"
mkdir -p "$CONTENTS_PATH/MacOS" "$CONTENTS_PATH/Resources"
cp "$BINARY_PATH" "$CONTENTS_PATH/MacOS/$APP_NAME"
cp "$INFO_PLIST_PATH" "$CONTENTS_PATH/Info.plist"
cp "$ICON_PATH" "$CONTENTS_PATH/Resources/AppIcon.icns"
chmod +x "$CONTENTS_PATH/MacOS/$APP_NAME"

if [[ "$SKIP_SIGNING" != "1" ]]; then
    log "Signing app with identity: $DEV_ID_APP_CERT"
    codesign --force --deep --options runtime --timestamp \
        --entitlements "$ENTITLEMENTS_PATH" \
        --sign "$DEV_ID_APP_CERT" \
        "$APP_PATH"
    codesign --verify --deep --strict --verbose=2 "$APP_PATH"
else
    log "Skipping app signing"
fi

if [[ "$SKIP_NOTARIZATION" != "1" ]]; then
    log "Notarizing app bundle"
    ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"
    xcrun notarytool submit "$ZIP_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
    xcrun stapler staple "$APP_PATH"
else
    log "Skipping app notarization"
fi

log "Creating DMG"
mkdir -p "$DMG_ROOT_PATH"
cp -R "$APP_PATH" "$DMG_ROOT_PATH/"
ln -s /Applications "$DMG_ROOT_PATH/Applications"
hdiutil create -volname "$APP_NAME" \
    -srcfolder "$DMG_ROOT_PATH" \
    -ov -format UDZO "$DMG_PATH"

if [[ "$SKIP_SIGNING" != "1" ]]; then
    log "Signing DMG"
    codesign --force --timestamp --sign "$DEV_ID_APP_CERT" "$DMG_PATH"
    codesign --verify --verbose=2 "$DMG_PATH"
fi

if [[ "$SKIP_NOTARIZATION" != "1" ]]; then
    log "Notarizing DMG"
    xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
    xcrun stapler staple "$DMG_PATH"
fi

rm -rf "$DMG_ROOT_PATH"

log "Release artifact ready"
echo "$DMG_PATH"
