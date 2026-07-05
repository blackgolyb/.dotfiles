{ config, lib, pkgs, ... }:

let
  cfg = config.my.apps.pass;
in
{
  options.my.apps.pass = {
    enable = lib.mkEnableOption "pass password store";

    repository = lib.mkOption {
      type = lib.types.str;
      default = "git@github.com:blackgolyb/pass.git";
      description = "Git repository used for the pass password store.";
    };

    storeDir = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.password-store";
      description = "Local password-store directory.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      pass
      git
      openssh
    ];

    home.activation.passwordStore = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      store=${lib.escapeShellArg cfg.storeDir}
      repo=${lib.escapeShellArg cfg.repository}
      parent="$(${pkgs.coreutils}/bin/dirname "$store")"

      if [ -d "$store/.git" ]; then
        current="$(${pkgs.git}/bin/git -C "$store" remote get-url origin 2>/dev/null || true)"
        if [ "$current" != "$repo" ]; then
          echo "Password store already exists with different origin: $current" >&2
        fi
        ${pkgs.coreutils}/bin/chmod 700 "$store" 2>/dev/null || true
        exit 0
      fi

      if [ -e "$store" ] || [ -L "$store" ]; then
        first_entry="$(${pkgs.findutils}/bin/find "$store" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null || true)"
        if [ -n "$first_entry" ]; then
          echo "Password store exists but is not a git repo, leaving untouched: $store" >&2
          exit 0
        fi
        ${pkgs.coreutils}/bin/rmdir "$store" 2>/dev/null || true
      fi

      ${pkgs.coreutils}/bin/mkdir -p "$parent"
      tmp="$parent/.password-store.clone.$$"
      ${pkgs.coreutils}/bin/rm -rf "$tmp"

      if GIT_SSH_COMMAND="${pkgs.openssh}/bin/ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new" \
        ${pkgs.git}/bin/git clone "$repo" "$tmp"; then
        ${pkgs.coreutils}/bin/mv "$tmp" "$store"
        ${pkgs.coreutils}/bin/chmod 700 "$store"
      else
        ${pkgs.coreutils}/bin/rm -rf "$tmp"
        echo "Failed to clone password store from $repo" >&2
        echo "Make sure your SSH key is available and can access the repository." >&2
      fi
    '';
  };
}
