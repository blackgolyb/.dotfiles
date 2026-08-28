# Model policy

The model chain for the OpenClaw agent. Configured under
`agents.defaults` in `openclaw-config.nix`.

## Chain (fallback order)

| # | Model ref | Provider (env) | Notes |
| --- | --- | --- | --- |
| 1 | `google/gemini-3.5-flash` | Google (`GEMINI_API_KEY`) | primary, free-tier Flash (strong reasoning + vision) |
| 2 | `google/gemini-3.1-flash-lite` | Google (`GEMINI_API_KEY`) | free-tier Flash-Lite; higher free RPD on quota hits |
| 3 | `groq/openai/gpt-oss-120b` | Groq (`GROQ_API_KEY`) | open-weight, low latency |
| 4 | `openrouter/minimax/minimax-m3:free` | OpenRouter (`OPENROUTER_API_KEY`) | free-tier MinMax M3 (verified live) |
| 5 | `openrouter/nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free` | OpenRouter (`OPENROUTER_API_KEY`) | free reasoning model (verified live) |
| 6 | `openrouter/nvidia/nemotron-3-super-120b-a12b:free` | OpenRouter (`OPENROUTER_API_KEY`) | free 1M-ctx workhorse (verified live) |
| 7 | `openrouter/poolside/laguna-s-2.1:free` | OpenRouter (`OPENROUTER_API_KEY`) | free coding-leaning model (verified live) |
| 8 | `ollama/qwen3.5:9b` | local Ollama (no key) | final fallback; never leaves the host |

Utility (session titles, progress narration): `ollama/qwen3.5:9b`.

Memory embeddings: `ollama/nomic-embed-text` (local).

## Rules

1. **Failover**: prefer the model with the fewest live provider requirements and
   the best cost/quality ratio that can actually handle the task. Only descend
   the chain when the current provider is down, overloaded, or lacks the
   capability (e.g. vision). Never silently switch to a *better-sounding* model.
2. **Local-only data**: anything private or offline-bound should use the Ollama
   fallback (no egress). Photos/audio and personal context may only go to
   providers the user has deliberately keyed.
3. **Verification**: after adding a key, verify the exact model id with
   `oci models list --probe` (or `openclaw config schema`) and update
   `openclaw-config.nix` if a catalog id differs.
4. **Cost**: the chain is free-tier-only (Gemini Flash/Flash-Lite, Groq free
   tier, OpenRouter `:free`, local Ollama). If a free key is not budgeted, unset
   it in `secrets/openclaw.yaml` and trim the chain. Do not add paid-only routes
   (e.g. Gemini 3.x Pro preview) to the chain. OpenRouter `:free` models rotate
   and may 429; they never cost money, they just fail to a lower fallback.
5. **No surprises**: model changes are a NixOS config change — propose,
   approve, `make switch`.

## Provider auth resolution

OpenClaw resolves API keys in order: stored auth profiles → environment
variables (the `EnvironmentFile`) → `models.providers.*.apiKey`. This deploy
uses the `models.providers.*` + env pins; refresh an auth profile via
`oci auth` only if you opt out of the pinned route.