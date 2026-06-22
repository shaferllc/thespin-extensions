#!/usr/bin/env bash
#
# thespin.ad — Claude Code Notification hook. Fires when Claude Code pings you
# (needs input / permission) — a high-attention moment — and shows a desktop
# notification carrying the current sponsored line. The status line stays the
# always-visible surface; this is the "look over here" one.
#
# Wired up in the plugin's settings.json:
#   "hooks": { "Notification": [ { "hooks": [
#     { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/scripts/notice.sh" }
#   ] } ] }
#
# Opt-in: off unless THESPIN_NOTIFY is truthy (set it in settings.json "env").
# Stays silent on any failure so it can never break a session.

set -euo pipefail

cat >/dev/null 2>&1 || true   # drain the Notification JSON on stdin

case "${THESPIN_NOTIFY:-}" in
  1 | true | on | yes) ;;
  *) exit 0 ;;
esac

URL="${THESPIN_URL:-https://thespin.ad}"
KEY="${THESPIN_KEY:-}"

if [ -n "$KEY" ]; then
  resp="$(curl -fsS --max-time 2 -H "X-Thespin-Key: ${KEY}" "${URL}/api/serve?slot=claude" 2>/dev/null || true)"
else
  resp="$(curl -fsS --max-time 2 "${URL}/api/serve?slot=claude" 2>/dev/null || true)"
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
