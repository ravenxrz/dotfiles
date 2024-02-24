-- NOTE: nvimgdb 依赖 gdb with python support
-- 检查方式为: gdb --config
-- 输出类似如下:
--with-python=/usr
--with-python-libdir=/usr/lib

-- 如果不支持python, 需要从源码编译gdb:
-- 1. 下载gdb源码: https://ftp.gnu.org/gnu/gdb/, 并解压
-- 2. ./configure --with-python
-- 3. make
-- 4. make install


vim.cmd([[
    let g:nvimgdb_disable_start_keymaps = 1
    let g:nvimgdb_use_find_executables = 0
    let g:nvimgdb_use_cmake_to_find_executables = 0
    let w:nvimgdb_termwin_command = "rightbelow vnew"
    let w:nvimgdb_codewin_command = "vnew"
    let g:nvimgdb_config_override = {
      \ 'key_next': '-n',
      \ 'key_step': '-s',
      \ 'key_finish': '-f',
      \ 'key_continue': '-c',
      \ 'key_until': '-u',
      \ 'key_breakpoint': '-b',
  \ }
]])

vim.cmd([[
  nnoremap <silent> <expr> <leader>dd ":GdbStart gdb -q " . input("debugee file path: ") . "\<ESC>"
]])

_G.GdbSessionInit = function()
  -- restore breakpoints if possible
  local utils = require("user.utils")
  if utils.exists('.bps.txt') then
    vim.defer_fn(function()
      vim.api.nvim_command(":Gdb source .bps.txt")
    end, 12000)
  end

  -- create bt & info locals window
  -- vim.api.nvim_command(":belowright GdbCreateWatch thread apply all bt")
  -- vim.api.nvim_command(":wincmd h")
  vim.api.nvim_command(":belowright GdbCreateWatch info locals")
  vim.api.nvim_command(":set wrap")


  -- move cursor back to gdb terminal
  vim.api.nvim_command(":wincmd k")
end

_G.StartGdbSession = function()
  -- start gdb sessoin
  local exec_file = vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
  vim.api.nvim_command(":GdbStart gdb -q " .. exec_file)
  vim.api.nvim_command("NvimTreeClose")
end

_G.CreateWatch = function()
  local watch_arg = vim.fn.input('Watch cmd: ')
  vim.api.nvim_command(":GdbCreateWatch " .. watch_arg)
end

-- _G.CloseWatchBuffers = function()
--   vim.defer_fn(function()
--     vim.api.nvim_command(":bd! thread info")
--   end, 10)
-- end
--
-- vim.api.nvim_set_keymap("n", "<leader>dr", "<cmd>GdbStart gdbr<cr>", {})
-- vim.api.nvim_set_keymap("n", "<leader>dd", "<cmd>lua StartGdbSession()<cr>", {})
-- vim.api.nvim_set_keymap("n", "<leader>dc", "<cmd>lua CreateWatch()<cr>", {})
-- vim.api.nvim_set_keymap("n", "<leader>dbt", "<cmd>GdbLopenBacktrace<cr>", {})
-- vim.api.nvim_set_keymap("n", "<leader>dbp", "<cmd>GdbLopenBreakpoints<cr>", {})


vim.cmd([[
  autocmd User NvimGdbStart :lua GdbSessionInit()
]])
