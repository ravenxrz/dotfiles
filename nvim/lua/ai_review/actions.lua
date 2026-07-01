local config = require("ai_review.config")
local git = require("ai_review.git")
local state = require("ai_review.state")
local ui = require("ai_review.ui")
local diff_view = require("ai_review.diff_view")

local M = {}

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "AI Review" })
end

local function current_ref()
  local ref = ui.current_ref()
  if not ref then
    notify("No review item under cursor", vim.log.levels.WARN)
  end
  return ref
end

local function find_file(path)
  for _, file in ipairs(state.files or {}) do
    if file.path == path then
      return file
    end
  end
end

local function open_file_at(hunk)
  if not hunk or not state.root then
    return false
  end
  local full = state.root .. "/" .. hunk.file
  if vim.fn.filereadable(full) == 0 then
    notify("File is not readable: " .. hunk.file, vim.log.levels.WARN)
    return false
  end
  local sidebar_win = state.sidebar_win
  local target_win = state.source_win
  if not (target_win and vim.api.nvim_win_is_valid(target_win)) or target_win == sidebar_win then
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if win ~= sidebar_win then
        target_win = win
        break
      end
    end
  end
  if target_win and vim.api.nvim_win_is_valid(target_win) then
    vim.api.nvim_set_current_win(target_win)
  end
  vim.cmd("edit " .. vim.fn.fnameescape(full))
  local line = math.max(1, hunk.new_start or 1)
  local line_count = vim.api.nvim_buf_line_count(0)
  line = math.min(line, line_count)
  vim.api.nvim_win_set_cursor(0, { line, 0 })
  vim.cmd("normal! zz")
  return true
end

local function call_gitsigns(action)
  local ok, gs = pcall(require, "gitsigns")
  if not ok then
    notify("gitsigns.nvim is not available", vim.log.levels.ERROR)
    return false
  end
  if type(gs[action]) ~= "function" then
    notify("gitsigns action not found: " .. action, vim.log.levels.ERROR)
    return false
  end
  gs[action]()
  return true
end

function M.refresh()
  diff_view.close()
  require("ai_review").refresh()
end

function M.close()
  ui.close()
end

function M.jump_or_toggle()
  local ref = current_ref()
  if not ref then return end
  if ref.kind == "file" then
    state.expanded[ref.file] = not state.expanded[ref.file]
    ui.render()
  elseif ref.kind == "hunk" then
    open_file_at(ref.hunk)
  end
end

local function reveal_hunk_keep_sidebar_focus(hunk)
  local sidebar_win = state.sidebar_win
  local ok = open_file_at(hunk)
  if ok and sidebar_win and vim.api.nvim_win_is_valid(sidebar_win) then
    vim.api.nvim_set_current_win(sidebar_win)
  end
  return ok
end

function M.preview()
  local ref = current_ref()
  if not ref or ref.kind ~= "hunk" then
    notify("Move cursor to a hunk to preview", vim.log.levels.WARN)
    return
  end
  if reveal_hunk_keep_sidebar_focus(ref.hunk) then
    diff_view.show(ref.hunk)
  end
end

function M.accept_hunk()
  local ref = current_ref()
  if not ref or ref.kind ~= "hunk" then
    notify("Move cursor to a pending hunk to accept", vim.log.levels.WARN)
    return
  end
  if ref.hunk.status ~= "pending" then
    notify("Only pending hunks can be accepted", vim.log.levels.WARN)
    return
  end

  local code, out = git.apply_hunk_to_index(state.root, ref.hunk)
  if code ~= 0 then
    notify("Failed to accept hunk:\n" .. table.concat(out, "\n"), vim.log.levels.ERROR)
    return
  end

  state.mark_hunk_status(ref.hunk, "accepted")
  diff_view.close()
  ui.render()
  ui.focus()
end

function M.reject_hunk()
  local ref = current_ref()
  if not ref or ref.kind ~= "hunk" then
    notify("Move cursor to a pending hunk to reject", vim.log.levels.WARN)
    return
  end
  if ref.hunk.status ~= "pending" then
    notify("Only pending hunks can be rejected", vim.log.levels.WARN)
    return
  end

  local rejected = vim.deepcopy(ref.hunk)
  local code, out = git.apply_reverse_hunk(state.root, rejected)
  if code ~= 0 then
    notify("Failed to reject hunk:\n" .. table.concat(out, "\n"), vim.log.levels.ERROR)
    return
  end

  state.mark_hunk_status(ref.hunk, "rejected")
  vim.cmd("checktime")
  diff_view.close()
  ui.render()
  ui.focus()
end

local function ref_file(ref)
  if not ref then return nil end
  if ref.kind == "file" then return ref.file end
  if ref.kind == "hunk" then return ref.file end
end

function M.accept_file()
  local file = ref_file(current_ref())
  if not file then
    notify("Move cursor to a file or hunk", vim.log.levels.WARN)
    return
  end
  local code, out = git.add_file(state.root, file)
  if code ~= 0 then
    notify(table.concat(out, "\n"), vim.log.levels.ERROR)
    return
  end
  require("ai_review").refresh()
end

function M.reject_file()
  local file = ref_file(current_ref())
  if not file then
    notify("Move cursor to a file or hunk", vim.log.levels.WARN)
    return
  end
  local ok = vim.fn.confirm("Reject all unstaged changes in " .. file .. "?", "&Yes\n&No", 2)
  if ok ~= 1 then return end
  local code, out = git.restore_file(state.root, file)
  if code ~= 0 then
    notify(table.concat(out, "\n"), vim.log.levels.ERROR)
    return
  end
  require("ai_review").refresh()
end

function M.unstage_file()
  local file = ref_file(current_ref())
  if not file then
    notify("Move cursor to a file or hunk", vim.log.levels.WARN)
    return
  end
  local code, out = git.unstage_file(state.root, file)
  if code ~= 0 then
    notify(table.concat(out, "\n"), vim.log.levels.ERROR)
    return
  end
  require("ai_review").refresh()
end

function M.undo_reject_hunk(hunk)
  local code, out = git.apply_hunk(state.root, hunk)
  if code ~= 0 then
    notify("Failed to undo rejected hunk:\n" .. table.concat(out, "\n"), vim.log.levels.ERROR)
    return
  end
  state.remove_rejected(hunk)
  vim.cmd("checktime")
  require("ai_review").refresh()
  ui.focus()
end

function M.unstage_current()
  local ref = current_ref()
  if not ref then return end
  if ref.kind == "hunk" and ref.hunk.status == "rejected" then
    M.undo_reject_hunk(ref.hunk)
    return
  end
  if ref.kind == "hunk" and ref.hunk.status == "accepted" then
    local code, out = git.unapply_hunk_from_index(state.root, ref.hunk)
    if code ~= 0 then
      notify("Failed to undo accepted hunk:\n" .. table.concat(out, "\n"), vim.log.levels.ERROR)
      return
    end
    state.mark_hunk_status(ref.hunk, "pending")
    diff_view.close()
    ui.render()
    ui.focus()
    return
  end
  if ref.kind == "hunk" then
    notify("Only accepted/rejected hunks can be undone with u", vim.log.levels.WARN)
    return
  end
  M.unstage_file()
end

function M.toggle_filter()
  local order = { "all", "pending", "accepted", "rejected" }
  local idx = 1
  for i, value in ipairs(order) do
    if value == state.filter then idx = i break end
  end
  state.filter = order[(idx % #order) + 1]
  ui.render()
end

function M.help()
  local lines = {
    "AI Review keys",
    "",
    "<CR>/o  jump to hunk or expand file",
    "p       preview hunk",
    "a/s     accept pending hunk",
    "x/r     reject pending hunk",
    "u       undo accepted/rejected hunk",
    "A       accept file",
    "X       reject file",
    "U       unstage file",
    "F       filter pending view",
    "R       refresh and clear processed hunks",
    "q       close sidebar",
  }
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = 48,
    height = #lines + 2,
    row = 4,
    col = math.floor((vim.o.columns - 48) / 2),
    border = "rounded",
    title = " AI Review Help ",
    style = "minimal",
  })
  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, silent = true })
end

local function move_to_hunk(delta)
  local cur = vim.api.nvim_win_get_cursor(0)[1]
  local target
  if delta > 0 then
    for line = cur + 1, #state.line_map do
      if state.line_map[line] and state.line_map[line].kind == "hunk" then
        target = line
        break
      end
    end
  else
    for line = cur - 1, 1, -1 do
      if state.line_map[line] and state.line_map[line].kind == "hunk" then
        target = line
        break
      end
    end
  end
  if target then
    vim.api.nvim_win_set_cursor(0, { target, 0 })
    local ref = state.line_map[target]
    if ref and ref.hunk then
      reveal_hunk_keep_sidebar_focus(ref.hunk)
      diff_view.show(ref.hunk)
    end
  end
end

function M.next_hunk() move_to_hunk(1) end
function M.prev_hunk() move_to_hunk(-1) end

function M.expand_all()
  for _, file in ipairs(state.files or {}) do
    state.expanded[file.path] = true
  end
  ui.render()
end

function M.collapse_all()
  for _, file in ipairs(state.files or {}) do
    state.expanded[file.path] = false
  end
  ui.render()
end

return M
