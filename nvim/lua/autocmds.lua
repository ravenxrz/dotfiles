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


-- 禁用markdown的treessiter, 老是会报错
-- 给markdown文件注入toc，可以有导航目录
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "markdown.mdx" },
  callback = function(args)
    vim.opt_local.foldmethod = "manual"
    vim.opt_local.foldexpr = "0"

    -- markdown-preview.nvim 不依赖 Tree-sitter；这里停掉 parser 避免 markdown injections 报错。
    pcall(vim.treesitter.stop, args.buf)

    local function ensure_markdown_preview_toc()
      local lines = vim.api.nvim_buf_get_lines(args.buf, 0, -1, false)
      for _, line in ipairs(lines) do
        if line:match("^%s*%[%[toc%]%]%s*$") or line:match("^%s*%[toc%]%s*$") or line:match("^%s*%$%{toc%}%s*$") or line:match("^%s*%[%[_toc_%]%]%s*$") then
          return
        end
      end

      local insert_at = 0
      if lines[1] and lines[1]:match("^%-%-%-%s*$") then
        for i = 2, #lines do
          if lines[i]:match("^%-%-%-%s*$") or lines[i]:match("^%.%.%.%s*$") then
            insert_at = i
            break
          end
        end
      end

      vim.api.nvim_buf_set_lines(args.buf, insert_at, insert_at, false, { "[[toc]]", "" })
    end

    -- markdown-preview.nvim only renders TOC when the document contains a TOC
    -- marker. Since preview auto-starts for Markdown files, insert the marker
    -- automatically so the browser preview always has heading navigation.
    ensure_markdown_preview_toc()
  end,
})
