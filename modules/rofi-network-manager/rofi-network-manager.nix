{ config, pkgs, ... }:

{
  xdg.configFile."rofi-network-manager" = {
    source = ./.;
    recursive = true;
  };
}
