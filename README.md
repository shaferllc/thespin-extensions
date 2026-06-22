# thespin.ad — agent extensions

Official integrations that show **one sponsored line while your AI coding agent
works**, so you keep 50% of the revenue. This folder is the source of truth; it's
published to the public **[shaferllc/thespin-extensions](https://github.com/shaferllc/thespin-extensions)**
repo for distribution (the main app repo stays private).

## What each agent supports

Not every agent exposes an always-visible "during-the-wait" surface. Here's the
honest breakdown:

| Agent | Surface | Always visible? | Mechanism |
|-------|---------|-----------------|-----------|
| **Claude Code** | Status line | ✅ Yes | Native plugin → command-backed `statusLine` |
| **VS Code / Cursor** | Status bar item | ✅ Yes | Compiled `.vsix` extension, polls the serve API |
| **Codex CLI** | Transcript (model-invoked) | ⚠️ No | MCP tool `sponsor_message` (no status-line API exists) |
| **Gemini CLI** | Transcript (model-invoked) | ⚠️ No | Extension bundling the same MCP tool + `/sponsor` |

Codex and Gemini **do not** have a third-party status line — their footers accept
only built-in items. The MCP-tool approach is the best supported path on those
two; it surfaces in the transcript when the agent calls the tool.

## Layout

```
extensions/
├── claude-code/      # native Claude Code plugin (status line)
├── vscode/           # VS Code + Cursor extension (.vsix, status bar)
├── mcp-server/       # shared MCP server (@shaferllc/thespin-mcp)
├── codex/            # Codex CLI integration (registers the MCP server)
├── gemini-cli/       # Gemini CLI extension (bundles the MCP server)
└── .claude-plugin/
    └── marketplace.json   # Claude Code marketplace listing
```

## Earn

Every integration reads a `THESPIN_KEY` (your publisher key from the
[Payouts page](https://thespin.ad)) and sends it as `X-Dwell-Key` so impressions
and clicks accrue to your account. Without a key, lines still show but earn
nothing. See each subfolder's README for install + config.
