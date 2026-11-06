-- (Re)start the persistence watcher whenever the server loads this config.
-- A watcher from a previous server outlives it with a dead connection, so replace it every time.
local home = os.getenv("HOME")
local rex_bin = "/Users/kevinbourgeix/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS/rex"
rex.exec({ "pkill", "-f", "persist[.]lua" })
rex.exec({ "sh", "-c",
  "nohup sh -c 'until \"$0\" do --all \"$1\"; do sleep 2; done' \"" .. rex_bin .. "\" \"" .. home ..
  "/.config/rex/persist.lua\" >/dev/null 2>&1 &" })

-- herdr-style leader (ctrl+b): one-shot "leader" mode + floating which-key panel.
local function close_hint() end

-- { key, label, action, args }
local keys = {
  { "c", "new tab", "client.tab.new" },
  { "n", "next tab", "client.tab.next" },
  { "p", "prev tab", "client.tab.previous" },
  { "shift+x", "close tab", "client.tab.close" },
  { "shift+t", "rename tab", "client.tab.rename" },
  { "h", "focus left", "pane.focus.left" },
  { "j", "focus down", "pane.focus.down" },
  { "k", "focus up", "pane.focus.up" },
  { "l", "focus right", "pane.focus.right" },
  { "v", "split right", "pane.split.right" },
  { "-", "split down", "pane.split.down" },
  { "x", "close pane", "pane.close" },
  { "z", "zoom", "pane.zoom" },
  { "tab", "next pane", "pane.focus_next" },
  { "r", "resize mode", "client.mode.enter", { name = "resize" } },
  { "w", "switch session", "session.switch" },
  { "shift+n", "new session", "session.new" },
  { "shift+w", "rename session", "session.rename" },
  { "b", "sidebar", "client.sidebar.toggle" },
  { "s", "palette", "client.palette.toggle" },
  { "shift+r", "reload config", "client.config.reload" },
  { "ctrl+b", "send ctrl+b", "pane.send_key", { key = "ctrl+b" } },
  { "g", "lazygit", "leader_lazygit" },
  { "t", "worktrees", "leader_worktree" },
}
for i = 1, 9 do keys[#keys + 1] = { tostring(i), "tab " .. i, "client.tab.goto", { index = i } } end


local function wrap(name, label, action, args)
  rex.action{
    name = name, title = label,
    run = function()
      close_hint()
      rex.client.queue(action, args)
    end,
  }
end
for i, k in ipairs(keys) do
  if k[3] == "leader_lazygit" then
    rex.action{
      name = "leader_lazygit", title = "lazygit",
      run = function(ctx)
        close_hint()
        -- ask the focused pane (ctx.block_id) explicitly; the default target isn't reliably the focused one
        local ok, res = pcall(rex.block.call, "com.superlogical.terminal", "pwd", { block_id = ctx.block_id })
        -- pwd is an OSC 7 URL (file://host/path, percent-encoded), not a plain path
        local cwd = ok and res and res.pwd and res.pwd:match("^file://[^/]*(/.*)$") or os.getenv("HOME")
        cwd = cwd:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end)
        rex.session.new_layer{
          bounds = { 0.05, 0.05, 0.9, 0.9 }, focus = true,
          layout = rex.layout.block{
            flavor = "com.superlogical.terminal.shell",
            options = { command = { "/opt/homebrew/bin/lazygit" }, cwd = cwd, shell = "none" },
          },
        }
      end,
    }
    rex.bind("ctrl+b>g", "leader_lazygit")
  elseif k[3] == "leader_worktree" then
    rex.action{
      name = "leader_worktree", title = "worktrees",
      run = function(ctx)
        close_hint()
        local ok, res = pcall(rex.block.call, "com.superlogical.terminal", "pwd", { block_id = ctx.block_id })
        local cwd = ok and res and res.pwd and res.pwd:match("^file://[^/]*(/.*)$") or os.getenv("HOME")
        cwd = cwd:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end)
        rex.session.new_layer{
          bounds = { 0.2, 0.15, 0.6, 0.7 }, focus = true,
          layout = rex.layout.block{
            flavor = "com.superlogical.terminal.shell",
            options = { command = { "/bin/bash", home .. "/.config/rex/wt.sh" }, cwd = cwd, shell = "none" },
          },
        }
      end,
    }
    rex.bind("ctrl+b>t", "leader_worktree")
  else
    local n = "leader_k" .. i
    wrap(n, k[2], k[3], k[4])
    rex.bind("ctrl+b>" .. k[1], n)
  end
end

-- resize mode (entered via leader+r)
rex.mode("resize", { exclusive = true })
for key, dir in pairs{ left = "left", h = "left", right = "right", l = "right", up = "up", k = "up", down = "down", j = "down" } do
  rex.bind("resize/" .. key, "pane.resize", { direction = dir })
end

-- leader+? : black cheat-sheet panel, any key closes it
do
  local q, seen = {}, false
  for _, k in ipairs(keys) do
    if not k[1]:match("^%d$") or (k[1] == "1" and not seen) then
      if k[1] == "1" then seen = true end
      q[#q + 1] = "'" .. string.format("%-9s %s", k[1] == "1" and "1-9" or k[1], k[1] == "1" and "go to tab" or k[2]) .. "'"
    end
  end
  local cmd = "printf '%s\\n' " .. table.concat(q, " ") .. "; exec /bin/bash -c 'read -rsn1'"
  rex.action{
    name = "leader_help", title = "keys",
    run = function()
      rex.session.new_layer{
        bounds = { 0.62, 0.05, 0.36, 0.9 }, focus = true,
        layout = rex.layout.block{
          flavor = "com.superlogical.terminal.shell",
          options = { command = { "sh", "-c", cmd }, shell = "none" },
        },
      }
    end,
  }
  rex.bind("ctrl+b>shift+/", "leader_help")
  rex.bind("ctrl+b>shift+,", "leader_help")
end
