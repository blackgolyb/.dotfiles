{ lib, ... }:

lib.mkMerge [
  {
    programs.wezterm.enable = true;
  }
  {
    dotfiles.config."wezterm/wezterm.lua" = {
      path = "modules/wezterm/wezterm.lua";
      source = ./wezterm.lua;
    };

    dotfiles.config."wezterm/colors/custom.toml" = {
      path = "modules/wezterm/colors/custom.toml";
      source = ./colors/custom.toml;
    };
  }
]
