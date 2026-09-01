-- lsp.lua — LSP via modern vim.lsp.config API (nvim 0.11+, no deprecated framework)
return {
  -- LSP installer
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    build = ":MasonUpdate",
    opts = {
      ui = { border = "rounded", icons = { package_installed = "✓", package_pending = "➜", package_uninstalled = "✗" } },
    },
  },
  -- core LSP client config
  {
    "neovim/nvim-lspconfig",
    dependencies = { "williamboman/mason.nvim" },
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local function on_attach(_, bufnr)
        local map = vim.keymap.set
        local opts = { buffer = bufnr, noremap = true, silent = true }
        map("n", "gd", vim.lsp.buf.definition, opts)
        map("n", "gr", vim.lsp.buf.references, opts)
        map("n", "K", vim.lsp.buf.hover, opts)
        map("n", "<leader>rn", vim.lsp.buf.rename, opts)
        map("n", "<leader>ca", vim.lsp.buf.code_action, opts)
        map("n", "<leader>F", function()
          vim.lsp.buf.format({ async = true })
        end, opts)
      end

      -- language servers: name -> extra settings (binaries installed directly)
      local servers = {
        lua_ls = {},                                    -- pacman: lua-language-server
        ts_ls = {},                                     -- npm: typescript-language-server
        html = {},                                      -- npm: vscode-langservers-extracted
        cssls = {},                                     -- npm: vscode-langservers-extracted
        jsonls = {},                                    -- npm: vscode-langservers-extracted
        pyright = { settings = { pyright = { analysis = { typeCheckingMode = "basic" } } } }, -- npm: pyright
        phpactor = { cmd = { "/root/.config/composer/vendor/bin/phpactor", "language-server" } }, -- composer
      }

      for name, cfg in pairs(servers) do
        vim.lsp.config(name, {
          cmd = cfg.cmd,
          settings = cfg.settings or {},
          on_attach = on_attach,
        })
        vim.lsp.enable(name)
      end
    end,
  },
}