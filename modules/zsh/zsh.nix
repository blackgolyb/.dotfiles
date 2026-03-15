{ config, pkgs, ... }:
{
    imports = [
    	../starship/starship.nix
    ];

    home.packages = with pkgs; [
      zsh
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
    ];


    initContent = ''
      source ${config.home.homeDirectory}/.config/zsh/zshrc
    '';
  };

  xdg.configFile."zsh/zshrc".source = ./.zshrc;
}
