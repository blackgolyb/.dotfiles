{ pkgs, lib, ... }:

lib.mkMerge [
  {
    home.packages = with pkgs; [
      starship
    ];
  }
  {
    dotfiles.config."starship/starship.toml" = {
      path = "modules/starship/starship.toml";
      source = ./starship.toml;
    };
  }
]
