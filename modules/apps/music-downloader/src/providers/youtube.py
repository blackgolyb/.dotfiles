import re
from pathlib import Path
from typing import List

from yt_dlp import YoutubeDL

from .base import AlbumResult, ArtistResult, Format, PlaylistResult, TrackResult

_MAX_RETRIES = 3
_CHANNEL_PATTERN = re.compile(r"https?://music\.youtube\.com/(channel/UC[\w-]+|@[\w.-]+)")
_YDL_QUIET = {"quiet": True, "no_warnings": True}


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
    for attempt in range(1, _MAX_RETRIES + 1):
        try:
            result = _download_track(url, title, tmp_dir, fmt)
            if result.error:
                raise RuntimeError(result.error)
            return result
        except Exception as e:
            last = TrackResult(title=title, url=url, error=str(e))
            print(f"    Attempt {attempt}/{_MAX_RETRIES} failed: {title} [{url}] — {e}")
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


def is_artist(url: str) -> bool:
    return bool(_CHANNEL_PATTERN.search(url))


def probe_artist(url: str) -> str:
    if not _CHANNEL_PATTERN.search(url):
        return ""
    with YoutubeDL({"extract_flat": True, **_YDL_QUIET}) as ydl:
        info = ydl.extract_info(url, download=False)
    if "entries" not in info:
        return ""
    return info.get("artist") or info.get("uploader") or info.get("channel") or ""


def get_artist(url: str) -> ArtistResult:
    with YoutubeDL({"extract_flat": True, **_YDL_QUIET}) as ydl:
        info = ydl.extract_info(url, download=False)

    artist_name = (
        info.get("artist") or info.get("uploader") or info.get("channel") or "Unknown Artist"
    )

    # Group tracks by album
    albums_dict: dict[str, list[TrackResult]] = {}

    if "entries" in info:
        for entry in info["entries"]:
            entry_url = entry.get("url") or entry.get("webpage_url")
            if not entry_url:
                entry_url = f"https://www.youtube.com/watch?v={entry['id']}"

            # Get detailed info for this track to get album information
            track_info = None
            try:
                with YoutubeDL({"extract_flat": False, **_YDL_QUIET}) as ydl_track:
                    track_info = ydl_track.extract_info(entry_url, download=False)
            except Exception:
                # Fallback to basic info if detailed extraction fails
                track_info = entry

            album_name = track_info.get("album") or track_info.get("album")
            if album_name is None or album_name == "":
                album_name = "Unknown Album"

            track_title = track_info.get("title", entry.get("title", entry.get("id", "unknown")))

            track = TrackResult(
                title=track_title,
                url=entry_url,
                artist=artist_name,
            )

            if album_name not in albums_dict:
                albums_dict[album_name] = []
            albums_dict[album_name].append(track)
    else:
        # Single video case
        track_info = info
        album_name = track_info.get("album") or track_info.get("album")
        if album_name is None or album_name == "":
            album_name = "Unknown Album"

        track = TrackResult(
            title=track_info.get("title", "unknown"),
            url=url,
            artist=artist_name,
        )
        albums_dict[album_name] = [track]

    # Convert to AlbumResult objects
    albums: list[AlbumResult] = [
        AlbumResult(title=album_name, tracks=tracks) for album_name, tracks in albums_dict.items()
    ]

    return ArtistResult(name=artist_name, url=url, albums=albums)


class YouTubeProvider:
    def matches(self, url: str) -> bool:
        return "music.youtube.com" in url or "youtube.com" in url

    def is_artist(self, url: str) -> bool:
        return is_artist(url)

    def is_playlist(self, url: str) -> bool:
        return is_playlist(url)

    def get_artist(self, url: str) -> ArtistResult:
        return get_artist(url)

    def get_playlist(self, url: str) -> PlaylistResult:
        return get_playlist(url)

    def get_track(self, url: str) -> TrackResult:
        # Simple fallback: get playlist and take first track
        playlist = self.get_playlist(url)
        if playlist.tracks:
            return playlist.tracks[0]
        # If no tracks, treat as single track with unknown title
        from .base import TrackResult

        return TrackResult(title="unknown", url=url, artist="")

    def download(self, url: str, title: str, tmp_dir: Path, fmt: Format) -> TrackResult:
        return download(url, title, tmp_dir, fmt.name.lower())
