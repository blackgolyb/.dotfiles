{ config, pkgs, lib, ... }:

let
  inherit (import ../dotfiles/lib.nix { inherit config lib; }) dotfileConfig;
in
lib.mkMerge [
{
    home.packages = with pkgs; [
      starship
    ];
}
  (dotfileConfig "starship/starship.toml" "modules/starship/starship.toml" ./starship.toml { })
]
