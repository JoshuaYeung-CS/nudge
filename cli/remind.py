#!/usr/bin/env python3
"""Silent macOS reminder notifications at a chosen interval."""

import argparse
import subprocess
import sys
import time


def notify(title: str, message: str) -> None:
    safe_title = title.replace('"', '\\"')
    safe_msg = message.replace('"', '\\"')
    script = f'display notification "{safe_msg}" with title "{safe_title}"'
    subprocess.run(["osascript", "-e", script], check=False)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Silent Mac reminder. Notifies every N minutes until Ctrl+C.",
    )
    parser.add_argument("message", help="Reminder text")
    parser.add_argument("minutes", type=float, help="Interval in minutes")
    parser.add_argument("-t", "--title", default="Reminder", help="Notification title")
    args = parser.parse_args()

    if args.minutes <= 0:
        print("Interval must be positive.", file=sys.stderr)
        return 1

    print(f"Reminding every {args.minutes:g} min: {args.message!r}")
    print("Press Ctrl+C to stop.")

    try:
        while True:
            time.sleep(args.minutes * 60)
            notify(args.title, args.message)
    except KeyboardInterrupt:
        print("\nStopped.")
        return 0


if __name__ == "__main__":
    sys.exit(main())
