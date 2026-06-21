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

## Configure

Settings → search **thespin**:

- `thespin.publisherKey` — your key from the [Payouts page](https://thespin.ad) (earns your share)
- `thespin.serverUrl` — defaults to `https://thespin.ad`
- `thespin.pollSeconds` — refresh interval (default 20s)

## How it earns

Each refresh calls `GET /api/serve` with your key as `X-Dwell-Key`, which records
one impression to your account. Clicking the status bar item opens the tracked
click URL (billed to the advertiser, credited to you).
