{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.apps.musicDownloader;
in
{
  options.my.apps.musicDownloader.enable = lib.mkEnableOption "music-downloader";

  config = lib.mkIf cfg.enable {
    home.packages = [
      (pkgs.callPackage ./package.nix { })
    ];
  };
}
