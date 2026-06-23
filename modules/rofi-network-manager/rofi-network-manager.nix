{ config, lib, pkgs, ... }:

let
  inherit (import ../dotfiles/lib.nix { inherit config lib; }) dotfileConfig;
in
dotfileConfig "rofi-network-manager" "modules/rofi-network-manager" ./. { recursive = true; }
