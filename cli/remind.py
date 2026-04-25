#!/usr/bin/env python3
"""Silent macOS reminder notifications at a chosen interval."""

import argparse
import subprocess
import sys
import time
from datetime import datetime


def notify(title: str, message: str) -> None:
    safe_title = title.replace('"', '\\"')
    safe_msg = message.replace('"', '\\"')
    script = f'display notification "{safe_msg}" with title "{safe_title}"'
    subprocess.run(["osascript", "-e", script], check=False)


def parse_interval(raw: str) -> float:
    """Parse '30s', '15m', '1h', or a bare number (minutes). Returns minutes."""
    raw = raw.strip().lower()
    if not raw:
        raise ValueError("empty interval")
    unit = raw[-1]
    if unit in ("s", "m", "h"):
        value = float(raw[:-1])
        return {"s": value / 60, "m": value, "h": value * 60}[unit]
    return float(raw)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Silent Mac reminder. Notifies every N minutes until Ctrl+C.",
        epilog='Examples:\n  remind "drink water" 15\n  remind "stand up" 30s\n  remind "take a break" 1h',
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("message", nargs="?", help="Reminder text")
    parser.add_argument("interval", nargs="?", help="Interval (e.g. 30, 30s, 15m, 1h). Plain number = minutes.")
    parser.add_argument("-t", "--title", default="Reminder", help="Notification title")
    parser.add_argument("--first-now", action="store_true", help="Fire the first notification immediately")
    args = parser.parse_args()

    message = args.message or input("What should I remind you about? ").strip()
    if not message:
        print("No message provided.", file=sys.stderr)
        return 1

    raw_interval = args.interval or input("How often? (e.g. 15, 30s, 1h) [15m]: ").strip() or "15m"
    try:
        minutes = parse_interval(raw_interval)
    except ValueError:
        print(f"Couldn't parse interval: {raw_interval!r}", file=sys.stderr)
        return 1
    if minutes <= 0:
        print("Interval must be positive.", file=sys.stderr)
        return 1

    seconds = minutes * 60
    pretty = f"{minutes:g} min" if minutes >= 1 else f"{seconds:g} sec"
    print(f"Reminding every {pretty}: {message!r}")
    print("Press Ctrl+C to stop.\n")

    try:
        if args.first_now:
            notify(args.title, message)
            print(f"  {datetime.now().strftime('%H:%M:%S')}  fired")
        while True:
            time.sleep(seconds)
            notify(args.title, message)
            print(f"  {datetime.now().strftime('%H:%M:%S')}  fired")
    except KeyboardInterrupt:
        print("\nStopped.")
        return 0


if __name__ == "__main__":
    sys.exit(main())
