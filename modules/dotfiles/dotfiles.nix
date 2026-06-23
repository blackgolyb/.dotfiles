{ config, lib, ... }:

{
  options.dotfiles = {
    pure = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Use Nix store-backed dotfiles instead of live out-of-store symlinks.";
    };

    root = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/nixos";
      description = "Absolute path to the dotfiles repository used for impure symlinks.";
    };
  };

  config = { };
}
