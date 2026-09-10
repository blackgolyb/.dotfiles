from dataclasses import dataclass, field
from pathlib import Path

from yt_dlp import YoutubeDL

FORMATS = ["mp3", "flac", "opus", "vorbis", "aac", "m4a"]


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


_YDL_QUIET = {"quiet": True, "no_warnings": True}

MAX_RETRIES = 3


def _download_track(url: str, title: str, tmp_dir: Path, fmt: str) -> TrackResult:
    opts = {
        "format": "bestaudio/best",
        "outtmpl": str(tmp_dir / "%(title)s.%(ext)s"),
        "writethumbnail": True,
        "postprocessors": [
            {"key": "FFmpegExtractAudio", "preferredcodec": fmt, "preferredquality": "0"},
            {"key": "EmbedThumbnail"},
            {"key": "FFmpegMetadata"},
        ],
        "quiet": True,
        "no_warnings": True,
    }
    with YoutubeDL(opts) as ydl:
        info = ydl.extract_info(url, download=True)
        filename = ydl.prepare_filename(info)
        stem = Path(filename).stem
        for ext in (fmt, "webm", "opus", "m4a", "mp4"):
            candidate = tmp_dir / f"{stem}.{ext}"
            if candidate.exists():
                return TrackResult(title=title, url=url, file=candidate)
    return TrackResult(title=title, url=url, error="file not found after download")


def download(url: str, title: str, tmp_dir: Path, fmt: str) -> TrackResult:
    last = None
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            result = _download_track(url, title, tmp_dir, fmt)
            if result.error:
                raise RuntimeError(result.error)
            return result
        except Exception as e:
            last = TrackResult(title=title, url=url, error=str(e))
            print(f"    Attempt {attempt}/{MAX_RETRIES} failed: {title} [{url}] — {e}")
    return last


def probe_playlist(url: str) -> str:
    with YoutubeDL({"extract_flat": True, **_YDL_QUIET}) as ydl:
        info = ydl.extract_info(url, download=False)
    if "entries" not in info:
        return ""
    return info.get("title", "playlist")


def is_playlist(url: str) -> bool:
    return bool(probe_playlist(url))


def get_playlist(url: str) -> PlaylistResult:
    with YoutubeDL({"extract_flat": True, **_YDL_QUIET}) as ydl:
        info = ydl.extract_info(url, download=False)

    tracks = []
    if "entries" in info:
        artist = info.get("artist") or info.get("uploader") or info.get("channel") or ""
        for entry in info["entries"]:
            video_url = entry.get("url") or entry.get("webpage_url")
            if not video_url:
                video_url = f"https://www.youtube.com/watch?v={entry['id']}"
            tracks.append(
                TrackResult(
                    title=entry.get("title", entry.get("id", "unknown")),
                    url=video_url,
                    artist=entry.get("artist")
                    or entry.get("uploader")
                    or entry.get("channel")
                    or artist,
                )
            )
        return PlaylistResult(title=info.get("title", "playlist"), artist=artist, tracks=tracks)

    artist = info.get("artist") or info.get("uploader") or info.get("channel") or ""
    tracks.append(TrackResult(title=info.get("title", "unknown"), url=url, artist=artist))
    return PlaylistResult(title="", artist=artist, tracks=tracks)
