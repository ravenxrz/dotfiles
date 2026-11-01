local M = {}

local directions = {
  left = { wincmd = "h", tmux_command = "NvimTmuxNavigateLeft" },
  down = { wincmd = "j", tmux_command = "NvimTmuxNavigateDown" },
  up = { wincmd = "k", tmux_command = "NvimTmuxNavigateUp" },
  right = { wincmd = "l", tmux_command = "NvimTmuxNavigateRight" },
}

local function herdr_binary()
  local binary = vim.env.HERDR_BIN_PATH
  if binary and binary ~= "" and vim.fn.executable(binary) == 1 then
    return binary
  end

  binary = vim.fn.exepath("herdr")
  if binary ~= "" then
    return binary
  end
end

function M.navigate(direction)
  local target = directions[direction]
  if not target then
    error("unknown navigation direction: " .. tostring(direction))
  end

  local previous_window = vim.api.nvim_get_current_win()
  vim.cmd("wincmd " .. target.wincmd)
  if vim.api.nvim_get_current_win() ~= previous_window then
    return
  end

  local pane_id = vim.env.HERDR_PANE_ID
  if pane_id and pane_id ~= "" then
    local binary = herdr_binary()
    if not binary then
      vim.notify("herdr executable not found", vim.log.levels.ERROR)
      return
    end

    vim.fn.system({
      binary,
      "pane",
      "focus",
      "--direction",
      direction,
      "--pane",
      pane_id,
    })
    if vim.v.shell_error ~= 0 then
      vim.notify("failed to focus Herdr pane: " .. direction, vim.log.levels.ERROR)
    end
    return
  end

  if vim.fn.exists(":" .. target.tmux_command) == 2 then
    vim.cmd(target.tmux_command)
  end
end

return M
