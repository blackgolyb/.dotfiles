{ pkgs, ... }:

{
  home.packages = with pkgs; [
    brightnessctl
    cliphist
    hyprpicker
    jq
    libnotify
    mpvpaper
    pamixer
    quickshell
    swaylock
    wl-clipboard
  ];

  xdg.configFile."hypr/hyprland.lua".source = ./hyprland.lua;

  xdg.configFile."quickshell/shell.qml".source = ./quickshell/shell.qml;

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

  services.dunst.enable = true;
}
