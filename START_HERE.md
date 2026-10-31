# Start here — Nudge

**What this is:** a silent macOS menu bar app for recurring reminders: discreet banner notifications at chosen intervals, no sound, no dock icon. Plus a one-file Python CLI that does the same for a single reminder.
**Status:** paused (feature-complete; last feature was per-reminder snooze). No web URL.

## Look here first
- [README.md](README.md) — features, install, usage, architecture
- [Sources/Nudge/AppDelegate.swift](Sources/Nudge/AppDelegate.swift) — menu bar item, menu and actions
- [Sources/Nudge/ReminderEngine.swift](Sources/Nudge/ReminderEngine.swift) — 5-second tick loop that fires due reminders
- [Sources/Nudge/Reminder.swift](Sources/Nudge/Reminder.swift) — reminder model + interval parser
- [scripts/build-app.sh](scripts/build-app.sh) — builds `Nudge.app`

## Where things are
- `Sources/Nudge/` — the whole app (entry point, engine, store, quiet hours, notifier, input dialog)
- `cli/remind.py` — standalone Python CLI
- `scripts/` — `build-app.sh`, `install-launchagent.sh`, app `Info.plist`
- `launchagent/` — LaunchAgent plist template for autostart

## Search for
- `nextFireDate`, `lastFiredAt`, `snoozedUntil` — firing and snooze logic
- `QuietHours` — quiet-hours window (wraps midnight)
- `osascript` / `Notifier` — how notifications are posted
- `state.json` / `ReminderStore` — persistence in `~/Library/Application Support/Nudge/`

## Set up & run
Needs a Mac (macOS 13+) with Swift 5.9+ (Xcode command line tools are enough).
```sh
swift build                      # quick compile check
./scripts/build-app.sh           # produces Nudge.app
open Nudge.app
./scripts/install-launchagent.sh /Applications/Nudge.app/Contents/MacOS/Nudge   # optional autostart
python3 cli/remind.py "drink water" 15                                         # CLI version
```
No tests and no env vars.

## Continue working
- No roadmap or todo file. The README "Features" and "Architecture" sections describe the current state.
- Check behavior by running the app and watching notifications; logs from the LaunchAgent go to `~/Library/Logs/Nudge/`.
