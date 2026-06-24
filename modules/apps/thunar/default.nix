{ config, lib, ... }:

let
  cfg = config.my.apps.thunar;
in
{
  options.my.apps.thunar.enable = lib.mkEnableOption "Thunar";

  config = lib.mkIf cfg.enable { };
}
