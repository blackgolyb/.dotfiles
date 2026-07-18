{
  config,
  inputs,
  lib,
  ...
}:

let
  cfg = config.my.apps.zen;
  desktopFile = "zen-twilight.desktop";
in
{
  imports = [
    inputs.zen-browser.homeModules.twilight
  ];

  options.my.apps.zen = {
    enable = lib.mkEnableOption "Zen Browser";
    default = lib.mkEnableOption "set Zen Browser as the default browser";
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        home.shellAliases.zen = "zen-twilight";

        programs.zen-browser.enable = true;

        stylix.targets.zen-browser.enable = false;
      }

      (lib.mkIf cfg.default {
        home.sessionVariables.BROWSER = "zen-twilight";

        xdg.mimeApps = {
          enable = true;
          defaultApplications = {
            "x-scheme-handler/http" = desktopFile;
            "x-scheme-handler/https" = desktopFile;
            "x-scheme-handler/chrome" = desktopFile;
            "text/html" = desktopFile;
            "application/xhtml+xml" = desktopFile;
          };
        };
      })
    ]
  );
}
