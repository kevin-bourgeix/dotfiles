local map = vim.keymap.set
local function m(mode, lhs, rhs, desc) map(mode, lhs, rhs, { desc = desc }) end

require("which-key").add({
  { "<leader>f", group = "find" },
  { "<leader>g", group = "git" },
  { "<leader>go", group = "octo (PR / review)" },
  { "<leader>l", group = "lsp" },
  { "<leader>c", group = "code" },
  { "<leader>b", group = "buffer" },
  { "<leader>d", group = "diff / markdown" },
  { "<leader>o", group = "overseer" },
  { "<leader>p", group = "plugins" },
  { "<leader>q", group = "quit" },
  { "<leader>u", group = "ui" },
  { "<leader>x", group = "trouble" },
  { "<leader>y", group = "yank" },
})

-- Yank path#Lline / selection as a fenced codeblock (handy for pasting into AI chats)
local function yank(text, what)
  vim.fn.setreg("+", text)
  vim.notify("Yanked " .. what, vim.log.levels.INFO)
end
m("n", "<leader>yf", function()
  local p = vim.fn.expand("%:.") .. "#L" .. vim.fn.line(".")
  yank(p, p)
end, "Yank relative path#Lline")
m("n", "<leader>yp", function()
  local p = vim.fn.expand("%:p") .. "#L" .. vim.fn.line(".")
  yank(p, p)
end, "Yank absolute path#Lline")
m("x", "<leader>yc", function()
  local s, e = vim.fn.line("v"), vim.fn.line(".")
  if s > e then s, e = e, s end
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then return vim.notify("Buffer has no file name", vim.log.levels.WARN) end
  local root = vim.fs.root(path, ".git") or vim.uv.cwd()
  local lang = ({ typescriptreact = "tsx", javascriptreact = "jsx", typescript = "ts", javascript = "js" })[vim.bo.filetype] or vim.bo.filetype
  local lines = vim.api.nvim_buf_get_lines(0, s - 1, e, false)
  yank(("```%s filename=\"%s\" line=%d\n%s\n```"):format(lang, vim.fs.relpath(root, path) or path, s, table.concat(lines, "\n")), #lines .. " lines as codeblock")
  vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "n", false)
end, "Yank selection as codeblock")

-- Trouble / todo-comments
m("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", "Workspace diagnostics")
m("n", "<leader>xr", "<cmd>Trouble lsp_references toggle<cr>", "LSP references")
m("n", "]t", function() require("todo-comments").jump_next() end, "Next todo")
m("n", "[t", function() require("todo-comments").jump_prev() end, "Previous todo")
m("n", "<leader>ft", "<cmd>TodoTelescope<cr>", "Todos")

-- General
m("n", "<Esc>", "<cmd>nohlsearch<cr>", "Clear search highlight")
m("n", "<leader>w", "<cmd>write<cr>", "Save")
m("n", "<leader>qq", "<cmd>qa<cr>", "Quit nvim")
m("n", "<C-h>", "<C-w>h", "Window left")
m("n", "<C-j>", "<C-w>j", "Window down")
m("n", "<C-k>", "<C-w>k", "Window up")
m("n", "<C-l>", "<C-w>l", "Window right")
m("v", "<", "<gv", "Indent left")
m("v", ">", ">gv", "Indent right")

-- Completion (coq popup): Tab accepts, arrows/S-Tab move, <C-Space> triggers, Enter expands pairs
local function selected() return vim.fn.complete_info({ "selected" }).selected ~= -1 end
map("i", "<Tab>", function()
  if vim.fn.pumvisible() == 0 then return "<Tab>" end
  return selected() and "<C-y>" or "<C-n><C-y>"
end, { expr = true, desc = "Accept completion / Tab" })
map("i", "<S-Tab>", function()
  return vim.fn.pumvisible() == 1 and "<C-p>" or "<S-Tab>"
end, { expr = true, desc = "Previous completion" })
map("i", "<CR>", function()
  if vim.fn.pumvisible() == 1 and selected() then return vim.keycode("<C-y>") end
  return require("nvim-autopairs").autopairs_cr()
end, { expr = true, replace_keycodes = false, desc = "Accept completion / newline with pairs" })

-- Buffers
m("n", "<S-h>", "<cmd>tabprevious<cr>", "Previous tab")
m("n", "<S-l>", "<cmd>tabnext<cr>", "Next tab")
m("n", "<leader>bd", "<cmd>bdelete<cr>", "Delete buffer")
m("n", "<leader>bo", "<cmd>%bdelete|edit #|bdelete #<cr>", "Delete other buffers")

-- Explorer (neo-tree)
m("n", "<leader>e", function()
  vim.cmd(vim.bo.filetype == "neo-tree" and "Neotree close" or "Neotree focus")
end, "Explorer focus / close")
m("n", "<leader>E", "<cmd>Neotree reveal current<cr>", "Explorer full window (reveal file)")

-- Find (telescope)
local tb = function(fn, opts) return function() require("telescope.builtin")[fn](opts) end end
m("n", "<leader><space>", tb("find_files", { hidden = true }), "Find files")
m("n", "<leader>ff", tb("find_files", { hidden = true }), "Files")
m("n", "<leader>fg", tb("live_grep"), "Grep")
m("n", "<leader>fw", tb("grep_string"), "Word under cursor")
m("n", "<leader>fb", tb("buffers"), "Buffers")
m("n", "<leader>fr", tb("oldfiles"), "Recent files")
m("n", "<leader>fh", tb("help_tags"), "Help")
m("n", "<leader>fk", tb("keymaps"), "Keymaps")
m("n", "<leader>fd", tb("diagnostics"), "Diagnostics")
m("n", "<leader>fs", tb("lsp_document_symbols"), "Document symbols")
m("n", "<leader>fS", tb("lsp_dynamic_workspace_symbols"), "Workspace symbols")
m("n", "<leader>f/", tb("current_buffer_fuzzy_find"), "Search in buffer")
m("n", "<leader>fc", tb("find_files", { cwd = vim.fn.stdpath("config") }), "Config files")

-- Flash (jump to word by label)
m({ "n", "x", "o" }, "s", function() require("flash").jump() end, "Flash jump")
m({ "n", "x", "o" }, "S", function() require("flash").treesitter() end, "Flash treesitter")
m("o", "r", function() require("flash").remote() end, "Flash remote")
m("c", "<C-s>", function() require("flash").toggle() end, "Flash toggle in search")

-- LSP (0.12 defaults gra/grn/grr/gri/grt/K/gO also work)
m("n", "gd", vim.lsp.buf.definition, "Go to definition")
m("n", "gD", vim.lsp.buf.declaration, "Go to declaration")

-- Vue/HTML: no LSP maps class="x" to .x in other css/scss files, so fall back to ripgrep when LSP finds nothing
local function css_class_fallback(method, pattern, globs, lsp_fn)
  return function()
    local word = vim.fn.expand("<cword>")
    local grep = function()
      require("telescope.builtin").grep_string({ search = pattern:format(word), use_regex = true, glob_pattern = globs })
    end
    if #vim.lsp.get_clients({ bufnr = 0, method = method }) == 0 then return grep() end -- buf_request_all never calls back with no client
    local params = vim.lsp.util.make_position_params(0, "utf-16")
    params.context = { includeDeclaration = true }
    vim.lsp.buf_request_all(0, method, params, function(res)
      for _, r in pairs(res) do
        if r.result and not vim.tbl_isempty(r.result) then return lsp_fn() end
      end
      grep()
    end)
  end
end
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "vue", "html", "css", "scss", "sass", "less" },
  callback = function(ev)
    vim.opt_local.iskeyword:append("-") -- my-class is one word
    local css = { "*.css", "*.scss", "*.sass", "*.less", "*.vue" }
    local any = vim.list_extend({ "*.html" }, css)
    local o = function(d) return { buffer = ev.buf, desc = d } end
    if vim.bo[ev.buf].filetype == "vue" or vim.bo[ev.buf].filetype == "html" then
      map("n", "gd", css_class_fallback("textDocument/definition", "\\.%s\\b", css, vim.lsp.buf.definition), o("Go to definition / CSS class"))
    end
    map("n", "grr", css_class_fallback("textDocument/references", "\\b%s\\b", any, tb("lsp_references")), o("References / CSS class"))
  end,
})
m("n", "grr", tb("lsp_references"), "References")
m({ "n", "x" }, "<leader>la", vim.lsp.buf.code_action, "Code action")
m("n", "<leader>ln", vim.lsp.buf.rename, "Rename")
m("n", "<leader>lr", tb("lsp_references"), "References")
m("n", "<leader>li", tb("lsp_implementations"), "Implementations")
m("n", "<leader>lt", tb("lsp_type_definitions"), "Type definition")
m("n", "<leader>lh", vim.lsp.buf.signature_help, "Signature help")
m("n", "<leader>lH", function()
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
end, "Toggle inlay hints")
m("n", "<leader>lR", "<cmd>lsp restart<cr>", "Restart LSP")
m("n", "<leader>lI", "<cmd>checkhealth vim.lsp<cr>", "LSP info")
m("n", "<leader>lm", "<cmd>Mason<cr>", "Mason")

-- Code / diagnostics / format
m({ "n", "x" }, "<leader>cf", function() require("conform").format({ lsp_format = "fallback" }) end, "Format")
m("n", "<leader>cd", vim.diagnostic.open_float, "Line diagnostics")
m("n", "<leader>cq", vim.diagnostic.setloclist, "Diagnostics to loclist")
m("n", "<leader>cj", function() require("treesj").toggle() end, "Split/join node")

-- Git (gitsigns + telescope)
local gs = function(fn, ...)
  local a = { ... }
  return function() require("gitsigns")[fn](unpack(a)) end
end
m("n", "]h", gs("nav_hunk", "next"), "Next hunk")
m("n", "[h", gs("nav_hunk", "prev"), "Previous hunk")
m("n", "<leader>gs", gs("stage_hunk"), "Stage/unstage hunk")
m("n", "<leader>gr", gs("reset_hunk"), "Reset hunk")
m("n", "<leader>gS", gs("stage_buffer"), "Stage buffer")
m("n", "<leader>gp", gs("preview_hunk"), "Preview hunk")
m("n", "<leader>gb", gs("blame_line"), "Blame line")
m("n", "<leader>gd", gs("diffthis"), "Diff this")
m("n", "<leader>gt", gs("toggle_current_line_blame"), "Toggle inline blame")
m("n", "<leader>gc", tb("git_commits"), "Commits")
m("n", "<leader>gf", tb("git_status"), "Changed files")
m("n", "<leader>gB", tb("git_branches"), "Branches")
m("n", "<leader>gol", "<cmd>Octo pr list<cr>", "PR list")
m("n", "<leader>gon", "<cmd>Octo pr create<cr>", "New PR")
m("n", "<leader>goo", "<cmd>Octo pr checkout<cr>", "Checkout PR")
m("n", "<leader>gom", "<cmd>Octo pr merge<cr>", "Merge PR")
m("n", "<leader>gos", "<cmd>Octo review start<cr>", "Start review")
m("n", "<leader>goR", "<cmd>Octo review resume<cr>", "Resume review")
m("n", "<leader>gok", "<cmd>Octo pr checks<cr>", "PR checks")
m("n", "<leader>gow", "<cmd>Octo pr browser<cr>", "Open PR in browser")
m("n", "<leader>goh", function()
  local layout = require("octo.reviews").get_current_layout()
  if not layout or not vim.api.nvim_win_is_valid(layout.left_winid) then return end
  local left, right = layout.left_winid, layout.right_winid
  local hidden = vim.w[left].octo_base_hidden
  vim.w[left].octo_base_hidden = not hidden
  vim.wo[left].winfixwidth = not hidden
  if hidden then
    vim.wo[left].winfixwidth = false
    local total = vim.api.nvim_win_get_width(left) + vim.api.nvim_win_get_width(right)
    vim.api.nvim_win_set_width(left, math.floor(total / 2))
  else
    vim.api.nvim_win_set_width(left, 1)
  end
end, "Toggle base side of review diff")
m("n", "gh", function()
  local root = vim.trim(vim.fn.system("git rev-parse --show-toplevel"))
  if vim.v.shell_error ~= 0 then return vim.notify("Not a git repo", vim.log.levels.WARN) end
  local hunks = {}
  for _, staged in ipairs({ true, false }) do
    local cmd = { "git", "-C", root, "diff", "-U0", "--no-color" }
    if staged then table.insert(cmd, "--cached") end
    local old, file, deleted, inhunk
    for _, l in ipairs(vim.fn.systemlist(cmd)) do
      local lnum, cnt = l:match("^@@ %-%S+ %+(%d+),?(%d*)")
      if l:match("^diff ") then old, file, deleted, inhunk = nil, nil, false, false
      elseif lnum and file then
        inhunk = true
        hunks[#hunks + 1] = { file = file, staged = staged, deleted = deleted, lnum = tonumber(lnum), cnt = cnt == "" and 1 or tonumber(cnt), lines = { l } }
      elseif inhunk then
        if l:sub(1, 1) ~= "\\" then table.insert(hunks[#hunks].lines, l) end
      elseif l:match("^%-%-%- a/") then old = l:match("^%-%-%- a/(.*)")
      elseif l:match("^%+%+%+ b/") then file = l:match("^%+%+%+ b/(.*)")
      elseif l:match("^%+%+%+ /dev/null") then file, deleted = old, true
      end
    end
  end
  if #hunks == 0 then return vim.notify("No hunks", vim.log.levels.INFO) end
  local pickers, finders, conf = require("telescope.pickers"), require("telescope.finders"), require("telescope.config").values
  local previewers, actions, state = require("telescope.previewers"), require("telescope.actions"), require("telescope.actions.state")
  pickers.new({}, {
    prompt_title = "Git hunks",
    finder = finders.new_table({
      results = hunks,
      entry_maker = function(h)
        local d = (h.staged and "[S] " or "") .. (h.deleted and "[D] " or "") .. h.file .. ":" .. h.lnum
        return { value = h, display = d, ordinal = d .. " " .. table.concat(h.lines, " ") }
      end,
    }),
    sorter = conf.generic_sorter({}),
    previewer = previewers.new_buffer_previewer({
      title = "Diff in file",
      define_preview = function(self, entry)
        local h, buf, win = entry.value, self.state.bufnr, self.state.winid
        local path = root .. "/" .. h.file
        local ft = vim.filetype.match({ filename = path })
        if h.deleted then
          local gone = vim.tbl_map(function(x) return x:sub(2) end, vim.list_slice(h.lines, 2))
          vim.api.nvim_buf_set_lines(buf, 0, -1, false, gone)
          require("telescope.previewers.utils").highlighter(buf, ft)
          vim.api.nvim_buf_set_extmark(buf, vim.api.nvim_create_namespace("hunk_preview"), 0, 0, { end_row = #gone, hl_eol = true, hl_group = "DiffDelete" })
          return
        end
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.fn.readfile(path))
        require("telescope.previewers.utils").highlighter(buf, ft)
        local ns, row, del = vim.api.nvim_create_namespace("hunk_preview"), h.lnum - 1, {}
        for i = 2, #h.lines do
          local l = h.lines[i]
          if l:sub(1, 1) == "-" then
            del[#del + 1] = { { l, "DiffDelete" } }
          elseif l:sub(1, 1) == "+" then
            vim.api.nvim_buf_set_extmark(buf, ns, row + i - 2 - #del, 0, { line_hl_group = "DiffAdd" })
          end
        end
        if #del > 0 then
          -- pure deletion (cnt == 0): lnum is the line before, so draw below it
          vim.api.nvim_buf_set_extmark(buf, ns, math.max(row, 0), 0, { virt_lines = del, virt_lines_above = h.cnt > 0 })
        end
        -- telescope resets the preview cursor after define_preview, so jump on the next tick
        vim.schedule(function()
          if not (vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf) then return end
          vim.api.nvim_win_set_cursor(win, { math.min(math.max(h.lnum, 1), vim.api.nvim_buf_line_count(buf)), 0 })
          vim.api.nvim_win_call(win, function() vim.cmd("normal! zz") end)
        end)
      end,
    }),
    attach_mappings = function(bufnr)
      actions.select_default:replace(function()
        local h = state.get_selected_entry().value
        if h.deleted then return vim.notify(h.file .. " is deleted", vim.log.levels.INFO) end
        actions.close(bufnr)
        vim.cmd.edit(vim.fn.fnameescape(root .. "/" .. h.file))
        vim.api.nvim_win_set_cursor(0, { math.max(h.lnum, 1), 0 })
      end)
      return true
    end,
  }):find()
end, "Git hunks (telescope)")

-- CodeDiff (diff explorer)
m("n", "<leader>dv", "<cmd>CodeDiff<cr>", "Toggle CodeDiff explorer")
m("n", "<leader>dh", "<cmd>CodeDiff history %<cr>", "File history (current file)")
m("n", "<leader>dH", "<cmd>CodeDiff history<cr>", "File history (repo)")

-- Markdown
m("n", "<leader>dr", "<cmd>RenderMarkdown toggle<cr>", "Toggle render")

-- Overseer
m("n", "<leader>or", "<cmd>OverseerRun<cr>", "Run task")
m("n", "<leader>ot", "<cmd>OverseerToggle<cr>", "Task list")
m("n", "<leader>oa", "<cmd>OverseerTaskAction<cr>", "Task action")

-- Substitute (s/S are Flash, so R; overrides Replace mode, use `gR` for that)
m("n", "R", function() require("substitute").operator() end, "Substitute with motion")
m("n", "RR", function() require("substitute").line() end, "Substitute line")
m("n", "<leader>R", function() require("substitute").eol() end, "Substitute to end of line")
m("x", "R", function() require("substitute").visual() end, "Substitute selection")

-- Surround: select text, then type the char to wrap it (overrides visual ( ) { } motions)
for _, c in ipairs({ "(", "[", "{", ")", "]", "}", '"', "'", "`" }) do
  -- closing chars (and quotes) wrap tight; opening chars add inner spaces, so map both to the tight form
  local tight = ({ ["("] = ")", ["["] = "]", ["{"] = "}" })[c] or c
  map("x", c, "<Plug>(nvim-surround-visual)" .. tight, { remap = true, desc = "Wrap selection in " .. tight })
end

-- Grapple
m("n", "<leader>m", function()
  require("grapple").toggle({ cursor = vim.api.nvim_win_get_cursor(0) })
end, "Grapple tag")
m("n", "<leader>M", "<cmd>Grapple toggle_tags<cr>", "Grapple menu")
for i = 1, 9 do
  m("n", "<leader>" .. i, "<cmd>Grapple select index=" .. i .. "<cr>", "Grapple " .. i)
end

-- UI / plugins
m("n", "<leader>uu", function()
  pcall(vim.cmd.packadd, "nvim.undotree")
  vim.cmd.Undotree()
end, "Undo tree")
m("n", "<leader>uw", "<cmd>set wrap!<cr>", "Toggle wrap")
m("n", "<leader>un", "<cmd>set relativenumber!<cr>", "Toggle relative numbers")
m("n", "<leader>pu", function() vim.pack.update() end, "Update plugins")
m("n", "<leader>ps", function() vim.pack.update(nil, { offline = true }) end, "Plugin status")
m("n", "<leader>pm", "<cmd>Mason<cr>", "Mason")
