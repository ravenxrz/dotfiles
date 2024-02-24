local M = {}

M.starts_with = function(str, start)
  return str:sub(1, #start) == start
end

M.ends_with = function(str, ending)
  return ending == "" or str:sub(- #ending) == ending
end

-- file exist?
M.exists = function(file)
  local ok, err, code = os.rename(file, file)
  if not ok then
    if code == 13 then
      -- Permission denied, but it exists
      return true
    end
  end
  return ok, err
end


M.SaveAndExit = function()
  -- wirte all buffer first
  vim.api.nvim_command(":wa")
  -- quit all buffer
  vim.api.nvim_command(":qa")
end


-- gtags
M.GtagsRefernce = function()
  local word = vim.api.nvim_call_function("expand", { "<cword>" })
  vim.api.nvim_command(":cs find c " .. word)
  vim.api.nvim_command(":copen")
end

M.GtagsText = function()
  local word = vim.api.nvim_call_function("expand", { "<cword>" })
  vim.api.nvim_command(":cs find t " .. word)
  vim.api.nvim_command(":copen")
end

return M
