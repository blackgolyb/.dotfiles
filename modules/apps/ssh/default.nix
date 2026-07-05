{ config, lib, pkgs, ... }:

let
  cfg = config.my.apps.ssh;

  defaultKeyNames = [
    "github"
  ];
in
{
  options.my.apps.ssh = {
    enable = lib.mkEnableOption "SSH keys managed by sops-nix";

    keyNames = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = defaultKeyNames;
      description = "SSH private key filenames to decrypt into ~/.ssh.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      age
      openssh
      sops
    ];

    sops = {
      age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
      defaultSopsFile = ../../../secrets/ssh.yaml;
      defaultSopsFormat = "yaml";
      secrets = lib.genAttrs (map (name: "ssh/${name}") cfg.keyNames) (_: { });
    };
  };
}
