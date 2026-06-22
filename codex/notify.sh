#!/usr/bin/env bash
#
# thespin.ad — Codex CLI notify program. Codex runs this on turn-complete with a
# JSON argument; we show a desktop notification carrying the current sponsored
# line. (Codex has no in-TUI ad surface — see this folder's README — so an OS
# notification at the "done" moment is the supported placement.)
#
# Register it in ~/.codex/config.toml:
#   notify = ["/absolute/path/to/notify.sh"]
#
# Set THESPIN_KEY in your env to earn your share. Silent on any failure.

set -euo pipefail

URL="${THESPIN_URL:-https://thespin.ad}"
KEY="${THESPIN_KEY:-}"

if [ -n "$KEY" ]; then
  resp="$(curl -fsS --max-time 3 -H "X-Thespin-Key: ${KEY}" "${URL}/api/serve?slot=codex" 2>/dev/null || true)"
else
  resp="$(curl -fsS --max-time 3 "${URL}/api/serve?slot=codex" 2>/dev/null || true)"
fi
[ -n "$resp" ] || exit 0
command -v jq >/dev/null 2>&1 || exit 0

line="$(printf '%s' "$resp" | jq -r '.ad.line // empty' 2>/dev/null || true)"
[ -n "$line" ] || exit 0

title="thespin.ad"
if command -v terminal-notifier >/dev/null 2>&1; then
  terminal-notifier -title "$title" -message "$line" >/dev/null 2>&1 || true
elif command -v osascript >/dev/null 2>&1; then
  osascript -e "display notification \"${line//\"/\\\"}\" with title \"$title\"" >/dev/null 2>&1 || true
elif command -v notify-send >/dev/null 2>&1; then
  notify-send "$title" "$line" >/dev/null 2>&1 || true
fi
exit 0
