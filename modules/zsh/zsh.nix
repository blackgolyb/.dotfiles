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
    };
    

    initContent = ''
      source ${config.home.homeDirectory}/.config/zsh/zshrc
    '';
  };

  xdg.configFile."zsh/zshrc".source = ./.zshrc;
}
