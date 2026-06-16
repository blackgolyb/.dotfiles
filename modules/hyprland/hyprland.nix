{ pkgs, ... }:

{
  home.packages = with pkgs; [
    brightnessctl
    cliphist
    hyprpicker
    hyprprop
    jq
    libnotify
    mpvpaper
    pamixer
    hyprpaper
    quickshell
    swaylock
    wl-clipboard
  ];

  xdg.configFile."hypr/hyprland.lua".source = ./hyprland.lua;

  xdg.configFile."hypr/hyprpaper.conf".text = ''
    splash = false
    ipc = on
  '';

  xdg.configFile."quickshell/shell.qml".source = ./quickshell/shell.qml;

  xdg.configFile."quickshell/widgets".source = ./quickshell/widgets;

  xdg.configFile."quickshell/battery_icons".source = ../qtile/resources/battery_icons;

  xdg.configFile."hypr/wallpapers".source = ../qtile/resources/wallpapers;

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
