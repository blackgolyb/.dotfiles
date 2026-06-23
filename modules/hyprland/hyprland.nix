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

  xdg.configFile."hypr/hyprpaper.conf".text = ''
    splash = false
    ipc = on
  '';

  xdg.dataFile."icons/qtile-cursors/index.theme".text = ''
    [Icon Theme]
    Name=qtile-cursors
  '';

  dotfiles.config = {
    "hypr/hyprland.lua" = {
      path = "modules/hyprland/hyprland.lua";
      source = ./hyprland.lua;
    };

    "quickshell/shell.qml" = {
      path = "modules/hyprland/quickshell/shell.qml";
      source = ./quickshell/shell.qml;
    };

    "quickshell/Src" = {
      path = "modules/hyprland/quickshell/Src";
      source = ./quickshell/Src;
    };

    "quickshell/battery_icons" = {
      path = "resources/battery_icons";
      source = ../../resources/battery_icons;
    };

    "hypr/wallpapers" = {
      path = "resources/wallpapers";
      source = ../../resources/wallpapers;
    };

    "hypr/scripts/autostart.sh" = {
      path = "modules/hyprland/scripts/autostart.sh";
      source = ./scripts/autostart.sh;
      executable = true;
    };

    "hypr/scripts/brightness_control" = {
      path = "modules/hyprland/scripts/brightness_control";
      source = ./scripts/brightness_control;
      executable = true;
    };

    "hypr/scripts/device_manager" = {
      path = "modules/hyprland/scripts/device_manager";
      source = ./scripts/device_manager;
      executable = true;
    };

    "hypr/scripts/multi_monitor" = {
      path = "modules/hyprland/scripts/multi_monitor";
      source = ./scripts/multi_monitor;
      executable = true;
    };

    "hypr/scripts/pick_color" = {
      path = "modules/hyprland/scripts/pick_color";
      source = ./scripts/pick_color;
      executable = true;
    };

    "hypr/scripts/screenshot" = {
      path = "modules/hyprland/scripts/screenshot";
      source = ./scripts/screenshot;
      executable = true;
    };

    "hypr/scripts/video_wallpaper" = {
      path = "modules/hyprland/scripts/video_wallpaper";
      source = ./scripts/video_wallpaper;
      executable = true;
    };

    "hypr/scripts/volume_control" = {
      path = "modules/hyprland/scripts/volume_control";
      source = ./scripts/volume_control;
      executable = true;
    };

    "hypr/scripts/wallpaper_control" = {
      path = "modules/hyprland/scripts/wallpaper_control";
      source = ./scripts/wallpaper_control;
      executable = true;
    };
  };

  dotfiles.data."icons/qtile-cursors/cursors" = {
    path = "resources/cursors";
    source = ../../resources/cursors;
  };
}
