import shutil
from enum import Enum
from pathlib import Path

from config import UNKNOWN_ARTIST
from youtube import TrackResult


class Layout(Enum):
    FLAT = "flat"  # everything in one folder
    ORGANIZED = "organized"  # artist[/playlist] subfolders


def sanitize(name: str) -> str:
    for ch in '<>:"/\\|?*':
        name = name.replace(ch, "_")
    return name.strip().strip(".")


def resolve_dir(layout: Layout, base_dir: Path, artist: str = "", playlist: str = "") -> Path:
    if layout is Layout.FLAT:
        return base_dir
    folder = base_dir / sanitize(artist or UNKNOWN_ARTIST)
    if playlist:
        folder = folder / sanitize(playlist)
    return folder


def save_track(result: TrackResult, folder: Path) -> None:
    if not result.file or not result.file.exists():
        return
    dest = folder / f"{sanitize(result.title)}{result.file.suffix}"
    shutil.move(str(result.file), str(dest))


def save_all(results: list[TrackResult], folder: Path) -> None:
    folder.mkdir(parents=True, exist_ok=True)
    for r in results:
        save_track(r, folder)
