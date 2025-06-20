--
-- list coredump files under specific dir
-- provide a select ui for user
--

local core_dump_dir = "/opt/tiger/cores"

-- 获取项目根目录
local function get_project_root()
  local output = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null")
  if vim.v.shell_error ~= 0 then
    print("Error: Not in a git repository")
    return nil
  end
  return vim.fn.trim(output)
end

-- 获取build目录路径
local function get_build_dir()
  local project_root = get_project_root()
  if not project_root then
    return nil
  end
  return project_root .. "/build"
end

-- 从文件名中提取时间戳
local function extract_timestamp(filename)
  local timestamp = string.match(filename, "elf%.(%d+)%.")
  return timestamp and tonumber(timestamp) or 0
end

-- 获取目录下所有以elf开头的文件并按时间戳排序
local function get_elf_files()
  local elf_files = {}
  local file = io.popen("ls " .. core_dump_dir .. "/elf* 2>/dev/null")
  if file then
    for line in file:lines() do
      table.insert(elf_files, line)
    end
    file:close()
  end

  -- 按时间戳倒序排序（最新的在前）
  table.sort(elf_files, function(a, b)
    return extract_timestamp(a) > extract_timestamp(b)
  end)

  return elf_files
end

-- 根据elf文件查找对应的core文件
local function find_matching_core(elf_file)
  local timestamp = extract_timestamp(elf_file)
  if not timestamp then
    return nil
  end

  -- 构建core文件路径
  local core_file = elf_file:gsub("elf%.", "core.")

  -- 检查文件是否存在
  if vim.fn.filereadable(core_file) == 1 then
    return core_file
  end

  return nil
end

-- 获取文件的绝对路径
local function get_absolute_path(file_path)
  if vim.fn.isdirectory(file_path) == 1 then
    return vim.fn.fnamemodify(file_path, ":p")
  else
    return vim.fn.fnamemodify(file_path, ":p:h") .. "/" .. vim.fn.fnamemodify(file_path, ":t")
  end
end

-- 获取build目录下所有test开头的可执行文件
local function get_test_executables()
  local build_path = get_build_dir()
  if not build_path then
    return {}
  end

  local test_files = {}
  local cmd = string.format("find %s -type f -executable -name 'test*' 2>/dev/null", build_path)
  local file = io.popen(cmd)

  if file then
    for line in file:lines() do
      table.insert(test_files, line)
    end
    file:close()
  end

  return test_files
end


-- 创建选择列表并处理用户选择
local function select_elf_and_start_gdb()
  local elf_files = get_elf_files()
  if #elf_files == 0 then
    print("No elf files found in " .. core_dump_dir)
    return
  end

  local items = {}
  for i, elf_file in ipairs(elf_files) do
    local core_file = find_matching_core(elf_file)
    local exists = core_file and vim.fn.filereadable(core_file) == 1 and "✓" or "✗"
    local short_elf = elf_file:match("[^/]+$")
    local short_core = core_file and core_file:match("[^/]+$") or ""
    local timestamp = extract_timestamp(elf_file)
    local time_str = timestamp and os.date("%Y-%m-%d %H:%M:%S", timestamp / 1000) or "N/A"

    table.insert(items, string.format("%-3d %-40s %-40s [%s] %s",
      i, short_elf, short_core, exists, time_str))
  end

  vim.ui.select(items, {
    prompt = "Select ELF file to debug (newest first):",
    format_item = function(item)
      return item
    end,
  }, function(choice)
    if not choice then
      print("Selection cancelled")
      return
    end
    local idx = tonumber(string.match(choice, "^%d+"))
    if not idx or idx < 1 or idx > #elf_files then
      print("Invalid selection")
      return
    end
    local elf_file = elf_files[idx]
    local core_file = find_matching_core(elf_file)

    if not core_file or vim.fn.filereadable(core_file) == 0 then
      print("Matching core file not found or unreadable: " .. (core_file or "nil"))
      return
    end


    local cmd = string.format(":GdbStart gdb %s %s", elf_file, core_file)
    print(cmd)
    vim.cmd(cmd)
  end)
end


-- 创建测试程序选择列表并启动GDB
local function select_test_and_start_gdb()
  local test_files = get_test_executables()
  if #test_files == 0 then
    print("No test executables found in build directory")
    return
  end

  local items = {}
  for _, test_file in ipairs(test_files) do
    local short_name = test_file:match("[^/]+$")
    table.insert(items, short_name)
  end

  vim.ui.select(items, {
    prompt = "Select test executable to debug:",
    format_item = function(item)
      return item
    end,
  }, function(choice)
    if not choice then
      print("Selection cancelled")
      return
    end

    -- 找到所选文件名对应的完整路径
    local selected_index = nil
    for i, test_file in ipairs(test_files) do
      local short_name = test_file:match("[^/]+$")
      if short_name == choice then
        selected_index = i
        break
      end
    end

    if not selected_index then
      print("Invalid selection")
      return
    end

    local test_file = test_files[selected_index]
    local abs_path = get_absolute_path(test_file)
    -- 建议使用 gdb 10.0 版本及其以上
    local cmd = string.format(":GdbStart gdb -q %s", abs_path)
    print(cmd)
    vim.cmd(cmd)
  end)
end



-- 创建命令
vim.api.nvim_create_user_command("ElfCoreDebug", select_elf_and_start_gdb, {})
vim.api.nvim_create_user_command("GdbDebugUt", select_test_and_start_gdb, {})
