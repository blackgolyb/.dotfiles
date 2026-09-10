#!/usr/bin/env python3
import argparse
from pathlib import Path

from config import Config
from core import run
from save import Layout
from youtube import FORMATS


def main():
    config = Config.load()

    parser = argparse.ArgumentParser(description="Download music from YouTube Music")
    parser.add_argument("url", help="YouTube Music URL (track or playlist)")
    parser.add_argument("-o", "--output", help="Output directory (default: config music_dir)")
    parser.add_argument(
        "-f",
        "--format",
        choices=FORMATS,
        default=config.format,
        help=f"Audio format (default: {config.format})",
    )
    args = parser.parse_args()

    out_dir = Path(args.output) if args.output else config.music_dir
    layout = Layout.FLAT if args.output else Layout.ORGANIZED

    run(args.url, out_dir, args.format, layout)


if __name__ == "__main__":
    main()
