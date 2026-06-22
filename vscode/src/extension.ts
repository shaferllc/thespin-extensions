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
    const res = await fetch(`${url}/api/serve`, {
      headers: key ? { "X-Dwell-Key": key } : {},
    });
    if (!res.ok) {
      throw new Error(`HTTP ${res.status}`);
    }
    const data = (await res.json()) as { ad?: Ad | null };
    const ad = data.ad;

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
  } catch (err) {
    // Stay quiet on the network; don't nag the user with errors.
    statusBarItem.text = "$(megaphone) thespin";
    statusBarItem.tooltip = `thespin.ad offline: ${String(err)}`;
  }
}
