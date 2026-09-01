-- init.lua — lightweight AI IDE bootstrap (Arch proot)
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.o.termguicolors = true

-- load core config
require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.mentor").setup()

-- bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    { import = "plugins" },
  },
  install = { colorscheme = { "tokyonight", "habamax" } },
  checker = { enabled = false }, -- no auto-update pings (lightweight)
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip", "tarPlugin", "tohtml", "tutor_mode_plugin",
        "zipPlugin", "netrwPlugin", "matchit", "matchparen",
      },
    },
  },
})
