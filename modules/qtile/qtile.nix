{ config, lib, pkgs, ... }:
{
    home.packages = with pkgs; [
       haskellPackages.greenclip
       librsvg
       adwaita-icon-theme
    ];

    home.sessionVariables = {
      GDK_PIXBUF_MODULE_FILE = "${pkgs.librsvg}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache";
    };

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
