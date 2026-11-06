-- Persist Rex sessions/tabs/panes in SQLite and rebuild them after a server restart.
-- Run once, long-lived:  rex do --all ~/.config/rex/persist.lua
-- Saves structure only: layout, labels, cwd, and the Claude sessionId of agent panes
-- (restored with `claude --resume <id>`). Needs the sqlite3 CLI.
local HOME = os.getenv("HOME")
local DB = HOME .. "/Library/Application Support/rex/state.db"
local FLAVOR = "com.superlogical.terminal.shell"
local INTERVAL = 5 -- seconds between snapshots; ponytail: polling, not events (rex.on can't see layout changes)

local function sql(stmt)
  local r = rex.exec({ "sqlite3", DB }, { stdin = stmt })
  if not r or not r.ok then
    rex.log("error", "sqlite3: " .. tostring(r and r.stderr))
    return nil
  end
  return r.stdout
end

local function q(s) return "'" .. s:gsub("'", "''") .. "'" end

sql("CREATE TABLE IF NOT EXISTS sessions(label TEXT PRIMARY KEY, position INT, layout_json TEXT);")

local PENDING = {} -- block_id -> {id, t}: agents just resumed by restore, kept until claude is seen running

local function block_info(session_id, block_id)
  local p = rex.call("block.method", { session_id = session_id, block_id = block_id, method = "process" })
  local fg = p and p.foreground
  local info = { cwd = fg and fg.cwd or (p and p.ancestors and p.ancestors[1] and p.ancestors[1].cwd) }
  if fg and fg.argv0 == "claude" then
    local f = io.open(HOME .. "/.claude/sessions/" .. fg.pid .. ".json")
    if f then
      local meta = rex.json.decode(f:read("*a"))
      f:close()
      info.agent = meta and meta.sessionId
    end
  end
  if fg and fg.argv0 == "nvim" then info.prog = "nvim" end
  local pend = PENDING[block_id]
  if info.agent or info.prog then
    PENDING[block_id] = nil
  elseif pend and os.time() - pend.t < 90 then
    info.agent, info.prog = pend.agent, pend.prog
  end
  return info
end

-- view layout node -> serializable node (keeps the shape session.create accepts, plus cwd/agent)
local function convert(node, blocks, session_id)
  if node.split then
    local s = node.split
    return { split = { direction = s.direction, ratio = s.ratio,
      before = convert(s.before, blocks, session_id), after = convert(s.after, blocks, session_id) } }
  end
  local b = blocks[node.block_id]
  local info = block_info(session_id, node.block_id)
  return { block = { flavor = b.flavor, label = b.label, cwd = info.cwd, agent = info.agent, prog = info.prog } }
end

local function snapshot()
  local list = rex.call("session.list", {})
  if not list then return end
  local rows, seen = {}, {}
  for i, s in ipairs(list.sessions) do
    rex.call("session.attach", { session_id = s.session_id })
    local v = rex.call("session.view", { session_id = s.session_id })
    if v and not seen[v.label] then
      seen[v.label] = true
      local windows = {}
      for _, w in ipairs(v.windows) do
        for _, layer in ipairs(w.layers) do
          if layer.kind == "tiled" then -- floating layers are not restored
            local blocks = {}
            for _, b in ipairs(layer.blocks) do blocks[b.block_id] = b end
            windows[#windows + 1] = { window_label = w.label, layout = convert(layer.layout, blocks, s.session_id) }
          end
        end
      end
      rows[#rows + 1] = string.format("INSERT INTO sessions VALUES(%s,%d,%s);", q(v.label), i, q(rex.json.encode(windows)))
    end
  end
  local stmt = "BEGIN;DELETE FROM sessions;" .. table.concat(rows) .. "COMMIT;"
  if stmt ~= LAST then
    if sql(stmt) then LAST = stmt end
  end
end

-- saved node -> node for session.create (cwd/agent become start options)
local function revive(node, agents)
  if node.split then
    local s = node.split
    return { split = { direction = s.direction, ratio = s.ratio, before = revive(s.before, agents), after = revive(s.after, agents) } }
  end
  local b = node.block
  agents[#agents + 1] = (b.agent or b.prog) and { agent = b.agent, prog = b.prog } or false
  local opts = { cwd = b.cwd }
  -- run claude as the pane's program (typing into a starting zsh/p10k loses the input); fall back to a shell when it exits
  if b.agent then opts.command = { "sh", "-c", 'claude --resume "$1"; SESSION_STARTED=1 exec "${SHELL:-/bin/zsh}" -l', "sh", b.agent }
  elseif b.prog then opts.command = { "sh", "-c", '"$1"; SESSION_STARTED=1 exec "${SHELL:-/bin/zsh}" -l', "sh", b.prog } end
  return { block = { flavor = b.flavor or FLAVOR, label = b.label, options = opts } }
end

local function resume(session_id, block_id, saved)
  -- slow zsh startup (p10k/conda/nvm, worse with many shells booting at once) eats typed input:
  -- wait until zle is up (bracketed_paste is only enabled at the prompt), max 60s
  for _ = 1, 60 do
    local m = rex.call("block.method", { session_id = session_id, block_id = block_id, method = "modes" })
    local up = false
    for _, x in ipairs(m and m.modes or {}) do
      if x.name == "bracketed_paste" and x.set then up = true end
    end
    if up then break end
    rex.sleep(1)
  end
  rex.sleep(0.5)
  local cmd = saved.agent and ("claude --resume " .. saved.agent) or saved.prog
  rex.call("block.method", { session_id = session_id, block_id = block_id, method = "write", args = { data = cmd .. "\n" } })
  PENDING[block_id] = { agent = saved.agent, prog = saved.prog, t = os.time() }
end

local function leaves(node, out)
  if node.split then
    leaves(node.split.before, out); leaves(node.split.after, out)
  else
    out[#out + 1] = node
  end
  return out
end

local function restore()
  local out = sql("SELECT json_group_array(json_object('label',label,'windows',json(layout_json))) FROM (SELECT * FROM sessions ORDER BY position);")
  local saved = out and rex.json.decode(out) or {}
  local live = {}
  for _, s in ipairs(rex.call("session.list", {}).sessions) do live[s.label] = s.session_id end
  for _, s in ipairs(saved) do
    if not live[s.label] then
      local wins, agents = {}, {}
      for i, w in ipairs(s.windows) do
        agents[i] = {}
        wins[i] = { window_label = w.window_label, layout = revive(w.layout, agents[i]) }
      end
      local res, err = rex.call("session.create", { label = s.label, initial_windows = wins })
      if not res then
        rex.log("error", "restore " .. s.label .. ": " .. tostring(err))
      else
        for i, w in ipairs(res.initial_windows or {}) do
          for j, bid in ipairs(w.block_ids or {}) do
            if agents[i][j] then PENDING[bid] = { agent = agents[i][j].agent, prog = agents[i][j].prog, t = os.time() } end
          end
        end
      end
    else
      -- session the server restored itself (native persistence drops pane commands, so panes are bare shells):
      -- pair saved and live panes in layout order and re-run claude --resume / nvim in each idle shell
      local sid = live[s.label]
      rex.call("session.attach", { session_id = sid })
      local v = rex.call("session.view", { session_id = sid })
      local lw = {}
      for _, w in ipairs(v and v.windows or {}) do
        for _, layer in ipairs(w.layers) do
          if layer.kind == "tiled" then lw[#lw + 1] = layer.layout end
        end
      end
      for i, w in ipairs(s.windows) do
        if lw[i] then
          local sl, ll = leaves(w.layout, {}), leaves(lw[i], {})
          if #sl == #ll then -- same shape; otherwise leave the user's layout alone
            for k, n in ipairs(sl) do
              local b = n.block
              if b and (b.agent or b.prog) then
                local p = rex.call("block.method", { session_id = sid, block_id = ll[k].block_id, method = "process" })
                local a0 = p and p.foreground and p.foreground.argv0
                if a0 ~= "claude" and a0 ~= "nvim" then resume(sid, ll[k].block_id, b) end
              end
            end
          end
        end
      end
    end
  end
end

-- only rebuild right after a server start, never on a later config reload / watcher restart
local function server_age()
  local st = rex.call("server.status", {})
  local d = rex.exec({ "date", "-u", "-j", "-f", "%Y-%m-%dT%H:%M:%S", (st.started_at or ""):sub(1, 19), "+%s" })
  return d and d.ok and os.time() - tonumber(d.stdout) or math.huge
end

if server_age() < 120 then restore() end
snapshot()
rex.every(INTERVAL, snapshot)
