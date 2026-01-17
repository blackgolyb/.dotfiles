{ config, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
  };

  home.packages = with pkgs; [
    unzip
    nodejs
    git
    gcc
    gnumake
    python3
    wget
    curl
  ];

  xdg.configFile."nvim" = {
    source = ./.;
    recursive = true;
  };
}
