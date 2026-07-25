#!/usr/bin/env python3

"""Manage static and video wallpapers from a writable JSON catalog."""

from __future__ import annotations

import argparse
import json
import os
import random
import shutil
import socket
import subprocess
import sys
import time
import uuid
from pathlib import Path
from typing import Any
from urllib.parse import unquote, urlparse


def xdg_path(variable: str, fallback: str) -> Path:
    return Path(os.environ.get(variable, str(Path.home() / fallback))).expanduser()


CONFIG_HOME = xdg_path("XDG_CONFIG_HOME", ".config")
STATE_HOME = xdg_path("XDG_STATE_HOME", ".local/state")
CATALOG_PATH = CONFIG_HOME / "hypr" / "wallpapers.json"
DEFAULT_CATALOG_PATH = CONFIG_HOME / "hypr" / "wallpapers.defaults.json"
STATE_PATH = STATE_HOME / "hypr" / "wallpaper-manager.json"
CURRENT_WALLPAPER_PATH = xdg_path("XDG_CACHE_HOME", ".cache") / "hypr" / "current-wallpaper"
MPV_SOCKET_PATH = (
    xdg_path("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}") / "mpvpaper-wallpaper.sock"
)
FIT_MODES = ("cover", "contain", "fill")


class WallpaperError(RuntimeError):
    pass


def ytdl_format(audio: bool) -> str:
    video = "bestvideo[height<=1080]"
    if audio:
        return f"{video}+bestaudio/best[height<=1080]/best"
    return f"{video}/best[height<=1080]/best"


def is_youtube_source(source: str) -> bool:
    hostname = (urlparse(source).hostname or "").lower()
    return hostname == "youtu.be" or hostname.endswith(".youtube.com") or hostname == "youtube.com"


def atomic_write(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(f".{path.name}.{os.getpid()}.tmp")
    temporary.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    temporary.replace(path)


def ensure_catalog() -> None:
    if CATALOG_PATH.exists():
        return
    CATALOG_PATH.parent.mkdir(parents=True, exist_ok=True)
    if DEFAULT_CATALOG_PATH.exists():
        shutil.copyfile(DEFAULT_CATALOG_PATH, CATALOG_PATH)
    else:
        atomic_write(CATALOG_PATH, {"version": 1, "wallpapers": []})


def read_catalog() -> dict[str, Any]:
    ensure_catalog()
    try:
        catalog = json.loads(CATALOG_PATH.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise WallpaperError(f"Cannot read {CATALOG_PATH}: {error}") from error

    if not isinstance(catalog, dict) or not isinstance(catalog.get("wallpapers"), list):
        raise WallpaperError(f"{CATALOG_PATH} must contain a wallpapers array")
    return catalog


def expand_source(source: str) -> str:
    values = {
        "HOME": str(Path.home()),
        "XDG_CONFIG_HOME": str(CONFIG_HOME),
        "XDG_STATE_HOME": str(STATE_HOME),
        "XDG_CACHE_HOME": str(xdg_path("XDG_CACHE_HOME", ".cache")),
    }
    expanded = source
    for name, value in values.items():
        expanded = expanded.replace(f"${{{name}}}", value).replace(f"${name}", value)
    return str(Path(expanded).expanduser()) if not urlparse(expanded).scheme else expanded


def normalized_entry(raw: Any) -> dict[str, Any]:
    if not isinstance(raw, dict):
        raise WallpaperError("Each wallpaper must be a JSON object")

    entry_type = raw.get("type")
    source = raw.get("source")
    if entry_type not in {"image", "video"} or not isinstance(source, str) or not source.strip():
        raise WallpaperError("Each wallpaper needs type image|video and a non-empty source")

    try:
        weight = max(0.0, float(raw.get("weight", 1)))
    except (TypeError, ValueError) as error:
        raise WallpaperError(f"Wallpaper {raw.get('id', source)} has an invalid weight") from error

    fit = str(raw.get("fit", "cover")).lower()
    if fit not in FIT_MODES:
        raise WallpaperError(
            f"Wallpaper {raw.get('id', source)} has invalid fit {fit!r}; "
            f"expected {'|'.join(FIT_MODES)}"
        )

    return {
        "id": str(raw.get("id") or uuid.uuid4().hex),
        "name": str(raw.get("name") or display_name(source)),
        "type": entry_type,
        "source": expand_source(source.strip()),
        "loop": bool(raw.get("loop", False)),
        "audio": bool(raw.get("audio", False)),
        "fit": fit,
        "weight": weight,
    }


def entries() -> list[dict[str, Any]]:
    return [normalized_entry(raw) for raw in read_catalog()["wallpapers"]]


def read_state() -> dict[str, Any]:
    try:
        state = json.loads(STATE_PATH.read_text(encoding="utf-8"))
        return state if isinstance(state, dict) else {}
    except (OSError, json.JSONDecodeError):
        return {}


def write_state(entry: dict[str, Any]) -> None:
    atomic_write(
        STATE_PATH,
        {
            "active": entry["id"],
            "type": entry["type"],
            "source": entry["source"],
            "loop": entry["loop"],
            "audio": entry["audio"],
            "fit": entry["fit"],
        },
    )


def stop_process(name: str) -> None:
    subprocess.run(
        ["pkill", "-x", name],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )


def mpv_request(command: list[Any]) -> Any:
    request = json.dumps({"command": command}).encode() + b"\n"
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as connection:
        connection.settimeout(1)
        connection.connect(str(MPV_SOCKET_PATH))
        connection.sendall(request)
        response = b""
        while b"\n" not in response:
            chunk = connection.recv(65536)
            if not chunk:
                break
            response += chunk

    if not response:
        raise WallpaperError("mpvpaper IPC returned no response")
    payload = json.loads(response.splitlines()[0])
    if payload.get("error") != "success":
        raise WallpaperError(f"mpvpaper IPC failed: {payload.get('error', 'unknown error')}")
    return payload.get("data")


def notify(message: str) -> None:
    if shutil.which("notify-send"):
        subprocess.run(["notify-send", "Wallpaper", message], check=False)


def monitor_names() -> list[str]:
    result = subprocess.run(
        ["hyprctl", "monitors", "-j"],
        text=True,
        capture_output=True,
        check=True,
    )
    return [monitor["name"] for monitor in json.loads(result.stdout)]


def play_image(entry: dict[str, Any]) -> None:
    source = Path(entry["source"])
    if not source.is_file():
        raise WallpaperError(f"Image does not exist: {source}")

    stop_process("mpvpaper")
    if not shutil.which("hyprpaper"):
        raise WallpaperError("hyprpaper is not installed")
    if subprocess.run(["pgrep", "-x", "hyprpaper"], check=False).returncode != 0:
        subprocess.Popen(
            ["hyprpaper"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )

    for _ in range(30):
        monitors = monitor_names()
        if monitors and all(
            subprocess.run(
                ["hyprctl", "hyprpaper", "wallpaper", f"{monitor},{source},{entry['fit']}"],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                check=False,
            ).returncode
            == 0
            for monitor in monitors
        ):
            CURRENT_WALLPAPER_PATH.parent.mkdir(parents=True, exist_ok=True)
            CURRENT_WALLPAPER_PATH.unlink(missing_ok=True)
            CURRENT_WALLPAPER_PATH.symlink_to(source.resolve())
            write_state(entry)
            return
        time.sleep(0.1)
    raise WallpaperError("Could not apply wallpaper through hyprpaper")


def play_video(entry: dict[str, Any]) -> None:
    if not shutil.which("mpvpaper"):
        raise WallpaperError("mpvpaper is not installed")

    stop_process("mpvpaper")
    stop_process("hyprpaper")
    MPV_SOCKET_PATH.unlink(missing_ok=True)
    options = []
    if entry["loop"]:
        options.append("loop-file=inf")
    if not entry["audio"]:
        options.append("no-audio")
    if entry["fit"] == "cover":
        options.extend(("keepaspect=yes", "panscan=1.0"))
    elif entry["fit"] == "contain":
        options.extend(("keepaspect=yes", "panscan=0.0"))
    else:
        options.append("keepaspect=no")
    options.append(f"input-ipc-server={MPV_SOCKET_PATH}")
    options.append(f"ytdl-format={ytdl_format(entry['audio'])}")

    command = ["mpvpaper", "--fork"]
    if options:
        command.extend(["--mpv-options", " ".join(options)])
    command.extend(["ALL", entry["source"]])
    result = subprocess.run(command, text=True, capture_output=True, check=False)
    if result.returncode != 0:
        raise WallpaperError(result.stderr.strip() or "mpvpaper failed to start")
    write_state(entry)


def resolve_ytdl_streams(source: str, audio: bool) -> tuple[str, str]:
    result = subprocess.run(
        [
            "yt-dlp",
            "--no-playlist",
            "--dump-single-json",
            "--format",
            ytdl_format(audio),
            source,
        ],
        text=True,
        capture_output=True,
        check=True,
        timeout=20,
    )
    payload = json.loads(result.stdout)
    formats = payload.get("requested_formats")
    if not isinstance(formats, list):
        return str(payload.get("url", "")), ""

    video_source = next(
        (
            str(item.get("url", ""))
            for item in formats
            if isinstance(item, dict) and item.get("vcodec") not in {None, "none"}
        ),
        "",
    )
    audio_source = next(
        (
            str(item.get("url", ""))
            for item in formats
            if isinstance(item, dict) and item.get("acodec") not in {None, "none"}
        ),
        "",
    )
    return video_source, audio_source if audio else ""


def lock_state() -> dict[str, Any]:
    state = read_state()
    if state.get("type") != "video":
        return {
            "type": state.get("type", "image"),
            "handoff": False,
            "fit": state.get("fit", "cover"),
        }

    try:
        mpv_request(["set_property", "pause", True])
        position = mpv_request(["get_property", "time-pos"])
        resolved_source = mpv_request(["get_property", "stream-open-filename"])
        audio_source = ""
        if str(resolved_source).startswith("edl://") or is_youtube_source(
            str(state.get("source", ""))
        ):
            resolved_source, audio_source = resolve_ytdl_streams(
                str(state.get("source", "")),
                bool(state.get("audio", False)),
            )
        if not resolved_source:
            raise WallpaperError("Could not resolve the video stream")
    except (
        OSError,
        TimeoutError,
        WallpaperError,
        json.JSONDecodeError,
        subprocess.SubprocessError,
    ):
        try:
            mpv_request(["set_property", "pause", False])
        except (OSError, TimeoutError, WallpaperError, json.JSONDecodeError):
            pass
        return {
            "type": "video",
            "handoff": False,
            "fit": state.get("fit", "cover"),
        }

    return {
        "type": "video",
        "handoff": True,
        "source": resolved_source or state.get("source", ""),
        "audioSource": audio_source,
        "positionMs": max(0, round(float(position or 0) * 1000)),
        "loop": bool(state.get("loop", False)),
        "audio": bool(state.get("audio", False)),
        "fit": state.get("fit", "cover"),
    }


def resume_video(position_ms: float) -> None:
    if read_state().get("type") != "video":
        return
    mpv_request(["set_property", "time-pos", max(0, position_ms) / 1000])
    mpv_request(["set_property", "pause", False])


def play(entry: dict[str, Any]) -> None:
    if entry["type"] == "image":
        play_image(entry)
    else:
        play_video(entry)


def find_entry(entry_id: str) -> dict[str, Any]:
    for entry in entries():
        if entry["id"] == entry_id:
            return entry
    raise WallpaperError(f"Unknown wallpaper: {entry_id}")


def display_name(source: str) -> str:
    parsed = urlparse(source)
    name = Path(unquote(parsed.path)).name if parsed.scheme else Path(source).name
    return name or parsed.netloc or "Video wallpaper"


def add_video(
    url: str,
    name: str | None,
    loop: bool,
    audio: bool,
    fit: str,
) -> dict[str, Any]:
    url = url.strip()
    if not url:
        raise WallpaperError("URL cannot be empty")

    catalog = read_catalog()
    entry = {
        "id": f"video-{uuid.uuid4().hex[:12]}",
        "name": name.strip() if name and name.strip() else display_name(url),
        "type": "video",
        "source": url,
        "loop": loop,
        "audio": audio,
        "fit": fit,
    }
    catalog["wallpapers"].append(entry)
    atomic_write(CATALOG_PATH, catalog)
    return normalized_entry(entry)


def list_command() -> None:
    state = read_state()
    print(
        json.dumps({"active": state.get("active", ""), "wallpapers": entries()}, ensure_ascii=False)
    )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    subparsers.add_parser("list", help="print the resolved catalog as JSON")

    play_parser = subparsers.add_parser("play", help="play a catalog entry")
    play_parser.add_argument("id")

    random_parser = subparsers.add_parser("random", help="play a random catalog entry")
    random_parser.add_argument("--type", choices=("image", "video"))

    add_parser = subparsers.add_parser("add", help="add a video URL to the catalog")
    add_parser.add_argument("url")
    add_parser.add_argument("--name")
    add_parser.add_argument("--loop", action="store_true")
    add_parser.add_argument("--audio", action="store_true")
    add_parser.add_argument("--fit", choices=FIT_MODES, default="cover")
    add_parser.add_argument("--play", action="store_true")

    subparsers.add_parser("lock-state", help="pause video and print lock-screen handoff state")

    resume_parser = subparsers.add_parser("resume", help="resume video after a lock-screen handoff")
    resume_parser.add_argument("--position-ms", type=float, required=True)

    subparsers.add_parser("stop", help="stop the active wallpaper backend")
    return parser


def main() -> int:
    args = build_parser().parse_args()
    if args.command == "list":
        list_command()
    elif args.command == "play":
        play(find_entry(args.id))
    elif args.command == "random":
        candidates = [
            entry for entry in entries() if args.type is None or entry["type"] == args.type
        ]
        if not candidates:
            raise WallpaperError("No matching wallpapers in the catalog")
        weights = [entry["weight"] for entry in candidates]
        if not any(weights):
            raise WallpaperError("Matching wallpapers all have zero weight")
        play(random.choices(candidates, weights=weights, k=1)[0])
    elif args.command == "add":
        entry = add_video(args.url, args.name, args.loop, args.audio, args.fit)
        if args.play:
            play(entry)
        print(entry["id"])
    elif args.command == "lock-state":
        print(json.dumps(lock_state(), ensure_ascii=False))
    elif args.command == "resume":
        resume_video(args.position_ms)
    elif args.command == "stop":
        stop_process("mpvpaper")
        stop_process("hyprpaper")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (WallpaperError, OSError, subprocess.SubprocessError, json.JSONDecodeError) as error:
        notify(str(error))
        print(f"wallpaper-manager: {error}", file=sys.stderr)
        raise SystemExit(1)
