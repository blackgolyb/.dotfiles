{ lib, pkgs, ... }:

lib.mkMerge [
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
]
