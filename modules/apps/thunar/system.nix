{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.apps.thunar;
in
{
  options.my.apps.thunar.enable = lib.mkEnableOption "Thunar";

  config = lib.mkIf cfg.enable {
    programs = {
      thunar = {
        enable = true;
        plugins = with pkgs; [
          thunar-archive-plugin
          thunar-volman
        ];
      };
    };

    environment.systemPackages = with pkgs; [
      file-roller
    ];

    services.gvfs.enable = true;
    services.tumbler.enable = true;
  };
}
