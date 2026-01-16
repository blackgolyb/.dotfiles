{ config, pkgs, lib, ... }:
{
  programs.wezterm.enable = true;

  xdg.configFile."wezterm/wezterm.lua".source = ./wezterm.lua;
  xdg.configFile."wezterm/colors/custom.toml".source = ./colors/custom.toml;
}
