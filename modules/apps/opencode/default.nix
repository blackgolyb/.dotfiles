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

    dotfiles.config = {
      "opencode/opencode.jsonc" = {
        source = ./opencode.jsonc;
        force = true;
      };

      "opencode/tui.json" = {
        source = ./tui.json;
      };

      "opencode/themes/monodark.json" = {
        source = ./themes/monodark.json;
      };

      "opencode/skills/gh" = {
        source = ./skills/gh;
      };

      "opencode/skills/new-task" = {
        source = ./skills/new-task;
      };
    };
  };
}
