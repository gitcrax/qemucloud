-- mentor.lua — AUTO AI mentor (hints + reviews + explanations via GROQ)
-- Three behaviors:
--   1. IDLE HINT: while typing, if you pause ~2.5s, ghost-text hint appears
--      suggesting the next line. <C-y> accepts, <C-g> dismisses.
--   2. AUTO REVIEW: when you leave insert mode after writing a function,
--      the mentor reviews it in a float (what's wrong + why + hint).
--   3. EXPLAIN: visual-select code + <leader>me -> mentor explains it.
-- Model: gpt-oss-20b via GROQ. Key from env (sourced in .zshrc from ava profile).

local M = {}

local api = vim.api
local fn = vim.fn

-- ---------------------------------------------------------------- state ---
M.state = {
  hint_timer = nil,     -- debounce timer for idle hint
  hint_buf = nil,       -- buffer the hint was computed for
  hint_text = nil,      -- current ghost-text hint
  hint_extmark = nil,   -- extmark id of ghost text
  reviewing = false,    -- guard: one review at a time
  last_review_line = 0, -- last reviewed function start line
}

-- ------------------------------------------------------------- helpers ---
local function groq_url()
  return "https://api.groq.com/openai/v1/chat/completions"
end

local function groq_key()
  return os.getenv("GROQ_API_KEY") or ""
end

--- Async GROQ call. callback(text) on success, callback(nil) on failure.
---@param system string
---@param user string
---@param callback fun(text: string|nil)
local function groq(system, user, callback)
  local key = groq_key()
  if key == "" then
    vim.notify("AI mentor: GROQ_API_KEY not set", vim.log.levels.WARN)
    return
  end
  local body = vim.json.encode({
    model = "openai/gpt-oss-20b",
    temperature = 0.3,
    max_tokens = 400, -- gpt-oss spends tokens on reasoning; give it headroom
    messages = {
      { role = "system", content = system },
      { role = "user", content = user },
    },
  })
  local tmp = fn.tempname() .. ".json"
  local f = io.open(tmp, "w")
  if not f then return end
  f:write(body)
  f:close()

  local curl = "curl -s -m 20 " .. groq_url()
    .. " -H 'Authorization: Bearer " .. key .. "'"
    .. " -H 'Content-Type: application/json'"
    .. " -d @" .. tmp

  fn.jobstart({ "bash", "-lc", curl }, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      os.remove(tmp)
      if not data or #data == 0 then
        callback(nil)
        return
      end
      local ok, res = pcall(vim.json.decode, table.concat(data, ""))
      if not ok or not res or not res.choices or not res.choices[1] then
        callback(nil)
        return
      end
      local text = res.choices[1].message.content
      callback(text and text:gsub("^%s+", ""):gsub("%s+$", "") or nil)
    end,
    on_stderr = function()
      os.remove(tmp)
      callback(nil)
    end,
    on_exit = function(code)
      os.remove(tmp)
      if code ~= 0 then callback(nil) end
    end,
  })
end

--- Get current line + a bit of context around the cursor.
local function context_lines(around)
  around = around or 1
  local l = api.nvim_win_get_cursor(0)[1]
  local start = math.max(1, l - around)
  local lines = api.nvim_buf_get_lines(0, start - 1, l, false)
  return table.concat(lines, "\n"), l
end

--- Current visual selection text (normalized) + its start line.
local function selection_text()
  local mode = api.nvim_get_mode().mode
  local sline, scol, eline, ecol
  if mode:match("^[vV\u{16}]") then
    sline, scol = unpack(api.nvim_buf_get_mark(0, "<"))
    eline, ecol = unpack(api.nvim_buf_get_mark(0, ">"))
  else
    return nil
  end
  local lines = api.nvim_buf_get_lines(0, sline - 1, eline, false)
  if #lines == 0 then return nil end
  if #lines == 1 then
    lines[1] = lines[1]:sub(scol + 1, ecol)
  else
    lines[1] = lines[1]:sub(scol + 1)
    lines[#lines] = lines[#lines]:sub(1, ecol)
  end
  return table.concat(lines, "\n"), sline, eline
end

--- Nearest enclosing function node via treesitter (line-based, language-agnostic).
local function enclosing_function()
  local buf = api.nvim_get_current_buf()
  local ok_ts, parser = pcall(vim.treesitter.get_parser, buf)
  if not ok_ts or not parser then return nil end
  local lang = parser:lang()
  local l = api.nvim_win_get_cursor(0)[1]
  local root = parser:parse()[1]:root()
  local best
  local function walk(node)
    if not node then return end
    local start_line = node:start() + 1
    local end_line = node:end_() + 1
    if start_line <= l and l <= end_line then
      local kind = node:type()
      if kind:match("function") or kind:match("method") or kind:match("definition")
        or kind == "func_declaration" or kind == "function_definition"
        or kind == "method_definition" or kind == "arrow_function"
        or kind == "function_declaration" or kind == "local_function" then
        best = node
      end
      for child in node:iter_children() do
        walk(child)
      end
    end
  end
  walk(root)
  if not best then return nil end
  local lines = api.nvim_buf_get_lines(buf, best:start(), best:end_() + 1, false)
  return table.concat(lines, "\n"), best:start() + 1, lang
end

--- Open a floating window with mentor feedback.
local function mentor_float(title, text)
  local width = math.min(90, vim.o.columns)
  local height = math.min(24, math.max(1, vim.o.lines - 4))
  local buf = api.nvim_create_buf(false, true)
  local lines = vim.split(text, "\n", { plain = true })
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].filetype = "markdown"
  vim.bo[buf].modifiable = false
  local win = api.nvim_open_win(buf, true, {
    relative = "editor",
    row = math.max(1, math.floor((vim.o.lines - height) / 2)),
    col = math.max(1, math.floor((vim.o.columns - width) / 2)),
    width = width,
    height = height,
    style = "minimal",
    border = "rounded",
    title = title,
    title_pos = "center",
  })
  api.nvim_set_option_value("winhl", "NormalFloat:Normal", { win = win })
  vim.keymap.set("n", "q", function()
    if api.nvim_win_is_valid(win) then api.nvim_win_close(win, true) end
  end, { buffer = buf, nowait = true })
  -- close on leave
  api.nvim_create_autocmd({ "BufLeave" }, {
    buffer = buf,
    once = true,
    callback = function()
      if api.nvim_win_is_valid(win) then api.nvim_win_close(win, true) end
    end,
  })
end

-- ------------------------------------------------------------ 1. IDLE HINT ---
local HINT_SYSTEM = [[You are a coding mentor giving a SINGLE-line hint, not a full solution.
Look at the user's current line and what they're typing. Output ONE short continuation (max ~60 chars, no explanations, no code fences) that nudges them toward the idiomatic next step. If unclear, output nothing.]]

local function clear_hint()
  if M.state.hint_extmark and M.state.hint_buf and api.nvim_buf_is_valid(M.state.hint_buf) then
    local ns = api.nvim_create_namespace("mentor_hint")
    pcall(api.nvim_buf_del_extmark, M.state.hint_buf, ns, M.state.hint_extmark)
  end
  M.state.hint_text = nil
  M.state.hint_extmark = nil
end

local function show_hint()
  if M.state.reviewing then return end
  local buf = api.nvim_get_current_buf()
  local line, col = unpack(api.nvim_win_get_cursor(0))
  local cur_text, _ = context_lines(1)
  if cur_text:gsub("%s", "") == "" then return end

  groq(HINT_SYSTEM, "Current line:\n" .. cur_text .. "\n\nGive one short hint:", function(text)
    if not text or text == "" then return end
    -- stale guard: only show if still in insert mode on same position
    local m = api.nvim_get_mode().mode
    local l2, c2 = unpack(api.nvim_win_get_cursor(0))
    if not m:match("^i") then return end
    if l2 ~= line or c2 ~= col then return end

    clear_hint()
    local ns = api.nvim_create_namespace("mentor_hint")
    M.state.hint_buf = buf
    M.state.hint_text = text
    M.state.hint_extmark = api.nvim_buf_set_extmark(buf, ns, line - 1, col, {
      virt_text = { { " ⟶ " .. text, "Comment" } },
      virt_text_pos = "eol",
      hl_mode = "combine",
    })
    vim.notify("Hint: " .. text, vim.log.levels.INFO, { title = "Mentor" })
  end)
end

local function arm_hint()
  if M.state.hint_timer then
    pcall(fn.timer_stop, M.state.hint_timer)
    M.state.hint_timer = nil
  end
  clear_hint()
  M.state.hint_timer = fn.timer_start(2500, function()
    show_hint()
  end)
end

-- accept hint: insert text at cursor
local function accept_hint()
  if not M.state.hint_text then return nil end
  local text = M.state.hint_text
  clear_hint()
  api.nvim_put(vim.split(text, "\n", { plain = true }), "c", true, true)
  return true
end

-- -------------------------------------------------------- 2. AUTO REVIEW ---
local REVIEW_SYSTEM = [[You are a senior coding mentor. The user just finished writing a function/method.
REVIEW it: point out what's wrong or substandard and WHY (best practice, correctness, performance, readability, security). Give ONE concrete hint toward the fix. Do NOT rewrite the code. Keep it under 120 words. If it's good, say so and explain why in one line.]]

local function review_function()
  if M.state.reviewing then return end
  local code, start_line, lang = enclosing_function()
  if not code then return end
  if start_line <= M.state.last_review_line then return end -- already reviewed this one

  M.state.reviewing = true
  M.state.last_review_line = start_line
  groq(REVIEW_SYSTEM, "Language: " .. lang .. "\n\nFunction:\n" .. code, function(text)
    M.state.reviewing = false
    if text then
      mentor_float("Mentor review", text)
    end
  end)
end

-- ----------------------------------------------------- 3. EXPLAIN SELECTION ---
local EXPLAIN_SYSTEM = [[You are a senior coding mentor. Explain the selected code: what it does, how it works, why it's written this way, and any idioms or patterns. Be concise (under 150 words), concrete, reference the actual code. Do not rewrite it.]]

local function explain_selection()
  local text, sline = selection_text()
  if not text then
    vim.notify("Mentor: select code in visual mode first", vim.log.levels.WARN)
    return
  end
  groq(EXPLAIN_SYSTEM, "Code:\n" .. text, function(resp)
    if resp then
      mentor_float("Mentor explains", resp)
    end
  end)
end

-- ------------------------------------------------------------ keymaps ---
local function setup_keymaps()
  local map = vim.keymap.set
  local opts = { noremap = true, silent = true }

  -- accept / dismiss ghost hint (insert mode)
  map("i", "<C-y>", function()
    if accept_hint() then return end
    return "<C-y>"
  end, { expr = true, silent = true })
  map("i", "<C-g>", clear_hint, opts)

  -- explain selection (visual)
  map("v", "<leader>me", explain_selection, { desc = "Mentor: explain selection" })
  map("n", "<leader>me", explain_selection, { desc = "Mentor: explain current function" })

  -- manual review trigger (normal): reviews function under cursor
  map("n", "<leader>mr", review_function, { desc = "Mentor: review function" })
end

-- ------------------------------------------------------------ autocmds ---
local function setup_autocmds()
  local aug = api.nvim_create_augroup("MentorAuto", { clear = true })

  -- arm idle hint after each typed char in insert mode
  api.nvim_create_autocmd("InsertCharPre", {
    group = aug,
    callback = arm_hint,
  })

  -- clear hint on leaving insert
  api.nvim_create_autocmd("InsertLeave", {
    group = aug,
    callback = function()
      clear_hint()
      if M.state.hint_timer then
        pcall(fn.timer_stop, M.state.hint_timer)
        M.state.hint_timer = nil
      end
    end,
  })

  -- auto review when leaving insert mode (function just finished)
  api.nvim_create_autocmd("InsertLeave", {
    group = aug,
    callback = function()
      -- small delay so treesitter has parsed the new text
      fn.timer_start(600, function()
        review_function()
      end)
    end,
  })
end

-- ------------------------------------------------------------- setup ---
function M.setup()
  setup_keymaps()
  setup_autocmds()
  M.groq = groq -- expose for tests / manual use
  M.review_function = review_function
  M.explain_selection = explain_selection
  M.enclosing_function = enclosing_function
  M.mentor_float = mentor_float
  return M
end

return M
