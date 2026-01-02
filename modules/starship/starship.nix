{ config, pkgs, lib, ... }:
{
    home.packages = with pkgs; [
      starship
    ];

    xdg.configFile."starship/starship.toml".source = ./starship.toml;
}
