#!/bin/sh
# Idempotent: install packages, link Claude config into ~/.claude, zsh stubs, rust, nvm + node.
set -eu
cd "$(dirname "$0")"
PATH="/opt/homebrew/bin:/opt/homebrew/opt/rustup/bin:$PATH"
command -v brew >/dev/null || { echo "Homebrew not found: install it from https://brew.sh, then re-run" >&2; exit 1; }

# one failed package (e.g. mas when signed out of the App Store) must not skip the rest
bundle_failed=
brew bundle --upgrade --file=Brewfile || bundle_failed=1

mkdir -p ~/.claude
for f in claude/*; do
  t=~/.claude/$(basename "$f")
  [ -e "$t" ] && [ ! -L "$t" ] && mv "$t" "$t.bak"
  ln -sfn "$PWD/$f" "$t"
done

# stubs hold machine-specific installer blocks: append, never overwrite
for s in zshrc zshenv; do
  t=~/.$s
  line="source ~/.config/zsh/$s"
  touch "$t"
  grep -qxF "$line" "$t" || echo "$line" >> "$t"
done

if command -v rustup >/dev/null; then rustup default stable; fi

# NVM_DIR must be set and exist: otherwise the installer picks $XDG_CONFIG_HOME/nvm, inside this repo
export NVM_DIR="$HOME/.nvm"
mkdir -p "$NVM_DIR"
if [ ! -s "$NVM_DIR/nvm.sh" ]; then
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.41.0/install.sh | PROFILE=/dev/null bash
fi
if [ -z "$(ls -A "$NVM_DIR/versions/node" 2>/dev/null)" ]; then
  # zshenv globs v$(<alias/default)*, so the alias must be a bare number, not lts/* or v24
  bash -c '. "$NVM_DIR/nvm.sh" && nvm install --lts && v=$(nvm current) && v=${v#v} && nvm alias default "${v%%.*}"'
fi

defaults write com.apple.finder AppleShowAllFiles -bool true
killall Finder || true

if [ -n "$bundle_failed" ]; then
  echo "brew bundle had failures (see above); fix them and re-run" >&2
  exit 1
fi
