# thespin.ad — VS Code & Cursor extension

Shows one sponsored line in the status bar while you work. Click it to open the
sponsor. Set your **publisher key** to keep 50% of the revenue for every line you
show.

## Install

```bash
# build the .vsix
npm install
npm run package
npx @vscode/vsce package      # → thespin-1.0.0.vsix

# install it
code   --install-extension thespin-1.0.0.vsix   # VS Code
cursor --install-extension thespin-1.0.0.vsix   # Cursor
```

Or: Command Palette → **Extensions: Install from VSIX…**

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

Each refresh calls `GET /api/serve` with your key as `X-Dwell-Key`, which records
one impression to your account. Clicking the status bar item opens the tracked
click URL (billed to the advertiser, credited to you).
