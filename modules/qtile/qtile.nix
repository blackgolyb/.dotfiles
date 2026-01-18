{ config, lib, pkgs, ... }:
{
    home.packages = with pkgs; [
       haskellPackages.greenclip
    ];

    xdg.configFile.qtile = {
      source = ./.;
      force = true;
    };

    xdg.configFile."picom/picom.conf" = {
      source = ./picom.conf;
      force = true;
    };

    services.picom = {
      enable = true;
    };

    services.unclutter = {
      enable = true;
      timeout = 10;
    };

    services.dunst = {
      enable = true;
    };
}
