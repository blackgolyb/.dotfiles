{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.apps.opencode;
in
{
  options.my.apps.opencode.enable = lib.mkEnableOption "OpenCode";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      opencode
    ];

    dotfiles.config."opencode/tui.json" = {
      source = ./tui.json;
    };

    dotfiles.config."opencode/themes/monodark.json" = {
      source = ./themes/monodark.json;
    };
  };
}
