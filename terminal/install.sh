#!/usr/bin/env bash
#
# thespin.ad — install the sponsored line into your terminal surfaces (tmux
# status bar, shell prompt, Starship). Works alongside any AI agent — the ad
# shows whenever you're at the terminal, not just inside one tool.
#
#   THESPIN_KEY=tsk_... ./install.sh            # set up every surface found
#   THESPIN_URL=https://thespin.ad THESPIN_KEY=tsk_... ./install.sh
#
# Idempotent: each surface is wrapped in # >>> thespin >>> markers, so re-running
# updates rather than duplicates. Set THESPIN_KEY to earn your 50% share.

set -euo pipefail

URL="${THESPIN_URL:-https://thespin.ad}"
KEY="${THESPIN_KEY:-}"
dir="${HOME}/.thespin"
line="${dir}/thespin-line.sh"
src="$(cd "$(dirname "$0")" && pwd)/thespin-line.sh"

green() { printf '\033[38;5;156m✓\033[0m %s\n' "$1"; }
dim()   { printf '\033[2m%s\033[0m\n' "$1"; }

mkdir -p "$dir"
cp "$src" "$line"
chmod +x "$line"
printf 'THESPIN_URL=%q\nTHESPIN_KEY=%q\n' "$URL" "$KEY" > "${dir}/config"
green "Installed $line"
[ -n "$KEY" ] && green "Earning to your account" || dim "Anonymous — set THESPIN_KEY to earn your share"

# Append a marker-wrapped block to a file, replacing any prior thespin block.
wire() {
  local file="$1" body="$2"
  [ -f "$file" ] || touch "$file"
  # Strip any existing block, then append the fresh one.
  if grep -q '# >>> thespin.ad >>>' "$file" 2>/dev/null; then
    sed -i.thespin-bak '/# >>> thespin.ad >>>/,/# <<< thespin.ad <<</d' "$file" 2>/dev/null || true
  fi
  {
    printf '# >>> thespin.ad >>>\n'
    printf '%s\n' "$body"
    printf '# <<< thespin.ad <<<\n'
  } >> "$file"
}

# --- tmux ---------------------------------------------------------------------
if command -v tmux >/dev/null 2>&1; then
  wire "${HOME}/.tmux.conf" "set -ag status-right ' #($line tmux) '"
  green "Wired tmux status bar (~/.tmux.conf) — reload with: tmux source ~/.tmux.conf"
fi

# --- zsh ----------------------------------------------------------------------
if [ -f "${HOME}/.zshrc" ] || [ "${SHELL:-}" = "$(command -v zsh 2>/dev/null)" ]; then
  wire "${HOME}/.zshrc" \
"_thespin_prompt() { local l; l=\"\$(\"$line\" prompt 2>/dev/null)\"; [ -n \"\$l\" ] && print -P \"%F{246}\$l%f\"; }
typeset -ga precmd_functions
precmd_functions+=(_thespin_prompt)"
  green "Wired zsh prompt (~/.zshrc) — open a new shell or: source ~/.zshrc"
fi

# --- bash ---------------------------------------------------------------------
if [ -f "${HOME}/.bashrc" ]; then
  wire "${HOME}/.bashrc" \
"_thespin_prompt() { local l; l=\"\$(\"$line\" prompt 2>/dev/null)\"; [ -n \"\$l\" ] && printf '\\033[38;5;246m%s\\033[0m\\n' \"\$l\"; }
case \"\${PROMPT_COMMAND:-}\" in *_thespin_prompt*) ;; *) PROMPT_COMMAND=\"_thespin_prompt;\${PROMPT_COMMAND:-}\" ;; esac"
  green "Wired bash prompt (~/.bashrc) — open a new shell or: source ~/.bashrc"
fi

# --- starship -----------------------------------------------------------------
if command -v starship >/dev/null 2>&1; then
  conf="${HOME}/.config/starship.toml"
  mkdir -p "$(dirname "$conf")"
  wire "$conf" \
"[custom.thespin]
command = \"$line starship\"
when = true
format = \"[\$output](dimmed)\""
  green "Wired Starship module (~/.config/starship.toml)"
fi

green "Done — the sponsored line now shows wherever you work in the terminal."
