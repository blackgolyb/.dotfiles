#!/usr/bin/env bash
# OpenClaw post-deploy security audit.
#
# Usage: check-openclaw-security.sh <openclaw.json path> <encrypted sops file>
#
# Exits non-zero on any check failure. A report is written to
# /var/lib/openclaw/logs/security-audit/latest.txt so the agent can review it.
set -u

CFG="${1:-/etc/openclaw/openclaw.json}"
SOPS_FILE="${2:-/home/blackgolyb/nixos/secrets/openclaw.yaml}"
REPORT_DIR="/var/lib/openclaw/logs/security-audit"
REPORT="$REPORT_DIR/latest.txt"

mkdir -p "$REPORT_DIR"
FAIL=0

audit() {
  # 1. Gateway must listen on loopback only.
  echo "-- gateway listener (port 18789) --"
  BINDS="$(ss -ltnp 2>/dev/null | grep -E ':(18789)\b' || true)"
  printf '%s\n' "$BINDS"
  if printf '%s\n' "$BINDS" | grep -qE '0\.0\.0\.0|\[::\]|\*:18789'; then
    echo "FAIL: gateway reachable on a public interface"
    FAIL=1
  fi

  # 2. Gateway must not run as root.
  echo "-- gateway service user --"
  U="$(systemctl show -p User --value openclaw-gateway.service 2>/dev/null)"
  echo "$U"
  if [ "$U" = "root" ] || [ -z "$U" ]; then
    echo "FAIL: gateway is not running as the dedicated openclaw user"
    FAIL=1
  fi

  # 3. Secret file on disk must still be sops-encrypted.
  echo "-- sops secret file --"
  if [ -f "$SOPS_FILE" ] && head -c 4 "$SOPS_FILE" | grep -q '^ENC\[' 2>/dev/null; then
    echo "secrets: $SOPS_FILE encrypted OK"
  else
    echo "FAIL: $SOPS_FILE is missing or not sops-encrypted"
    FAIL=1
  fi

  # 4. Persisted gateway config must reference secrets as \${ENV_VAR}
  #    placeholders, never with concrete key material inline.
  echo "-- persisted config secret handling --"
  if [ -f "$CFG" ]; then
    PLACEHOLDERS="$(grep -oE '\$\{[A-Z_]+\}' "$CFG" | sort -u || true)"
    if [ -n "$PLACEHOLDERS" ]; then
      printf 'placeholders: %s\n' "$(printf '%s' "$PLACEHOLDERS" | tr '\n' ' ')"
    else
      echo "WARN: no env placeholders found in $CFG"
    fi
    for VAR in OPENCLAW_GATEWAY_TOKEN GEMINI_API_KEY OPENROUTER_API_KEY GROQ_API_KEY; do
      if grep -qP "\"${VAR}\"\s*:\s*\"(?!\\\$\{)" "$CFG" 2>/dev/null; then
        echo "FAIL: $VAR resolved to concrete material in persisted config"
        FAIL=1
      fi
    done
  else
    echo "FAIL: $CFG not found"
    FAIL=1
  fi

  # 5. Tailscale managed Serve must be active (informational).
  echo "-- tailscale serve --"
  tailscale serve status 2>&1 | head -20 || true
  if ! tailscale serve status >/dev/null 2>&1; then
    echo "WARN: tailscale serve reports an issue (see output above)"
  fi

  # 6. Gateway service must be running.
  echo "-- gateway service state --"
  systemctl is-active openclaw-gateway.service || FAIL=1
}

{
  echo "OpenClaw security audit $(date -Is)"
  echo "===================================="
  audit
  echo
  echo "RESULT: $([ "$FAIL" -eq 0 ] && echo PASS || echo FAIL)"
} | tee "$REPORT"

exit "$FAIL"
