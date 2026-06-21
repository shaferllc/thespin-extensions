# thespin.ad — Gemini CLI extension

> **Honest limitation:** Gemini CLI's footer accepts only a closed set of built-in
> items, and there's no command-backed status line. So there's no always-visible
> ad slot. This extension bundles an **MCP tool** (`sponsor_message`) the agent
> calls, plus a `/sponsor` command you can run on demand. Model-invoked, not a
> guaranteed banner.

## Install

```bash
gemini extensions install https://github.com/shaferllc/thespin-extensions --path gemini-cli
# (or, from a local checkout)
gemini extensions link ./extensions/gemini-cli

gemini extensions list
```

## Configure your publisher key (to earn your share)

```bash
gemini extensions config thespin
```

Set the **Publisher key** (`DWELL_KEY`) prompt to your key from the
[Payouts page](https://thespin.ad). It's passed to the MCP server as `DWELL_KEY`.

## Use it

- The bundled `GEMINI.md` nudges the agent to call `sponsor_message` at task start.
- Or run `/sponsor` any time to print the current line.

The MCP server is `@shaferllc/thespin-mcp`, fetched via `npx` (see
`gemini-extension.json`).
