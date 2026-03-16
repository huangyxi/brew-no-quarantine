# brew-no-quarantine

A Homebrew wrapper that automatically removes the `com.apple.quarantine` attribute from applications installed or upgraded via Homebrew Cask, replacing the deprecated `--no-quarantine` feature.

## What it does

This script behaves exactly like the standard `brew` command for almost all operations. However, when you run `brew-no-quarantine install`, `reinstall`, or `upgrade` for MacOS Cask applications, the script intercepts the operation:
1. It calculates the exact absolute path to the `.app` bundle targets before Installation starts.
2. It executes the standard `brew` command.
3. If the applications were successfully downloaded, modified, or updated, the script automatically triggers `xattr -cr /path/to/App.app` to strip the quarantine attributes, bypassing the "App is damaged and can't be opened" or "Apple could not verify this app is free from malware" prompts on first launch.

## Installation

### Via Homebrew (Recommended)

```bash
brew install huangyxi/homebrew-tap/brew-no-quarantine
```

### Manual Installation

1. Place the [`bin/brew-no-quarantine`](bin/brew-no-quarantine) script somewhere in your `$PATH`.
2. Make it executable: `chmod +x brew-no-quarantine`.
3. Source the desired shell completion script for your environment (Bash, Zsh, Fish, or PowerShell) from the `completions/` folder.

## Usage

Run `brew-no-quarantine install <cask-name>`, `brew-no-quarantine upgrade`, etc. as you normally would with Homebrew!

If you really know what you're doing, you can also alias `brew` to `brew-no-quarantine`:
```bash
alias brew='brew-no-quarantine'
```

~~If you still can't figure this out, you might be the kind of user the Homebrew team is trying to protect. This script is probably not for you.~~

## Why does this exist?

In Q4 2025, the Homebrew team introduced [Pull Request #20929](https://github.com/Homebrew/brew/pull/20929), heavily restricting and eventually deprecating the widely-used `--no-quarantine` flag.

While the Homebrew maintainers argued this was to align with macOS security standards, many advanced users criticized this move as an overreach [^1]. The decision forces users to manually bypass Gatekeeper dialogs for every single application update, despite Apple deliberately providing built-in, native tools like `xattr` specifically designed for clearing quarantine attributes when a user explicitly chooses to trust software from their package manager.

As behavioral economics puts it, “losses loom larger than gains.” Removing a capability users already rely on is far more frustrating than introducing a new restriction.

Since the developers opted to enforce their own view of user security and Apple's notarization related income over convenience and user-choice, this repository was created. It restores control to power users by transparently handling quarantine removal via a seamless wrapper script, without manually removing the quarantine attribute after every installation or update.

[^1]: [brew#20755](https://github.com/Homebrew/brew/issues/20755). This issue was locked due to overwhelming amount of criticisms by the community.
