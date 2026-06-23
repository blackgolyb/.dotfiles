{ config, lib, pkgs, ... }:

let
  inherit (import ../dotfiles/lib.nix { inherit config lib; }) dotfileConfig;
in
lib.mkMerge [
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

}
  (dotfileConfig "rofi" "modules/rofi" ./. { recursive = true; })
]
