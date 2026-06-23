{ pkgs, lib, ... }:

lib.mkMerge [
  {
    home.packages = with pkgs; [
      starship
    ];
  }
  {
    dotfiles.config."starship/starship.toml" = {
      source = ./starship.toml;
    };
  }
]
