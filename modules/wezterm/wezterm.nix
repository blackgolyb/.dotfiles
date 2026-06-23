{ lib, ... }:

lib.mkMerge [
  {
    programs.wezterm.enable = true;
    stylix.targets.wezterm.enable = false;
  }
  {
    dotfiles.config."wezterm/wezterm.lua" = {
      source = ./wezterm.lua;
    };

    dotfiles.config."wezterm/colors/custom.toml" = {
      source = ./colors/custom.toml;
    };
  }
]
