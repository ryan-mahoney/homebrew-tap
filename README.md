# Homebrew tap

## AI capacity dashboard

Requires [Homebrew](https://brew.sh), an Apple Silicon Mac, and macOS 14 or later.

```bash
brew install ryan-mahoney/tap/ai-capacity
ai-capacity
```

The command opens the dashboard in your browser. Keep the terminal open. Press Ctrl+C to stop the server.
Homebrew installs Python and the prebuilt report executable. No source build or executable path is required.
Provider sign-ins and macOS Keychain permissions still apply.

For another port, run `ai-capacity --port 8789`. Use `--no-open` to leave the browser closed.

## Update

```bash
brew update
brew upgrade ai-capacity
```

After the update, stop and restart the dashboard.

## Checks

```bash
brew test ryan-mahoney/tap/ai-capacity
```

The test uses synthetic data. It does not read account credentials or contact providers.

The [source repository](https://github.com/ryan-mahoney/CodexBar) contains the dashboard, report command, and release instructions.
