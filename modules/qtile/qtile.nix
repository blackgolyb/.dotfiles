{ config, lib, pkgs, ... }:
{
    home.packages = with pkgs; [
        xgamma
        haskellPackages.greenclip
        librsvg
        adwaita-icon-theme
        dunst
        picom
        unclutter-xfixes
    ];

    home.sessionVariables = {
      GDK_PIXBUF_MODULE_FILE = "${pkgs.librsvg}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache";
    };

    xdg.configFile.qtile = {
      source = ./.;
      recursive = true;
      force = true;
    };

    xdg.configFile."qtile/resources" = {
      source = ../../resources;
      force = true;
    };

    xdg.configFile."picom/picom.conf" = {
      source = ./picom.conf;
      force = true;
    };

}
