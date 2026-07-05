{ config, lib, pkgs, ... }:

let
  cfg = config.my.apps.ssh;

  linkSopsSshSecrets = pkgs.writeShellScript "link-sops-ssh-secrets" ''
    set -eu

    link_secret() {
      source=$1
      target=$2
      parent="$(${pkgs.coreutils}/bin/dirname "$target")"

      ${pkgs.coreutils}/bin/install -d -m 700 "$parent"

      if [ -L "$target" ]; then
        current="$(${pkgs.coreutils}/bin/readlink "$target")"
        if [ "$current" = "$source" ]; then
          return 0
        fi
        ${pkgs.coreutils}/bin/rm "$target"
      elif [ -e "$target" ]; then
        if ${pkgs.diffutils}/bin/cmp -s "$source" "$target"; then
          ${pkgs.coreutils}/bin/rm "$target"
        else
          backup="$target.pre-sops-link.$(${pkgs.coreutils}/bin/date +%Y%m%d%H%M%S)"
          ${pkgs.coreutils}/bin/mv "$target" "$backup"
          echo "Backed up existing SSH key before linking SOPS secret: $backup" >&2
        fi
      fi

      ${pkgs.coreutils}/bin/ln -s "$source" "$target"
    }

    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: target: ''
      link_secret ${lib.escapeShellArg config.sops.secrets."ssh/${name}".path} ${lib.escapeShellArg target}
    '') cfg.linkTargets)}
  '';
in
{
  options.my.apps.ssh = {
    enable = lib.mkEnableOption "SSH keys managed by sops-nix";

    keyNames = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "github"
      ];
      description = "SSH private key names to decrypt with sops-nix.";
    };

    linkTargets = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {
        github = "${config.home.homeDirectory}/.ssh/github";
      };
      description = "Symlinks to create from regular filesystem paths to decrypted SOPS SSH secrets.";
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

    systemd.user.services.link-sops-ssh-secrets = {
      Unit = {
        Description = "Link SSH keys from sops-nix secrets";
        After = [ "sops-nix.service" ];
        Requires = [ "sops-nix.service" ];
      };

      Service = {
        Type = "oneshot";
        ExecStart = "${linkSopsSshSecrets}";
      };

      Install.WantedBy = [ "default.target" ];
    };
  };
}
