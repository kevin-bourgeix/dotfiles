# Neovim config (0.12+)

Lightweight config built on the native `vim.pack` plugin manager and native LSP.
Leader is `<Space>`; press it and wait for which-key to list everything (`<leader>fk` searches all keymaps).

## Prerequisites

```sh
brew install neovim git ripgrep fd fzf node go tree-sitter-cli
xcode-select --install        # provides `make` (builds telescope-fzf-native)
brew install php composer     # PHP work only
rustup default stable         # Rust work only
```

| Tool | Needed for |
|---|---|
| `git` | `vim.pack` plugin installs |
| `make` + C compiler | telescope-fzf-native, tree-sitter parsers |
| `ripgrep` | `<leader>fg` live grep |
| `fd` | faster `<leader>ff` file search |
| `fzf` | fuzzy matching (via telescope-fzf-native) |
| `tree-sitter-cli` | parser install for nvim-treesitter (main) |
| `node` | most LSP servers + prettier (installed through Mason) |
| `go` / `cargo` / `php` | their language toolchains |

Use a [Nerd Font](https://www.nerdfonts.com/) in your terminal for icons.

## First run

1. `nvim` — plugins are cloned automatically; Mason then installs the LSP servers and formatters.
2. Restart once Mason/treesitter finish; check with `:checkhealth vim.pack vim.lsp mason`.
3. Commit `nvim-pack-lock.json` so plugin versions are reproducible.

## Layout

- `init.lua` options, loads the modules below
- `lua/plugins.lua` plugin list (`vim.pack.add`) and setup
- `lua/lsp.lua` LSP overrides (servers are enabled by mason-lspconfig)
- `lua/keymaps.lua` every keymap and which-key group

## Key groups

| Prefix | Area |
|---|---|
| `<leader>f` | find (telescope) |
| `<leader>e` / `E` | file explorer / reveal file |
| `s` / `S` | flash jump / treesitter select |
| `<leader>l` | LSP (also native `gra grn grr gri grt K`) |
| `<leader>c` | format, diagnostics |
| `<leader>g` / `]h [h` | git hunks, blame, commits |
| `<leader>m` | markdown render toggle |
| `<leader>u` | undo tree, UI toggles |
| `<leader>p` | plugin update/status, Mason |
| `<leader>qq` | quit nvim (files autosave, no formatting) |

## Maintenance

- Update plugins: `<leader>pu` (or `:lua vim.pack.update()`), then `:w` to confirm.
- Add a language: add the server to `ensure_installed` in `lua/plugins.lua`, the parser to `parsers`, and a formatter to conform.
