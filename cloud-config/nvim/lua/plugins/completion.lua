-- completion.lua — blink.cmp (fast, lightweight, LSP+snippet support)
return {
  {
    "saghen/blink.cmp",
    version = "*",
    event = "InsertEnter",
    dependencies = { "rafamadriz/friendly-snippets" },
    opts = {
      keymap = {
        preset = "default",
        ["<C-space>"] = { "show", "hide" },
        ["<C-e>"] = { "hide" },
        ["<Tab>"] = { "select_and_accept" },
      },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
        providers = {
          lsp = { name = "LSP", module = "blink.cmp.sources.lsp" },
          path = { name = "Path", module = "blink.cmp.sources.path", score_offset = 3 },
          snippets = { name = "Snippets", module = "blink.cmp.sources.snippets" },
          buffer = { name = "Buffer", module = "blink.cmp.sources.buffer", score_offset = -2 },
        },
      },
      appearance = {
        use_nvim_cmp_as_default = false,
        nerd_font_variant = "mono",
      },
      completion = {
        accept = { auto_brackets = { enabled = true } },
        list = { selection = { preselect = false, auto_insert = false } },
        documentation = { auto_show = true, window = { border = "rounded" } },
      },
      signature = { enabled = true, window = { border = "rounded" } },
    },
  },
}
