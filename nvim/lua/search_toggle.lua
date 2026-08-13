local M = {}

M.current_search_mode = "Project"

local search_root_cache = {}
local custom_search_root = nil

local always_exclude_globs = {
  "!**/.git/**",
}

-- grug-far 默认在 Files Filter 里排除的目录/文件（每行一个 glob）。
-- 因为 grug-far 用了 --no-config 不再读 ~/.ripgreprc，这里用来补回常见的
-- 忽略项；需要搜某个目录时，直接在 grug-far 面板的 Files Filter 删掉对应行即可。
local default_grug_far_files_filter = {
  "!**/.git/**",
  "!**/third_party/**",
  "!**/third/**",
  "!**/build/**",
  "!**/.cache/**",
  "!**/.tmp/**",
}

local function get_exclude_globs()
  return always_exclude_globs
end

function M.get_files_filter(existing)
  if existing and existing ~= "" then
    return existing
  end
  return table.concat(default_grug_far_files_filter, "\n")
end

local function normalize_path(path)
  return vim.fs.normalize(path):gsub("/+$", "")
end

local function get_auto_search_root()
  local bufname = vim.api.nvim_buf_get_name(0)
  local start_dir

  if bufname ~= "" then
    start_dir = normalize_path(vim.fs.dirname(bufname))
  else
    start_dir = normalize_path(vim.uv.cwd())
  end

  if search_root_cache[start_dir] then
    return search_root_cache[start_dir]
  end

  local git_marker = vim.fs.find(".git", {
    path = start_dir,
    upward = true,
    limit = 1,
  })[1]

  local root
  if git_marker then
    root = normalize_path(vim.fs.dirname(git_marker))
  else
    root = start_dir
  end

  search_root_cache[start_dir] = root
  search_root_cache[root] = root
  return root
end

local function get_search_root()
  return custom_search_root or get_auto_search_root()
end

local function setup_project_ripignore(root)
  local ripignore_path = root .. "/.ripignore"
  local file = io.open(ripignore_path, "r")
  if not file then
    vim.notify("Creating .ripignore at " .. root, vim.log.levels.INFO, { title = "Telescope" })
    file = io.open(ripignore_path, "w")
    if not file then
      vim.notify("Could not create .ripignore at " .. ripignore_path, vim.log.levels.ERROR, { title = "Telescope" })
      return nil
    end
    file:write("build/\n")
    file:write("third_party/\n")
    file:write(".cache/\n")
    file:write("*.idx/\n")
    file:write(".calltree*/\n")
    file:close()
  else
    file:close()
  end
  return ripignore_path
end

local function get_find_files_command(root)
  local cmd

  if M.current_search_mode == "Project" then
    local ripignore_path = setup_project_ripignore(root)
    cmd = { "rg", "--files", "--hidden", "--no-ignore", "--no-config" }
    if ripignore_path then
      table.insert(cmd, "--ignore-file=" .. ripignore_path)
    end
  elseif M.current_search_mode == "All" then
    cmd = { "rg", "--files", "--hidden", "--no-ignore", "--no-config" }
  else
    cmd = { "rg", "--files", "--hidden" }
  end

  for _, glob in ipairs(get_exclude_globs()) do
    table.insert(cmd, "--glob")
    table.insert(cmd, glob)
  end

  return cmd
end

local function get_negative_glob_patterns()
  return get_exclude_globs()
end

local function get_grep_additional_args(root, fixed_strings)
  local args = { "--hidden" }

  if M.current_search_mode == "Project" then
    local ripignore_path = setup_project_ripignore(root)
    table.insert(args, "--no-ignore")
    table.insert(args, "--no-config")
    if ripignore_path then
      table.insert(args, "--ignore-file=" .. ripignore_path)
    end
  elseif M.current_search_mode == "All" then
    table.insert(args, "--no-ignore")
    table.insert(args, "--no-config")
  end

  if fixed_strings then
    table.insert(args, "-F")
  end

  for _, glob in ipairs(get_negative_glob_patterns()) do
    table.insert(args, "--glob=" .. glob)
  end

  return args
end

local function get_visual_selection_text()
  local _, ls, cs = unpack(vim.fn.getpos("v"))
  local _, le, ce = unpack(vim.fn.getpos("."))

  ls, le = math.min(ls, le), math.max(ls, le)
  cs, ce = math.min(cs, ce), math.max(cs, ce)

  local lines = vim.api.nvim_buf_get_text(0, ls - 1, cs - 1, le - 1, ce, {})
  return table.concat(lines, "\n")
end

function M.find_files()
  local builtin = require("telescope.builtin")
  local root = get_search_root()

  builtin.find_files({
    cwd = root,
    hidden = true,
    find_command = get_find_files_command(root),
    sorting_strategy = "ascending",
    prompt_title = string.format(
      "Find Files | mode=%s | root=%s",
      M.current_search_mode,
      vim.fs.basename(root)
    ),
  })
end

function M.grep_current_word()
  local root = get_search_root()
  local text = vim.trim(vim.fn.expand("<cword>"))

  if text == "" then
    return
  end

  require("telescope").extensions.live_grep_args.live_grep_args({
    cwd = root,
    search_dirs = { root },
    default_text = require("telescope-live-grep-args.helpers").quote(text),
    additional_args = get_grep_additional_args(root, true),
    sorting_strategy = "ascending",
    prompt_title = string.format(
      "Grep Word | mode=%s | root=%s",
      M.current_search_mode,
      vim.fs.basename(root)
    ),
  })
end

function M.grep_visual_selection()
  local root = get_search_root()
  local text = vim.trim(get_visual_selection_text())

  if text == "" then
    return
  end

  require("telescope").extensions.live_grep_args.live_grep_args({
    cwd = root,
    search_dirs = { root },
    default_text = require("telescope-live-grep-args.helpers").quote(text),
    additional_args = get_grep_additional_args(root, true),
    sorting_strategy = "ascending",
    prompt_title = string.format(
      "Grep Selection | mode=%s | root=%s",
      M.current_search_mode,
      vim.fs.basename(root)
    ),
  })
end

function M.live_grep()
  local builtin = require("telescope.builtin")
  local root = get_search_root()

  builtin.live_grep({
    cwd = root,
    additional_args = get_grep_additional_args(root),
    sorting_strategy = "ascending",
    prompt_title = string.format(
      "Live Grep | mode=%s | root=%s",
      M.current_search_mode,
      vim.fs.basename(root)
    ),
  })
end

function M.set_search_root()
  local auto_root = get_auto_search_root()
  local current_root = custom_search_root or auto_root

  vim.ui.input({
    prompt = "Set Telescope search root (empty = auto Git root): ",
    default = current_root,
    completion = "dir",
  }, function(input)
    if input == nil then
      return
    end

    input = vim.trim(input)
    if input == "" then
      custom_search_root = nil
      vim.notify("Telescope search root reset to auto: " .. auto_root, vim.log.levels.INFO, { title = "Telescope" })
      return
    end

    local root = normalize_path(vim.fn.expand(input))
    if vim.fn.isdirectory(root) ~= 1 then
      vim.notify("Invalid Telescope search root: " .. root, vim.log.levels.ERROR, { title = "Telescope" })
      return
    end

    custom_search_root = root
    search_root_cache[root] = root
    vim.notify("Telescope search root set to: " .. root, vim.log.levels.INFO, { title = "Telescope" })
  end)
end

function M.edit_ripignore()
  local root = get_search_root()
  local ripignore_path = setup_project_ripignore(root)
  if ripignore_path then
    vim.cmd("edit " .. vim.fn.fnameescape(ripignore_path))
  end
end

function M.set_search_mode(mode)
  M.current_search_mode = mode
  vim.notify("Telescope search mode set to: " .. mode, vim.log.levels.INFO, { title = "Telescope" })
end

-- grug-far 持久实例：整个 nvim session 复用同一个命名 buffer，退出面板时用
-- hide（关窗但不删 buffer）而不是 close，这样 search/replacement/Files Filter/
-- flags/paths 等所有输入在下次打开时原样保留，不用重填。
local GRUG_FAR_INSTANCE = "persistent"
local GRUG_FAR_WINDOW_COMMAND = "topleft split"

local function resize_grug_far_window()
  local height = math.max(1, math.floor(vim.o.lines * 2 / 3))
  vim.api.nvim_win_set_height(0, height)
end

-- 打开（或聚焦）持久 grug-far 实例。
-- prefills 只在首次创建实例时用于铺底（比如默认 Files Filter）；实例已存在时
-- 直接聚焦，保留里面的全部输入。update 用于把指定字段覆盖进已存在的实例
-- （clearOld=false，未给的字段保持不变）。
function M.open_grug_far(opts)
  opts = opts or {}
  local prefills = opts.prefills or {}
  local update = opts.update

  local grug = require("grug-far")

  if grug.has_instance(GRUG_FAR_INSTANCE) then
    local inst = grug.get_instance(GRUG_FAR_INSTANCE)
    inst:open()
    resize_grug_far_window()
    if update and next(update) ~= nil then
      inst:update_input_values(update, false)
    end
    return inst
  end

  prefills.filesFilter = M.get_files_filter(prefills.filesFilter)
  local inst = grug.open({
    instanceName = GRUG_FAR_INSTANCE,
    windowCreationCommand = GRUG_FAR_WINDOW_COMMAND,
    prefills = prefills,
  })
  resize_grug_far_window()
  return inst
end

function M.open_grug_far_with_cword()
  return M.open_grug_far({
    prefills = {
      search = vim.fn.expand("<cword>"),
    },
    update = {
      search = vim.fn.expand("<cword>"),
    },
  })
end

function M.open_grug_far_with_visual_selection()
  local lines = require("grug-far").get_current_visual_selection_lines(true) or {}
  local text = table.concat(lines, "\n")
  return M.open_grug_far({
    prefills = {
      search = text,
    },
    update = {
      search = text,
    },
  })
end

function M.open_search_menu()
  local options = {
    "Default(使用全局+Git的忽略规则)",
    "Project(项目目录下的ripignore)",
    "All(不忽略)",
    "Set Search Root",
    "Edit .ripignore",
  }

  vim.ui.select(options, { prompt = "Search menu:" }, function(choice)
    if not choice then
      return
    end

    if choice == "Set Search Root" then
      M.set_search_root()
    elseif choice == "Edit .ripignore" then
      M.edit_ripignore()
    else
      M.set_search_mode(string.match(choice, "^%w+"))
    end
  end)
end

return M
