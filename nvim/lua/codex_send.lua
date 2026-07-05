-- codex_send.lua
-- 把内容发送到 tmux 中运行 codex CLI 的 pane：只粘入、不提交，由用户手动回车确认。
-- 经 tmux load-buffer + bracketed paste 粘入，末尾换行被剥掉所以不会自动执行。

local M = {}

-- 底层：把一段文本粘入目标 pane
local function codex_paste(text)
  text = text:gsub('[\r\n]+$', '') -- 去掉末尾换行 -> 不提交
  if text == '' then return end
  local pane = vim.g.codex_pane or '{last}'
  local tmp = vim.fn.tempname()
  vim.fn.writefile(vim.split(text, '\n', { plain = true }), tmp)
  vim.fn.system({ 'tmux', 'load-buffer', tmp })
  vim.fn.system({ 'tmux', 'paste-buffer', '-p', '-d', '-t', pane })
  vim.fn.delete(tmp)
end

-- 发送 visual 选区的文本内容
function M.send_selection()
  local save_reg  = vim.fn.getreg('"')
  local save_type = vim.fn.getregtype('"')
  vim.cmd('noautocmd normal! "vy')
  local text = vim.fn.getreg('v')
  vim.fn.setreg('"', save_reg, save_type)
  codex_paste(text)
end

-- 发送 visual 选区的行号范围（文件路径:起始行-结束行）
function M.send_lines()
  -- 退出 visual 让 '< '> 标记生效
  vim.cmd('noautocmd normal! \27')
  local s = vim.fn.line("'<")
  local e = vim.fn.line("'>")
  if s > e then s, e = e, s end

  local path = vim.fn.expand('%')
  if path == '' then
    path = vim.api.nvim_buf_get_name(0)
  end
  -- 尽量用相对当前工作目录的路径
  local rel = vim.fn.fnamemodify(path, ':.')
  if rel == '' then rel = path end

  local ref
  if s == e then
    ref = string.format('%s:%d', rel, s)
  else
    ref = string.format('%s:%d-%d', rel, s, e)
  end
  codex_paste(ref)
end

-- 运行时切换目标 pane
function M.set_pane(pane)
  vim.g.codex_pane = pane
end

return M
