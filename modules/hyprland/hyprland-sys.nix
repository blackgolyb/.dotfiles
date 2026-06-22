{ pkgs, ... }:

{
  programs.hyprland = {
    enable = true;
    package = pkgs.hyprland;
    portalPackage = pkgs.xdg-desktop-portal-hyprland;
    xwayland.enable = true;
    withUWSM = true;
  };

  programs.uwsm.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-hyprland
    ];
    config.common.default = [
      "hyprland"
      "gtk"
    ];
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  services.upower.enable = true;

  security.polkit.enable = true;

  security.pam.services.quickshell-lock = { };
}
