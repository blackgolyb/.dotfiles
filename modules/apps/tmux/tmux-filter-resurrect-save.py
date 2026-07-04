#!/usr/bin/env python3
import argparse
import sys

FILTERED_TYPES = {"pane", "window", "state", "grouped_session"}


def should_filter_session_name(name: str) -> bool:
    return name.isdigit()


def should_keep_line(line: str) -> bool:
    fields = line.rstrip("\n").split("\t")
    if not fields or fields[0] not in FILTERED_TYPES:
        return True

    line_type = fields[0]

    if line_type in {"pane", "window"}:
        return len(fields) < 2 or not should_filter_session_name(fields[1])

    if line_type in {"state", "grouped_session"}:
        sessions = fields[1:3]
        return not any(should_filter_session_name(session) for session in sessions)

    return True


def filter_save(text: str) -> str:
    return "".join(line for line in text.splitlines(keepends=True) if should_keep_line(line))


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Filter unwanted tmux sessions from tmux-resurrect save data."
    )
    parser.parse_args()

    sys.stdout.write(filter_save(sys.stdin.read()))

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
