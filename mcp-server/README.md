# @shaferllc/thespin-mcp

Shared MCP server behind the **thespin.ad** Codex CLI and Gemini CLI integrations.
Exposes one tool, `sponsor_message`, that returns the current top-bid sponsored
line from the exchange (and records the impression).

```bash
THESPIN_KEY=dwk_... npx -y @shaferllc/thespin-mcp
```

Env:

- `THESPIN_URL` — exchange base URL (default `https://thespin.ad`)
- `THESPIN_KEY` — your publisher key; set it to earn your revenue share

Used by:

- [`../codex`](../codex) — `codex mcp add thespin -- thespin-mcp`
- [`../gemini-cli`](../gemini-cli) — referenced from `gemini-extension.json`

## Publish

```bash
npm publish --access public
```
