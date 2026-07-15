{ config, lib, ... }:

let
  cfg = config.my.apps.wezterm;
in
{
  options.my.apps.wezterm.enable = lib.mkEnableOption "WezTerm";

  config = lib.mkIf cfg.enable (
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
  );
}
