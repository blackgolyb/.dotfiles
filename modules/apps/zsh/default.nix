{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.apps.zsh;
in
{
  options.my.apps.zsh.enable = lib.mkEnableOption "Zsh";

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        home.packages = with pkgs; [
          zsh
          fzf
          just
        ];

        programs.zsh = {
          enable = true;
          enableCompletion = true;
          autosuggestion.enable = true;
          syntaxHighlighting.enable = true;

          oh-my-zsh = {
            enable = true;
            plugins = [
              "git"
              "poetry"
              "zsh-navigation-tools"
            ];
          };

          plugins = [
            {
              name = "zsh-vi-mode";
              src = pkgs.zsh-vi-mode;
              file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
            }
            {
              name = "just-completion";
              src = pkgs.just;
              file = "share/zsh/site-functions/_just";
            }
          ];

          initContent = ''
            source ${config.home.homeDirectory}/.config/zsh/zshrc
            source ${pkgs.fzf}/share/fzf/key-bindings.zsh
          '';
        };
      }
      {
        dotfiles.config."zsh/zshrc" = {
          source = ./.zshrc;
        };
      }
    ]
  );
}
