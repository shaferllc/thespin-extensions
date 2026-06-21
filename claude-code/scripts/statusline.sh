#!/usr/bin/env bash
#
# thespin.ad — Claude Code sponsored status line.
#
# Prints the current top-bid sponsored line into Claude Code's status line.
# Claude Code pipes session JSON on stdin (ignored) and renders our stdout.
# Wired up by the plugin's bundled settings.json:
#
#   "statusLine": { "type": "command",
#                   "command": "${CLAUDE_PLUGIN_ROOT}/scripts/statusline.sh",
#                   "refreshInterval": 5 }
#
# Each invocation hits the serve API, which counts one impression. Set DWELL_KEY
# (your publisher key from the Payouts page) in ~/.claude/settings.json "env" to
# earn your revenue share; leave it blank to show ads anonymously.

set -euo pipefail

# Drain Claude's JSON payload so the pipe doesn't break (we don't need it).
cat >/dev/null 2>&1 || true

DWELL_URL="${DWELL_URL:-https://thespin.ad}"
DWELL_KEY="${DWELL_KEY:-}"

# ANSI: lime mark + line, amber price, dim chrome. Claude renders these.
DIM=$'\033[2m'; RESET=$'\033[0m'; LIME=$'\033[38;5;156m'; AMBER=$'\033[38;5;221m'

# Send the publisher key as a header so the server can attribute earnings.
if [ -n "$DWELL_KEY" ]; then
  resp="$(curl -fsS --max-time 2 -H "X-Dwell-Key: ${DWELL_KEY}" "${DWELL_URL}/api/serve" 2>/dev/null || true)"
else
  resp="$(curl -fsS --max-time 2 "${DWELL_URL}/api/serve" 2>/dev/null || true)"
fi

if [ -z "$resp" ]; then
  # API unreachable — stay quiet rather than break the status line.
  printf '%s' "${DIM}◆ thespin${RESET}"
  exit 0
fi

# Parse with jq when available, else fall back to python3 (ships with macOS).
if command -v jq >/dev/null 2>&1; then
  line="$(printf '%s' "$resp"  | jq -r '.ad.line        // ""')"
  price="$(printf '%s' "$resp" | jq -r '.ad.price_per_1k // ""')"
elif command -v python3 >/dev/null 2>&1; then
  read -r line price < <(printf '%s' "$resp" | python3 -c '
import sys, json
d = (json.load(sys.stdin).get("ad") or {})
print(d.get("line",""), "\x1f", d.get("price_per_1k",""))
' 2>/dev/null | tr "\x1f" " ")
else
  printf '%s' "${DIM}◆ thespin (install jq for ads)${RESET}"
  exit 0
fi

if [ -z "${line:-}" ]; then
  printf '%s' "${DIM}◆ thespin · spinner unclaimed — bid at ${DWELL_URL}${RESET}"
  exit 0
fi

# e.g.  ◆ Ramp · save time and money            $25.00/1k  [ad]
printf '%s◆%s %s%s%s  %s%s%s %s[ad]%s' \
  "$LIME" "$RESET" "$LIME" "$line" "$RESET" "$AMBER" "${price}/1k" "$RESET" "$DIM" "$RESET"
