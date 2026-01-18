{ config, pkgs, ... }:

{
  xdg.configFile."rofi-bluetooth" = {
    source = ./.;
    recursive = true;
  };
}
