#!/usr/bin/env bash
#
# thespin.ad — server-driven spinner verbs (the "loading screen" text).
#
# Claude Code's `spinnerVerbs` is static config with no command mode, so we make
# it server-driven the only supported way: a SessionStart hook that fetches the
# current sponsor's verbs from the serve API and rewrites the `verbs` array in
# this plugin's own settings.json. Settings hot-reload, so the spinner picks up
# the new lines (this session or the next). Wired up in settings.json:
#
#   "hooks": { "SessionStart": [ { "hooks": [
#     { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/scripts/spinner-verbs.sh" }
#   ] } ] }
#
# The spinner is ad space too: the verb shown next to "thinking…" is the brand's.
# Stays silent on any failure so it can never break a session.

set -euo pipefail

# Drain the SessionStart JSON on stdin (we don't need it).
cat >/dev/null 2>&1 || true

# Opt-in. This refresh hits /api/serve, counting one impression per session start
# on top of the status line's. Off unless THESPIN_SPINNER_VERBS is truthy; flip it
# to "1" in the plugin's settings.json "env" (or your own settings) to enable.
case "${THESPIN_SPINNER_VERBS:-}" in
  1 | true | on | yes) ;;
  *) exit 0 ;;
esac

THESPIN_URL="${THESPIN_URL:-https://thespin.ad}"
THESPIN_KEY="${THESPIN_KEY:-}"
SETTINGS="${CLAUDE_PLUGIN_ROOT:-}/settings.json"

# No plugin root / settings file → nothing to patch.
[ -f "$SETTINGS" ] || exit 0

if [ -n "$THESPIN_KEY" ]; then
  resp="$(curl -fsS --max-time 2 -H "X-Dwell-Key: ${THESPIN_KEY}" "${THESPIN_URL}/api/serve" 2>/dev/null || true)"
else
  resp="$(curl -fsS --max-time 2 "${THESPIN_URL}/api/serve" 2>/dev/null || true)"
fi

[ -n "$resp" ] || exit 0

# Patch .spinnerVerbs.verbs with the served array, preserving everything else.
# jq when available, else python3 (ships with macOS). No tool → leave the static
# verbs in place.
tmp="$(mktemp 2>/dev/null || echo "${SETTINGS}.tmp")"

if command -v jq >/dev/null 2>&1; then
  verbs="$(printf '%s' "$resp" | jq -c '.ad.verbs // empty' 2>/dev/null || true)"
  [ -n "$verbs" ] || exit 0
  jq --argjson verbs "$verbs" \
    '.spinnerVerbs.mode = (.spinnerVerbs.mode // "append") | .spinnerVerbs.verbs = $verbs' \
    "$SETTINGS" > "$tmp" 2>/dev/null && mv "$tmp" "$SETTINGS"
elif command -v python3 >/dev/null 2>&1; then
  RESP="$resp" SETTINGS="$SETTINGS" TMP="$tmp" python3 <<'PY' || true
import json, os
verbs = (json.loads(os.environ["RESP"]).get("ad") or {}).get("verbs")
if not verbs:
    raise SystemExit(0)
settings_path, tmp = os.environ["SETTINGS"], os.environ["TMP"]
with open(settings_path) as f:
    cfg = json.load(f)
sv = cfg.get("spinnerVerbs") or {}
sv.setdefault("mode", "append")
sv["verbs"] = verbs
cfg["spinnerVerbs"] = sv
with open(tmp, "w") as f:
    json.dump(cfg, f, indent=2)
os.replace(tmp, settings_path)
PY
fi

exit 0
