vim.loader.enable()
vim.g.mapleader = " "
vim.g.maplocalleader = ","
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1 -- neo-tree is the only directory explorer; avoids the netrw flash

local o = vim.o
o.number = true
o.relativenumber = true
o.signcolumn = "yes"
o.cursorline = true
o.termguicolors = true
o.mouse = "a"
o.clipboard = "unnamedplus"
o.ignorecase = true
o.smartcase = true
o.expandtab = true
o.shiftwidth = 2
o.tabstop = 2
o.smartindent = false -- treesitter indentexpr handles indentation
o.undofile = true
o.swapfile = false
o.splitright = true
o.splitbelow = true
o.scrolloff = 8
o.updatetime = 250
o.timeoutlen = 400
o.completeopt = "menu,menuone,noselect"
o.winborder = "rounded"
o.laststatus = 3 -- one global statusline (neo-tree no longer gets its own)
o.showmode = false -- mode is in the statusline

require("plugins")
require("lsp")
require("keymaps")

-- Autosave without format-on-save (noautocmd skips BufWritePre)
vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged", "CursorHold", "FocusLost", "BufLeave" }, {
  callback = function(a)
    local b = a.buf
    if vim.bo[b].modified and vim.bo[b].buftype == "" and vim.api.nvim_buf_get_name(b) ~= "" then
      vim.api.nvim_buf_call(b, function() vim.cmd("noautocmd silent! update") end)
    end
  end,
})

-- No file argument: show the explorer full-window instead of an empty [No Name] buffer (wiped once hidden)
vim.api.nvim_create_autocmd("VimEnter", {
  nested = true,
  callback = function()
    if vim.fn.argc() == 0 and vim.api.nvim_buf_get_name(0) == "" and vim.fn.line2byte("$") == -1 then
      vim.bo.bufhidden = "wipe"
      vim.cmd("Neotree filesystem current")
    end
  end,
})

-- Publish this instance's RPC socket so external tools (lazygit launched from Rex) can open files here
vim.api.nvim_create_autocmd({ "VimEnter", "FocusGained" }, {
  callback = function()
    vim.fn.writefile({ vim.v.servername }, vim.fn.expand("~/.cache/nvim-server"))
  end,
})

vim.api.nvim_create_autocmd("TextYankPost", { callback = function() vim.hl.on_yank() end })
