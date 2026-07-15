{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.apps.copyToClipboard;
in
{
  options.my.apps.copyToClipboard.enable = lib.mkEnableOption "copy-to-clipboard";

  config = lib.mkIf cfg.enable {
    home.packages = [
      (pkgs.callPackage ./package.nix { })
    ];
  };
}
