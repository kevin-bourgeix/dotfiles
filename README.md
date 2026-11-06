# ~/.config

Personal config: zsh, nvim, rex, zed, ponytail.

## New machine

```sh
git clone <repo-url> ~/.config
brew bundle --file=~/.config/Brewfile

# zsh: ~/.zshrc is a one-line stub that sources the repo version
echo 'source ~/.config/zsh/zshrc'    > ~/.zshrc
```

Tool installers (conda, nvm, bun, sdkman…) append their init blocks to `~/.zshrc`.
That is the stub, not the repo, on purpose: machine-specific stuff stays out of git.

## Contents

- `zsh/` shell config (Ctrl-R = fzf history, `cd` = zoxide)
- `nvim/` see `nvim/README.md`
- `rex/`, `zed/`, `ponytail/` app configs
- `Brewfile` packages the configs above need; extend with `brew bundle dump --no-vscode`
