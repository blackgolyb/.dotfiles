import tempfile
from pathlib import Path

from save import Layout, resolve_dir, save_all
from youtube import (
    PlaylistResult,
    TrackResult,
    download,
    get_playlist,
    is_playlist,
)


def _download_tracks(
    tracks: list[TrackResult], out_dir: Path, fmt: str
) -> tuple[list[TrackResult], list[TrackResult]]:
    done, failed = [], []
    total = len(tracks)
    with tempfile.TemporaryDirectory() as tmp:
        tmp_dir = Path(tmp)
        for i, track in enumerate(tracks, 1):
            print(f"[{i}/{total}] {track.title}")
            result = download(track.url, track.title, tmp_dir, fmt)
            if result.error:
                print(f"  ERROR: {track.title} [{track.url}] — {result.error}")
                failed.append(result)
            else:
                print(f"  Downloaded: {result.title}")
                done.append(result)
        save_all(done, out_dir)
    return done, failed


def run_single(url: str, base_dir: Path, fmt: str, layout: Layout) -> TrackResult:
    playlist = get_playlist(url)
    track = playlist.tracks[0]
    out_dir = resolve_dir(layout, base_dir, artist=track.artist)
    print("Single track detected\n")
    done, failed = _download_tracks([track], out_dir, fmt)
    if failed:
        print(f"\nFAILED: {failed[0].title} [{failed[0].url}] - {failed[0].error}")
        raise SystemExit(1)
    print("\nDone!")
    return done[0]


def run_playlist(url: str, base_dir: Path, fmt: str, layout: Layout) -> PlaylistResult:
    playlist = get_playlist(url)
    out_dir = resolve_dir(layout, base_dir, artist=playlist.artist, playlist=playlist.title)
    out_dir.mkdir(parents=True, exist_ok=True)

    print(f"Playlist: {playlist.title}")
    print(f"Folder:   {out_dir}")
    print(f"Tracks:   {len(playlist.tracks)}\n")

    done, failed = _download_tracks(playlist.tracks, out_dir, fmt)

    if failed:
        print(f"\n--- Failed ({len(failed)}) ---")
        for r in failed:
            print(f"  {r.title}")
            print(f"  {r.url}")
            print(f"  {r.error}")

    print("\nDone!")
    return playlist


def run(url: str, base_dir: Path, fmt: str, layout: Layout):
    if is_playlist(url):
        run_playlist(url, base_dir, fmt, layout)
    else:
        run_single(url, base_dir, fmt, layout)
