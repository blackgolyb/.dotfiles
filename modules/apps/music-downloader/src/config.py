from __future__ import annotations

import os
import tomllib
from dataclasses import dataclass, field
from pathlib import Path

APP_NAME = "music-downloader"
UNKNOWN_ARTIST = "Unknown Artist"

DEFAULT_CONFIG = {
    "music_dir": "~/Music",
    "format": "mp3",
}

DEFAULT_CONFIG_TEXT = """\
# music-downloader config
music_dir = "~/Music"   # where downloaded music is stored
format = "mp3"          # mp3 | flac | opus | vorbis | aac | m4a
"""


def _expand(path: str) -> Path:
    return Path(os.path.expandvars(os.path.expanduser(path)))


def _config_path() -> Path:
    base = os.environ.get("XDG_CONFIG_HOME")
    if base:
        return Path(base) / APP_NAME / "config.toml"
    return Path.home() / ".config" / APP_NAME / "config.toml"


@dataclass(frozen=True)
class Config:
    music_dir: Path
    format: str

    @classmethod
    def load(cls) -> Config:
        path = _config_path()
        data = dict(DEFAULT_CONFIG)

        if path.exists():
            with open(path, "rb") as f:
                data.update(tomllib.load(f))
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(DEFAULT_CONFIG_TEXT)

        return cls(
            music_dir=_expand(data.get("music_dir", DEFAULT_CONFIG["music_dir"])),
            format=data.get("format", DEFAULT_CONFIG["format"]),
        )
