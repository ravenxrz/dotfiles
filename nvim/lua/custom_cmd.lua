--
-- copy filename / filename wo extensions/full path/breakpoint
--
local send2clipboard = function(text)
  vim.fn.setreg("+", text)
end
local copy_cur_filename = function()
  local filename = vim.fn.expand("%:t")
  send2clipboard(filename)
  print("copy filename:" .. filename)
end
local copy_cur_filename_wo_ext = function()
  local filename = vim.fn.expand("%:t")
  local filename_wo_ext = vim.fn.fnamemodify(filename, ":r")
  send2clipboard(filename_wo_ext)
  print("copy filename wo ext:" .. filename_wo_ext)
end
local copy_cur_file_path = function()
  local file_path = vim.fn.expand("%:p")
  send2clipboard(file_path)
  print("copy file path:" .. file_path)
end
local copy_cur_file_path_wo_ext = function()
  local file_path = vim.fn.expand("%:p")
  local filepath_wo_ext = vim.fn.fnamemodify(file_path, ":r")
  send2clipboard(filepath_wo_ext)
  print("copy file path wo ext:" .. filepath_wo_ext)
end
local copy_cur_breakpoint = function()
  local file_name = vim.fn.expand("%:t")
  -- get current line number
  local line_number = vim.fn.line(".")
  local breakpoint = file_name .. ":" .. line_number
  send2clipboard(breakpoint)
  print("copy breakpoint:" .. breakpoint)
end

local function get_current_function_name()
  -- 获取当前缓冲区的 ID
  local bufnr = vim.api.nvim_get_current_buf()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  row = row - 1 -- 调整为 0 索引

  local clients = vim.lsp.get_active_clients({ bufnr = bufnr })
  if #clients == 0 then
    vim.notify("No LSP client is attached to this buffer.", vi.log.levels.WARN)
    return
  end

  local params = { textDocument = vim.lsp.util.make_text_document_params(bufnr) }
  local result = nil
  for _, client in ipairs(clients) do
    result = client.request_sync("textDocument/documentSymbol", params, 2000, bufnr)
    if result and result.result then
      break
    end
  end

  if not result or not result.result then
    vim.notify("Failed to get document symbols from LSP.", vim.log.levels.WARN)
    return
  end

  local function find_function_symbol(symbols)
    local kind = vim.lsp.protocol.SymbolKind
    local expect_kind = {
      kind.Constructor,
      kind.Function,
      kind.Method,
    }
    for _, symbol in ipairs(symbols) do
      if vim.tbl_contains(expect_kind, symbol.kind) then
        local range = symbol.location and symbol.location.range or symbol.range
        if
            range
            and range.start.line <= row
            and range["end"].line >= row
            and (
              range.start.line ~= range["end"].line
              or (range.start.character <= col and range["end"].character >= col)
            )
        then
          return symbol.name
        end
      end
      if symbol.children then
        local child_result = find_function_symbol(symbol.children)
        if child_result then
          return child_result
        end
      end
    end
    return nil
  end

  local function_name = find_function_symbol(result.result)
  if function_name then
    return function_name
  else
    return nil
  end
end

local function copy_cursor_func_name()
  local func_name = get_current_function_name()
  if func_name == nil then
    return
  end
  send2clipboard(func_name)
  print("copy func_name:" .. func_name)
end

vim.api.nvim_create_user_command("CopyFileName", copy_cur_filename, {})
vim.api.nvim_create_user_command("CopyFileNameWoExt", copy_cur_filename_wo_ext, {})
vim.api.nvim_create_user_command("CopyFilePath", copy_cur_file_path, {})
vim.api.nvim_create_user_command("CopyFilePathWoExt", copy_cur_file_path_wo_ext, {})
vim.api.nvim_create_user_command("CopyBreakPoint", copy_cur_breakpoint, {})
vim.api.nvim_create_user_command("CopyFuncName", copy_cursor_func_name, {})

---
--- custom Make command: use docker to compile project
--- and output to quicklist(so that I can quick nagivate to the error)
---

local function get_quickfix_win_id()
  -- 获取所有窗口信息
  local wins = vim.fn.getwininfo()
  local quickfix_win_id = nil
  -- 查找 Quickfix 窗口的 ID
  for _, win in ipairs(wins) do
    if win.quickfix == 1 then
      quickfix_win_id = win.winid
      break
    end
  end
  return quickfix_win_id
end

local function is_quickfix_active(quickfix_win_id)
  return quickfix_win_id and quickfix_win_id ~= vim.api.nvim_get_current_win()
end

-- 自动刷新 Quickfix 列表可见范围到最后一行的函数
local function auto_scroll_quickfix(quickfix_win_id)
  if quickfix_win_id then
    -- 获取 Quickfix 列表的总行数
    local line_count = vim.api.nvim_buf_line_count(vim.fn.getwininfo(quickfix_win_id)[1].bufnr)
    -- 设置 Quickfix 窗口的滚动位置到最后一行
    vim.fn.setwinvar(quickfix_win_id, '&scrollbind', 0)
    vim.fn.setwinvar(quickfix_win_id, '&scl', 'yes')
    vim.api.nvim_win_set_cursor(quickfix_win_id, { line_count, 0 })
    vim.fn.setwinvar(quickfix_win_id, '&scrollbind', 1)
  end
end

local function do_make(container_name, root_path, target)
  Make.last_container_name = container_name
  Make.last_root_path = root_path
  Make.last_target = target
  local qf_open = false
  -- build the compile commands
  local docker_command = string.format(
    'docker exec %s bash -c "cd %s; make %s -j"', container_name, root_path, target)
  print(string.format("exec cmd:%s", docker_command))
  -- clear quickfix window
  vim.fn.setqflist({}, 'r')
  Make.flying_make_job_id = vim.fn.jobstart(docker_command, {
    on_exit = function(_, exit_code)
      Make.flying_make_job_id = nil
      local qwinid = get_quickfix_win_id()
      if not qf_open and exit_code == 0 then
        -- 打开 quickfix 窗口
        vim.cmd('copen')
        if is_quickfix_active(qwinid) then
          auto_scroll_quickfix(qwinid)
        end
      else
        if exit_code == 0 then
          vim.cmd("cclose")
        end
      end
      print("compile finished, with exit code", exit_code)
    end,
    -- 当有标准输出时的回调函数
    on_stdout = function(_, data)
      if data then
        -- 将标准输出数据添加到 quickfix 列表
        vim.fn.setqflist({}, 'a', { lines = data })
        if not qf_open then
          vim.cmd('copen')
          qf_open = true
        end
        local qwinid = get_quickfix_win_id()
        if is_quickfix_active(qwinid) then
          auto_scroll_quickfix(qwinid)
        end
      end
    end,
    -- 当有标准错误输出时的回调函数
    on_stderr = function(_, data)
      if data then
        -- 将标准错误输出数据添加到 quickfix 列表
        vim.fn.setqflist({}, 'a', { lines = data })
        if not qf_open then
          vim.cmd('copen')
          qf_open = true
        end
        local qwinid = get_quickfix_win_id()
        if is_quickfix_active(qwinid) then
          auto_scroll_quickfix(qwinid)
        end
      end
    end
  })
end

Make = {
  flying_make_job_id = nil,
  last_container_name = nil,
  last_root_path = nil,
  last_target = nil
}

Make.flying_make_job_id = nil
vim.api.nvim_create_user_command("Make", function(opts)
  if Make.flying_make_job_id and vim.fn.jobwait({ Make.flying_make_job_id }, 0)[1] == -1 then
    vim.notify('There is already a job running with ID: ' .. Make.flying_make_job_id, vim.log.levels.ERROR)
    return
  end

  -- setup args
  local args = vim.split(opts.args, ' ', { trimempty = true })
  if #args < 2 then
    vim.notify('Make command requires at least 2 arguments: container_name and compile_root_path', vim.log.levels.ERROR)
    return
  end
  local container_name = args[1]
  local root_path = args[2]
  local target = #args > 2 and args[3] or ''
  if root_path:sub(1, 1) ~= '/' then
    -- 相对路径
    local cwd = vim.fn.getcwd()
    root_path = cwd .. '/' .. root_path
  end
  do_make(container_name, root_path, target)
end, {
  nargs = '+'
})

vim.api.nvim_create_user_command("MakeSelect", function(opts)
  local container_name
  local root_path

  -- setup args
  local args = vim.split(opts.args, ' ', { trimempty = true })
  if # args == 0 and Make.last_container_name ~= nil and Make.last_root_path ~= nil then
    container_name = Make.last_container_name
    root_path = Make.last_root_path
  elseif #args == 2 then
    container_name = args[1]
    root_path = args[2]
    if root_path:sub(1, 1) ~= '/' then
      -- 相对路径
      local cwd = vim.fn.getcwd()
      root_path = cwd .. '/' .. root_path
    end
  else
    vim.notify('MakeSelect command requires 2 arguments: container_name and compile_root_path', vim.log.levels.ERROR)
    return
  end

  local cmd = string.format("docker exec %s bash -c 'cd %s; cmake --build . --target help'", container_name, root_path)
  local output = vim.fn.system(cmd)
  local exit_code = vim.v.shell_error
  if exit_code ~= 0 then
    print(string.format("get targets list failed, exit_code:%d output:%s", exit_code, output))
    return
  end

  -- 解析输出，提取所有的target
  local targets = {}
  for line in output:gmatch("[^\n]+") do
    local target = line:match("^%s-%.%.%.%s+(%S+)")
    if target then
      table.insert(targets, target)
    end
  end

  -- 使用vim.ui.select供用户选择
  vim.ui.select(targets, {
    prompt = "Choose target",
  }, function(choice)
    if choice then
      do_make(container_name, root_path, choice)
    end
  end)
end, {
  nargs = '*'
})

vim.api.nvim_create_user_command("MakeLast", function(opts)
  if Make.last_container_name ~= nil and Make.last_root_path ~= nil and Make.last_target ~= nil then
    do_make(Make.last_container_name, Make.last_root_path, Make.last_target)
  else
    vim.notify("no last make info", vim.log.levels.WARN)
  end
end, {
  nargs = 0
})


vim.api.nvim_create_user_command('KillMake', function(opts)
  if Make.flying_make_job_id and vim.fn.jobwait({ Make.flying_make_job_id }, 0)[1] == -1 then
    -- kill neovim job itself
    vim.fn.jobstop(Make.flying_make_job_id)
    vim.notify('Job with ID ' .. Make.flying_make_job_id .. ' has been killed', vim.log.levels.INFO)
    Make.flying_make_job_id = nil
  end
  -- kill container compile process
  local commands_to_kill = {
    "bash -c",
    "ld",
    "cc1plus"
  }
  local container_name = nil
  if opts.args ~= nil then
    container_name = opts.args
  elseif Make.last_container_name ~= nil then
    container_name = Make.last_container_name
  else
    vim.notify("no container name", vim.log.levels.WARN)
    return
  end
  for _, command in pairs(commands_to_kill) do
    local kill_command = string.format('docker exec %s pkill -f "%s"', container_name, command)
    print(kill_command)
    vim.fn.system(kill_command)
  end
end, {
  nargs = "?",
  -- 命令的描述
  desc = 'Kill the currently running Make job'
})


---
--- cutoms run ut command:
--- find all executable files under sepcified dir path
--- provoid a select ui to user
---
local function execute_command(cmd)
  -- 拆分路径为目录和文件名
  local dir, filename = cmd:match("^(.*/)([^/]+)$")
  if not dir then
    dir = "./"
    filename = cmd
  end

  -- 生成日志文件名
  local log_file_path = dir .. filename .. ".log"

  -- 打开日志文件以写入输出
  local log_file = io.open(log_file_path, "w")
  if not log_file then
    vim.notify("open log file failed" .. log_file_path, vim.log.levels.ERROR)
    return
  end

  local buf = vim.fn.bufadd(log_file_path)
  vim.fn.bufload(buf)
  vim.api.nvim_set_current_buf(buf)
  local buffer_flush_round = 0

  local job = vim.fn.jobstart(cmd, {
    on_stdout = function(_, data)
      if data then
        for _, line in ipairs(data) do
          log_file:write(line .. "\n")
        end
        log_file:flush()
        buffer_flush_round = buffer_flush_round + 1
        if buffer_flush_round % 5 == 0 then
          vim.cmd("edit! " .. log_file_path)
        end
      end
    end,
    on_stderr = function(_, data)
      if data then
        for _, line in ipairs(data) do
          log_file:write(line .. "\n")
        end
        log_file:flush()
        if buffer_flush_round % 5 == 0 then
          vim.cmd("edit! " .. log_file_path)
        end
      end
    end,
    on_exit = function()
      log_file:close()
      vim.api.nvim_set_current_buf(buf)
    end
  })
end



vim.api.nvim_create_user_command('Run', function(opts)
  local path = opts.args
  local uv = vim.loop

  -- 检查路径是否是目录
  local stat = uv.fs_stat(path)
  if stat and stat.type == 'directory' then
    -- 查找目录下的所有可执行文件
    local files = {}
    local handle = uv.fs_scandir(path)
    if handle then
      while true do
        local name, typ = uv.fs_scandir_next(handle)
        if not name then break end
        if typ == 'file' then
          local file_path = path .. '/' .. name
          if vim.fn.executable(file_path) == 1 then
            table.insert(files, file_path)
          end
        end
      end
    end

    if #files > 0 then
      vim.ui.select(files, {
        prompt = 'Choose executable file',
      }, function(choice)
        if choice then
          print("exec file", choice)
          execute_command(choice)
        end
      end)
    else
      vim.notify('No exec files found', vim.log.levels.ERROR)
    end
  elseif stat and stat.type == 'file' and vim.fn.executable(path) == 1 then
    execute_command(path)
  else
    vim.notify('Invalid path', vim.log.levels.ERROR)
  end
end, { nargs = 1 })
