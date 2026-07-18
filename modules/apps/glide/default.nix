{
  config,
  inputs,
  lib,
  ...
}:

let
  cfg = config.my.apps.glide;
  desktopFile = "glide.desktop";
in
{
  imports = [
    inputs.glide-browser.homeModules.default
  ];

  options.my.apps.glide = {
    enable = lib.mkEnableOption "Glide";
    default = lib.mkEnableOption "set Glide as the default browser";
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        home.shellAliases.glide = "glide";

        programs.glide-browser.enable = true;
      }

      (lib.mkIf cfg.default {
        home.sessionVariables.BROWSER = "glide";

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
