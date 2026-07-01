local config = require("ai_review.config")
local git = require("ai_review.git")
local parser = require("ai_review.parser")
local state = require("ai_review.state")
local ui = require("ai_review.ui")
local highlights = require("ai_review.highlights")

local M = {}

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "AI Review" })
end

local function load_files(root)
  local diff_code, diff_lines = git.diff(root)
  if diff_code ~= 0 then
    return nil, table.concat(diff_lines, "\n")
  end
  local pending = parser.parse(diff_lines, "pending")
  -- Refresh intentionally drops accepted/rejected history so the sidebar only
  -- tracks unresolved changes for the current review pass.
  state.rejected_log = {}
  state.filter = "all"
  return parser.merge_files(pending, {}, {})
end

function M.refresh()
  local root, err = git.find_root(vim.api.nvim_buf_get_name(0))
  if not root then
    notify("Not inside a Git repository: " .. (err or ""), vim.log.levels.WARN)
    return
  end
  state.reset_for_root(root)
  local files, load_err = load_files(root)
  if not files then
    notify(load_err, vim.log.levels.ERROR)
    return
  end
  state.files = files
  ui.render()
end

function M.open()
  local root, err = git.find_root(vim.api.nvim_buf_get_name(0))
  if not root then
    notify("Not inside a Git repository: " .. (err or ""), vim.log.levels.WARN)
    return
  end
  state.reset_for_root(root)
  ui.ensure_sidebar()
  M.refresh()
  ui.focus()
end

function M.close()
  ui.close()
end

function M.toggle()
  if state.sidebar_win and vim.api.nvim_win_is_valid(state.sidebar_win) then
    M.close()
  else
    M.open()
  end
end

function M.setup(opts)
  config.setup(opts)
  highlights.setup()

  vim.api.nvim_create_user_command("AiReviewOpen", M.open, {})
  vim.api.nvim_create_user_command("AiReviewClose", M.close, {})
  vim.api.nvim_create_user_command("AiReviewToggle", M.toggle, {})
  vim.api.nvim_create_user_command("AiReviewRefresh", M.refresh, {})
end

return M
