local function gh(repo) return "https://github.com/" .. repo end

-- Build steps, must be registered before vim.pack.add
vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if kind ~= "install" and kind ~= "update" then return end
    if name == "telescope-fzf-native.nvim" then
      vim.system({ "make" }, { cwd = ev.data.path }):wait()
    elseif name == "nvim-treesitter" then
      if not ev.data.active then vim.cmd.packadd("nvim-treesitter") end
      pcall(vim.cmd, "TSUpdate")
    end
  end,
})

vim.g.nvim_surround_no_visual_mappings = true -- visual `S` is Flash; bound to `gs` in keymaps.lua

vim.pack.add({
  gh("rezniqov/soviet.nvim"),
  gh("nvim-lua/plenary.nvim"),
  gh("nvim-tree/nvim-web-devicons"),
  gh("cbochs/grapple.nvim"),
  gh("MunifTanjim/nui.nvim"),
  gh("folke/which-key.nvim"),
  gh("folke/flash.nvim"),
  gh("lewis6991/gitsigns.nvim"),
  gh("nvim-telescope/telescope.nvim"),
  gh("nvim-telescope/telescope-fzf-native.nvim"),
  { src = gh("nvim-neo-tree/neo-tree.nvim"), version = "v3.x" },
  { src = gh("nvim-treesitter/nvim-treesitter"), version = "main" },
  gh("MeanderingProgrammer/render-markdown.nvim"),
  gh("neovim/nvim-lspconfig"),
  gh("mason-org/mason.nvim"),
  gh("mason-org/mason-lspconfig.nvim"),
  gh("WhoIsSethDaniel/mason-tool-installer.nvim"),
  gh("b0o/SchemaStore.nvim"),
  gh("ms-jpq/coq_nvim"),
  gh("windwp/nvim-autopairs"),
  gh("HiPhish/rainbow-delimiters.nvim"),
  gh("stevearc/conform.nvim"),
  gh("stevearc/overseer.nvim"),
  gh("Wansmer/treesj"),
  gh("gbprod/substitute.nvim"),
  gh("kylechui/nvim-surround"),
  gh("glepnir/galaxyline.nvim"),
  gh("pwntester/octo.nvim"),
  gh("folke/trouble.nvim"),
  gh("folke/todo-comments.nvim"),
  gh("brenoprata10/nvim-highlight-colors"),
  gh("b0o/incline.nvim"),
  gh("rachartier/tiny-cmdline.nvim"),
  gh("esmuellert/codediff.nvim"),
}, { confirm = false })

require("soviet").setup({})
vim.cmd.colorscheme("soviet-dark")

require("which-key").setup({ preset = "helix" })
require("flash").setup()
require("gitsigns").setup()
require("grapple").setup({})

-- Sign on the line each Grapple tag was saved at (tag cursor is fixed at tag time)
local grapple_ns = vim.api.nvim_create_namespace("grapple_signs")
local function grapple_signs(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(buf, grapple_ns, 0, -1)
  local path = vim.api.nvim_buf_get_name(buf)
  local tags = require("grapple").tags() or {}
  for i, tag in ipairs(tags) do
    local row = tag.cursor and tag.cursor[1]
    if tag.path == path and row and row <= vim.api.nvim_buf_line_count(buf) then
      vim.api.nvim_buf_set_extmark(buf, grapple_ns, row - 1, 0, { sign_text = "󰃀" .. i, sign_hl_group = "DiagnosticInfo" })
    end
  end
end
vim.api.nvim_create_autocmd({ "BufEnter", "User" }, {
  pattern = { "*", "GrappleUpdate" },
  callback = function() pcall(grapple_signs) end,
})
require("render-markdown").setup()

-- Telescope
local telescope = require("telescope")
telescope.setup({ defaults = { file_ignore_patterns = { "^%.git/" } } })
pcall(telescope.load_extension, "fzf") -- silent until `make` has run

local function lead(key, desc, extra)
  return vim.tbl_extend("force", { lhs = "<leader>go" .. key, desc = desc }, extra or {})
end
local review_keys = {
  submit_review = lead("S", "submit review"),
  discard_review = lead("d", "discard review"),
  focus_files = lead("e", "focus changed files"),
  toggle_files = lead("b", "toggle changed files"),
  toggle_viewed = lead("v", "toggle viewed"),
}
require("octo").setup({
  picker = "telescope",
  use_local_fs = true, -- right side of review diffs is the local file, so LSP works (checkout the PR first)
  mappings = {
    pull_request = { add_comment = lead("c", "add comment"), resolve_thread = lead("r", "resolve thread"), unresolve_thread = lead("T", "unresolve thread") },
    review_thread = { add_comment = lead("c", "add comment"), resolve_thread = lead("r", "resolve thread"), unresolve_thread = lead("T", "unresolve thread") },
    review_diff = vim.tbl_extend("force", review_keys, {
      add_review_comment = lead("c", "review comment", { mode = { "n", "x" } }),
      add_review_suggestion = lead("g", "review suggestion", { mode = { "n", "x" } }),
    }),
    file_panel = review_keys,
  },
}) -- needs `gh auth login`
-- Loading indicator: count in-flight `gh` jobs started by Octo and show a spinner in the statusline
local gh_jobs, spinner_timer = {}, nil
local spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
local function gh_busy()
  local now = vim.uv.now()
  for j, t in pairs(gh_jobs) do
    if now - t > 60000 then gh_jobs[j] = nil end -- drop jobs whose on_exit never fired
  end
  return next(gh_jobs) ~= nil
end
local function gh_job_done(job)
  gh_jobs[job] = nil
  vim.schedule(function() vim.cmd.redrawstatus() end)
end
local function gh_job_start(job)
  gh_jobs[job] = vim.uv.now()
  if spinner_timer then return end
  spinner_timer = vim.uv.new_timer()
  spinner_timer:start(0, 100, vim.schedule_wrap(function()
    if gh_busy() then
      vim.cmd.redrawstatus()
    elseif spinner_timer then
      spinner_timer:stop()
      spinner_timer:close()
      spinner_timer = nil
      vim.cmd.redrawstatus()
    end
  end))
end
local PlenaryJob = require("plenary.job")
local job_new = PlenaryJob.new
PlenaryJob.new = function(self, o)
  if type(o) == "table" and o.command == require("octo.config").values.gh_cmd then
    local on_exit = o.on_exit
    local job
    o.on_exit = function(...)
      gh_job_done(job)
      if on_exit then return on_exit(...) end
    end
    job = job_new(self, o)
    gh_job_start(job)
    return job
  end
  return job_new(self, o)
end
local function octo_loading()
  if not gh_busy() then return "" end
  return spinner[math.floor(vim.uv.hrtime() / 1e8) % #spinner + 1] .. " GitHub"
end

-- Marking a file as viewed jumps to the next file (diff windows act on the current file, the panel on the cursor's)
require("octo.mappings").toggle_viewed = function()
  local layout = require("octo.reviews").get_current_layout()
  if not layout then return end
  local in_panel = vim.api.nvim_get_current_win() == layout.file_panel.winid
  local file = in_panel and layout.file_panel:get_file_at_cursor() or layout:get_current_file()
  if not file then return end
  local was_viewed = file.viewed_state == "VIEWED"
  file:toggle_viewed()
  if was_viewed then return end
  local tries, timer = 0, vim.uv.new_timer()
  timer:start(100, 100, vim.schedule_wrap(function()
    tries = tries + 1
    local done = file.viewed_state == "VIEWED"
    if not (done or tries > 50) then return end
    timer:stop()
    timer:close()
    if not done then return end
    for i, f in ipairs(layout.files) do
      if f == file then
        layout:set_current_file(layout.files[i % #layout.files + 1])
        break
      end
    end
  end))
end

-- Explorer
local neo_file = vim.deepcopy(require("neo-tree.defaults").renderers.file)
for _, c in ipairs(neo_file) do
  if c[1] == "container" then
    c.content = vim.tbl_filter(function(x) return x[1] ~= "git_status" end, c.content)
    for i, x in ipairs(c.content) do
      if x[1] == "name" then table.insert(c.content, i + 1, { "git_status", zindex = 10, align = "left" }) break end
    end
    table.insert(c.content, { "grapple", zindex = 10, align = "right" })
  end
end
require("neo-tree").setup({
  window = {
    mappings = {
      -- Enter: new tab, except on a fresh start (only the empty startup buffer exists) where it reuses the window
      ["<cr>"] = function(state)
        local cmds = require("neo-tree.sources.common.commands")
        local fresh = vim.iter(vim.fn.getbufinfo({ buflisted = 1 })):all(function(b) return b.name == "" and b.changed == 0 end)
        return (fresh and cmds.open or cmds.open_tabnew)(state)
      end,
      ["o"] = "open", -- current window
    },
  },
  default_component_configs = {
    git_status = {
      symbols = {
        modified = "", unstaged = "", staged = "", added = "", untracked = "",
        deleted = "", renamed = "", conflict = "", ignored = "",
      },
    },
  },
  filesystem = {
    hijack_netrw_behavior = "open_current", -- `nvim <dir>`: explorer fills the window instead of a sidebar
    filtered_items = { visible = true },
    follow_current_file = { enabled = true },
    use_libuv_file_watcher = true, -- pick up git changes made outside nvim
    components = {
      grapple = function(_, node)
        for i, tag in ipairs(require("grapple").tags() or {}) do
          if tag.path == node.path then return { text = "󰃀" .. i .. " ", highlight = "DiagnosticInfo" } end
        end
        return {}
      end,
    },
    renderers = { file = neo_file },
  },
})
vim.api.nvim_create_autocmd("User", {
  pattern = "GrappleUpdate",
  callback = function() pcall(require("neo-tree.events").fire_event, "git_event") end,
})
vim.api.nvim_create_autocmd({ "FocusGained", "ShellCmdPost" }, {
  callback = function() pcall(require("neo-tree.events").fire_event, "git_event") end,
})

-- Treesitter (main branch: parsers installed by us, highlighting is built-in)
local parsers = {
  "lua", "vim", "vimdoc", "typescript", "tsx", "javascript", "rust", "go", "gomod",
  "php", "html", "css", "vue", "json", "yaml", "toml", "dockerfile", "bash",
  "markdown", "markdown_inline", "regex", "diff", "gitcommit",
}
if vim.fn.executable("tree-sitter") == 1 then
  require("nvim-treesitter").install(parsers)
end
vim.api.nvim_create_autocmd("FileType", {
  callback = function(ev)
    if pcall(vim.treesitter.start, ev.buf) then
      vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

-- Completion (coq v2 attaches on setup; options go in vim.g.coq_settings before it)
-- Keymaps are ours (Tab accept, <C-Space> trigger; see keymaps.lua)
vim.g.coq_settings = {
  keymap = { recommended = false, manual_complete = "<C-Space>" },
}
require("coq").setup()

-- Auto-pairs (<CR> mapping lives in keymaps.lua so it can cooperate with coq's popup)
require("nvim-autopairs").setup({ check_ts = true, map_cr = false })

-- Rainbow brackets (treesitter-based, colours borrowed from the active theme)
local function rainbow_hl()
  local groups = { Red = "Statement", Yellow = "String", Blue = "Function", Orange = "Number", Green = "Type", Violet = "Keyword", Cyan = "Special" }
  for name, src in pairs(groups) do
    local fg = vim.api.nvim_get_hl(0, { name = src, link = false }).fg
    vim.api.nvim_set_hl(0, "RainbowDelimiter" .. name, { fg = fg })
  end
end
rainbow_hl()
vim.api.nvim_create_autocmd("ColorScheme", { callback = rainbow_hl })

-- Formatting
require("conform").setup({
  formatters_by_ft = {
    lua = { "stylua" },
    javascript = { "prettier" }, javascriptreact = { "prettier" },
    typescript = { "prettier" }, typescriptreact = { "prettier" },
    json = { "prettier" }, jsonc = { "prettier" }, yaml = { "prettier" },
    vue = { "prettier" }, markdown = { "prettier" }, html = { "prettier" }, css = { "prettier" },
    go = { "goimports", "gofmt" },
    rust = { lsp_format = "prefer" },
  },
  format_on_save = { timeout_ms = 1500, lsp_format = "fallback" },
})

-- Tasks
require("overseer").setup()
require("treesj").setup({ use_default_keymaps = false })
require("substitute").setup()
require("nvim-surround").setup()

-- Statusline (galaxyline; custom providers avoid its deprecated LSP/diagnostic ones)
local gl = require("galaxyline")
local gls = gl.section
gl.short_line_list = { "neo-tree", "TelescopePrompt" }

local function seg(fn, color, icon)
  return {
    provider = function()
      local ok, v = pcall(fn)
      return ok and v and v ~= "" and (icon .. " " .. v .. " ") or ""
    end,
    highlight = { color, "NONE", "bold" },
  }
end

local function git_status()
  local d = vim.b.gitsigns_status_dict
  if not d or not d.head or d.head == "" then return "" end
  local s = d.head
  if (d.added or 0) > 0 then s = s .. " +" .. d.added end
  if (d.changed or 0) > 0 then s = s .. " ~" .. d.changed end
  if (d.removed or 0) > 0 then s = s .. " -" .. d.removed end
  return s
end

local function diag()
  local c, out = vim.diagnostic.count(0), {}
  for sev, icon in pairs({ [1] = "E", [2] = "W" }) do
    if c[sev] then table.insert(out, icon .. c[sev]) end
  end
  return table.concat(out, " ")
end

local function overseer_status()
  local ok, ov = pcall(require, "overseer")
  if not ok then return "" end
  local run = #ov.list_tasks({ status = "RUNNING" })
  local fail = #ov.list_tasks({ status = "FAILURE" })
  return (run > 0 and ("run " .. run .. " ") or "") .. (fail > 0 and ("fail " .. fail) or "")
end

local modes = {
  n = { "NORMAL", "#7aa2f7" }, i = { "INSERT", "#9ece6a" }, v = { "VISUAL", "#bb9af7" },
  V = { "V-LINE", "#bb9af7" }, ["\22"] = { "V-BLOCK", "#bb9af7" }, c = { "COMMAND", "#e0af68" },
  R = { "REPLACE", "#f7768e" }, s = { "SELECT", "#ff9e64" }, S = { "S-LINE", "#ff9e64" },
  t = { "TERMINAL", "#73daca" }, no = { "OP-PENDING", "#7aa2f7" },
}
local function mode() return modes[vim.fn.mode()] or modes[vim.fn.mode():sub(1, 1)] or modes.n end
local function mode_hl()
  local color = mode()[2]
  vim.api.nvim_set_hl(0, "GalaxyMode", { fg = "#15161e", bg = color, bold = true })
  vim.api.nvim_set_hl(0, "GalaxyModeEnd", { fg = color })
end
vim.api.nvim_create_autocmd({ "ModeChanged", "ColorScheme", "VimEnter" }, {
  callback = function() mode_hl(); vim.cmd.redrawstatus() end,
})

gls.left = {
  { Mode = { provider = function() return "  " .. mode()[1] .. " " end, highlight = { "#15161e", "#7aa2f7", "bold" } } },
  { ModeEnd = { provider = function() return "" end, highlight = { "#7aa2f7", "NONE" } } },
  { File = { provider = function() return " " .. vim.fn.expand("%:t") .. " " end, highlight = { "#c0caf5", "NONE", "bold" } } },
  { Git = seg(git_status, "#bb9af7", "") },
}
gls.right = {
  { Octo = { provider = function() local s = octo_loading() return s ~= "" and (s .. " ") or "" end, highlight = { "#e0af68", "NONE", "bold" } } },
  { Grapple = seg(function() return require("grapple").name_or_index() end, "#7dcfff", "󰃀") },
  { Tasks = seg(overseer_status, "#e0af68", "") },
  { Diag = seg(diag, "#f7768e", "") },
  { Pos = { provider = function() return " " .. vim.fn.line(".") .. ":" .. vim.fn.col(".") .. " " end, highlight = { "#c0caf5", "NONE" } } },
}
gls.short_line_left = { { Short = { provider = function() return " " .. vim.fn.expand("%:t") end, highlight = { "#565f89", "NONE" } } } }
vim.api.nvim_create_autocmd("User", { pattern = "GrappleUpdate", callback = function() vim.cmd.redrawstatus() end })

-- Editor extras
require("trouble").setup()
require("todo-comments").setup()
require("nvim-highlight-colors").setup()
require("tiny-cmdline").setup({ position = { y = "20%" } })
require("tabline").setup()
-- ponytail: no `diff.compact` (his config enables it but needs a workaround for neovim#40290, an "Invalid buffer id" crash)
require("codediff").setup({ explorer = { width = 50, auto_open_on_cursor = true, view_mode = "tree", line_stats = { enabled = true } } })
require("incline").setup({
  window = { margin = { vertical = 0, horizontal = 1 }, zindex = 10 },
  hide = { cursorline = "smart" },
  render = function(props)
    local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
    if name == "" then return "" end
    local icon, hl = require("nvim-web-devicons").get_icon(name, vim.fn.fnamemodify(name, ":e"), { default = true })
    return { { icon, group = hl }, { " " }, { vim.bo[props.buf].modified and "[+] " or "" }, { name } }
  end,
})

-- Mason: servers + formatters
require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = {
    "lua_ls", "vtsls", "vue_ls", "eslint", "rust_analyzer", "gopls", "intelephense",
    "jsonls", "yamlls", "taplo", "dockerls", "bashls", "marksman", "cssls",
  },
  automatic_enable = true,
})
require("mason-tool-installer").setup({
  ensure_installed = { "prettier", "stylua", "goimports" },
})
