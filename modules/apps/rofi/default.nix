{ config, lib, pkgs, ... }:

let
  cfg = config.my.apps.rofi;
in
{
  options.my.apps.rofi.enable = lib.mkEnableOption "Rofi";

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      home.packages = [
        (pkgs.rofi.override {
          plugins = [
            pkgs.rofi-calc
            pkgs.rofi-emoji
          ];
        })
      ];

      stylix.targets.rofi.enable = false;
    }
    {
      dotfiles.config."rofi" = {
        source = ./.;
        recursive = true;
        force = true;
      };
    }
  ]);
}
