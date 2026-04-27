---
name: installing-mdv
description: Install or reinstall the latest mdv from negipo/tap. Use when the user asks to install, reinstall, or update mdv (typically right after a release).
---

Always use the cask from `negipo/tap`. The plain `mdv` formula in homebrew/core is a different (Python) tool and must not be installed here.

```bash
brew update
brew reinstall --cask negipo/tap/mdv
```

If `brew reinstall` fails because mdv is not installed, fall back to:

```bash
brew install --cask negipo/tap/mdv
```

After installation, report the installed version:

```bash
brew list --cask --versions mdv | \cat
```
