{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.apps.openwhispr;
  packageSystem = pkgs.stdenv.hostPlatform.system;
in
{
  options.my.apps.openwhispr.enable = lib.mkEnableOption "OpenWhispr";

  config = lib.mkIf cfg.enable {
    home.packages = [
      inputs.openwhispr.packages.${packageSystem}.openwhispr
    ];
  };
}
