{ ... }:

{
  dotfiles.config."rofi-network-manager" = {
    path = "modules/rofi-network-manager";
    source = ./.;
    recursive = true;
  };
}
