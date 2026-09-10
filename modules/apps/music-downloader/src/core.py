import tempfile
from pathlib import Path

from providers import get_provider
from providers.base import Format, TrackResult
from save import Layout, resolve_dir, sanitize, save_all


def _download_tracks(
    tracks: list[TrackResult], out_dir: Path, fmt: Format
) -> tuple[list[TrackResult], list[TrackResult]]:
    done, failed = [], []
    total = len(tracks)
    with tempfile.TemporaryDirectory() as tmp:
        tmp_dir = Path(tmp)
        for i, track in enumerate(tracks, 1):
            print(f"[{i}/{total}] {track.title}")
            provider = get_provider(track.url)
            if provider is None:
                result = TrackResult(title=track.title, url=track.url, error="No provider found")
            else:
                result = provider.download(track.url, track.title, tmp_dir, fmt)
            if result.error:
                print(f"  ERROR: {track.title} [{track.url}] — {result.error}")
                failed.append(result)
            else:
                print(f"  Downloaded: {result.title}")
                done.append(result)
        save_all(done, out_dir)
    return done, failed


def run_single(url: str, base_dir: Path, fmt: Format, layout: Layout) -> TrackResult:
    provider = get_provider(url)
    if provider is None:
        raise ValueError(f"No provider found for URL: {url}")
    playlist = provider.get_playlist(url)
    track = playlist.tracks[0]
    out_dir = resolve_dir(layout, base_dir, artist=track.artist)
    print("Single track detected\n")
    done, failed = _download_tracks([track], out_dir, fmt)
    if failed:
        print(f"\nFAILED: {failed[0].title} [{failed[0].url}] - {failed[0].error}")
        raise SystemExit(1)
    print("\nDone!")
    return done[0]


def run_playlist(url: str, base_dir: Path, fmt: Format, layout: Layout) -> PlaylistResult:
    provider = get_provider(url)
    if provider is None:
        raise ValueError(f"No provider found for URL: {url}")
    playlist = provider.get_playlist(url)
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


def run_artist(url: str, base_dir: Path, fmt: Format, layout: Layout) -> ArtistResult:
    provider = get_provider(url)
    if provider is None:
        raise ValueError(f"No provider found for URL: {url}")
    artist = provider.get_artist(url)

    if not artist.albums:
        print(f"No albums found for {artist.name}")
        return artist

    print(f"Artist: {artist.name}")
    print(f"Albums: {len(artist.albums)}")
    total_tracks = sum(len(album.tracks) for album in artist.albums)
    print(f"Tracks: {total_tracks}\n")

    all_failed = []
    for album in artist.albums:
        album_dir = resolve_dir(layout, base_dir, artist=artist.name, playlist=album.title)
        album_dir.mkdir(parents=True, exist_ok=True)

        print(f"Album: {album.title}")
        print(f"Folder: {album_dir}")
        print(f"Tracks: {len(album.tracks)}\n")

        _, failed = _download_tracks(album.tracks, album_dir, fmt)
        all_failed.extend(failed)

    if all_failed:
        print(f"\n--- Failed ({len(all_failed)}) ---")
        for r in all_failed:
            print(f"  {r.title}")
            print(f"  {r.url}")
            print(f"  {r.error}")

    print("\nDone!")
    return artist


def run(url: str, base_dir: Path, fmt: Format, is_external_dir: bool):
    provider = get_provider(url)
    if provider is None:
        raise ValueError(f"No provider found for URL: {url}")
    if provider.is_artist(url):
        # For artist downloads, determine layout based on whether output directory was specified
        layout = Layout.PLAYLIST if is_external_dir else Layout.ARTIST_AND_PLAYLIST
        run_artist(url, base_dir, fmt, layout)
    elif provider.is_playlist(url):
        run_playlist(
            url, base_dir, fmt, Layout.FLAT if is_external_dir else Layout.ARTIST_AND_PLAYLIST
        )
    else:
        run_single(
            url, base_dir, fmt, Layout.FLAT if is_external_dir else Layout.ARTIST_AND_PLAYLIST
        )
