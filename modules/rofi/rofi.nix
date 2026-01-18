{ config, pkgs, ... }:

{
  programs.rofi = {
    enable = true;
    package = pkgs.rofi.override {
      plugins = [ 
        pkgs.rofi-calc 
        pkgs.rofi-emoji 
      ];
    };
  };

  xdg.configFile.rofi = {
    source = ./.;
    recursive = true;
  };
}
