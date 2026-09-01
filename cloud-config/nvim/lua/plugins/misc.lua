-- misc.lua — small quality-of-life extras (kept minimal)
return {
  -- modern colorscheme + icons (pure Lua, lightweight)
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("tokyonight").setup({ style = "storm", lualine_bold = true })
      vim.cmd.colorscheme("tokyonight")
    end,
  },
  {
    "nvim-tree/nvim-web-devicons",
    lazy = true,
  },
  -- git signs in gutter
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "│" },
        change = { text = "│" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
      },
      current_line_blame = false, -- keep it light
      on_attach = function(bufnr)
        vim.keymap.set("n", "<leader>gp", "<cmd>Gitsigns preview_hunk<CR>", { buffer = bufnr, desc = "Preview hunk" })
        vim.keymap.set("n", "<leader>gs", "<cmd>Gitsigns stage_hunk<CR>", { buffer = bufnr, desc = "Stage hunk" })
        vim.keymap.set("n", "<leader>gu", "<cmd>Gitsigns undo_stage_hunk<CR>", { buffer = bufnr, desc = "Unstage hunk" })
      end,
    },
  },
  -- auto pairs (brackets, quotes)
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = { check_ts = true },
  },
  -- comment toggling
  {
    "numToStr/Comment.nvim",
    keys = {
      { "gc", mode = { "n", "v" }, desc = "Toggle comment" },
      { "gb", mode = { "n", "v" }, desc = "Block comment" },
    },
    opts = {},
  },
  -- statusline (lightweight, no deps) — themed to match colorscheme
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        theme = "tokyonight",
        section_separators = { left = "", right = "" },
        component_separators = { left = "|", right = "|" },
        globalstatus = true,
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff", "diagnostics" },
        lualine_c = { "filename" },
        lualine_x = { "filetype" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
    },
  },
  -- tab/bufferline
  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    opts = {
      options = {
        diagnostics = "nvim_lsp",
        offsets = { { filetype = "NvimTree", text = "", padding = 1 } },
      },
    },
  },
  -- file explorer (mini.files - tiny, no deps, matches colorscheme)
  {
    "echasnovski/mini.files",
    keys = {
      { "<leader>n", "<cmd>MiniFiles open<CR>", desc = "Files explorer" },
      { "<leader>N", "<cmd>MiniFiles close<CR>", desc = "Close explorer" },
    },
    opts = {
      options = { permanent = true },
      window = { preview = true, width = 35 },
    },
  },
  -- indent guides
  {
    "lukas-reineke/indent-blankline.nvim",
    event = { "BufReadPre", "BufNewFile" },
    main = "ibl",
    opts = {
      indent = { char = "│" },
      scope = { enabled = true },
    },
  },
}
