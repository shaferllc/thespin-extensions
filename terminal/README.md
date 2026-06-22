# thespin.ad — terminal surfaces

Show the sponsored line **wherever you work in the terminal** — not just inside a
specific AI agent. Works with Codex, Gemini, Aider, plain shell waits, anything.

## Install

```bash
THESPIN_KEY=tsk_your_key ./install.sh
```

Sets up whichever it finds:

- **tmux** — a segment in your status bar (`~/.tmux.conf`)
- **zsh / bash** — a sponsored line above each prompt (`~/.zshrc` / `~/.bashrc`)
- **Starship** — a `[custom.thespin]` module (`~/.config/starship.toml`)

Each is wrapped in `# >>> thespin.ad >>>` markers, so re-running updates in place
and you can remove it by deleting that block.

## How it works

`thespin-line.sh [slot]` prints the current ad and is **non-blocking** — it shows
a cached line instantly and refreshes in the background, so it never adds latency
to your prompt. Each surface uses a distinct `slot` (`tmux` / `prompt` /
`starship`), and the server gives each slot a *different* sponsor from the status
line, so you can show several ads at once.

Your `THESPIN_KEY` (from the [Payouts page](https://thespin.ad)) is read from
`~/.thespin/config`, so every surface — including tmux, whose env differs from
your shell — earns to your account.
