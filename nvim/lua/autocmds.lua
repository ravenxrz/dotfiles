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

-- grug-far set fixed-string shortcut
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("my-grug-far-custom-keybinds", { clear = true }),
  pattern = { "grug-far" },
  callback = function(args)
    local buf = args.buf

    vim.keymap.set("n", "<localleader>w", function()
      local state = unpack(require("grug-far").toggle_flags({ "--fixed-strings" }))
      vim.notify("grug-far: toggled --fixed-strings " .. (state and "ON" or "OFF"))
    end, { buffer = true })

    -- grug-far inputs (Search/Replace/Filter/...) are single-line regions delimited by
    -- extmarks. Pasting a linewise / multi-line register there spills across physical
    -- lines and overflows into the next input (e.g. Files Filter). Two culprits:
    --   1. grug-far's own paste handler mishandles linewise registers.
    --   2. our global `keymap("v","p",'"_dP')` (keymaps.lua) hijacks visual paste: `"_d`
    --      deletes the selection, then `P` pastes the linewise register as new lines.
    -- Observed: normal `p` is fine, only visual (select-then-paste) breaks.
    -- Fix:
    --   * normal p/P  -> flatten the register to a single charwise line, then paste.
    --   * visual p/P  -> deterministic buffer edit (replace the selection with the
    --     flattened text via nvim_buf_set_text), bypassing native paste / "_dP /
    --     grug-far's fallback entirely so nothing can turn it into multiple lines.
    -- Maps are set in vim.schedule so they are registered after grug-far binds its own
    -- keymaps and therefore win.
    local function in_input_region()
      local ok, inst = pcall(function()
        return require("grug-far.instances").get_instance(0)
      end)
      if not ok or not inst then
        -- default to treating it as an input so we still fix the reported case
        return true
      end
      local ok_row, header = pcall(function()
        return require("grug-far.inputs").getHeaderRow(inst._context, inst._buf)
      end)
      if not ok_row or not header then
        return true
      end
      return (vim.fn.line(".") - 1) < header
    end

    -- normal-mode paste: flatten a linewise / multi-line register to one charwise line.
    local function normal_paste(key)
      return function()
        local reg = vim.v.register
        local content = vim.fn.getreg(reg)
        local regtype = vim.fn.getregtype(reg)
        local flattened = false
        if in_input_region() and (regtype:sub(1, 1) == "V" or content:find("[\r\n]")) then
          -- drop trailing newline(s) outright; turn interior newlines into spaces
          vim.fn.setreg(reg, (content:gsub("[\r\n]+$", ""):gsub("[\r\n]+", " ")), "c")
          flattened = true
        end
        pcall(vim.cmd, "normal! \"" .. reg .. key)
        if flattened then
          vim.schedule(function()
            vim.fn.setreg(reg, content, regtype)
          end)
        end
      end
    end

    -- visual-mode paste: replace the selection with flattened text via a direct buffer
    -- edit. This never routes through native paste, so the linewise register and the
    -- global "_dP map cannot spill it onto extra lines.
    local function visual_paste(before)
      return function()
        local reg = vim.v.register
        local content = vim.fn.getreg(reg)
        local mode = vim.fn.mode()
        local vpos = vim.fn.getpos("v")
        local cpos = vim.fn.getpos(".")
        local srow, scol = vpos[2], vpos[3]
        local erow, ecol = cpos[2], cpos[3]
        if srow > erow or (srow == erow and scol > ecol) then
          srow, scol, erow, ecol = erow, ecol, srow, scol
        end
        -- leave visual mode before editing
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)

        if not in_input_region() then
          -- results region: keep native visual paste behaviour
          vim.cmd("normal! gv\"" .. reg .. (before and "P" or "p"))
          return
        end

        local flat = content:gsub("[\r\n]+$", ""):gsub("[\r\n]+", " ")
        if mode == "V" or srow ~= erow then
          -- whole-line (or multi-line) selection inside a single-line input: replace the
          -- start line's text entirely.
          local line = vim.api.nvim_buf_get_lines(0, srow - 1, srow, false)[1] or ""
          vim.api.nvim_buf_set_text(0, srow - 1, 0, srow - 1, #line, { flat })
          vim.api.nvim_win_set_cursor(0, { srow, #flat })
        else
          -- charwise selection within one line: replace [scol, ecol] inclusive.
          local line = vim.api.nvim_buf_get_lines(0, srow - 1, srow, false)[1] or ""
          local a = math.min(scol - 1, #line)
          local b = math.min(ecol, #line)
          if b < a then b = a end
          vim.api.nvim_buf_set_text(0, srow - 1, a, srow - 1, b, { flat })
          vim.api.nvim_win_set_cursor(0, { srow, a + #flat })
        end
      end
    end

    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(buf) then
        return
      end
      local o = { buffer = buf, nowait = true, silent = true }
      vim.keymap.set("n", "p", normal_paste("p"), o)
      vim.keymap.set("n", "P", normal_paste("P"), o)
      -- map both x (visual) and v (visual+select) to reliably override the global "_dP
      vim.keymap.set("x", "p", visual_paste(false), o)
      vim.keymap.set("x", "P", visual_paste(true), o)
    end)
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

