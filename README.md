# ~/.config

Personal config: zsh, nvim, rex, zed, ponytail, claude.

## New machine

```sh
git clone <repo-url> ~/.config
~/.config/install.sh    # brew bundle + links claude/* into ~/.claude (idempotent)
rustup default stable   # rust toolchain (rustup is keg-only)

# zsh: ~/.zshrc is a one-line stub that sources the repo version
echo 'source ~/.config/zsh/zshrc'    > ~/.zshrc
echo 'source ~/.config/zsh/zshenv'    > ~/.zshenv
```

Claude Code: `install.sh` symlinks `claude/` (settings, CLAUDE.md, RTK.md, statusline) into `~/.claude`;
an existing real file there is moved to `*.bak`. Plugins (ponytail, superpowers) are declared in
`claude/settings.json`, so the first `claude` launch asks you to trust the marketplaces, then installs them.
Ponytail's mode is `ponytail/config.json`. Not tracked: plugins, skills (symlinks to local repos), history.

Rex font is an app setting, not in the repo: pick "GeistMono Nerd Font" in Rex's terminal font picker.

DockDoor: grant Accessibility + Screen Recording once in System Settings → Privacy & Security; its settings are app prefs, not in the repo.
Loop: grant Accessibility once, same place; prefs also untracked.

Tool installers (conda, nvm, bun, sdkman…) append their init blocks to `~/.zshrc`.
That is the stub, not the repo, on purpose: machine-specific stuff stays out of git.

## Contents

- `starship.toml` prompt
- `zsh/` shell config (zshenv = env vars, zshrc = interactive; Ctrl-R = fzf history, `cd` = zoxide)
- `nvim/` see `nvim/README.md`
- `rex/`, `zed/`, `ponytail/` app configs
- `claude/` Claude Code config, linked into `~/.claude` by `install.sh`
- `install.sh` new-machine bootstrap
- `Brewfile` packages the configs above need; extend with `brew bundle dump --no-vscode`
