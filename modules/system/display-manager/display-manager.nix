{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.system.displayManager;
in
{
  options.my.system.displayManager = {
    enable = lib.mkEnableOption "Display manager";

    dm = lib.mkOption {
      type = lib.types.enum [
        "lightdm"
        "greetd"
      ];
      default = "lightdm";
      description = "Display manager to use.";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      (lib.mkIf (cfg.dm == "lightdm") {
        services.xserver = {
          enable = true;
          updateDbusEnvironment = true;
          desktopManager.runXdgAutostartIfNone = true;

          displayManager.lightdm.greeters = {
            slick.enable = true;
            mini.enable = false;
          };
        };
      })

      (lib.mkIf (cfg.dm == "greetd") {
        services.greetd = {
          enable = true;
          useTextGreeter = true;
          settings = {
            default_session = {
              command = "${pkgs.tuigreet}/bin/tuigreet --time --asterisks --wayland-sessions /run/current-system/sw/share/wayland-sessions --xsessions /run/current-system/sw/share/xsessions";
            };
          };
        };
      })
    ]
  );
}
