{ config, pkgs, lib, ... }:

let
  inherit (import ../dotfiles/lib.nix { inherit config lib; }) dotfileConfig;
in
lib.mkMerge [
{
  programs.wezterm.enable = true;
}
  (dotfileConfig "wezterm/wezterm.lua" "modules/wezterm/wezterm.lua" ./wezterm.lua { })
  (dotfileConfig "wezterm/colors/custom.toml" "modules/wezterm/colors/custom.toml" ./colors/custom.toml { })
]
