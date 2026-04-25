# nudge

Silent macOS reminder CLI. Calls `osascript display notification` on an interval — no sound, no haptics.

## Usage

```sh
python3 cli/remind.py "drink water" 15        # every 15 minutes
python3 cli/remind.py "stand up" 30s          # every 30 seconds
python3 cli/remind.py "take a break" 1h       # every hour
python3 cli/remind.py "stretch" 20m --first-now  # fire one now, then every 20m
```

Plain number = minutes. Suffix with `s`, `m`, or `h`. Ctrl+C to stop.
