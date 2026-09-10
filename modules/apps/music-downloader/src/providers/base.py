from dataclasses import dataclass, field
from enum import Enum, auto
from pathlib import Path
from typing import Protocol, runtime_checkable


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


@dataclass
class TrackResult:
    title: str
    url: str
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
    def matches(self, url: str) -> bool: ...
    def is_artist(self, url: str) -> bool: ...
    def is_playlist(self, url: str) -> bool: ...
    def get_artist(self, url: str) -> ArtistResult: ...
    def get_playlist(self, url: str) -> PlaylistResult: ...
    def get_track(self, url: str) -> TrackResult: ...
    def download(self, url: str, title: str, tmp_dir: Path, fmt: Format) -> TrackResult: ...
