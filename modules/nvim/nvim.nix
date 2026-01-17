{ config, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
  };

  xdg.configFile."nvim" = {
    source = ./.;
    recursive = true;
  };
}
