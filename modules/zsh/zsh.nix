{ config, pkgs, ... }:

{
  imports = [
    ../starship/starship.nix
  ];

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

  xdg.configFile."zsh/zshrc".source = ./.zshrc;
}
