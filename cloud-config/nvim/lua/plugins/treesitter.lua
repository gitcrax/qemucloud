-- treesitter.lua — syntax highlighting (stable v0.8 API, precompiled parsers, no tree-sitter CLI needed)
return {
  {
    "nvim-treesitter/nvim-treesitter",
    version = "v0.10.0", -- pinned stable: last release with old config API (no tree-sitter CLI needed)
    build = ":TSUpdate",
    main = "nvim-treesitter.configs",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      ensure_installed = {
        "lua", "vim", "vimdoc",
        "html", "css", "javascript", "typescript", "tsx",
        "json", "php", "python", "markdown", "yaml", "bash",
      },
      highlight = { enable = true },
      indent = { enable = true },
    },
  },
}