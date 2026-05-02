#!/usr/bin/env bash
# Install a LaunchAgent so Nudge starts on login and restarts if it crashes.
set -euo pipefail

cd "$(dirname "$0")/.."

APP_PATH="${1:-/Applications/Nudge.app/Contents/MacOS/Nudge}"
if [ ! -x "$APP_PATH" ]; then
    echo "Executable not found at: $APP_PATH"
    echo "Pass the path explicitly: $0 /path/to/Nudge.app/Contents/MacOS/Nudge"
    exit 1
fi

LABEL="com.joshuayeung.nudge"
LOG_DIR="$HOME/Library/Logs/Nudge"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
TEMPLATE="launchagent/$LABEL.plist.template"

mkdir -p "$LOG_DIR" "$(dirname "$PLIST")"

sed -e "s|__APP_PATH__|$APP_PATH|g" \
    -e "s|__LOG_DIR__|$LOG_DIR|g" \
    "$TEMPLATE" > "$PLIST"

# Reload (unload first in case we're updating an existing install).
launchctl unload "$PLIST" 2>/dev/null || true
launchctl load "$PLIST"

echo "Installed: $PLIST"
echo "Logs at:   $LOG_DIR"
echo "Uninstall: launchctl unload $PLIST && rm $PLIST"
