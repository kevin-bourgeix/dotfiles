#!/bin/bash
# Worktree picker for rex (ctrl+b t). Runs in the focused pane's cwd.
# enter: open session | ctrl-d: remove worktree + session | "+ new": create from branch name
export PATH="/opt/homebrew/bin:$PATH"  # layer runs with shell=none, so no login PATH
REX="/Users/kevinbourgeix/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS/rex"
ROOT="$HOME/Repos/worktrees"
common=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || { echo "not in a git repo"; read -rsn1; exit 1; }
main=$(dirname "$common")
repo=$(basename "$main")

list() { git -C "$main" worktree list --porcelain | awk '/^worktree /{p=$2} /^branch /{sub("refs/heads/","",$2); print $2 "\t" p}'; }
label() { echo "$repo:$1"; }

sel=$( { echo "+ new"; list; } | fzf --prompt="$repo worktree> " --header="enter open | ctrl-d remove" \
  --expect=ctrl-d --delimiter=$'\t' --with-nth=1 ) || exit 0
key=$(sed -n 1p <<<"$sel"); line=$(sed -n 2p <<<"$sel")
[ -z "$line" ] && exit 0

if [ "$line" = "+ new" ]; then
  read -rp "branch: " br; [ -z "$br" ] && exit 0
  path="$ROOT/$repo-${br//\//-}"
  mkdir -p "$ROOT"
  git -C "$main" worktree add "$path" -b "$br" 2>/dev/null || git -C "$main" worktree add "$path" "$br" || { read -rsn1; exit 1; }
  "$REX" new "$(label "$br")" -c "$path"
else
  br=${line%%$'\t'*}; path=${line#*$'\t'}
  if [ "$key" = ctrl-d ]; then
    [ "$path" = "$main" ] && { echo "refusing to remove main worktree"; read -rsn1; exit 1; }
    "$REX" session kill "$(label "$br")" 2>/dev/null
    git -C "$main" worktree remove "$path" || { read -rsn1; exit 1; }
  else
    "$REX" new "$(label "$br")" -c "$path"
  fi
fi
