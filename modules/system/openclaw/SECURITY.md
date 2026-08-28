# Security posture

## Do nots (from the deployment plan)

- Never expose the gateway on a public interface. `gateway.bind: "loopback"`
  is enforced; only Tailscale-managed HTTPS (serve mode) fronts it.
- The gateway never runs as root. Dedicated `openclaw` system user; config dir
  is root-owned read-only (`0644`); state dir is `openclaw`-owned.
- No secrets in git/config/logs. All keys live in sops (`secrets/openclaw.yaml`)
  and are injected only as `${ENV_VAR}` placeholders that resolve at runtime.
- No `sudo` inside the agent; no curl|bash payloads; no automatic installs.

## Privilege notes

- `openclaw` is a member of `docker` and `tailscale` groups:
  - `docker`: required so the gateway can spawn the sandbox containers it
    manages. Group membership is the practical equivalent of root on the admin
    socket; this is the upstream-sanctioned model for Docker-backed sandboxing
    on a personal host. The sandbox containers themselves get no docker socket.
  - `tailscale`: lets the gateway verify tailnet identity headers; the
  Tailscale Serve route itself is published by a root systemd unit
  (gateway-tailscale-serve), not by the gateway.
- Sandbox containers: `network: bridge` (needed for clone/push/tests),
  `capDrop: ALL`, `readOnlyRoot: true`, writable tmpfs, run as uid/gid
  `1000:100`. Host binds are limited to the agent workspace (`workspaceAccess:
  rw`); the Git SSH key is the only external source, enabled via the single
  `dangerouslyAllowExternalBindSources` escape hatch because OpenClaw fixes
  allowed bind roots to the workspace dirs. The key source is a deliberately
  staged `0400` file in the gateway's own root-owned state dir, never a user
  path.
- Git auth for the workspace repo is the operator's GitHub SSH key
  (`secrets/ssh/system/github.key`). Two on-disk copies exist because the
  sandbox (uid 1000) and the service user (`openclaw`, uid 994) are different
  users and OpenSSH requires `0400` owner-only private keys:
  - host pull copy: `/var/lib/openclaw/secrets/github-ssh` (owner `openclaw`,
    mode `0400` — OpenSSH refuses group-readable keys, so not `0440` as
    initially shipped);
  - sandbox copy: `/var/lib/openclaw/secrets/sandbox/github-ssh` (owner uid
    `1000` / gid `100`, mode `0400`), staged by the root `openclaw-sandbox-key`
    oneshot and bind-mounted read-only inside the container at
    `/var/lib/openclaw/secrets/github-ssh` so the repo-local `core.sshCommand`
    works. It is the same key the `pass` store
  uses; a dedicated repo-scoped deploy key would limit blast radius — consider
  rotating to one if the agent ever prompts for arbitrary repositories.

## Automated audit

`openclaw-security-audit.service` runs at boot and `openclaw-security-audit.timer`
daily. It checks:

1. Gateway listens on loopback only (port 18789).
2. Gateway runs as `openclaw`, not root.
3. `secrets/openclaw.yaml` is sops-encrypted on disk.
4. `/etc/openclaw/openclaw.json` contains only `${ENV_VAR}` placeholders for
   secrets (no serialized key material).
5. Tailscale Serve report (informational).
6. Gateway service is `active`.

Report: `/var/lib/openclaw/logs/security-audit/latest.txt`.
Agent skill `security-report` explains how to triage findings.

## Threat model (summary)

The main risk chain is model → tool call → container. Failure modes and
mitigations:

| Threat | Mitigation |
| --- | --- |
| Prompt injection leads to destructive exec | sandbox only, cap-less, RO root, user 1000:1000 |
| Exfiltration via egress | bridge egress allowed only for work; audit logs; no secrets outside env |
| Compromised provider | local fallbacks for sensitive/offline data |
| Write to host repos | workspace clones + branch/PR flow; host checkout stays untouched |
| Token leak via config/logs | env placeholders only; security audit greps the persisted config |

## Incident response

Any `FAIL` in the audit is a P1: surface to the user, stop autonomous work,
recommend key rotation for whatever applies, and fix declaratively.