-- keymaps.lua
local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- leader shortcuts
map("n", "<leader>e", "<cmd>FzfLua files<CR>", opts)          -- find file
map("n", "<leader>f", "<cmd>FzfLua live_grep<CR>", opts)      -- grep
map("n", "<leader>b", "<cmd>FzfLua buffers<CR>", opts)        -- buffers
map("n", "<leader>h", "<cmd>FzfLua helptags<CR>", opts)       -- help
map("n", "<leader>g", "<cmd>FzfLua git_status<CR>", opts)     -- git changes
map("n", "<leader>a", "<cmd>CodeCompanionChat<CR>", opts)     -- AI chat
map("n", "<leader>c", "<cmd>CodeCompanionActions<CR>", opts)  -- AI actions
map("n", "<leader>s", "<cmd>w<CR>", opts)                     -- save
map("n", "<leader>q", "<cmd>q<CR>", opts)                     -- quit

-- LSP
map("n", "gd", vim.lsp.buf.definition, opts)
map("n", "gD", vim.lsp.buf.declaration, opts)
map("n", "gr", vim.lsp.buf.references, opts)
map("n", "gi", vim.lsp.buf.implementation, opts)
map("n", "K", vim.lsp.buf.hover, opts)
map("n", "<leader>rn", vim.lsp.buf.rename, opts)
map("n", "<leader>ca", vim.lsp.buf.code_action, opts)
map("n", "[d", vim.diagnostic.goto_prev, opts)
map("n", "]d", vim.diagnostic.goto_next, opts)
map("n", "<leader>d", vim.diagnostic.open_float, opts)

-- better window nav
map("n", "<C-h>", "<C-w>h", opts)
map("n", "<C-j>", "<C-w>j", opts)
map("n", "<C-k>", "<C-w>k", opts)
map("n", "<C-l>", "<C-w>l", opts)

-- sane paste: don't lose selection after indent
map("v", "<", "<gv", opts)
map("v", ">", ">gv", opts)

-- keep yank register when pasting over selection
map("v", "p", '"_dP', opts)

-- escape terminal mode
map("t", "<Esc>", "<C-\\><C-n>", opts)
