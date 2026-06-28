local M = {}

local function clear_telescope_prompt_if_single_a(prompt_bufnr)
  local ok, state = pcall(require, "telescope.state")
  if ok then
    local status = state.get_status(prompt_bufnr)
    if status and status.picker then
      local ok_prompt, prompt = pcall(function()
        return status.picker:_get_prompt()
      end)
      if ok_prompt then
        if prompt == "A" then
          status.picker:reset_prompt("")
          return true
        end
      end
    end
  end

  return false
end

function M.guard_initial_a()
  local started_at = vim.uv and vim.uv.now() or vim.loop.now()
  local group = vim.api.nvim_create_augroup("my-telescope-clear-initial-a", { clear = true })

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "TelescopePrompt",
    callback = function(event)
      local prompt_bufnr = event.buf

      vim.api.nvim_create_autocmd({ "TextChangedI", "CursorMovedI" }, {
        group = group,
        buffer = prompt_bufnr,
        callback = function()
          clear_telescope_prompt_if_single_a(prompt_bufnr)

          local now = vim.uv and vim.uv.now() or vim.loop.now()
          if now - started_at > 2000 then
            pcall(vim.api.nvim_del_augroup_by_id, group)
          end
        end,
      })

      for i = 1, 20 do
        vim.defer_fn(function()
          clear_telescope_prompt_if_single_a(prompt_bufnr)
        end, i * 50)
      end
    end,
  })

  for i = 1, 20 do
    vim.defer_fn(function()
      local ok, state = pcall(require, "telescope.state")
      if not ok then return end

      for _, prompt_bufnr in ipairs(state.get_existing_prompt_bufnrs()) do
        clear_telescope_prompt_if_single_a(prompt_bufnr)
      end
    end, i * 50)
  end
end

return M
