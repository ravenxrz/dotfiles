-- 检测 Python 文件的缩进并设置相应缩进
local function detect_python_indent()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" or vim.bo.buftype ~= "" or vim.fn.filereadable(path) ~= 1 then
    return
  end
  for line in io.lines(path) do
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

-- format for rust
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("rust setup", { clear = true }),
  pattern = { "rust" },
  callback = function()
    vim.keymap.set({ "n" }, "<leader>lf", "<cmd>RustFmt<cr>", { buffer = true })
    vim.keymap.set({ "v" }, "<leader>lf", ":RustFmtRange<cr>", { buffer = true })
  end,
})

-- quickfix bqf 的fzf模式调色
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("quickfix_keymaps", { clear = true }),
  pattern = "qf",
  callback = function(event)
    vim.api.nvim_set_hl(0, "qfFileName", { fg = "#1d4ed8", bold = true })
    vim.api.nvim_set_hl(0, "qfLineNr", { fg = "#92400e" })
    vim.api.nvim_set_hl(0, "qfText", { fg = "#1f2328" })

    vim.keymap.set("n", "o", "<CR><cmd>cclose<CR>", {
      buffer = event.buf,
      silent = true,
      desc = "Open quickfix item and close quickfix",
    })

    vim.keymap.set("n", "q", "<cmd>cclose<CR>", {
      buffer = event.buf,
      silent = true,
      desc = "Close quickfix",
    })
  end,
})

-- gd/gr 限定
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("cpp_navigation_keymaps", { clear = true }),
  pattern = { "c", "cpp", "objc", "objcpp", "cuda", "pov" },
  callback = function(event)
    require("cpp_navigation").setup_buffer(event.buf)
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("telescope_disable_folds", { clear = true }),
  pattern = { "TelescopePrompt", "TelescopeResults" },
  callback = function(args)
    for _, win in ipairs(vim.fn.win_findbuf(args.buf)) do
      vim.api.nvim_set_option_value("foldenable", false, { win = win })
      vim.api.nvim_set_option_value("foldmethod", "manual", { win = win })
      vim.api.nvim_set_option_value("foldexpr", "0", { win = win })
    end
  end,
})


-- Browser Markdown preview used to inject [[toc]] automatically here.
-- Keep TraeCLI/AI generated plan files unmodified for in-buffer review with
-- render-markdown.nvim; add a TOC marker manually only when browser preview
-- specifically needs one.

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("markdown_review_view", { clear = true }),
  pattern = { "markdown", "markdown.mdx" },
  callback = function(args)
    local bo = vim.bo[args.buf]
    if bo.buftype ~= "" or vim.api.nvim_buf_get_name(args.buf) == "" then
      return
    end

    -- Review-oriented defaults: keep Markdown readable inside Neovim without
    -- forcing a browser preview or mutating generated plan files.
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.breakindent = true
    vim.opt_local.breakindentopt = "shift:2,min:20"
    vim.opt_local.showbreak = "  "
    vim.opt_local.conceallevel = 2
    vim.opt_local.foldmethod = "manual"
    vim.opt_local.foldexpr = "0"

    pcall(vim.treesitter.stop, args.buf)

    -- Keep Markdown readable, but do not force Zen Mode automatically.
    -- Use <leader>zz when a centered Zen view is wanted.
  end,
})

