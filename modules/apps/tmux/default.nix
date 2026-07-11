{ config, lib, pkgs, ... }:

let
  cfg = config.my.apps.tmux;

  tmuxProjectSessionSource = pkgs.replaceVars ./tmux-project-session.sh {
    sessionPrefix = cfg.projectSessionPrefix;
  };

  tmuxProjectSession = pkgs.writeShellApplication {
    name = "tmux-project-session";
    runtimeInputs = with pkgs; [
      coreutils
      fzf
      git
      tmux
    ];
    text = builtins.readFile tmuxProjectSessionSource;
  };

  resurrectSave = "${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect/scripts/save.sh";
  resurrectRestore = "${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect/scripts/restore.sh";
  tmuxFilterResurrectSave = pkgs.writeShellApplication {
    name = "tmux-filter-resurrect-save";
    runtimeInputs = [ pkgs.python3 ];
    text = ''
      exec python3 ${./tmux-filter-resurrect-save.py} "$@"
    '';
  };
  tmuxStateDir = "\${XDG_RUNTIME_DIR:-/tmp}/tmux-resurrect-systemd";
  tmuxAutostart = pkgs.writeShellApplication {
    name = "tmux-autostart";
    runtimeInputs = with pkgs; [
      coreutils
      gawk
      gnugrep
      gnused
      gnutar
      gzip
      procps
      tmux
    ];
    text = ''
      set -eu

      state_dir="${tmuxStateDir}"
      restoring="$state_dir/restoring"
      restored="$state_dir/restored"

      mkdir -p "$state_dir"
      rm -f "$restored"
      touch "$restoring"

      cleanup() {
        rm -f "$restoring"
      }
      trap cleanup EXIT

      placeholder="__restore__"

      if ! tmux has-session 2>/dev/null; then
        tmux new-session -d -s "$placeholder"
      fi

      socket="$(tmux display-message -p '#{socket_path}')"
      TMUX="$socket,0,0" ${resurrectRestore} \
        2> >(${pkgs.gnugrep}/bin/grep -v 'no current client' >&2) || true

      if tmux has-session -t "$placeholder" 2>/dev/null \
        && [ "$(tmux list-sessions 2>/dev/null | wc -l)" -gt 1 ]; then
        tmux kill-session -t "$placeholder"
      fi

      touch "$restored"
    '';
  };
  tmuxAutosave = pkgs.writeShellApplication {
    name = "tmux-autosave";
    runtimeInputs = with pkgs; [
      coreutils
      gawk
      gnugrep
      gnused
      gnutar
      gzip
      procps
      tmux
    ];
    text = ''
      set -eu

      state_dir="${tmuxStateDir}"
      restoring="$state_dir/restoring"
      restored="$state_dir/restored"

      [ -e "$restoring" ] && exit 0
      [ -e "$restored" ] || exit 0

      filter_last_save() {
        resurrect_dir="$HOME/.tmux/resurrect"
        last_link="$resurrect_dir/last"

        [ -e "$last_link" ] || return 0

        last_target="$(readlink "$last_link" || true)"
        [ -n "$last_target" ] || return 0

        last_file="$resurrect_dir/$last_target"
        backup_file="$resurrect_dir/_bak_$(basename "$last_target")"
        [ -f "$last_file" ] || return 0

        tmp="$(mktemp "$last_file.XXXXXX")"
        ${lib.getExe tmuxFilterResurrectSave} < "$last_file" > "$tmp"

        if [ ! -s "$tmp" ]; then
          rm -f "$tmp"
          return 0
        fi

        if cmp -s "$last_file" "$tmp"; then
          rm -f "$tmp"
        else
          cp -p "$last_file" "$backup_file"
          mv "$tmp" "$last_file"
        fi
      }

      if tmux has-session 2>/dev/null; then
        ${resurrectSave} quiet
        filter_last_save
      fi
    '';
  };
in
{
  options.my.apps.tmux = {
    enable = lib.mkEnableOption "tmux";

    autoSaveAndRestore = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to automatically save and restore tmux sessions with tmux-resurrect.";
    };

    autoSaveInterval = lib.mkOption {
      type = lib.types.str;
      default = "10min";
      description = "systemd timer interval for tmux-resurrect autosaves.";
    };

    projectSessionPrefix = lib.mkOption {
      type = lib.types.str;
      default = "p-";
      description = "Prefix used to identify tmux sessions managed by the Git project workflow.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ tmuxProjectSession ]
      ++ lib.optionals cfg.autoSaveAndRestore [
        tmuxAutostart
        tmuxAutosave
        tmuxFilterResurrectSave
      ];

    programs.tmux = {
      enable = true;
      baseIndex = 1;
      clock24 = true;
      escapeTime = 0;
      keyMode = "vi";
      mouse = true;
      terminal = "tmux-256color";

      plugins = with pkgs.tmuxPlugins; [
        resurrect
        vim-tmux-navigator
      ];

      extraConfig = ''
        source-file -q ${config.home.homeDirectory}/.config/tmux/base.conf
      '';
    };

    dotfiles.config."tmux/base.conf" = {
      source = ./base.conf;
    };

    # auto-start tmux on login so resurrect can restore sessions
    # even before you open a terminal
    systemd.user.services = lib.mkIf cfg.autoSaveAndRestore {
      tmux = {
        Unit = {
          Description = "tmux: terminal multiplexer (detached)";
          Documentation = [ "man:tmux(1)" ];
        };
        Service = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = lib.getExe tmuxAutostart;
          ExecStop = [
            (lib.getExe tmuxAutosave)
            "${lib.getExe pkgs.tmux} kill-server"
          ];
          KillMode = "mixed";
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };

      tmux-autosave = {
        Unit = {
          Description = "tmux-resurrect autosave";
          After = [ "tmux.service" ];
        };
        Service = {
          Type = "oneshot";
          ExecStart = lib.getExe tmuxAutosave;
        };
      };
    };

    systemd.user.timers = lib.mkIf cfg.autoSaveAndRestore {
      tmux-autosave = {
        Unit = {
          Description = "tmux-resurrect autosave timer";
        };
        Timer = {
          OnActiveSec = cfg.autoSaveInterval;
          OnUnitActiveSec = cfg.autoSaveInterval;
          Unit = "tmux-autosave.service";
        };
        Install = {
          WantedBy = [ "timers.target" ];
        };
      };
    };
  };
}
