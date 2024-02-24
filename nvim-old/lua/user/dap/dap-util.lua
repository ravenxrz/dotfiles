local M = {}
local dap = require 'dap'

-- refresh config
M.reload_continue = function()
  package.loaded['user.dap.dap-config'] = nil
  require('user.dap.dap-config').setup()
  dap.continue()
end

-- support passing args
M.find_next_start = function(str, cur_idx)
  while cur_idx <= #str and str:sub(cur_idx, cur_idx) == ' ' do
    cur_idx = cur_idx + 1
  end
  return cur_idx
end

--  vim.fn.split(argument_string, " ", true)
M.str2argtable = function(str)
  -- trim spaces
  str = string.gsub(str, '^%s*(.-)%s*$', '%1')
  local arg_list = {}

  local start = 1
  local i = 1
  local quote_refs_cnt = 0
  while i <= #str do
    local c = str:sub(i, i)
    if c == '"' then
      quote_refs_cnt = quote_refs_cnt + 1
      start = i
      i = i + 1
      -- find next quote
      while i <= #str and str:sub(i, i) ~= '"' do
        i = i + 1
      end
      if i <= #str then
        quote_refs_cnt = quote_refs_cnt - 1
        arg_list[#arg_list + 1] = str:sub(start, i)
        start = M.find_next_start(str, i + 1)
        i = start
      end
      -- find next start
    elseif c == ' ' then
      arg_list[#arg_list + 1] = str:sub(start, i - 1)
      start = M.find_next_start(str, i + 1)
      i = start
    else
      i = i + 1
    end
  end

  -- add last arg if possiable
  if start ~= i and quote_refs_cnt == 0 then
    arg_list[#arg_list + 1] = str:sub(start, i)
  end
  return arg_list
end


-- persist breakpoint
local bp_base_dir = os.getenv("HOME") .. "/.cache/dap-breakpoint/"
local breakpoints = require('dap.breakpoints')
local utils = require("user.utils")

function M.store_breakpoints()
  if not utils.exists(bp_base_dir) then
    os.execute("mkdir -p " .. bp_base_dir)
  end

  -- save current buffer breakpoints
  local bps = {}
  local breakpoints_by_buf = breakpoints.get()
  for buf, buf_bps in pairs(breakpoints_by_buf) do
    if buf == vim.api.nvim_buf_get_number(0) then
      bps[vim.api.nvim_buf_get_name(buf)] = buf_bps
    end
  end

  -- build bps json file
  local buf_name = vim.api.nvim_buf_get_name(0)
  buf_name = buf_name:gsub("/", "-")
  local fp = io.open(bp_base_dir .. buf_name:sub(2, #buf_name) .. '.json', 'w')

  -- write bps into json file
  local json_str = vim.fn.json_encode(bps)
  if json_str ~= nil then
    fp:write(json_str)
  end
  fp:close()
end

function M.load_breakpoints()
  -- build bps json file
  local buf_name = vim.api.nvim_buf_get_name(0)
  buf_name = buf_name:gsub("/", "-")
  local fp = io.open(bp_base_dir .. buf_name:sub(2, #buf_name) .. '.json', 'r')
  if fp == nil then
    return
  end

  -- read breakpoints from json file
  local content = fp:read('*a')
  local bps = vim.fn.json_decode(content)
  for bufname, buf_bps in pairs(bps) do
    if vim.api.nvim_buf_get_name(0) == bufname then
      local bufnr = vim.api.nvim_buf_get_number(0)
      for _, bp in pairs(buf_bps) do
        local line = bp.line
        local opts = {
          condition = bp.condition,
          log_message = bp.logMessage,
          hit_condition = bp.hitCondition
        }
        breakpoints.set(opts, bufnr, line)
      end
    end
  end
end

return M
