import tempfile
from itertools import groupby
from operator import attrgetter
from pathlib import Path

from providers import MusicProvider, get_provider
from providers.base import ArtistResult, DownloadProgress, Format, PlaylistResult, TrackResult
from save import Layout, resolve_dir, save_all
from tqdm import tqdm


def _advance_bar(bar, progress: DownloadProgress, label: str) -> None:
    if progress.total and bar.total != progress.total:
        bar.total = progress.total
        bar.refresh()
    if label:
        bar.set_postfix_str(label, refresh=False)
    bar.update(1)


def download_tracks(
    tracks: list[TrackResult],
    work_dir: Path,
    fmt: Format,
    providers: dict[str, MusicProvider],
) -> tuple[list[TrackResult], list[TrackResult]]:
    downloaded = []
    failed = []

    for provider_name, group in groupby(tracks, attrgetter("provider")):
        group_list = list(group)
        provider = providers[provider_name]

        with tqdm(total=len(group_list), desc=provider_name, unit="track") as bar:
            progress = DownloadProgress(
                total=len(group_list), on_advance=lambda label: _advance_bar(bar, progress, label)
            )
            done, fail = provider.download_tracks(group_list, work_dir, fmt, progress)

        downloaded.extend(done)
        failed.extend(fail)

    return (downloaded, failed)


def run_single(url: str, base_dir: Path, fmt: Format, layout: Layout) -> TrackResult:
    provider = get_provider(url)
    if provider is None:
        raise ValueError(f"No provider found for URL: {url}")
    playlist = provider.get_playlist(url)
    track = playlist.tracks[0]
    out_dir = resolve_dir(layout, base_dir, artist=track.artist)
    print("Single track detected\n")
    with tempfile.TemporaryDirectory() as tmp:
        done, failed = download_tracks([track], Path(tmp), fmt, {provider.name: provider})
        save_all(done, out_dir)
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

    with tempfile.TemporaryDirectory() as tmp:
        done, failed = download_tracks(playlist.tracks, Path(tmp), fmt, {provider.name: provider})
        save_all(done, out_dir)

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
    with tqdm(unit="track", desc=f"Fetching {provider.name}") as bar:
        progress = DownloadProgress(on_advance=lambda label: _advance_bar(bar, progress, label))
        artist = provider.get_artist(url, progress)

    if not artist.albums:
        print(f"No albums found for {artist.name}")
        return artist

    print(f"Artist: {artist.name}")
    print(f"Albums: {len(artist.albums)}")
    total_tracks = sum(len(album.tracks) for album in artist.albums)
    print(f"Tracks: {total_tracks}\n")

    all_failed = []
    with tempfile.TemporaryDirectory() as tmp:
        tmp_root = Path(tmp)
        for i, album in enumerate(artist.albums):
            album_dir = resolve_dir(layout, base_dir, artist=artist.name, playlist=album.title)
            album_dir.mkdir(parents=True, exist_ok=True)

            print(f"Album: {album.title}")
            print(f"Folder: {album_dir}")
            print(f"Tracks: {len(album.tracks)}\n")

            work_dir = tmp_root / str(i)
            work_dir.mkdir(parents=True, exist_ok=True)
            done, failed = download_tracks(album.tracks, work_dir, fmt, {provider.name: provider})
            save_all(done, album_dir)
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
