{ config, lib, ... }:

let
  cfg = config.my.apps.rofiNetworkManager;
in
{
  options.my.apps.rofiNetworkManager.enable = lib.mkEnableOption "Rofi Network Manager";

  config = lib.mkIf cfg.enable {
    dotfiles.config."rofi-network-manager" = {
      source = ./.;
      recursive = true;
      force = true;
    };
  };
}
