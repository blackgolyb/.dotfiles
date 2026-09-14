from dataclasses import dataclass, field
from enum import Enum, auto
from pathlib import Path
from threading import Lock
from typing import Callable, Protocol, runtime_checkable


class Format(Enum):
    MP3 = auto()
    FLAC = auto()
    OPUS = auto()
    VORBIS = auto()
    AAC = auto()
    M4A = auto()

    @classmethod
    def to_list(cls) -> list[str]:
        return [f.name.lower() for f in cls]

    @classmethod
    def from_str(cls, value: str) -> "Format":
        try:
            return cls[value.upper()]
        except KeyError:
            raise ValueError(f"Invalid format: {value}")


class DownloadProgress:
    def __init__(self, total: int = 0, on_advance: Callable[[str], None] | None = None):
        self.total = total
        self.completed = 0
        self.failed = 0
        self.on_advance = on_advance
        self.lock = Lock()

    def done(self, label: str = ""):
        with self.lock:
            self.completed += 1
            self._advance(label)

    def fail(self, label: str = ""):
        with self.lock:
            self.failed += 1
            self._advance(label)

    def _advance(self, label: str):
        if self.on_advance is not None:
            self.on_advance(label)


@dataclass
class TrackResult:
    title: str
    url: str
    provider: str = ""
    artist: str = ""
    file: Path | None = None
    error: str | None = None


@dataclass
class PlaylistResult:
    title: str
    artist: str = ""
    tracks: list[TrackResult] = field(default_factory=list)


@dataclass
class AlbumResult:
    title: str
    tracks: list[TrackResult] = field(default_factory=list)


@dataclass
class ArtistResult:
    name: str
    url: str
    albums: list[AlbumResult] = field(default_factory=list)


@runtime_checkable
class MusicProvider(Protocol):
    name: str

    def matches(self, url: str) -> bool: ...
    def is_artist(self, url: str) -> bool: ...
    def is_playlist(self, url: str) -> bool: ...
    def get_artist(self, url: str, progress: DownloadProgress | None = None) -> ArtistResult: ...
    def get_playlist(self, url: str) -> PlaylistResult: ...
    def get_track(self, url: str) -> TrackResult: ...
    def download(self, url: str, title: str, tmp_dir: Path, fmt: Format) -> TrackResult: ...
    def download_tracks(
        self,
        tracks: list[TrackResult],
        work_dir: Path,
        fmt: Format,
        progress: DownloadProgress,
    ) -> tuple[list[TrackResult], list[TrackResult]]: ...
