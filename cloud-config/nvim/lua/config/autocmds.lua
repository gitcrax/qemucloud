-- autocmds.lua
local augroup = vim.api.nvim_create_augroup("UserConfig", { clear = true })

-- auto format on save (handled by conform, triggered via BufWritePre in format plugin)
-- trim trailing whitespace on save
vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup,
  pattern = "*",
  command = "%s/\\s\\+$//e",
})

-- return to last edit position
vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup,
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    if mark[1] > 1 and mark[1] <= vim.api.nvim_buf_line_count(0) then
      pcall(vim.api.nvim_win_set_cursor, 0, { mark[1], mark[2] })
    end
  end,
})

-- highlight yank
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup,
  callback = function()
    vim.hl.on_yank({ timeout = 200 })
  end,
})

-- resize splits on window resize
vim.api.nvim_create_autocmd("VimResized", {
  group = augroup,
  command = "tabdo wincmd =",
})

-- close some filetypes with q
vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = { "help", "qf", "lspinfo", "checkhealth", "fzf" },
  callback = function()
    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = true, silent = true })
  end,
})
