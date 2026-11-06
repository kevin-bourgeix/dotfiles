-- Powerline-style tab pills (adapted from craftzdog); colours borrowed from the active theme.
local M = {}
local LEFT, RIGHT = "\u{e0ba}", "\u{e0b8}"
local MAX, CUT = 20, 17

local function hl_attr(name, attr) return vim.api.nvim_get_hl(0, { name = name, link = false })[attr] end

local function setup_hl()
  local set = vim.api.nvim_set_hl
  local accent, dim = hl_attr("Function", "fg"), hl_attr("CursorLine", "bg") or hl_attr("Visual", "bg")
  set(0, "TabLineActive", { fg = hl_attr("Normal", "bg"), bg = accent, bold = true })
  set(0, "TabLineInactive", { fg = hl_attr("Comment", "fg"), bg = dim })
  set(0, "TabLineSepActive", { fg = accent })
  set(0, "TabLineSepInactive", { fg = dim })
  set(0, "TabLineFill", { bg = "NONE" })
end

local function name_of(buf)
  if vim.bo[buf].buftype == "terminal" then return "[Terminal]", "" end
  local path = vim.api.nvim_buf_get_name(buf)
  if path == "" then return "[No Name]", "" end
  local name = vim.fn.fnamemodify(path, ":t")
  local icon = require("nvim-web-devicons").get_icon(name, vim.fn.fnamemodify(name, ":e"), { default = true })
  if #name > MAX then name = name:sub(1, CUT) .. "…" end
  return name, icon
end

function M.render()
  local cur, out = vim.fn.tabpagenr(), {}
  for t = 1, vim.fn.tabpagenr("$") do
    local buf = vim.fn.tabpagebuflist(t)[vim.fn.tabpagewinnr(t)]
    local name, icon = name_of(buf)
    local on = t == cur and "Active" or "Inactive"
    out[#out + 1] = ("%%%dT%%#TabLineSep%s#%s%%#TabLine%s#   %s%s %s   %%#TabLineSep%s#%s%%T"):format(
      t, on, LEFT, on, vim.bo[buf].modified and "[+] " or "", icon, name, on, RIGHT)
  end
  return table.concat(out) .. "%#TabLineFill#"
end

function M.setup()
  setup_hl()
  vim.api.nvim_create_autocmd("ColorScheme", { callback = setup_hl })
  vim.o.showtabline = 1
  vim.o.tabline = "%!v:lua.require('tabline').render()"
end

return M
