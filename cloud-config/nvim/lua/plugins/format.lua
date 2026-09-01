-- format.lua — conform.nvim (format on save, lightweight)
return {
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "Format", "FormatWrite" },
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        javascript = { "prettierd" },
        typescript = { "prettierd" },
        javascriptreact = { "prettierd" },
        typescriptreact = { "prettierd" },
        html = { "prettierd" },
        css = { "prettierd" },
        json = { "prettierd" },
        markdown = { "prettierd" },
        python = { "ruff_format" },
        php = { "php-cs-fixer" },
      },
      format_on_save = {
        timeout_ms = 2000,
        lsp_format = "fallback", -- use LSP formatter if no conform tool
      },
    },
    config = function(_, opts)
      require("conform").setup(opts)
      vim.keymap.set("n", "<leader>F", function()
        require("conform").format({ lsp_format = "fallback", async = true })
      end, { noremap = true, silent = true, desc = "Format buffer" })
    end,
  },
}
