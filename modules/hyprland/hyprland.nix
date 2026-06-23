{ config, lib, pkgs, ... }:

let
  inherit (import ../dotfiles/lib.nix { inherit config lib; }) dotfileConfig dotfileData;
in
lib.mkMerge [
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

  xdg.configFile."hypr/hyprpaper.conf".text = ''
    splash = false
    ipc = on
  '';

  xdg.dataFile."icons/qtile-cursors/index.theme".text = ''
    [Icon Theme]
    Name=qtile-cursors
  '';
}
  (dotfileConfig "hypr/hyprland.lua" "modules/hyprland/hyprland.lua" ./hyprland.lua { })
  (dotfileConfig "quickshell/shell.qml" "modules/hyprland/quickshell/shell.qml" ./quickshell/shell.qml { })
  (dotfileConfig "quickshell/Src" "modules/hyprland/quickshell/Src" ./quickshell/Src { })
  (dotfileConfig "quickshell/battery_icons" "resources/battery_icons" ../../resources/battery_icons { })
  (dotfileConfig "hypr/wallpapers" "resources/wallpapers" ../../resources/wallpapers { })
  (dotfileData "icons/qtile-cursors/cursors" "resources/cursors" ../../resources/cursors { })
  (dotfileConfig "hypr/scripts/autostart.sh" "modules/hyprland/scripts/autostart.sh" ./scripts/autostart.sh { executable = true; })
  (dotfileConfig "hypr/scripts/brightness_control" "modules/hyprland/scripts/brightness_control" ./scripts/brightness_control { executable = true; })
  (dotfileConfig "hypr/scripts/device_manager" "modules/hyprland/scripts/device_manager" ./scripts/device_manager { executable = true; })
  (dotfileConfig "hypr/scripts/multi_monitor" "modules/hyprland/scripts/multi_monitor" ./scripts/multi_monitor { executable = true; })
  (dotfileConfig "hypr/scripts/pick_color" "modules/hyprland/scripts/pick_color" ./scripts/pick_color { executable = true; })
  (dotfileConfig "hypr/scripts/screenshot" "modules/hyprland/scripts/screenshot" ./scripts/screenshot { executable = true; })
  (dotfileConfig "hypr/scripts/video_wallpaper" "modules/hyprland/scripts/video_wallpaper" ./scripts/video_wallpaper { executable = true; })
  (dotfileConfig "hypr/scripts/volume_control" "modules/hyprland/scripts/volume_control" ./scripts/volume_control { executable = true; })
  (dotfileConfig "hypr/scripts/wallpaper_control" "modules/hyprland/scripts/wallpaper_control" ./scripts/wallpaper_control { executable = true; })
]
