{ writeShellApplication, wl-clipboard, xclip }:

writeShellApplication {
  name = "copy-to-clipboard";

  runtimeInputs = [
    wl-clipboard
    xclip
  ];

  text = ''
    if [ -n "''${WAYLAND_DISPLAY:-}" ] && [ -n "''${XDG_RUNTIME_DIR:-}" ]; then
      exec wl-copy
    fi

    if [ -n "''${DISPLAY:-}" ]; then
      exec xclip -selection clipboard -in
    fi

    mkdir -p "$HOME/.cache"
    cat > "$HOME/.cache/tmux-buffer"
  '';
}
