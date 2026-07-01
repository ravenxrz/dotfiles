local config = require("ai_review.config")
local state = require("ai_review.state")
local highlights = require("ai_review.highlights")

local M = {}

local function is_valid_win(win)
  return win and vim.api.nvim_win_is_valid(win)
end

local function is_valid_buf(buf)
  return buf and vim.api.nvim_buf_is_valid(buf)
end

local function rel_root(root)
  return vim.fn.fnamemodify(root or "", ":t")
end

local function file_icon(path)
  local ok, devicons = pcall(require, "nvim-web-devicons")
  if ok then
    local icon = devicons.get_icon(path, vim.fn.fnamemodify(path, ":e"), { default = true })
    if icon and icon ~= "" then
      return icon
    end
  end
  return config.options.icons.file
end

local function visible_hunks(file)
  local filter = state.filter
  local hunks = {}
  local function add(list)
    for _, h in ipairs(list or {}) do
      table.insert(hunks, h)
    end
  end
  if filter == "all" or filter == "pending" then add(file.pending) end
  if filter == "all" or filter == "accepted" then add(file.accepted) end
  if filter == "all" or filter == "rejected" then add(file.rejected) end
  table.sort(hunks, function(a, b)
    if a.file == b.file then
      return (a.new_start or 0) < (b.new_start or 0)
    end
    return a.file < b.file
  end)
  return hunks
end

local function status_icon(status)
  if status == "accepted" then
    return config.options.icons.accepted, "AiReviewAccepted"
  elseif status == "rejected" then
    return config.options.icons.rejected, "AiReviewRejected"
  end
  return config.options.icons.pending, "AiReviewPending"
end

local function add_highlight(buf, line, start_col, end_col, group)
  pcall(vim.api.nvim_buf_add_highlight, buf, -1, group, line, start_col, end_col)
end

function M.ensure_sidebar()
  if is_valid_win(state.sidebar_win) and is_valid_buf(state.sidebar_buf) then
    return state.sidebar_buf, state.sidebar_win
  end

  state.source_win = vim.api.nvim_get_current_win()
  local side = config.options.sidebar.side
  local width = config.options.sidebar.width
  if side == "right" then
    vim.cmd("botright vertical " .. width .. "new")
  else
    vim.cmd("topleft vertical " .. width .. "new")
  end
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_get_current_buf()
  state.sidebar_win = win
  state.sidebar_buf = buf

  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "hide"
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = "ai-review"
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].foldenable = false
  vim.wo[win].cursorline = true
  vim.wo[win].wrap = false
  vim.wo[win].winfixwidth = true
  vim.api.nvim_win_set_width(win, width)

  return buf, win
end

local function set_key(buf, lhs, rhs, desc)
  if type(lhs) == "table" then
    for _, one in ipairs(lhs) do
      set_key(buf, one, rhs, desc)
    end
    return
  end
  vim.keymap.set("n", lhs, rhs, { buffer = buf, silent = true, nowait = true, desc = desc })
end

function M.set_keymaps(buf)
  local actions = require("ai_review.actions")
  local km = config.options.keymaps
  set_key(buf, km.jump, actions.jump_or_toggle, "AI Review jump/toggle")
  set_key(buf, km.preview, actions.preview, "AI Review preview hunk")
  set_key(buf, km.accept, actions.accept_hunk, "AI Review accept hunk")
  set_key(buf, km.reject, actions.reject_hunk, "AI Review reject hunk")
  set_key(buf, km.unstage, actions.unstage_current, "AI Review unstage")
  set_key(buf, km.accept_file, actions.accept_file, "AI Review accept file")
  set_key(buf, km.reject_file, actions.reject_file, "AI Review reject file")
  set_key(buf, km.unstage_file, actions.unstage_file, "AI Review unstage file")
  set_key(buf, km.refresh, actions.refresh, "AI Review refresh")
  set_key(buf, km.filter, actions.toggle_filter, "AI Review toggle filter")
  set_key(buf, km.help, actions.help, "AI Review help")
  set_key(buf, km.close, actions.close, "AI Review close")
  set_key(buf, km.next_hunk, actions.next_hunk, "AI Review next hunk")
  set_key(buf, km.prev_hunk, actions.prev_hunk, "AI Review previous hunk")
  set_key(buf, km.expand_all, actions.expand_all, "AI Review expand all")
  set_key(buf, km.collapse_all, actions.collapse_all, "AI Review collapse all")
end

function M.close()
  pcall(function()
    require("ai_review.diff_view").close()
  end)
  if is_valid_win(state.sidebar_win) then
    vim.api.nvim_win_close(state.sidebar_win, true)
  end
  state.sidebar_win = nil
end

local function render_header(lines, line_map)
  local files, pending, accepted, rejected = state.counts()
  table.insert(lines, string.format("%s AI Review", config.options.icons.title))
  table.insert(line_map, { kind = "header" })
  table.insert(lines, string.format("%s %s", config.options.icons.git, rel_root(state.root)))
  table.insert(line_map, { kind = "header" })
  table.insert(lines, string.format("%d files  %d hunks", files, pending + accepted + rejected))
  table.insert(line_map, { kind = "header" })
  table.insert(lines, string.format("%s %d pending   %s %d accepted   %s %d rejected", config.options.icons.pending, pending, config.options.icons.accepted, accepted, config.options.icons.rejected, rejected))
  table.insert(line_map, { kind = "header" })
  table.insert(lines, "────────────────────────────────────────")
  table.insert(line_map, { kind = "header" })
  table.insert(lines, string.format("Filter: %s", state.filter))
  table.insert(line_map, { kind = "header" })
end

local function render_file(lines, line_map, file)
  local expanded = state.expanded[file.path]
  if expanded == nil then
    expanded = true
    state.expanded[file.path] = true
  end
  local arrow = expanded and config.options.icons.expanded or config.options.icons.collapsed
  local counts = string.format("+%d -%d", file.added or 0, file.deleted or 0)
  local text = string.format("%s %s %s", arrow, file_icon(file.path), file.path)
  local width = config.options.sidebar.width - #counts - 2
  if #text > width then
    text = "…" .. text:sub(#text - width + 2)
  end
  table.insert(lines, string.format("%-" .. tostring(width) .. "s %s", text, counts))
  table.insert(line_map, { kind = "file", file = file.path })

  if expanded then
    for _, hunk in ipairs(visible_hunks(file)) do
      local icon = status_icon(hunk.status)
      local line_no = hunk.status == "accepted" and hunk.new_start or math.max(hunk.new_start or 1, 1)
      local summary = hunk.summary or "changed lines"
      local max_summary = math.max(12, config.options.sidebar.width - 22)
      if #summary > max_summary then
        summary = summary:sub(1, max_summary - 3) .. "..."
      end
      table.insert(lines, string.format("  %s H%d  line %-5s %s", icon, hunk.index or 0, tostring(line_no), summary))
      table.insert(line_map, { kind = "hunk", file = file.path, hunk = hunk })
    end
  end
end

function M.render()
  highlights.setup()
  local buf = M.ensure_sidebar()
  state.line_map = {}
  local lines = {}
  render_header(lines, state.line_map)

  if not state.files or #state.files == 0 then
    table.insert(lines, "")
    table.insert(state.line_map, { kind = "empty" })
    table.insert(lines, "No Git changes found.")
    table.insert(state.line_map, { kind = "empty" })
  else
    for _, file in ipairs(state.files) do
      local has_visible = #visible_hunks(file) > 0
      if has_visible then
        table.insert(lines, "")
        table.insert(state.line_map, { kind = "space" })
        render_file(lines, state.line_map, file)
      end
    end
  end

  table.insert(lines, "")
  table.insert(state.line_map, { kind = "space" })
  table.insert(lines, "a accept  x reject  p preview  F filter  ? help")
  table.insert(state.line_map, { kind = "help" })

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.api.nvim_buf_clear_namespace(buf, -1, 0, -1)

  for i, line in ipairs(lines) do
    local idx = i - 1
    if i == 1 then
      add_highlight(buf, idx, 0, -1, "AiReviewTitle")
    elseif i == 2 then
      add_highlight(buf, idx, 0, -1, "AiReviewRoot")
    elseif line:match("^─") then
      add_highlight(buf, idx, 0, -1, "AiReviewSeparator")
    elseif line:match("pending") or line:match("Filter:") then
      add_highlight(buf, idx, 0, -1, "AiReviewStats")
    elseif state.line_map[i] and state.line_map[i].kind == "file" then
      add_highlight(buf, idx, 0, -1, "AiReviewFile")
    elseif state.line_map[i] and state.line_map[i].kind == "hunk" then
      local h = state.line_map[i].hunk
      local _, group = status_icon(h.status)
      add_highlight(buf, idx, 0, 5, group)
      add_highlight(buf, idx, 6, -1, "AiReviewMuted")
    elseif state.line_map[i] and state.line_map[i].kind == "help" then
      add_highlight(buf, idx, 0, -1, "AiReviewHelp")
    end
  end

  M.set_keymaps(buf)
end

function M.current_ref()
  local line = vim.api.nvim_win_get_cursor(0)[1]
  return state.line_map[line]
end

function M.focus()
  if is_valid_win(state.sidebar_win) then
    vim.api.nvim_set_current_win(state.sidebar_win)
  end
end

return M
