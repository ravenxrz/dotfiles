-- 检测 Python 文件的缩进并设置相应缩进
local function detect_python_indent()
  for line in io.lines(vim.fn.expand("%")) do
    local spaces = line:match("^(%s*)") -- 匹配每行开头的空格
    if spaces then
      local tabsize = #spaces           -- 计算空格数
      if tabsize > 0 then
        vim.opt_local.expandtab = true
        vim.opt_local.shiftwidth = tabsize
        vim.opt_local.softtabstop = tabsize
        vim.opt_local.tabstop = tabsize
        break -- 设置完毕后退出循环
      end
    end
  end
end
vim.api.nvim_create_augroup("DetectPythonIndent", { clear = true })
vim.api.nvim_create_autocmd("BufReadPost", {
  pattern = "*.py",
  callback = function() -- some others plugins set indent too, delay some time to let them go first
    vim.defer_fn(detect_python_indent, 10)
  end,
  group = "DetectPythonIndent",
})

-- 针对python文件（多是cd用例), 添加local keymap jo  跳转到对应的log文件
vim.api.nvim_create_augroup("PythonCDJumpToLog", { clear = true })

_edit_exist_file = function(file_path)
  if vim.fn.filereadable(file_path) == 1 then
    vim.cmd("e " .. file_path)
  else
    vim.notify("no such file:" .. file_path, vim.log.levels.WARN)
  end
end

-- jump to log file
vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  group = "PythonCDJumpToLog",
  callback = function()
    -- 为当前缓冲区设置本地键映射
    local filepath = vim.fn.expand("<afile>:p")
    local log_filepath = filepath .. ".log"
    local filename = vim.fn.expand("<afile>:t")
    -- only match cd_xxx.py CD_xxx.py tc_xxx.py TC_xxx.py
    if filename:lower():find("cd_") == 1 or filename:lower():find("tc_") == 1 then
      cmd = ':lua _edit_exist_file("' .. log_filepath .. '")<cr>'
      vim.api.nvim_buf_set_keymap(0, "n", "<leader>l", cmd, { noremap = true, silent = true })
    end
  end,
})
-- log file back to python file
vim.api.nvim_create_autocmd("BufRead", {
  pattern = "*.log",
  group = "PythonCDJumpToLog",
  callback = function()
    -- 为当前缓冲区设置本地键映射
    local log_filepath = vim.fn.expand("<afile>:p")
    if log_filepath:find("%.py.log$") then
      local py_filepath = log_filepath:gsub("%.log$", "")
      cmd = ':lua _edit_exist_file("' .. py_filepath .. '")<cr>'
      vim.api.nvim_buf_set_keymap(0, "n", "<leader>l", cmd, { noremap = true, silent = true })
    end
  end,
})

local win_focus_ignore_filetypes = { "neo-tree" }
vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  callback = function(_)
    if vim.tbl_contains(win_focus_ignore_filetypes, vim.bo.filetype) then
      vim.b.focus_disable = true
    else
      vim.b.focus_disable = false
    end
  end,
  desc = "Disable focus autoresize for FileType",
})

-- grug-far set fixed-string shortcut
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("my-grug-far-custom-keybinds", { clear = true }),
  pattern = { "grug-far" },
  callback = function()
    vim.keymap.set("n", "<localleader>w", function()
      local state = unpack(require("grug-far").toggle_flags({ "--fixed-strings" }))
      vim.notify("grug-far: toggled --fixed-strings " .. (state and "ON" or "OFF"))
    end, { buffer = true })
  end,
})

-- link.txt和日志文件自动开启wrap
vim.api.nvim_create_autocmd("BufRead", {
  pattern = { "*" },
  callback = function()
    local filename = vim.fn.expand("<afile>")
    local patterns = { "link.txt", "%.log$", "DEBUG", "INFO", "WARN", "ERROR" }
    for _, pattern in ipairs(patterns) do
      if string.match(filename, pattern) then
        vim.cmd("setlocal wrap")
        return
      end
    end
  end,
})

-- call grpah mark mode shortcuts
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("callgraph_mark_mode", { clear = true }),
  pattern = { "callgraph" },
  callback = function()
    vim.keymap.set("n", "cs", "<cmd>CallGraphMarkNode<cr>", { buffer = true })
    vim.keymap.set("n", "ce", "<cmd>CallGraphMarkEnd<cr>", { buffer = true })
    vim.keymap.set("n", "cc", "<cmd>CallGraphMarkExit<cr>", { buffer = true })
  end,
})


-- 为nvimgdb文件类型创建自动命令组
local group = vim.api.nvim_create_augroup("NVIMGDBConfig", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  pattern = "nvimgdb",
  group = group,
  callback = function()
    vim.keymap.set("t", "<C-h>", "<C-\\><C-n><C-w>h", { buffer = true, desc = "GDB → Code" })
  end,
})
