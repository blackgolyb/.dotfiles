# OpenClaw gateway on NixOS

Self-hosted OpenClaw personal AI agent deployed declaratively from this flake.

## Architecture

```
Control UI (Tailscale HTTPS)  ->  openclaw-gateway (systemd, user `openclaw`)
                                     | 127.0.0.1:18789
                                     +-> Docker sandbox `openclaw-sandbox:latest`
                                     |     (baked-in: git, node, python, opencode)
                                     +-> Ollama 127.0.0.1:11434  (utility + memory embeddings)
                                     +-> git repos (branches / PRs)
```

- **Package**: `nix-openclaw` flake input (pinned `v2026.7.1-2`), NixOS module
  `services.openclaw-gateway`, garnix binary cache.
- **Config source**: `openclaw-config.nix` attrset, rendered to
  `/etc/openclaw/openclaw.json` at build time. Never edit it by hand.
- **Secrets**: `/run/secrets/openclaw.env` (sops, dotenv) mounted via
  systemd `EnvironmentFile`; config references them as `${VAR}` placeholders.
- **State**: `/var/lib/openclaw` (workspace, sqlite memory, logs/gateway.log).
- **Workspace**: a git repository stored in `/var/lib/openclaw/workspace`,
  bootstrapped from the private repo `git@github.com:blackgolyb/openclaw` on
  first boot, then fast-forward-pulled on every switch. Identity files, skills
  and memory all live in that repo; the agent commits its own approved changes
  back into it (sandbox has `git` + the GitHub SSH key). Your commits there are
  the curation layer.

## Layout

| Path | Purpose |
| --- | --- |
| `openclaw.nix` | module: service, user, workspace repo, sops, sandbox image, audit |
| `openclaw-config.nix` | generated `openclaw.json` attrset |
| `sandbox.nix` | Docker sandbox image (with OpenCode) |
| `scripts/check-openclaw-security.sh` | automated security audit |
| `MODEL_POLICY.md` | model chain, providers, budgets, policies |
| `SECURITY.md` | security posture, threat notes |

## One-time secrets

```
make openclaw-secrets         # sops edit secrets/openclaw.yaml
```

Fill in your provider keys (see MODEL_POLICY.md). The gateway token is already
randomly generated. Clone/pull/agent pushes use the GitHub SSH key already in
this flake (`secrets/ssh/system/github.key`; the same key the `pass` store
uses) — it must have access to `blackgolyb/openclaw`. The repo must contain at
least one commit on `main` before the first deploy, or the clone fails. After
editing, `nixos-rebuild switch` restarts the gateway.

## Deploy / update

```
make switch                   # sudo nixos-rebuild switch --flake .#nixos
```

Update the pinned OpenClaw release by bumping `nix-openclaw` input
(`nix flake update nix-openclaw`), then `make switch`.

Tailscale Serve (HTTPS on the tailnet) is managed by a root systemd unit
(`openclaw-tailscale-serve`); the gateway itself stays loopback-only and holds
no tailnet operator grants. Inspect with `tailscale serve status`;
`openclaw doctor` is the first troubleshooting step.

## Ops cheatsheet

```
sudo systemctl status openclaw-gateway.service
journalctl -u openclaw-gateway.service -f
tail -f /var/lib/openclaw/logs/gateway.log
sudo systemctl status openclaw-security-audit    # boot audit
sudo systemctl list-timers openclaw-security-audit
oci status          # CLI wrapper for your user (sops-decrypted secrets, ~/.openclaw state)
oci tui             # terminal UI as your user (alias: openclaw-tui)
oci qr              # mobile pairing code (needs --public-url https://nixos.tail94df59.ts.net)
sudo systemctl start openclaw-sandbox-image      # reload sandbox image
```

```
sudo systemctl status openclaw-workspace-repo   # clone / ff-pull workspace
```

## Status

- Workspace repo is the single source of truth for the agent tree. Approved
  Skill Workshop changes land in the workspace repo; the agent (sandbox) can
  commit and push them itself. To make something baseline, commit it in the
  workspace repo (or bump it here if it ever becomes config).
- Free text-to-speech (Microsoft Edge, no API key) is enabled in `tts`
  (`openclaw-config.nix`): every reply is also spoken as audio. This is speech
  OUTPUT only. For live two-way voice, pair a macOS/iOS/Android app as a node
  (`oci qr --public-url https://nixos.tail94df59.ts.net`, then approve with
  `openclaw devices approve`) and turn on native Talk; the node's on-device
  speech recognition is free and the reply voice uses the `tts` provider above.
  Realtime browser Talk (OpenAI Realtime / Gemini Live) stays off: it needs a
  paid provider. Messaging channels are separate (see task.md phase 3).