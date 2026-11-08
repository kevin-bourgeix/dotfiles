# ~/.config

Personal config: zsh, nvim, rex, zed, ponytail, claude.

## New machine

Prerequisites: [Homebrew](https://brew.sh) and `xcode-select --install`.

```sh
git clone <repo-url> ~/.config
~/.config/install.sh    # run in your own terminal: casks may prompt for a password
```

`install.sh` is idempotent. It runs brew bundle, links `claude/*` into `~/.claude`, adds the zsh stubs,
sets the rust toolchain, installs nvm + LTS node, and shows hidden files in Finder.
If a package fails it still does the rest, then exits 1.

Then, by hand:

1. Open a new shell.
2. Set a git identity: `git config --global user.name` and `user.email`.
3. Check GitHub access: `ssh -T git@github.com`.
4. Sign in to the App Store, then re-run `install.sh` if RunCat Neo failed.
5. Run `nvim`: plugins clone and Mason installs servers. Restart it when done.
6. Run `claude` and trust the marketplaces.
7. Grant the app permissions below, and open the other menu bar apps and Logi Options+ once.

Optional, not done by `install.sh`:

- Rex: no Homebrew cask, install it separately. `rex/` is ready for it.
- Screenshots saved to a file and copied to the clipboard: `nvim/shot2clip-setup.md`.

Claude Code: `install.sh` symlinks `claude/` (settings, CLAUDE.md, RTK.md, statusline) into `~/.claude`;
an existing real file there is moved to `*.bak`. Plugins (ponytail, superpowers) are declared in
`claude/settings.json`, so the first `claude` launch asks you to trust the marketplaces, then installs them.
Ponytail's mode is `ponytail/config.json`. Not tracked: plugins, skills (symlinks to local repos), history.

Rex font is an app setting, not in the repo: pick "GeistMono Nerd Font" in Rex's terminal font picker.

DockDoor: grant Accessibility + Screen Recording once in System Settings → Privacy & Security; its settings are app prefs, not in the repo.
Loop: grant Accessibility once, same place; prefs also untracked.

`~/.zshrc` and `~/.zshenv` are stubs that source the repo versions. Tool installers (conda, bun, sdkman…)
append their init blocks to `~/.zshrc`. That is the stub, not the repo, on purpose: machine-specific stuff
stays out of git. nvm is the exception: `install.sh` keeps it out of the stub because `zshrc` lazy-loads it.

## Contents

- `starship.toml` prompt
- `zsh/` shell config (zshenv = env vars, zshrc = interactive; Ctrl-R = fzf history, `cd` = zoxide)
- `nvim/` see `nvim/README.md`
- `rex/`, `zed/`, `ponytail/` app configs
- `claude/` Claude Code config, linked into `~/.claude` by `install.sh`
- `install.sh` new-machine bootstrap
- `Brewfile` packages the configs above need; extend with `brew bundle dump --no-vscode`
