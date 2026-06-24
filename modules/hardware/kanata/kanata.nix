{ config, lib, ... }:

let
  cfg = config.my.hardware.kanata;

  kanataConfigDir = builtins.path {
    path = ./config;
    name = "kanata-config";
  };
in
{
  options.my.hardware.kanata.enable = lib.mkEnableOption "Kanata";

  config = lib.mkIf cfg.enable {
    services.kanata = {
      enable = true;
      keyboards.default.configFile =
        "${kanataConfigDir}/config.kbd";
    };

    boot.kernelModules = [ "uinput" ];
    hardware.uinput.enable = true;

    services.udev.extraRules = ''
      KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
    '';

    users.groups.uinput = { };

    systemd.services.kanata-internalKeyboard.serviceConfig = {
      SupplementaryGroups = [
        "input"
        "uinput"
      ];
    };
  };
}
