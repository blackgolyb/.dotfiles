{ pkgs, ... }:

{
  home.packages = with pkgs; [
    brightnessctl
    cliphist
    curl
    hyprpicker
    hyprprop
    jq
    libnotify
    mpvpaper
    pamixer
    playerctl
    hyprpaper
    qrencode
    quickshell
    wl-clipboard
    (writeShellScriptBin "qsm" ''
      set -eu

      config_path="''${XDG_CONFIG_HOME:-$HOME/.config}/quickshell"
      qs_args=()

      while [ "$#" -gt 0 ]; do
        case "$1" in
          -p)
            if [ "$#" -lt 2 ]; then
              echo "error: -p requires a path argument" >&2
              exit 1
            fi
            config_path="$2"
            shift 2
            ;;
          *)
            qs_args+=("$1")
            shift
            ;;
        esac
      done

      rm -rf "$HOME/.cache/quickshell/qmlcache/"

      export QML2_IMPORT_PATH="$config_path''${QML2_IMPORT_PATH:+:$QML2_IMPORT_PATH}"
      export QML_IMPORT_PATH="$config_path''${QML_IMPORT_PATH:+:$QML_IMPORT_PATH}"

      exec qs -p "$config_path" "''${qs_args[@]}"
    '')
    (writeShellScriptBin "lock" ''
      exec qs ipc call lock open
    '')
  ];

  xdg.configFile."hypr/hyprland.lua".source = ./hyprland.lua;

  xdg.configFile."hypr/hyprpaper.conf".text = ''
    splash = false
    ipc = on
  '';

  xdg.configFile."quickshell/shell.qml".source = ./quickshell/shell.qml;

  xdg.configFile."quickshell/Src".source = ./quickshell/Src;

  xdg.configFile."quickshell/battery_icons".source = ../../resources/battery_icons;

  xdg.configFile."hypr/wallpapers".source = ../../resources/wallpapers;

  xdg.dataFile."icons/qtile-cursors/cursors".source = ../../resources/cursors;

  xdg.dataFile."icons/qtile-cursors/index.theme".text = ''
    [Icon Theme]
    Name=qtile-cursors
  '';

  xdg.configFile."hypr/scripts/autostart.sh" = {
    source = ./scripts/autostart.sh;
    executable = true;
  };

  xdg.configFile."hypr/scripts/brightness_control" = {
    source = ./scripts/brightness_control;
    executable = true;
  };

  xdg.configFile."hypr/scripts/device_manager" = {
    source = ./scripts/device_manager;
    executable = true;
  };

  xdg.configFile."hypr/scripts/multi_monitor" = {
    source = ./scripts/multi_monitor;
    executable = true;
  };

  xdg.configFile."hypr/scripts/pick_color" = {
    source = ./scripts/pick_color;
    executable = true;
  };

  xdg.configFile."hypr/scripts/screenshot" = {
    source = ./scripts/screenshot;
    executable = true;
  };

  xdg.configFile."hypr/scripts/video_wallpaper" = {
    source = ./scripts/video_wallpaper;
    executable = true;
  };

  xdg.configFile."hypr/scripts/volume_control" = {
    source = ./scripts/volume_control;
    executable = true;
  };

  xdg.configFile."hypr/scripts/wallpaper_control" = {
    source = ./scripts/wallpaper_control;
    executable = true;
  };
}
