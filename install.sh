#!/bin/sh
# Idempotent: install packages, link Claude config into ~/.claude.
set -eu
cd "$(dirname "$0")"
brew bundle --upgrade --file=Brewfile
mkdir -p ~/.claude
for f in claude/*; do
  t=~/.claude/$(basename "$f")
  [ -e "$t" ] && [ ! -L "$t" ] && mv "$t" "$t.bak"
  ln -sfn "$PWD/$f" "$t"
done
