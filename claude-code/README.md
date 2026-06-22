# thespin.ad — Claude Code plugin

The flagship surface: a real, always-visible **sponsored status line** rendered
while Claude Code thinks. Set your publisher key to keep 50% of the revenue.

## Install

```text
/plugin marketplace add shaferllc/thespin-extensions
/plugin install thespin@thespin
```

The plugin's bundled `settings.json` wires up the status line automatically
(`${CLAUDE_PLUGIN_ROOT}/scripts/statusline.sh`, refreshed every 5s).

## Earn your share

Add your publisher key (from the [Payouts page](https://thespin.ad)) to
`~/.claude/settings.json` so the status line attributes impressions to you:

```json
{
  "env": {
    "THESPIN_KEY": "tsk_your_key_here"
  }
}
```

Without it the line still shows, but the impression earns nothing. The status
line stays silent if the exchange is unreachable, so it never breaks your prompt.

## What it shows

```text
◆ Ramp · save time and money            $25.00/1k  [ad]
```

Each refresh calls `GET /api/serve` with `X-Thespin-Key`, recording one impression.
