{ config, lib, pkgs, ... }:

let
  cfg = config.my.apps.tmux;
in
{
  options.my.apps.tmux.enable = lib.mkEnableOption "tmux";

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      programs.tmux = {
        enable = true;
        baseIndex = 1;
        clock24 = true;
        escapeTime = 0;
        keyMode = "vi";
        mouse = true;
        terminal = "tmux-256color";

        plugins = with pkgs.tmuxPlugins; [
          resurrect
          continuum
          vim-tmux-navigator
        ];

        extraConfig = ''
          source-file -q ${config.home.homeDirectory}/.config/tmux/base.conf
        '';
      };
    }
    {
      dotfiles.config."tmux/base.conf" = {
        source = ./base.conf;
      };
    }
  ]);
}
