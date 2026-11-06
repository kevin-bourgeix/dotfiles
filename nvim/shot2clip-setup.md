# macOS: screenshots saved to a file AND copied to the clipboard

Goal: `Cmd+Shift+3/4/5` saves a PNG as usual, and the image is also on the clipboard so it can be pasted
(e.g. `Ctrl+V` in Claude Code). macOS cannot do both natively, so a LaunchAgent copies each new screenshot
to the clipboard.

## Why not something simpler

- `Cmd+Ctrl+Shift+4` sends to the clipboard only, no file.
- `defaults write com.apple.screencapture target clipboard` is ignored on recent macOS (27) because
  `target-screenshot` overrides it. Check with `defaults read com.apple.screencapture`.
- Do not use `~/Screenshots`: on macOS 27 the capture service silently falls back to the Desktop for a
  folder directly under `$HOME`. `~/Pictures/Screenshots` works. Also set `location-screenshot`, `location-last`
  and `location-screenrecording` to the same absolute path.
- Glob gotcha: `*.png(N[1])` is the first file by *name*, not the newest. Use `(N.om[1])`.
- Slow clipboard: the floating thumbnail delays writing the file by ~5s (disabled via `show-thumbnail`), and
  launchd throttles reruns to 10s by default (`ThrottleInterval` 1).
- Do not watch `~/Desktop`, `~/Documents` or `~/Downloads`. macOS privacy protection (TCC) blocks launchd
  agents from reading them, so the script runs, globs nothing and exits 0 silently.
  Use an unprotected folder.
- Do not match filenames like `Screenshot*.png`. The name is localised ("Capture d’écran …" in French).
  Match `*.png` in a folder dedicated to screenshots.

## Setup

Run these in order. Nothing needs sudo.

```bash
# 1. Save screenshots to an unprotected folder, as files
mkdir -p ~/Pictures/Screenshots ~/.local/bin ~/.local/share ~/Library/LaunchAgents
for k in location location-screenshot location-last location-screenrecording; do defaults write com.apple.screencapture $k ~/Pictures/Screenshots; done
defaults write com.apple.screencapture target-screenshot file
defaults write com.apple.screencapture show-thumbnail -bool false  # else the file is written ~5s late
killall SystemUIServer

# 2. Script: copy the newest PNG (once per file) to the clipboard
cat > ~/.local/bin/shot2clip.sh <<'EOF'
#!/bin/zsh
# copy the newest screenshot to the clipboard, once per file
exec >>~/.local/share/shot2clip.log 2>&1
echo "$(date '+%F %T') start load=$(sysctl -n vm.loadavg)"
f=(~/Pictures/Screenshots/*.png(N.om[1]))
# launchd fires on file creation: wait until the PNG size is stable (max ~2s)
for i in {1..20}; do a=$(stat -f %z "$f"); sleep 0.1; [[ $a -gt 0 && $a == $(stat -f %z "$f") ]] && break; done
last=~/.local/share/shot2clip.last
[[ -n $f && $f != "$(cat $last 2>/dev/null)" ]] || { echo "  skip f=$f"; exit 0 }
osascript -e "set the clipboard to (read (POSIX file \"$f\") as «class PNGf»)" && { print -r -- $f >$last; echo "  copied $f" } || echo "  osascript failed rc=$?"
EOF
chmod +x ~/.local/bin/shot2clip.sh

# 3. LaunchAgent: run the script whenever ~/Pictures/Screenshots changes
cat > ~/Library/LaunchAgents/local.shot2clip.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>Label</key><string>local.shot2clip</string>
<key>ProgramArguments</key><array><string>$HOME/.local/bin/shot2clip.sh</string></array>
<key>ThrottleInterval</key><integer>1</integer>
<key>WatchPaths</key><array><string>$HOME/Pictures/Screenshots</string></array>
</dict></plist>
EOF
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/local.shot2clip.plist
```

## Verify

Without taking a screenshot, simulate one:

```bash
cp /path/to/any.png ~/Pictures/Screenshots/test.png && touch ~/Pictures/Screenshots/test.png; sleep 5
osascript -e 'clipboard info' | cut -c1-30   # «class PNGf», <size of any.png>
rm ~/Pictures/Screenshots/test.png
```

Then take a real screenshot with `Cmd+Shift+4` and paste it. In Claude Code the paste key is `Ctrl+V`, not `Cmd+V`.
`launchctl list | grep shot2clip` should show a row.

## Debugging

- Clipboard does not change: read `~/.local/share/shot2clip.log` (the script logs every run). No `start` line =
  launchd never ran it (check `launchctl print gui/$(id -u)/local.shot2clip | grep runs`, and that screenshots
  really land in `~/Pictures/Screenshots` and not on the Desktop). `skip` = that file was already copied.
  `f=` empty = glob/TCC problem. Running the script by hand in Terminal works even when the agent fails,
  because Terminal has the permissions. Test through `launchctl kickstart -k gui/$(id -u)/local.shot2clip`.
- Reload after editing the plist:
  `launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/local.shot2clip.plist` then `bootstrap` again.
- If macOS blocks it: System Settings → General → Login Items & Extensions.

## Behaviour and limits

- Loads at login automatically. There is no `RunAtLoad`, so it only runs when `~/Pictures/Screenshots` changes.
- About 1s lag between the screenshot and the clipboard (right after boot the machine is busy and it can take longer).
- The log grows forever (a few lines per screenshot); delete it whenever.
- Each new `.png` is copied once (state in `~/.local/share/shot2clip.last`, log in `shot2clip.log`). No age limit, so a late launchd start after boot still works.

## Uninstall

```bash
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/local.shot2clip.plist
rm ~/Library/LaunchAgents/local.shot2clip.plist ~/.local/bin/shot2clip.sh
rm -f ~/.local/share/shot2clip.log ~/.local/share/shot2clip.last
for k in location location-screenshot location-last location-screenrecording show-thumbnail; do defaults delete com.apple.screencapture $k; done; killall SystemUIServer
```
