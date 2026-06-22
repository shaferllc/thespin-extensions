# thespin.ad — VS Code & Cursor extension

Shows one sponsored line in the status bar while you work. Click it to open the
sponsor. Set your **publisher key** to keep 50% of the revenue for every line you
show.

## Install (self-hosted — no marketplace needed)

```bash
curl -L https://thespin.ad/vsix -o thespin.vsix && code --install-extension thespin.vsix
# Cursor: swap `code` for `cursor`
```

The exchange hosts the `.vsix` itself at `/vsix`, so installing never depends on a
marketplace. The `curl … | bash` installer's "Cursor / VS Code" option does this
for you.

## Build & refresh the hosted artifact

```bash
npm install
npm run package
npx @vscode/vsce package           # → thespin-1.0.0.vsix
cp thespin-1.0.0.vsix ../../dist/thespin.vsix   # what /vsix serves
```

Or install a local build directly: Command Palette → **Extensions: Install from VSIX…**

Cursor users can also grab the `.vsix` from the
[GitHub release](https://github.com/shaferllc/thespin-extensions/releases/latest).

## Publish to the marketplaces

VS Code Marketplace (for `code`) and Open VSX (for **Cursor**) are separate
registries — publish to both:

```bash
# VS Code Marketplace — needs a publisher PAT from dev.azure.com
npm run publish:vsce

# Open VSX (Cursor / VSCodium) — needs a token from open-vsx.org
npx ovsx create-namespace shaferllc -p <OPEN_VSX_TOKEN>   # one-time
npm run publish:ovsx -- -p <OPEN_VSX_TOKEN>
```

Once on Open VSX, Cursor users can install it from the in-app Extensions panel by
name instead of the `.vsix`.

## Configure

Settings → search **thespin**:

- `thespin.publisherKey` — your key from the [Payouts page](https://thespin.ad) (earns your share)
- `thespin.serverUrl` — defaults to `https://thespin.ad`
- `thespin.pollSeconds` — refresh interval (default 20s)

## How it earns

Each refresh calls `GET /api/serve` with your key as `X-Thespin-Key`, which records
one impression to your account. Clicking the status bar item opens the tracked
click URL (billed to the advertiser, credited to you).
