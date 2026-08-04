#!/bin/zsh
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
BUILD_DIR="$ROOT_DIR/.build"
APP_DIR="$BUILD_DIR/Release/spocon.app"
CONTENTS_DIR="$APP_DIR/Contents"

swift build -c release

rm -rf "$APP_DIR"
mkdir -p "$CONTENTS_DIR/MacOS"
mkdir -p "$CONTENTS_DIR/Resources"

cp "$BUILD_DIR/arm64-apple-macosx/release/spocon" "$CONTENTS_DIR/MacOS/spocon"
chmod +x "$CONTENTS_DIR/MacOS/spocon"
cp "$ROOT_DIR/Packaging/Info.plist" "$CONTENTS_DIR/Info.plist"
cp "$ROOT_DIR/Packaging/spocon.entitlements" "$CONTENTS_DIR/Resources/spocon.entitlements"

codesign --force --entitlements "$ROOT_DIR/Packaging/spocon.entitlements" --sign - "$APP_DIR"

echo "Built $APP_DIR"
