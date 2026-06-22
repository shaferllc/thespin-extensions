#!/usr/bin/env bash
#
# thespin.ad — plain-text sponsor line for the /sponsor slash command.
#
# Unlike statusline.sh (which emits ANSI for Claude Code's status bar), this
# prints a clean line + tracked click URL suitable for the transcript. Each call
# hits the serve API and counts one impression; set THESPIN_KEY to earn.

set -euo pipefail

THESPIN_URL="${THESPIN_URL:-https://thespin.ad}"
THESPIN_KEY="${THESPIN_KEY:-}"

if [ -n "$THESPIN_KEY" ]; then
  resp="$(curl -fsS --max-time 3 -H "X-Thespin-Key: ${THESPIN_KEY}" "${THESPIN_URL}/api/serve" 2>/dev/null || true)"
else
  resp="$(curl -fsS --max-time 3 "${THESPIN_URL}/api/serve" 2>/dev/null || true)"
fi

if [ -z "$resp" ]; then
  printf '◆ thespin · exchange offline (%s)\n' "$THESPIN_URL"
  exit 0
fi

# Render with jq when available, else python3 (ships with macOS). Each backend
# prints the final text itself so multi-word brands/lines survive intact.
if command -v jq >/dev/null 2>&1; then
  line="$(printf '%s' "$resp"  | jq -r '.ad.line         // ""')"
  if [ -z "$line" ]; then
    printf '◆ thespin · spinner unclaimed — bid at %s\n' "$THESPIN_URL"
    exit 0
  fi
  brand="$(printf '%s' "$resp" | jq -r '.ad.brand        // ""')"
  price="$(printf '%s' "$resp" | jq -r '.ad.price_per_1k // ""')"
  premium="$(printf '%s' "$resp" | jq -r 'if .ad.premium then "1" else "" end')"
  click="$(printf '%s' "$resp"  | jq -r '.ad.click_url    // ""')"
  [ -n "$premium" ] && mark="★" || mark="◆"
  printf '%s %s — %s/1k [ad]\n' "$mark" "$line" "$price"
  [ -n "$brand" ] && printf 'Sponsor: %s\n' "$brand"
  [ -n "$click" ] && printf 'Open (tracked): %s\n' "$click"
elif command -v python3 >/dev/null 2>&1; then
  THESPIN_URL="$THESPIN_URL" RESP="$resp" python3 <<'PY'
import json, os
d = (json.loads(os.environ["RESP"]).get("ad") or {})
line = d.get("line") or ""
if not line:
    print(f'◆ thespin · spinner unclaimed — bid at {os.environ["THESPIN_URL"]}')
else:
    mark = "★" if d.get("premium") else "◆"
    print(f'{mark} {line} — {d.get("price_per_1k") or ""}/1k [ad]')
    if d.get("brand"):
        print(f'Sponsor: {d["brand"]}')
    if d.get("click_url"):
        print(f'Open (tracked): {d["click_url"]}')
PY
else
  printf '◆ thespin (install jq or python3 to render the line)\n'
  exit 0
fi
