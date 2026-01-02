{ config, lib, impurity, ... }:
{
    xdg.configFile.qtile = {
      source = ./.;
      force = true;
    };

    services.picom = {
      enable = true;
      vSync = true;
      backend = "xr_glx_hybrid";
      settings = {
        glx-no-stencil = true;
        glx-no-rebind-pixmap = true;
        unredir-if-possible = true;
        xrender-sync-fence = true;
      };
    };

    services.unclutter = {
      enable = true;
      timeout = 10;
    };

    services.dunst = {
      enable = true;
    };
}
