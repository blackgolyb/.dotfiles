{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.apps.secrets;
in
{
  options.my.apps.secrets = {
    enable = lib.mkEnableOption "explicit sops-nix secrets";

    ageKeyFile = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
      description = "Age identity used by sops-nix.";
    };

    secrets = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = {
        "ssh/system/github" = {
          sopsFile = ../../../secrets/ssh/system/github.key;
          format = "binary";
        };
      };
      description = "Explicit sops-nix secret declarations.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      age
      sops
    ];

    sops = {
      age.keyFile = cfg.ageKeyFile;
      secrets = cfg.secrets;
    };
  };
}
