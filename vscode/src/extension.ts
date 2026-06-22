import * as vscode from "vscode";

interface Ad {
  line?: string;
  brand?: string;
  price_per_1k?: string;
  click_url?: string;
  premium?: boolean;
}

let statusBarItem: vscode.StatusBarItem;
let timer: NodeJS.Timeout | undefined;
let currentClickUrl: string | undefined;
let currentAd: Ad | undefined;
let cardPanel: vscode.WebviewPanel | undefined;
// Rotating attestation token echoed on the next serve to prove a real session.
let lastAttest: string | undefined;

function config() {
  const c = vscode.workspace.getConfiguration("thespin");
  return {
    url: (c.get<string>("serverUrl") || "https://thespin.ad").replace(/\/+$/, ""),
    key: c.get<string>("publisherKey") || "",
    pollMs: Math.max(10, c.get<number>("pollSeconds") || 20) * 1000,
  };
}

export function activate(context: vscode.ExtensionContext): void {
  // Clicking the item opens the current sponsor (a tracked click) or the site.
  const clickCommand = vscode.commands.registerCommand("thespin.click", () => {
    const target = currentClickUrl || config().url;
    void vscode.env.openExternal(vscode.Uri.parse(target));
  });
  context.subscriptions.push(clickCommand);

  // Walkthrough "Add your publisher key" step jumps straight to the setting.
  const setupKeyCommand = vscode.commands.registerCommand("thespin.setupKey", () => {
    void vscode.commands.executeCommand("workbench.action.openSettings", "thespin.publisherKey");
  });
  context.subscriptions.push(setupKeyCommand);

  // A richer "sponsor card" webview — brand, line, price, premium badge, and a
  // tracked open button. More than the status-bar tooltip can show.
  const cardCommand = vscode.commands.registerCommand("thespin.openCard", () => {
    if (cardPanel) {
      cardPanel.reveal(vscode.ViewColumn.Active);
    } else {
      cardPanel = vscode.window.createWebviewPanel(
        "thespin.card",
        "thespin.ad — sponsor",
        vscode.ViewColumn.Active,
        { enableScripts: true, retainContextWhenHidden: true },
      );
      cardPanel.onDidDispose(() => (cardPanel = undefined), null, context.subscriptions);
      // The card's button asks us to open the sponsor (a tracked click).
      cardPanel.webview.onDidReceiveMessage(
        (msg: { type?: string }) => {
          if (msg?.type === "open") {
            void vscode.env.openExternal(vscode.Uri.parse(currentClickUrl || config().url));
          }
        },
        null,
        context.subscriptions,
      );
    }
    renderCard();
  });
  context.subscriptions.push(cardCommand);

  statusBarItem = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Right, 100);
  statusBarItem.command = "thespin.click";
  statusBarItem.text = "$(megaphone) thespin";
  statusBarItem.tooltip = "thespin.ad — fetching the sponsored line…";
  statusBarItem.show();
  context.subscriptions.push(statusBarItem);

  void refresh();
  schedule();

  // Re-schedule if the poll interval changes.
  context.subscriptions.push(
    vscode.workspace.onDidChangeConfiguration((e) => {
      if (e.affectsConfiguration("thespin")) {
        schedule();
        void refresh();
      }
    }),
  );
}

export function deactivate(): void {
  if (timer) {
    clearInterval(timer);
    timer = undefined;
  }
}

function schedule(): void {
  if (timer) {
    clearInterval(timer);
  }
  timer = setInterval(() => void refresh(), config().pollMs);
}

async function refresh(): Promise<void> {
  const { url, key } = config();
  try {
    // global fetch is available in the VS Code / Cursor Node runtime (Node 18+).
    const headers: Record<string, string> = {};
    if (key) headers["X-Thespin-Key"] = key;
    if (lastAttest) headers["X-Thespin-Attest"] = lastAttest;
    const res = await fetch(`${url}/api/serve`, { headers });
    if (!res.ok) {
      throw new Error(`HTTP ${res.status}`);
    }
    const data = (await res.json()) as { ad?: Ad | null; attest?: string | null };
    lastAttest = data.attest ?? undefined; // echo it next time
    const ad = data.ad;
    currentAd = ad ?? undefined;

    if (ad?.line) {
      currentClickUrl = ad.click_url;
      // The top live bid gets a ★ and a highlighted background so the premium
      // slot reads as premium; everyone else stays quiet chrome.
      statusBarItem.text = `$(megaphone) ${ad.premium ? "$(star-full) " : ""}${ad.line}`;
      statusBarItem.backgroundColor = ad.premium
        ? new vscode.ThemeColor("statusBarItem.warningBackground")
        : undefined;
      statusBarItem.tooltip = new vscode.MarkdownString(
        `**${ad.brand ?? "Sponsored"}**${ad.premium ? " · top bid ★" : ""} · ${ad.price_per_1k ?? ""}/1k\n\n` +
          `_thespin.ad — click to open. ${key ? "Earning your share." : "Set your publisher key to earn."}_`,
      );
    } else {
      currentClickUrl = url;
      statusBarItem.text = "$(megaphone) thespin · unclaimed";
      statusBarItem.tooltip = "Spinner unclaimed — bid at thespin.ad";
      statusBarItem.backgroundColor = undefined;
    }
    // Keep an open card in sync with the freshly fetched line.
    renderCard();
  } catch (err) {
    // Stay quiet on the network; don't nag the user with errors.
    statusBarItem.text = "$(megaphone) thespin";
    statusBarItem.tooltip = `thespin.ad offline: ${String(err)}`;
  }
}

/** Escape a string for safe interpolation into the card's HTML. */
function esc(value: string | undefined): string {
  return (value ?? "").replace(
    /[&<>"']/g,
    (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]!,
  );
}

/** (Re)render the sponsor card webview from the current ad, if it's open. */
function renderCard(): void {
  if (!cardPanel) {
    return;
  }
  const { key } = config();
  const ad = currentAd;
  const nonce = String(Date.now());
  const csp =
    `default-src 'none'; style-src 'unsafe-inline'; ` +
    `script-src 'nonce-${nonce}';`;

  const body = ad?.line
    ? `
      ${ad.premium ? `<div class="badge">★ Top bid</div>` : ``}
      <div class="line">${esc(ad.line)}</div>
      <div class="brand">${esc(ad.brand ?? "Sponsored")}</div>
      <div class="price">${esc(ad.price_per_1k ?? "")}/1k</div>
      <button id="open">Open sponsor →</button>
      <p class="foot">${
        key
          ? "thespin.ad — opening counts as a tracked click. Earning your share."
          : "thespin.ad — set your publisher key in settings to earn your share."
      }</p>`
    : `
      <div class="line">Spinner unclaimed</div>
      <p class="foot">No live bid right now. <button id="open">Bid at thespin.ad →</button></p>`;

  cardPanel.webview.html = `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta http-equiv="Content-Security-Policy" content="${csp}" />
  <style>
    body { font-family: var(--vscode-font-family); color: var(--vscode-foreground);
           padding: 24px; text-align: center; }
    .badge { display: inline-block; margin-bottom: 12px; padding: 2px 10px; border-radius: 999px;
             font-size: 12px; font-weight: 600;
             background: var(--vscode-statusBarItem-warningBackground);
             color: var(--vscode-statusBarItem-warningForeground); }
    .line { font-size: 20px; font-weight: 600; margin: 8px 0; }
    .brand { opacity: 0.85; }
    .price { opacity: 0.7; font-size: 13px; margin: 4px 0 18px; }
    button { font: inherit; cursor: pointer; padding: 8px 16px; border: none; border-radius: 4px;
             background: var(--vscode-button-background); color: var(--vscode-button-foreground); }
    button:hover { background: var(--vscode-button-hoverBackground); }
    .foot { margin-top: 18px; font-size: 12px; opacity: 0.6; }
  </style>
</head>
<body>
  ${body}
  <script nonce="${nonce}">
    const vscode = acquireVsCodeApi();
    const btn = document.getElementById("open");
    if (btn) { btn.addEventListener("click", () => vscode.postMessage({ type: "open" })); }
  </script>
</body>
</html>`;
}
