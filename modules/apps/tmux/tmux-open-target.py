import argparse
import os
import re
import shlex
import subprocess
import sys
import tempfile
import time
from pathlib import Path

URL_RE = re.compile(r"^(?:https?|file)://|^mailto:")
ANSI_RE = re.compile(r"\x1b\[[0-?]*[ -/]*[@-~]")


def tmux(*args: str, check: bool = True) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["tmux", *args],
        check=check,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
    )


def display(message: str, pane: str | None = None) -> None:
    args = ["display-message"]
    if pane:
        args.extend(["-t", pane])
    args.append(message)
    tmux(*args, check=False)


def pane_info(pane: str) -> tuple[int, int, Path]:
    output = tmux(
        "display-message",
        "-p",
        "-t",
        pane,
        "#{pane_in_mode}\t#{cursor_x}\t#{cursor_y}\t#{copy_cursor_x}\t#{copy_cursor_y}\t#{pane_current_path}",
    ).stdout.rstrip("\n")
    pane_in_mode, cursor_x, cursor_y, copy_cursor_x, copy_cursor_y, cwd = output.split("\t", 5)

    if pane_in_mode == "1" and copy_cursor_x != "" and copy_cursor_y != "":
        return int(copy_cursor_x), int(copy_cursor_y), Path(cwd)

    return int(cursor_x), int(cursor_y), Path(cwd)


def capture_line(pane: str, y: int) -> str:
    output = tmux("capture-pane", "-p", "-J", "-t", pane, "-S", str(y), "-E", str(y)).stdout
    return ANSI_RE.sub("", output.rstrip("\n"))


def pane_cwd(pane: str) -> Path:
    return Path(
        tmux("display-message", "-p", "-t", pane, "#{pane_current_path}").stdout.rstrip("\n")
    )


def selection_is_active(pane: str) -> bool:
    proc = tmux("display-message", "-p", "-t", pane, "#{selection_active}", check=False)
    return proc.returncode == 0 and proc.stdout.strip() == "1"


def selected_text(pane: str) -> str:
    if not selection_is_active(pane):
        return ""

    fd, path = tempfile.mkstemp(prefix="tmux-open-target-")
    os.close(fd)
    output_path = Path(path)

    try:
        tmux(
            "send-keys",
            "-t",
            pane,
            "-X",
            "copy-pipe-no-clear",
            "cat > " + shlex.quote(str(output_path)),
            check=False,
        )

        deadline = time.monotonic() + 1
        while time.monotonic() < deadline:
            text = output_path.read_text(errors="replace")
            if text:
                return text
            time.sleep(0.02)

        return output_path.read_text(errors="replace")
    finally:
        output_path.unlink(missing_ok=True)


def is_delimiter(char: str) -> bool:
    return char.isspace() or char in "<>\"'`()[]{}"


def token_at(line: str, x: int) -> str:
    if not line:
        return ""

    index = min(max(x, 0), len(line) - 1)
    if is_delimiter(line[index]):
        if index > 0 and not is_delimiter(line[index - 1]):
            index -= 1
        elif index + 1 < len(line) and not is_delimiter(line[index + 1]):
            index += 1
        else:
            return ""

    start = index
    while start > 0 and not is_delimiter(line[start - 1]):
        start -= 1

    end = index + 1
    while end < len(line) and not is_delimiter(line[end]):
        end += 1

    return clean_token(line[start:end])


def clean_token(token: str) -> str:
    token = token.strip().strip("\"'`<>")
    while token and token[0] in "([{":
        token = token[1:]
    while token and token[-1] in ".,;)]}":
        token = token[:-1]
    return token


def target_candidates(text: str) -> list[str]:
    return [candidate for part in text.split() if (candidate := clean_token(part))]


def is_url_target(target: str) -> bool:
    return bool(URL_RE.search(clean_token(target)))


def split_file_location(token: str) -> tuple[str, int | None, int | None]:
    match = re.match(r"^(.*):(\d+):(\d+)$", token)
    if match:
        return match.group(1), int(match.group(2)), int(match.group(3))

    match = re.match(r"^(.*):(\d+)$", token)
    if match:
        return match.group(1), int(match.group(2)), None

    return token, None, None


def resolve_path(path_text: str, cwd: Path) -> Path:
    expanded = Path(os.path.expanduser(path_text))
    if expanded.is_absolute():
        return expanded
    return cwd / expanded


def target_from_text(text: str, cwd: Path) -> str:
    candidates = target_candidates(text)
    if not candidates:
        return ""

    for candidate in candidates:
        if is_url_target(candidate):
            return candidate

    for candidate in candidates:
        path_text, _, _ = split_file_location(candidate)
        path = resolve_path(path_text, cwd)
        if path.exists():
            return candidate

    if len(candidates) == 1:
        return candidates[0]

    return clean_token(text)


def nvr_args(server: str, path: Path, line: int | None, column: int | None) -> list[str]:
    base = ["nvr", "--servername", server, "--remote"]

    if line and column:
        return [*base, f"+call cursor({line},{column})", str(path)]
    if line:
        return [*base, f"+{line}", str(path)]
    return [*base, str(path)]


def nvr_serverlist() -> list[str]:
    try:
        proc = subprocess.run(
            ["nvr", "--serverlist"],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
    except FileNotFoundError:
        return []

    stdout = proc.stdout.strip()
    if proc.returncode != 0:
        return []

    return [line for line in stdout.splitlines() if line]


def nvr_ui_count(server: str) -> int:
    proc = subprocess.run(
        ["nvr", "--servername", server, "--remote-expr", "len(nvim_list_uis())"],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        check=False,
    )

    stdout = proc.stdout.strip()
    if proc.returncode != 0:
        return 0

    try:
        return int(stdout)
    except ValueError:
        return 0


def select_nvr_server() -> str | None:
    servers = nvr_serverlist()
    env_server = os.getenv("NVIM_LISTEN_ADDRESS") or os.getenv("NVIM")

    ordered_servers = []
    if env_server and env_server in servers:
        ordered_servers.append(env_server)
    ordered_servers.extend(server for server in servers if server not in ordered_servers)

    for server in ordered_servers:
        if nvr_ui_count(server) > 0:
            return server

    if ordered_servers:
        return ordered_servers[0]

    return None


def open_target(target: str, cwd: Path, pane: str | None, source: str = "cursor") -> int:
    target = target_from_text(target, cwd)
    if not target:
        display(f"No URL or file target under {source}", pane)
        return 0

    if is_url_target(target):
        args = ["xdg-open", target]
        subprocess.Popen(args, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return 0

    path_text, line, column = split_file_location(target)
    path = resolve_path(path_text, cwd)
    if not path.exists():
        display(f"Not an existing file: {target}", pane)
        return 0

    server = select_nvr_server()
    if not server:
        display("No nvr server found", pane)
        return 0

    args = nvr_args(server, path, line, column)
    subprocess.Popen(args, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Open URL or file target from tmux cursor/mouse coordinates."
    )
    parser.add_argument("--pane", default=None)
    parser.add_argument("--x", type=int, default=None)
    parser.add_argument("--y", type=int, default=None)
    parser.add_argument("--target", default=None)
    parser.add_argument("--cwd", default=None)
    args = parser.parse_args()

    pane = args.pane

    if args.target is not None and args.cwd is not None:
        return open_target(args.target, Path(args.cwd), pane)

    pane = pane or tmux("display-message", "-p", "#{pane_id}").stdout.strip()

    if args.target is not None:
        cwd = pane_info(pane)[2]
        return open_target(args.target, cwd, pane)

    selection = selected_text(pane)
    if selection:
        return open_target(selection, pane_cwd(pane), pane, "selection")

    cursor_x, cursor_y, cwd = pane_info(pane)
    x = args.x if args.x is not None else cursor_x
    y = args.y if args.y is not None else cursor_y
    return open_target(token_at(capture_line(pane, y), x), cwd, pane)


if __name__ == "__main__":
    sys.exit(main())
