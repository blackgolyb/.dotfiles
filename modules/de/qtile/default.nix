{ config, lib, pkgs, ... }:

let
  cfg = config.my.de.qtile;
in
{
  options.my.de.qtile.enable = lib.mkEnableOption "Qtile desktop";

  config = lib.mkIf cfg.enable {
    my.apps.flameshot.enable = lib.mkDefault true;
    my.apps.rofi.enable = lib.mkDefault true;
    my.apps.thunar.enable = lib.mkDefault true;
    my.apps.wezterm.enable = lib.mkDefault true;

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

    dotfiles.config."qtile" = {
      source = ./.;
      recursive = true;
      force = true;
    };

    dotfiles.config."picom/picom.conf" = {
      source = ./picom.conf;
      force = true;
    };
  };
}
