#!/usr/bin/env bash
#
# thespin.ad — one sponsored line for any terminal surface (tmux status, shell
# prompt, Starship). Prints the current ad and earns your share.
#
#   thespin-line.sh [slot]      # slot defaults to "term"; use distinct slots
#                               # (tmux/prompt/starship) to show different ads
#
# Non-blocking: it prints a cached line instantly and refreshes in the
# background, so it never adds latency to your prompt. Stays silent on failure.
# Set THESPIN_KEY (and optionally THESPIN_URL / THESPIN_TTL) in your env to earn.

set -euo pipefail

dir="${HOME}/.thespin"
mkdir -p "$dir" 2>/dev/null || true
# Config (THESPIN_URL / THESPIN_KEY / THESPIN_TTL) so every surface — including
# tmux, whose env differs from your shell — picks up your key.
[ -f "${dir}/config" ] && . "${dir}/config" 2>/dev/null || true
ttl="${THESPIN_TTL:-20}"

# --- refresh mode: fetch the line and write the cache (run in background) ------
if [ "${1:-}" = "--refresh" ]; then
  slot="${2:-term}"
  cache="${dir}/line-${slot}"
  url="${THESPIN_URL:-https://thespin.ad}"
  key="${THESPIN_KEY:-}"

  if [ -n "$key" ]; then
    resp="$(curl -fsS --max-time 3 -H "X-Thespin-Key: ${key}" "${url}/api/serve?slot=${slot}" 2>/dev/null || true)"
  else
    resp="$(curl -fsS --max-time 3 "${url}/api/serve?slot=${slot}" 2>/dev/null || true)"
  fi
  [ -n "$resp" ] || exit 0
  command -v jq >/dev/null 2>&1 || exit 0

  line="$(printf '%s' "$resp" | jq -r '.ad.line // empty' 2>/dev/null || true)"
  price="$(printf '%s' "$resp" | jq -r '.ad.price_per_1k // empty' 2>/dev/null || true)"
  if [ -n "$line" ]; then
    printf '◆ %s  %s [ad]' "$line" "$price" > "$cache"
  else
    : > "$cache" # nothing live — blank the surface
  fi
  exit 0
fi

# --- print mode: show the cached line, refresh in the background if stale ------
slot="${1:-term}"
cache="${dir}/line-${slot}"

[ -f "$cache" ] && cat "$cache"

age=999999
if [ -f "$cache" ]; then
  mtime="$(stat -f %m "$cache" 2>/dev/null || stat -c %Y "$cache" 2>/dev/null || echo 0)"
  age=$(( $(date +%s) - mtime ))
fi

if [ "$age" -ge "$ttl" ]; then
  ( "$0" --refresh "$slot" >/dev/null 2>&1 & ) 2>/dev/null || true
fi
