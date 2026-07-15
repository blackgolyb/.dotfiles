{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.de.qtile;
in
{
  options.my.de.qtile.enable = lib.mkEnableOption "Qtile desktop";

  config = lib.mkIf cfg.enable {
    services = {
      xserver = {
        enable = true;
        updateDbusEnvironment = true;
        desktopManager.runXdgAutostartIfNone = true;
        windowManager.qtile = {
          enable = true;
          extraPackages =
            python3Packages: with python3Packages; [
              qtile-extras
              requests
            ];
        };

        displayManager.lightdm.greeters = {
          slick.enable = true;
          mini.enable = false;
        };
      };

      udev.extraRules = ''
        SUBSYSTEM=="leds", KERNEL=="platform::micmute", RUN+="${pkgs.coreutils}/bin/chmod 0666 /sys/class/leds/platform::micmute/brightness"
      '';
    };
  };
}
