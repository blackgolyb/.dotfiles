{ config, lib, pkgs, ... }:

let
  inherit (import ../dotfiles/lib.nix { inherit config lib; }) dotfileConfig;
in
lib.mkMerge [
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

}
  (dotfileConfig "qtile" "modules/qtile" ./. { recursive = true; force = true; })
  (dotfileConfig "picom/picom.conf" "modules/qtile/picom.conf" ./picom.conf { force = true; })
]
