# ~/.config

Personal config: zsh, nvim, rex, zed, ponytail.

## New machine

```sh
git clone <repo-url> ~/.config
brew bundle --upgrade --file=~/.config/Brewfile
rustup default stable   # rust toolchain (rustup is keg-only)

# zsh: ~/.zshrc is a one-line stub that sources the repo version
echo 'source ~/.config/zsh/zshrc'    > ~/.zshrc
echo 'source ~/.config/zsh/zshenv'    > ~/.zshenv
```

Rex font is an app setting, not in the repo: pick "GeistMono Nerd Font" in Rex's terminal font picker.

Tool installers (conda, nvm, bun, sdkman…) append their init blocks to `~/.zshrc`.
That is the stub, not the repo, on purpose: machine-specific stuff stays out of git.

## Contents

- `starship.toml` prompt
- `zsh/` shell config (zshenv = env vars, zshrc = interactive; Ctrl-R = fzf history, `cd` = zoxide)
- `nvim/` see `nvim/README.md`
- `rex/`, `zed/`, `ponytail/` app configs
- `Brewfile` packages the configs above need; extend with `brew bundle dump --no-vscode`
