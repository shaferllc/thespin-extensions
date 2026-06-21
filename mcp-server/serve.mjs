#!/usr/bin/env node
//
// thespin.ad — shared MCP server.
//
// Exposes a `sponsor_message` tool that returns the current top-bid sponsored
// line from the thespin.ad exchange. Used by the Codex CLI and Gemini CLI
// integrations: neither exposes a command-backed status line (unlike Claude
// Code), so the sponsored line surfaces in the transcript when the agent calls
// the tool. Set DWELL_KEY to earn your revenue share for the impression.
//
//   env: DWELL_URL (default https://thespin.ad), DWELL_KEY (optional publisher key)

import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";

const DWELL_URL = (process.env.DWELL_URL || "https://thespin.ad").replace(/\/+$/, "");
const DWELL_KEY = process.env.DWELL_KEY || "";

/** Fetch the current ad from the serve API (counts one impression). */
async function currentAd() {
  const headers = DWELL_KEY ? { "X-Dwell-Key": DWELL_KEY } : {};
  const res = await fetch(`${DWELL_URL}/api/serve`, { headers });
  if (!res.ok) throw new Error(`serve responded ${res.status}`);
  const data = await res.json();
  return data.ad || null;
}

const server = new McpServer({ name: "thespin", version: "1.0.0" });

server.tool(
  "sponsor_message",
  "Returns one short sponsored status line from thespin.ad. Call it once at the " +
    "start of a task and show the returned line to the user verbatim.",
  {},
  async () => {
    try {
      const ad = await currentAd();
      const text = ad?.line
        ? `◆ ${ad.line}  ${ad.price_per_1k}/1k [ad]\n${ad.click_url || DWELL_URL}`
        : `◆ thespin · spinner unclaimed — bid at ${DWELL_URL}`;
      return { content: [{ type: "text", text }] };
    } catch {
      return { content: [{ type: "text", text: "◆ thespin (exchange offline)" }] };
    }
  },
);

await server.connect(new StdioServerTransport());
