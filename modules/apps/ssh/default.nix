{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.apps.ssh;

  keyType = lib.types.submodule {
    options = {
      privateKeyFile = lib.mkOption {
        type = lib.types.path;
        description = "SOPS-encrypted private SSH key file.";
      };

      publicKeyFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Plain public SSH key file.";
      };

      target = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Optional symlink target for the decrypted private key.";
      };
    };
  };

  sshKeysDir = ../../../secrets/ssh/user;
  runtimeDir = ''"''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}/dotfiles-ssh"'';

  keysFromDir =
    dir:
    let
      entries = builtins.readDir dir;
      keyFiles = lib.filter (name: lib.hasSuffix ".key" name) (lib.attrNames entries);
      keyName = file: lib.removeSuffix ".key" file;
    in
    lib.genAttrs (map keyName keyFiles) (name: {
      privateKeyFile = dir + "/${name}.key";
      publicKeyFile = if builtins.pathExists (dir + "/${name}.pub") then dir + "/${name}.pub" else null;
    });

  defaultUserKeys = lib.mapAttrs (
    _: key:
    key
    // {
      target = "${config.home.homeDirectory}/.ssh/${_}";
    }
  ) (keysFromDir sshKeysDir);

  renderKey = name: key: ''
    decrypt_key ${lib.escapeShellArg key.privateKeyFile} "$runtime_dir/user/${name}"
    ${lib.optionalString (key.publicKeyFile != null) ''
      install_public_key ${lib.escapeShellArg key.publicKeyFile} "$runtime_dir/user/${name}.pub"
    ''}
    ${lib.optionalString (key.target != null) ''
      link_key "$runtime_dir/user/${name}" ${lib.escapeShellArg key.target}
      ${lib.optionalString (key.publicKeyFile != null) ''
        link_key "$runtime_dir/user/${name}.pub" ${lib.escapeShellArg (key.target + ".pub")}
      ''}
    ''}
  '';

  installSshKeys = pkgs.writeShellScript "install-dotfiles-ssh-keys" ''
    set -eu

    runtime_dir=${runtimeDir}
    export SOPS_AGE_KEY_FILE=${lib.escapeShellArg cfg.ageKeyFile}

    decrypt_key() {
      source=$1
      target=$2
      tmp="$target.tmp.$$"

      ${pkgs.coreutils}/bin/install -d -m 700 "$(${pkgs.coreutils}/bin/dirname "$target")"
      ${pkgs.sops}/bin/sops --decrypt --input-type binary --output-type binary "$source" > "$tmp"
      ${pkgs.coreutils}/bin/chmod 400 "$tmp"
      ${pkgs.coreutils}/bin/mv "$tmp" "$target"
    }

    install_public_key() {
      source=$1
      target=$2

      ${pkgs.coreutils}/bin/install -d -m 700 "$(${pkgs.coreutils}/bin/dirname "$target")"
      ${pkgs.coreutils}/bin/install -m 444 "$source" "$target"
    }

    link_key() {
      source=$1
      target=$2

      ${pkgs.coreutils}/bin/install -d -m 700 "$(${pkgs.coreutils}/bin/dirname "$target")"
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
          echo "Backed up existing SSH file before linking SOPS key: $backup" >&2
        fi
      fi
      ${pkgs.coreutils}/bin/ln -s "$source" "$target"
    }

    ${lib.concatStringsSep "\n" (lib.mapAttrsToList renderKey cfg.userKeys)}
  '';
in
{
  options.my.apps.ssh = {
    enable = lib.mkEnableOption "SOPS-backed SSH keys";

    ageKeyFile = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
      description = "Age identity used to decrypt SSH key files with sops.";
    };

    userKeys = lib.mkOption {
      type = lib.types.attrsOf keyType;
      default = defaultUserKeys;
      description = "User SSH keys decrypted into the runtime SSH secret directory and optionally linked into ~/.ssh.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      openssh
      sops
    ];

    systemd.user.services.ssh-keys = {
      Unit.Description = "Install SSH keys from SOPS files";

      Service = {
        Type = "oneshot";
        ExecStart = "${installSshKeys}";
      };

      Install.WantedBy = [ "default.target" ];
    };
  };
}
