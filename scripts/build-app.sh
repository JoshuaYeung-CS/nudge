#!/usr/bin/env bash
# Build a Nudge.app bundle from the SwiftPM release artifact.
set -euo pipefail

cd "$(dirname "$0")/.."

echo "Building release executable..."
swift build -c release

APP="Nudge.app"
echo "Assembling $APP..."
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp ".build/release/Nudge" "$APP/Contents/MacOS/Nudge"
cp "scripts/Info.plist" "$APP/Contents/Info.plist"

# Ad-hoc sign so launchd will accept it on Apple silicon.
codesign --force --sign - "$APP" >/dev/null 2>&1 || true

echo
echo "Built $APP"
echo "  Open it:    open ./$APP"
echo "  Install it: mv $APP /Applications/"
