# Generates the `openclaw.json` attrset for the gateway.
#
# Secret values are never inlined here: every secret is referenced as an
# OpenClaw `${ENV_VAR}` placeholder resolved at runtime from the gateway
# process environment (loaded from `/run/secrets/openclaw.env`, see
# openclaw.nix). Keep this file free of any key material.

{
  lib,
  stateDir ? "/var/lib/openclaw",
  # Decrypted GitHub SSH key (sops) used by the workspace repo. Mounted at the
  # SAME path inside the sandbox as on the host so the repo-local
  # `core.sshCommand` works identically when the agent pushes from the container.
  sshKeyPath ? "/var/lib/openclaw/secrets/github-ssh",
  # Real file (NOT the sops /run symlink) owned by the sandbox uid for the
  # container bind; staged by the openclaw-sandbox-key unit.
  sshSandboxKeyPath ? "/var/lib/openclaw/secrets/sandbox/github-ssh",
  # Main model chain (verified/curated in MODEL_POLICY.md). Primary and early
  # fallbacks are free-tier Gemini Flash/Flash-Lite (aistudio key, no billing);
  # 3.x Pro routes are paid-only and intentionally not used.
  primaryModel ? "google/gemini-3.5-flash",
  fallbackModels ? [
    "google/gemini-3.1-flash-lite"
    "groq/openai/gpt-oss-120b"
    "openrouter/minimax/minimax-m3:free"
    "openrouter/nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free"
    "openrouter/nvidia/nemotron-3-super-120b-a12b:free"
    "openrouter/poolside/laguna-s-2.1:free"
    "ollama/qwen3.5:9b"
  ],
  utilityModel ? "ollama/qwen3.5:9b",
}:

let
  envVar = name: "\${${name}}";
in
{
  gateway = {
    # Local mode: channels and the agent runtime run on this host.
    mode = "local";
    port = 18789;
    # TZ: never expose on a public interface; 127.0.0.1 only.
    bind = "loopback";
    # Tailscale HTTPS is published by a root systemd unit
    # (openclaw-tailscale-serve), not by the gateway: keeps the service user
    # (openclaw) free of any tailnet operator grants.
    tailscale = {
      mode = "off";
    };
    auth = {
      mode = "token";
      token = envVar "OPENCLAW_GATEWAY_TOKEN";
      # Tokenless Control UI/WebSocket auth over Tailscale identity headers.
      allowTailscale = true;
    };
  };

  # Telegram: built-in channel (long-polling, no exposed webhook/port needed —
  # fits the loopback-only posture). Single-operator bot: only the owner's
  # numeric Telegram user id may DM; groups are disabled entirely.
  channels = {
    telegram = {
      enabled = true;
      # Secret via env (sops -> /run/secrets/openclaw.env), never inlined.
      botToken = envVar "TELEGRAM_BOT_TOKEN";
      # Only the owner: explicit numeric id allowlist. First approved DM pairing
      # also bootstraps commands.ownerAllowFrom (owner-only commands/approvals).
      dmPolicy = "allowlist";
      # Resolved from env/sops at runtime (never inlined here). You'll add
      # TELEGRAM_USER_ID=numeric-user-id to secrets/openclaw.yaml.
      allowFrom = [
        (envVar "TELEGRAM_USER_ID")
      ];
      # No groups: this is the operator's personal bot.
      groupPolicy = "disabled";
    };
  };

  # Global TTS for outbound voice replies. Microsoft Edge neural voices need no
  # API key (free, best-effort — see MODEL_POLICY cost posture). Telegram
  # delivers these as native voice notes. `off` = never auto-speak; TTS only on
  # explicit intent (/tts audio, "say it as voice", audio directives).
  messages = {
    tts = {
      auto = "tagged";
      provider = "microsoft";
      providers.microsoft = {
        lang = "en-US";
        outputFormat = "audio-24khz-48kbitrate-mono-mp3";
        rate = "+0%";
        pitch = "+0%";
        speakerVoice = "en-US-MichelleNeural";
      };
    };
  };

  # Mobile pairing: the gateway never leaves loopback (bind + tailscale.mode
  # above), so the device-pair plugin must be told the public URL to mint
  # reachable setup codes. The value comes from the environment (encrypted at
  # rest in secrets/openclaw.yaml), never inlined here.
  plugins = {
    entries = {
      device-pair = {
        # Bundled plugin is disabled by default; the mobile app's setup
        # handshake (and the /pair slash command) needs it active. Approvals
        # stay manual; scopes stay bounded by the setup-code profile.
        enabled = true;
        config = {
          publicUrl = envVar "OPENCLAW_PUBLIC_URL";
        };
      };
      # Talk STT provider config lives under the voice-call streaming section
      voice-call = {
        config = {
          streaming = {
            provider = "deepgram";
            providers.deepgram = {
              apiKey = envVar "DEEPGRAM_API_KEY";
              language = "en-US";
              encoding = "mulaw";
              sampleRate = 8000;
              endpointingMs = 800;
              interimResults = true;
            };
          };
        };
      };
    };
  };

  agents = {
    defaults = {
      # Keep the default personal workspace: <stateDir>/workspace.
      model = {
        primary = primaryModel;
        fallbacks = fallbackModels;
      };
      # Cheap short internal tasks (titles, progress narration) run locally.
      inherit utilityModel;
      # Local memory search: MEMORY.md + cross-conversation transcripts,
      # embedded by the local Ollama server (host hit only).
      memorySearch = {
        enabled = true;
        provider = "ollama";
        model = "nomic-embed-text";
        fallback = "none";
        sources = [
          "memory"
          "sessions"
        ];
      };
      # TZ core: the gateway never runs arbitrary commands on the host.
      # All tool execution goes through the Docker sandbox.
      sandbox = {
        mode = "all";
        scope = "agent";
        backend = "docker";
        workspaceAccess = "rw";
        docker = {
          image = "openclaw-sandbox:latest";
          readOnlyRoot = true;
          tmpfs = [
            "/tmp"
            "/var/tmp"
            "/run"
          ];
          # Coding/git tasks need egress (clone, push, deps). Tightened in
          # SECURITY.md; sandbox still drops all capabilities.
          network = "bridge";
          capDrop = [ "ALL" ];
          # Run as the operator's uid:gid so workspace files created inside the
          # sandbox are owned by blackgolyb (and group `users`, matching the
          # setgid workspace repo dir shared with the openclaw user).
          user = "1000:100";
          # Sandbox git auth: the key mounted at the same path the repo-local
          # `core.sshCommand` uses. This is NOT the sops path — sops deploys
          # via a /run/secrets symlink, which OpenSSH and the bind guard reject.
          # The staged real file (0400, owned by the sandbox uid 1000) satisfies
          # both OpenSSH's permission check and the sandbox security guard.
          #
          # OpenClaw locks bind sources to the workspace dirs by default; the
          # key lives outside them, so we enable the single-purpose escape hatch
          # (`dangerouslyAllowExternalBindSources`). Scope: the source path is a
          # deliberately staged 0400 file in the gateway's own state dir (root
          # owned dir), never a user path — see SECURITY.md.
          dangerouslyAllowExternalBindSources = true;
          binds = [ "${sshSandboxKeyPath}:${sshKeyPath}:ro" ];
          env = {
            HOME = "/tmp";
            GIT_EDITOR = "true";
          };
        };
      };
    };
  };

  memory = {
    backend = "builtin";
  };

  # TZ: self-learning through the Skill Workshop, but human-gated. Autonomous
  # capture drafts proposals; every apply/reject still needs operator approval.
  skills = {
    workshop = {
      autonomous = {
        enabled = true;
      };
      approvalPolicy = "pending";
    };
  };

  models = {
    providers = {
      google = {
        apiKey = envVar "GEMINI_API_KEY";
      };
      openrouter = {
        apiKey = envVar "OPENROUTER_API_KEY";
      };
      groq = {
        apiKey = envVar "GROQ_API_KEY";
      };
      ollama = {
        baseUrl = "http://127.0.0.1:11434";
        apiKey = "ollama-local";
      };
    };
  };

  logging = {
    level = "info";
  };

  # Talk-mode client voice for the web/mobile UIs. Two halves under stt-tts:
  #   - TTS: Microsoft Edge neural voices (keyless, free, best-effort — see
  #     MODEL_POLICY cost posture).
  #   - STT: Deepgram realtime transcription (generous free credit), configured
  #     under the voice-call plugin streaming section (that is where the Talk
  #     transcription relay reads provider config from).
  talk = {
    provider = "microsoft";
    providers.microsoft = {
      lang = "en-US";
      outputFormat = "audio-24khz-48kbitrate-mono-mp3";
      rate = "+0%";
      pitch = "+0%";
      speakerVoice = "en-US-MichelleNeural";
    };
    realtime = {
      mode = "stt-tts";
      transport = "managed-room";
      brain = "agent-consult";
    };
    speechLocale = "en-US";
    interruptOnSpeech = true;
    silenceTimeoutMs = 1200;
  };

  # TZ: no silent self-updates; systemd Restart=always keeps it supervised.
  update = {
    checkOnStart = false;
    auto = {
      enabled = false;
    };
  };
}
