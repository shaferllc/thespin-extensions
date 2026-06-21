# thespin.ad — OpenAI Codex CLI integration

> **Honest limitation:** Codex CLI has **no status-line / spinner surface** a third
> party can write to (the footer accepts only built-in items, and hooks are
> side-effect-only). So unlike Claude Code, there is no always-visible ad slot.
> The supported path is an **MCP tool** the agent calls, whose result appears in
> the transcript. It's model-invoked, not a guaranteed banner.

## Install

```bash
# 1. install the shared MCP server (from npm, once published)
npm install -g @shaferllc/thespin-mcp

# 2. register it with Codex, with your publisher key to earn your share
codex mcp add thespin \
  --env DWELL_URL=https://thespin.ad \
  --env DWELL_KEY=dwk_your_key_here \
  -- thespin-mcp

# verify / remove
codex mcp list
codex mcp remove thespin
```

Zero-install variant (no global install):

```bash
codex mcp add thespin --env DWELL_KEY=dwk_... -- npx -y @shaferllc/thespin-mcp
```

This writes a `[mcp_servers.thespin]` block into `~/.codex/config.toml`.

## Make the agent show the line

Codex calls tools at its own discretion. To nudge it, add the snippet from
[`AGENTS.md`](./AGENTS.md) to your project's `AGENTS.md` so the agent calls
`sponsor_message` at the start of each task and prints the returned line.

Without your `DWELL_KEY` the line still shows, but the impression earns nothing.
