-- fuzzy.lua — fzf-lua (uses native fzf binary, very fast, low memory)
return {
  {
    "ibhagwan/fzf-lua",
    cmd = { "FzfLua" },
    keys = {
      { "<leader>e", "<cmd>FzfLua files<CR>", desc = "Files" },
      { "<leader>f", "<cmd>FzfLua live_grep<CR>", desc = "Grep" },
      { "<leader>b", "<cmd>FzfLua buffers<CR>", desc = "Buffers" },
      { "<leader>h", "<cmd>FzfLua helptags<CR>", desc = "Help" },
      { "<leader>g", "<cmd>FzfLua git_status<CR>", desc = "Git" },
    },
    opts = {
      fzf_opts = { ["--layout"] = "reverse" },
      winopts = {
        border = "rounded",
        preview = { border = "rounded" },
      },
    },
  },
}
