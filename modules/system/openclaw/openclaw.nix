# OpenClaw personal AI gateway.
#
# Declarative deployment of the OpenClaw gateway as a systemd service using the
# first-party nix-openclaw module:
#   OpenClaw gateway (systemd, dedicated `openclaw` user)
#   -> Docker sandbox (custom image with OpenCode)
#   -> git repositories
# Tailscale-managed HTTPS (serve mode, loopback bind only), sops secrets,
# local-model memory embeddings, human-gated Skill Workshop.
#
# See ./README.md (ops), ./MODEL_POLICY.md (models), ./SECURITY.md (posture).

{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.my.system.openclaw;

  system = pkgs.hostPlatform.system;
  nixOpenClaw = inputs.nix-openclaw;

  # Full CLI package is used for both the service and the `oci` helper so we
  # build/attest one derivation.
  openclawPkg = nixOpenClaw.packages.${system}.openclaw;

  openclawConfig = import ./openclaw-config.nix {
    inherit lib;
    # Decrypted GitHub SSH key (sops) used for the workspace repo clone/pull on
    # the host and mounted read-only at the SAME path inside the sandbox, so the
    # repo-local `core.sshCommand` works identically in both contexts. The mount
    # is NOT the sops path (sops symlinks into /run, which the sandbox bind
    # guard blocks): a separate real file owned by the sandbox uid is staged at
    # sshSandboxKeyPath by a root oneshot.
    sshKeyPath = config.sops.secrets."openclaw/github-ssh".path;
    sshSandboxKeyPath = "/var/lib/openclaw/secrets/sandbox/github-ssh";
  };

  sandboxImage = import ./sandbox.nix { inherit pkgs; };

  securityAudit = ./scripts/check-openclaw-security.sh;

  stateDir = "/var/lib/openclaw";
  configPath = "/etc/openclaw/openclaw.json";
in
{
  imports = [ nixOpenClaw.nixosModules.openclaw-gateway ];

  options.my.system.openclaw = {
    enable = lib.mkEnableOption "OpenClaw AI gateway";
    workspaceRepo = lib.mkOption {
      type = lib.types.str;
      default = "git@github.com:blackgolyb/openclaw.git";
      description = "Private git repository holding the OpenClaw workspace (identity files, skills, memory, notes).";
    };
    workspaceBranch = lib.mkOption {
      type = lib.types.str;
      default = "main";
      description = "Branch to clone/pull on the workspace repository.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.openclaw-gateway = {
      enable = true;
      package = openclawPkg;
      port = 18789;
      user = "openclaw";
      group = "openclaw";
      inherit stateDir configPath;
      config = openclawConfig;
      environmentFiles = [ "/run/secrets/openclaw.env" ];

      servicePath = [
        pkgs.docker
        pkgs.tailscale
        pkgs.git
        pkgs.openssh
      ];

      execStartPre = [ ];
    };

    # The gateway orchestrates the Docker sandbox, so the dedicated user must be
    # able to talk to the daemon. Tailscale group access lets the gateway manage
    # its own Serve route and verify tailnet identity headers. `users` lets the
    # gateway and the operator share the workspace repository (homelab).
    users.users.openclaw.extraGroups = [
      "docker"
      "tailscale"
      "users"
    ];

    # ---- systemd services / timers / tmpfiles ----
    systemd = {
      services = {
        # Hardening / ordering. Secrets must exist before the gateway starts
        # (there is no restart-loop benefit in an unconfigured process). We force
        # sops' systemd activation path so secrets are also present after a reboot
        # (actsinstall-only mode would leave /run/secrets empty on boot).
        openclaw-gateway = {
          after = [
            "sops-install-secrets.service"
            "docker.service"
            "tailscaled.service"
          ];
          requires = [ "sops-install-secrets.service" ];
        };

        # Ensure the secret target dir exists before sops activation writes into it.
        sops-install-secrets.after = lib.mkAfter [
          "systemd-tmpfiles-setup.service"
        ];

        # ---- workspace repository (single source of truth for the agent tree) ----
        # The OpenClaw workspace lives in a private git repo. On first boot it is
        # cloned (bootstrap); afterwards it is updated with a fast-forward pull on
        # every (re)start/switch. The agent itself commits skills/memory changes
        # into this repo (sandbox has git + the GitHub SSH key); human curation = your commits.
        openclaw-workspace-repo = {
          description = "Clone/update OpenClaw workspace repository";
          wantedBy = [ "multi-user.target" ];
          before = [ "openclaw-gateway.service" ];
          after = [
            "sops-install-secrets.service"
            "network-online.target"
            "systemd-tmpfiles-setup.service"
          ];
          requires = [ "sops-install-secrets.service" ];
          path = [
            pkgs.git
            pkgs.openssh
            pkgs.coreutils
          ];
          serviceConfig = {
            Type = "oneshot";
            User = "openclaw";
            Group = "openclaw";
            RemainAfterExit = true;
            Restart = "on-failure";
            RestartSec = 10;
          };
          unitConfig.StartLimitIntervalSec = 0;
          script = ''
            set -eu

            ws="${stateDir}/workspace"
            repo="${cfg.workspaceRepo}"
            branch="${cfg.workspaceBranch}"
            key="${config.sops.secrets."openclaw/github-ssh".path}"

            # SSH for all workspace git ops (host pull + sandbox push share the same
            # key path and settings via the repo-local core.sshCommand below). The
            # same pattern as the `pass` store bootstrap. Batch/IdentitiesOnly keep
            # it non-interactive; accept-new records the known host key.
            ssh_base="-i $key -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=/tmp/gh_known_hosts"
            export GIT_SSH_COMMAND="${pkgs.openssh}/bin/ssh $ssh_base"
            export GIT_TERMINAL_PROMPT=0

            mkdir -p "$ws"
            chmod g+rwX "$ws"

            git config --global user.name  "openclaw"
            git config --global user.email "openclaw@${config.networking.hostName}.local"

            if [ ! -d "$ws/.git" ]; then
              if [ -n "$(ls -A "$ws")" ]; then
                echo "workspace not empty and no git repo; refusing to clobber" >&2
                exit 1
              fi
              git clone --branch "$branch" --single-branch "$repo" "$ws"
            else
              git -C "$ws" pull --ff-only origin "$branch"
            fi

            # Shared ownership: the sandbox (uid 1000) and the operator (uid 1000,
            # group `users`) both commit to this repo. core.sshCommand makes every
            # git call inside the workspace use the key (in both host and sandbox).
            git -C "$ws" config core.sharedRepository group
            git -C "$ws" config core.sshCommand "${pkgs.openssh}/bin/ssh $ssh_base"
            chmod -R g+rwX "$ws"
          '';
        };

        # ---- Docker sandbox image -----
        openclaw-sandbox-image = {
          description = "Load OpenClaw sandbox Docker image";
          wantedBy = [ "multi-user.target" ];
          requires = [ "docker.service" ];
          after = [ "docker.service" ];
          before = [ "openclaw-gateway.service" ];
          path = [ pkgs.docker ];
          restartIfChanged = true;
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          script = ''
            ${pkgs.docker}/bin/docker load -i ${sandboxImage}
          '';
        };

        openclaw-security-audit = {
          description = "OpenClaw post-deploy security audit";
          wantedBy = [ "multi-user.target" ];
          after = [
            "openclaw-gateway.service"
            "sops-install-secrets.service"
          ];
          path = [
            pkgs.gnugrep
            pkgs.gnused
            pkgs.coreutils
            pkgs.iproute2
            pkgs.tailscale
            pkgs.bash
          ];
          script = ''
            set +e
            ${securityAudit} ${configPath} ${../../../secrets/openclaw.yaml}
          '';
        };

        # ---- managed tailscale exposure (root-owned, not the gateway) ----
        # `gateway.tailscale.mode = "off"` (openclaw-config.nix): the service user
        # holds no tailnet operator grants. Instead a root oneshot publishes the
        # HTTPS route over the tailnet (Tailscale-signed cert, tailnet-only) to the
        # loopback gateway. Identity checks (allowTailscale) still work: requests
        # reaching the loopback port carry the Tailscale client cert header.
        openclaw-tailscale-serve = {
          description = "Publish OpenClaw gateway over Tailscale Serve";
          wantedBy = [ "multi-user.target" ];
          after = [
            "tailscaled.service"
            "openclaw-gateway.service"
          ];
          requires = [ "tailscaled.service" ];
          path = [
            pkgs.tailscale
            pkgs.coreutils
          ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            Restart = "on-failure";
            RestartSec = 10;
          };
          unitConfig.StartLimitIntervalSec = 0;
          script = ''
            set -eu
            # HTTPS on 443 with the tailnet's own certificate family, proxying to the
            # loopback gateway. `--bg` persists the route across restarts.
            tailscale serve --bg --https=443 http://127.0.0.1:18789
          '';
        };

        # Stage the sandbox's private key copy: a REAL file (sops deploys via a
        # /run symlink, which the sandbox bind guard realpath-checks and blocks)
        # owned by the sandbox's uid 1000 / gid 100 with mode 0400 so OpenSSH
        # inside the container accepts it. The gateway reads this path for the
        # container bind mount; the repo-local core.sshCommand path is unchanged.
        openclaw-sandbox-key = {
          description = "Stage sandbox GitHub SSH key copy";
          wantedBy = [ "multi-user.target" ];
          after = [
            "sops-install-secrets.service"
            "openclaw-workspace-repo.service"
          ];
          requires = [ "sops-install-secrets.service" ];
          before = [ "openclaw-gateway.service" ];
          path = [ pkgs.coreutils ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          script = ''
            set -eu
            install -d -o 1000 -g 100 -m 0700 /var/lib/openclaw/secrets/sandbox
            install -o 1000 -g 100 -m 0400 /run/secrets/openclaw/github-ssh /var/lib/openclaw/secrets/sandbox/github-ssh
          '';
        };
      };

      tmpfiles.rules = [
        "d ${stateDir} 0750 openclaw openclaw - -"
        "d ${stateDir}/workspace 2770 openclaw users - -"
        "d ${stateDir}/secrets 0750 openclaw openclaw - -"
        "d ${stateDir}/logs/security-audit 0750 openclaw openclaw - -"
        "d ${stateDir}/secrets/sandbox 0700 1000 100 - -"
      ];

      timers.openclaw-security-audit = {
        description = "Daily OpenClaw security audit";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
        };
      };
    };

    # ---- secrets ----
    sops = {
      useSystemdActivation = true;
      age.keyFile = "/home/blackgolyb/.config/sops/age/keys.txt";

      secrets."openclaw/env" = {
        sopsFile = ../../../secrets/openclaw.yaml;
        format = "dotenv";
        path = "/run/secrets/openclaw.env";
        owner = "openclaw";
        group = "openclaw";
        mode = "0400";
      };

      # GitHub SSH key (same material as the `pass` store clone) used by the
      # workspace-repo service on the host AND by the agent's git commands inside
      # the sandbox. Two on-disk copies are needed (sops only deploys the key via
      # a /run/secrets symlink, which both OpenSSH and the sandbox bind guard
      # reject):
      #   - host copy: 0400, owner openclaw — OpenSSH refuses group/world-readable
      #     private keys, so NOT 0440 as initially shipped;
      #   - sandbox copy: 0400, owner uid 1000 (mirrors the container user) and a
      #     REAL file under /var/lib/openclaw (not a /run symlink, which the
      #     sandbox security guard realpath-checks and blocks). Staged by the
      #     openclaw-sandbox-key unit below.
      secrets."openclaw/github-ssh" = {
        sopsFile = ../../../secrets/ssh/system/github.key;
        format = "binary";
        path = "/var/lib/openclaw/secrets/github-ssh";
        owner = "openclaw";
        group = "openclaw";
        mode = "0400";
      };
    };

    # ---- local model integrations ----
    services.ollama.loadModels = [ "nomic-embed-text" ];

    # ---- operator CLI ----
    environment.systemPackages = [
      # Operator-facing wrapper: resolves secrets with the invoking user's own
      # sops age key (the service user's /run/secrets are intentionally readable
      # only by the service) and runs against the deployed gateway config with a
      # writable per-user state dir under ~/.openclaw. `oci qr`, `oci tui`,
      # `oci status`, `oci doctor`, ... all work for the operator.
      (pkgs.writeShellScriptBin "oci" ''
        eval "$(${pkgs.sops}/bin/sops -d --input-type dotenv --output-type dotenv ${../../../secrets/openclaw.yaml} | ${pkgs.gnused}/bin/sed 's/^/export /')"
        export OPENCLAW_CONFIG_PATH=${configPath}
        exec ${openclawPkg}/bin/openclaw "$@"
      '')
    ];
  };
}
