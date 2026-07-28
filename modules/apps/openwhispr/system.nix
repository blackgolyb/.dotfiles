{
  config,
  inputs,
  lib,
  ...
}:

let
  cfg = config.my.apps.openwhispr;
in
{
  imports = [
    inputs.openwhispr.nixosModules.default
  ];

  options.my.apps.openwhispr.enable = lib.mkEnableOption "OpenWhispr";

  config = lib.mkIf cfg.enable {
    programs.openwhispr = {
      enable = true;
      users = [ "blackgolyb" ];
    };
  };
}
