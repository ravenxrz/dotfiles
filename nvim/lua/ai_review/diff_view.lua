local state = require("ai_review.state")
local highlights = require("ai_review.highlights")

local M = {
  ns = nil,
  buf = nil,
  mark_id = nil,
  hunk = nil,
}

local function ensure_ns()
  if not M.ns then
    M.ns = vim.api.nvim_create_namespace("ai_review_diff_view")
  end
  return M.ns
end

local function is_valid_buf(buf)
  return buf and vim.api.nvim_buf_is_valid(buf)
end

local function strip_prefix(line)
  return line:sub(2)
end

local function split_hunk(hunk)
  local original = {}
  local current = {}
  local header = hunk.header or ""

  for _, line in ipairs(hunk.patch or {}) do
    local prefix = line:sub(1, 1)
    if line:match("^@@") then
      header = line
    elseif prefix == "-" and not line:match("^%-%-%-") then
      table.insert(original, strip_prefix(line))
    elseif prefix == "+" and not line:match("^%+%+%+") then
      table.insert(current, strip_prefix(line))
    elseif prefix == " " then
      local text = strip_prefix(line)
      table.insert(original, text)
      table.insert(current, text)
    end
  end

  if #original == 0 then
    table.insert(original, "∅")
  end
  if #current == 0 then
    table.insert(current, "∅")
  end

  return header, original, current
end

local function virt_line(text, group)
  return { { text, group } }
end

local function build_virtual_lines(hunk)
  local header, original, current = split_hunk(hunk)
  local lines = {}

  table.insert(lines, virt_line(
    string.format("AI Review Diff Preview: %s  H%s  line %s  [%s]", hunk.file or "", tostring(hunk.index or "?"), tostring(hunk.new_start or "?"), hunk.status or "pending"),
    "AiReviewDiffHeader"
  ))
  if header ~= "" then
    table.insert(lines, virt_line(header, "AiReviewMuted"))
  end
  table.insert(lines, virt_line("<<<<<<< ORIGINAL", "AiReviewDiffOriginalLabel"))
  for _, line in ipairs(original) do
    table.insert(lines, virt_line(line, "AiReviewDiffOriginal"))
  end
  table.insert(lines, virt_line("======= AI / CURRENT", "AiReviewDiffCurrentLabel"))
  for _, line in ipairs(current) do
    table.insert(lines, virt_line(line, "AiReviewDiffCurrent"))
  end
  table.insert(lines, virt_line(">>>>>>> END", "AiReviewDiffEndLabel"))

  return lines
end

local function target_buffer_for_hunk(hunk)
  if not hunk or not state.root then
    return nil
  end
  local full = state.root .. "/" .. hunk.file
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_name(buf) == full then
      return buf
    end
  end
  return nil
end

function M.close()
  local ns = ensure_ns()
  if is_valid_buf(M.buf) then
    pcall(vim.api.nvim_buf_clear_namespace, M.buf, ns, 0, -1)
  end
  M.buf = nil
  M.mark_id = nil
  M.hunk = nil
end

function M.show(hunk)
  if not hunk then
    return
  end
  highlights.setup()

  -- Reuse the source buffer that actions.preview()/navigation has just opened.
  local buf = target_buffer_for_hunk(hunk) or vim.api.nvim_get_current_buf()
  if not is_valid_buf(buf) then
    return
  end

  M.close()

  local ns = ensure_ns()
  local line = math.max((hunk.new_start or 1) - 1, 0)
  local line_count = vim.api.nvim_buf_line_count(buf)
  line = math.min(line, math.max(line_count - 1, 0))

  M.mark_id = vim.api.nvim_buf_set_extmark(buf, ns, line, 0, {
    virt_lines = build_virtual_lines(hunk),
    virt_lines_above = true,
    hl_mode = "combine",
  })
  M.buf = buf
  M.hunk = hunk

  if state.sidebar_win and vim.api.nvim_win_is_valid(state.sidebar_win) then
    vim.api.nvim_set_current_win(state.sidebar_win)
  end
end

function M.refresh_if_open(hunk)
  if M.is_open() then
    M.show(hunk)
  end
end

function M.is_open()
  return is_valid_buf(M.buf) and M.mark_id ~= nil
end

return M
