# nudge

Silent macOS reminder CLI. Calls `osascript display notification` on an interval — no sound, no haptics.

## Usage

```sh
python3 cli/remind.py "drink water" 15
python3 cli/remind.py "stand up" 30 --title "Posture"
```

Ctrl+C to stop.
