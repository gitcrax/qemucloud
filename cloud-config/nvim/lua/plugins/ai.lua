-- ai.lua — AI MENTOR (not a code-writing harness)
-- Design: guides, teaches, reviews. Does NOT write your code for you.
--   - inline (visual selection -> mentor explains WHAT's wrong, WHY, gives hints; YOU fix it)
--   - chat: ask questions, learn concepts
--   - "Mentor: check my fix" — after you redo it, mentor verifies your understanding
-- Provider: Groq (free). Needs GROQ_API_KEY in env (auto-sourced from ava profile).
return {
  {
    "olimorris/codecompanion.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = { "CodeCompanionChat", "CodeCompanionActions", "CodeCompanion" },
    keys = {
      { "<leader>a", "<cmd>CodeCompanionChat<CR>", desc = "AI mentor chat" },
      { "<leader>c", "<cmd>CodeCompanionActions<CR>", desc = "AI mentor actions" },
      { "gcm", "<cmd>CodeCompanion <CR>", desc = "Mentor review selection", mode = { "v", "n" } },
    },
    opts = {
      adapters = {
        groq = function()
          return require("codecompanion.adapters").extend("openai_compatible", {
            env = {
              api_key = "GROQ_API_KEY",
              url = "https://api.groq.com/openai/v1/chat/completions",
            },
            schema = {
              model = { default = "openai/gpt-oss-20b" },
            },
          })
        end,
      },
      strategies = {
        chat = { adapter = "groq" },
        inline = { adapter = "groq" },
      },
      tools = {
        ["fetch_webpage"] = { opts = { require_approval_before = false } },
        ["web_search"] = {
          opts = {
            adapter = "tavily",
            opts = { search_depth = "advanced", max_results = 5 },
          },
        },
      },
      display = {
        action_palette = { provider = "default" },
        chat = {
          window = { layout = "vertical", width = 0.45 },
          show_references = true,
        },
        diff = { enabled = true },
      },

      interactions = {
        chat = {
          opts = {
            -- web tools always available so the mentor checks LIVE docs
            default_tools = { "web_search", "fetch_webpage" },
            system_prompt = [[You are a senior coding MENTOR, not an autopilot. Your job is to make the user a better engineer.

GOLDEN RULES:
1. NEVER just write the answer and hand it over. Explain the concept, the why, and the trade-offs, then let the user attempt it.
2. When reviewing code: point out issues, explain WHY each is a problem (correctness, best practice, performance, readability, security), and give a hint toward the fix — never the finished fix.
3. End with one guiding question to make the user think.
4. If the user shows you an attempt: acknowledge what they did right FIRST, then gently note what can improve.
5. Teach idioms and design patterns specific to the language (PHP, Python, JS/TS, HTML/CSS) and framework (Astro, React, Next.js, etc.).
6. CURRENT-DOCS RULE: Your training may lag behind the latest framework releases. Whenever the user mentions a framework, library, or API, ALWAYS use web_search / fetch_webpage FIRST to check the official current documentation before guiding. Cite what the current docs say. Never rely on memory for version-specific APIs, config options, or CLI flags — verify.
7. Be concrete: reference exact code, line numbers, function names.
8. If the code is already good, say so plainly and explain WHY it is good, so the user learns the positive standard too.]],
          },
        },
        inline = {
          -- mentor tone comes from the prompt_library review prompts below
          keymaps = {
            accept_change = { modes = { n = "gda" }, opts = { nowait = true, noremap = true } },
            reject_change = { modes = { n = "gdr" }, opts = { nowait = true, noremap = true } },
          },
        },
      },

      prompt_library = {
        ["Mentor: teach me"] = {
          interaction = "chat",
          description = "Ask the mentor to teach a concept step by step",
          prompts = {
            { role = "user", content = "Act as my mentor. Teach me #[prompt] step by step with examples. Don't write full solutions — guide me so I can do it myself." },
          },
        },
        ["Mentor: review & guide"] = {
          interaction = "chat",
          description = "Review the current buffer and guide improvement",
          prompts = {
            { role = "user", content = "Mentor-review this code. Explain issues and why, give hints only, let me fix it. Reference exact lines. Don't paste finished code.\n\n@buffer" },
          },
        },
      },
    },
  },
}