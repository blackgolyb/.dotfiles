{ ... }:

{
  dotfiles.config."rofi-network-manager" = {
    source = ./.;
    recursive = true;
    force = true;
  };
}
