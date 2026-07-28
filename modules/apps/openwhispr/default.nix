{ config, lib, ... }:

let
  cfg = config.my.apps.openwhispr;
in
{
  options.my.apps.openwhispr.enable = lib.mkEnableOption "OpenWhispr";

  config = lib.mkIf cfg.enable { };
}
