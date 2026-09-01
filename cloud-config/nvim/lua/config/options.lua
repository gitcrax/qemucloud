-- options.lua — minimal, fast defaults
local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"
opt.cursorline = true

opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.autoindent = true
opt.smartindent = true
opt.wrap = false
opt.scrolloff = 8

opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true

opt.termguicolors = true
opt.background = "dark"
-- colorscheme applied in init.lua (tokyonight); fallback only if it's missing
if not vim.g.colors_name then
  vim.cmd.colorscheme("habamax")
end

opt.splitright = true
opt.splitbelow = true
opt.clipboard = "unnamedplus" -- share with system clipboard (Termux: termux-clipboard-set)

opt.swapfile = false
opt.undofile = true
opt.updatetime = 250

opt.completeopt = "menu,menuone,noselect"
opt.pumheight = 10

-- faster rendering on proot
opt.lazyredraw = true
opt.synmaxcol = 200
opt.foldlevelstart = 99

-- built-in LSP diagnostics UI
vim.diagnostic.config({
  virtual_text = { prefix = "●" },
  signs = true,
  update_in_insert = false,
  float = { border = "rounded" },
})

-- modern editor feel: inlay hints (type names inline), semantic tokens, cursorline
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client.server_capabilities.inlayHintProvider then
      vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
    end
    if client and client.server_capabilities.semanticTokensProvider then
      vim.lsp.semantic_tokens.enable(true, { bufnr = args.buf })
    end
  end,
})

-- file explorer toggle (netrw is disabled; use mini.files - tiny, zero deps)
vim.keymap.set("n", "<leader>n", "<cmd>MiniFiles open<CR>", { noremap = true, silent = true, desc = "Files explorer" })
vim.keymap.set("n", "<leader>N", "<cmd>MiniFiles close<CR>", { noremap = true, silent = true, desc = "Close explorer" })
