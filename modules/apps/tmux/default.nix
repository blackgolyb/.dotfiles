{ config, lib, pkgs, ... }:

let
  cfg = config.my.apps.tmux;
  tmuxProjectSessionSource = pkgs.replaceVars ./tmux-project-session.sh {
    sessionPrefix = cfg.projectSessionPrefix;
  };
  tmuxProjectSession = pkgs.writeShellApplication {
    name = "tmux-project-session";
    runtimeInputs = with pkgs; [
      coreutils
      fzf
      git
      tmux
    ];
    text = builtins.readFile tmuxProjectSessionSource;
  };
in
{
  options.my.apps.tmux = {
    enable = lib.mkEnableOption "tmux";

    projectSessionPrefix = lib.mkOption {
      type = lib.types.str;
      default = "p-";
      description = "Prefix used to identify tmux sessions managed by the Git project workflow.";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      home.packages = [
        tmuxProjectSession
      ];

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
