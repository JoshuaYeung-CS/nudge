# Nudge

A silent macOS menu bar app for recurring reminders. No sound, no haptic, no
modal — just a discreet banner notification at intervals you choose.

Built because every reminder app I tried either (a) buzzed my Apple Watch every
15 minutes or (b) was a 50 MB Electron blob to do what `osascript` can do in
one line.

New here? Read [START_HERE.md](START_HERE.md).

```
🔔 Nudge
─────────────────────────────────
• drink water — every 15m
• stand up — every 1h
• post export — every 15m
─────────────────────────────────
Add reminder…                  ⌘N
─────────────────────────────────
Pause all
Quiet hours: 22:00–08:00
─────────────────────────────────
About Nudge
Quit Nudge                     ⌘Q
```

## Features

- **Silent by default** — uses `osascript display notification` with no sound argument, so notifications appear but never play sound or haptic.
- **Multiple reminders** — each with its own message, title, and interval (`30s`, `15m`, `1h`, `1h30m`).
- **Persistent** — state lives at `~/Library/Application Support/Nudge/state.json` and survives quits and reboots.
- **Quiet hours** — set a window like `22:00–08:00` and reminders pause inside it. Wraps midnight correctly.
- **Global pause** — single click silences everything; the menu bar icon swaps to `bell.slash` so you don't forget you paused.
- **Per-reminder snooze** — 15m / 30m / 60m one-shot snooze on any reminder.
- **Menu bar only** — no dock icon, no window stealing focus.
- **Survives reboot** — optional LaunchAgent template included.

## Install

Requirements: macOS 13+, Swift 5.9+ (Xcode command line tools is enough).

```sh
git clone https://github.com/JoshuaYeung-CS/nudge.git
cd nudge
./scripts/build-app.sh
mv Nudge.app /Applications/
open /Applications/Nudge.app
```

The first time it runs, macOS will ask whether `Script Editor` (the host of
`osascript`) can post notifications — allow it.

### Autostart on login (optional)

```sh
./scripts/install-launchagent.sh /Applications/Nudge.app/Contents/MacOS/Nudge
```

This drops a LaunchAgent at `~/Library/LaunchAgents/com.joshuayeung.nudge.plist`
that re-launches Nudge if it crashes and starts it on login. Logs go to
`~/Library/Logs/Nudge/`.

To uninstall:

```sh
launchctl unload ~/Library/LaunchAgents/com.joshuayeung.nudge.plist
rm ~/Library/LaunchAgents/com.joshuayeung.nudge.plist
```

## Usage

1. Click the bell icon in the menu bar.
2. **Add reminder…** — message, title, and interval. The interval accepts plain numbers (minutes), or `30s` / `15m` / `1h` / `1h30m`.
3. Each reminder gets a submenu: pause, edit, snooze, delete.
4. **Quiet hours** lives near the bottom — `HH:MM-HH:MM` 24-hour format.

The bell icon reflects state:

| Icon | Meaning |
|---|---|
| `bell` | Active, at least one reminder running |
| `moon` | In quiet hours — reminders are suspended until the window ends |
| `bell.slash` | Globally paused |

## CLI sibling

If you don't want the full app, the `cli/` directory has a Python script that
does the same thing for one reminder at a time:

```sh
python3 cli/remind.py "drink water" 15
python3 cli/remind.py "stand up" 30s --first-now
```

## Architecture

```
Sources/Nudge/
├── main.swift           — NSApp entry point, .accessory activation
├── AppDelegate.swift    — status item + menu construction + actions
├── Reminder.swift       — reminder model + interval parser
├── ReminderEngine.swift — 5-second tick loop, fires due reminders
├── ReminderStore.swift  — JSON persistence to Application Support
├── QuietHours.swift     — time-window model with midnight wrap
├── Notifier.swift       — osascript wrapper
└── InputDialog.swift    — NSAlert with text field accessory views
```

The engine ticks every 5 seconds and asks each enabled reminder for its
`nextFireDate`. Anything overdue fires and gets its `lastFiredAt` updated.
Snooze is just a `snoozedUntil` field consulted in `nextFireDate`.

Why osascript instead of `UNUserNotificationCenter`? UNUNC requires a signed,
identified bundle and tries hard to make notifications interactive. For a
local tool that just wants a silent banner, the four-line shell-out is much
less friction.

## License

MIT — see [LICENSE](LICENSE).
