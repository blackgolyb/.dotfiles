#!/usr/bin/env python3
import argparse
from pathlib import Path

from config import Config
from core import run
from providers.base import Format
from save import Layout


def main():
    config = Config.load()

    parser = argparse.ArgumentParser(description="Download music from YouTube Music")
    parser.add_argument(
        "url",
        help="YouTube Music URL (track, playlist, or artist channel)",
    )
    parser.add_argument("-o", "--output", help="Output directory (default: config music_dir)")
    parser.add_argument(
        "-f",
        "--format",
        choices=Format.to_list(),
        default=config.format,
        help=f"Audio format (default: {config.format})",
    )
    args = parser.parse_args()

    out_dir = Path(args.output) if args.output else config.music_dir
    fmt_enum = Format.from_str(args.format)

    run(args.url, out_dir, fmt_enum, bool(args.output))


if __name__ == "__main__":
    main()
