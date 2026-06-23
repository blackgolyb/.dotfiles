{ lib, pkgs, ... }:

lib.mkMerge [
  {
    programs.rofi = {
      enable = true;
      package = pkgs.rofi.override {
        plugins = [
          pkgs.rofi-calc
          pkgs.rofi-emoji
        ];
      };
    };
  }
  {
    dotfiles.config."rofi" = {
      path = "modules/rofi";
      source = ./.;
      recursive = true;
    };
  }
]
