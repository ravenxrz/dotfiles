local search_root_cache = {}
local custom_search_root = nil

local function normalize_path(path)
  return vim.fn.fnamemodify(path, ":p"):gsub("/$", "")
end

local function is_path_inside(path, root)
  path = normalize_path(path)
  root = normalize_path(root)

  return path == root or vim.startswith(path, root .. "/")
end

local function get_auto_search_root()
  local buf_name = vim.api.nvim_buf_get_name(0)
  local start_dir = nil

  if buf_name and buf_name ~= "" then
    start_dir = vim.fn.fnamemodify(buf_name, ":p:h")
  end

  if not start_dir or start_dir == "" then
    start_dir = vim.fn.getcwd()
  end

  start_dir = normalize_path(start_dir)

  if search_root_cache[start_dir] then
    return search_root_cache[start_dir]
  end

  for _, root in pairs(search_root_cache) do
    if is_path_inside(start_dir, root) then
      search_root_cache[start_dir] = root
      return root
    end
  end

  local output = vim.fn.system({ "git", "-C", start_dir, "rev-parse", "--show-toplevel" })
  if vim.v.shell_error ~= 0 then
    search_root_cache[start_dir] = start_dir
    return start_dir
  end

  local root = normalize_path(vim.fn.trim(output))
  search_root_cache[start_dir] = root
  search_root_cache[root] = root
  return root
end

local function get_search_root()
  return custom_search_root or get_auto_search_root()
end

-- Helper function to create a project-specific .ripignore if it doesn't exist
local function setup_project_ripignore()
  local root = get_search_root()
  if not root then return nil end

  local ripignore_path = root .. '/.ripignore'
  local file = io.open(ripignore_path, "r")
  if not file then
    vim.notify("Creating .ripignore at " .. root, vim.log.levels.INFO, { title = "Telescope" })
    file = io.open(ripignore_path, "w")
    if file then
      file:write("build/\n")
      file:write("third_party/\n")
      file:write(".cache/\n")
      file:write("*.idx/\n")
      file:write(".calltree*/\n")
      file:close()
    else
      vim.notify("Error: Could not create .ripignore file at " .. ripignore_path, vim.log.levels.ERROR)
      return nil
    end
  else
    file:close()
  end
  return ripignore_path, root
end

local function get_visual_selection()
  local _, ls, cs = unpack(vim.fn.getpos("v"))
  local _, le, ce = unpack(vim.fn.getpos("."))

  ls, le = math.min(ls, le), math.max(ls, le)
  cs, ce = math.min(cs, ce), math.max(cs, ce)

  local lines = vim.api.nvim_buf_get_text(0, ls - 1, cs - 1, le - 1, ce, {})
  return vim.trim(table.concat(lines, "\n"))
end

local function get_project_vimgrep_arguments(ripignore, fixed_strings)
  local args = {
    'rg',
    '--color=never',
    '--no-heading',
    '--with-filename',
    '--line-number',
    '--column',
    '--smart-case',
    '--no-ignore',
    '--no-config',
    string.format('--ignore-file=%s', ripignore),
  }

  if fixed_strings then
    table.insert(args, '-F')
  end

  return args
end

local function get_default_vimgrep_arguments(fixed_strings)
  local args = vim.deepcopy(require("telescope.config").values.vimgrep_arguments)
  if fixed_strings then
    table.insert(args, '-F')
  end
  return args
end

local function get_all_vimgrep_arguments(fixed_strings)
  local args = {
    'rg',
    '--color=never',
    '--no-heading',
    '--with-filename',
    '--line-number',
    '--column',
    '--smart-case',
    '--no-ignore',
    '--no-config',
  }

  if fixed_strings then
    table.insert(args, '-F')
  end

  return args
end

local function get_search_hint(root)
  return "Hint: -g/参数放前面, 目录放最后"
end

local function get_find_files_hint(root)
  return "Hint: 输入文件名过滤结果"
end

local function get_title_hint(hint)
  return vim.trim((hint or ""):gsub("%s*>%s*$", ""))
end

local function get_search_title(title, root)
  return string.format("%s | path=%s", title, vim.fn.fnamemodify(root, ":~"))
end

local function set_prompt_title(prompt_bufnr, title)
  local status = require("telescope.state").get_status(prompt_bufnr)
  local picker = status and status.picker
  local border = picker and picker.layout and picker.layout.prompt and picker.layout.prompt.border

  if border then
    border:change_title(title)
  end
end

local function set_results_title(prompt_bufnr, title)
  local status = require("telescope.state").get_status(prompt_bufnr)
  local picker = status and status.picker
  local border = picker and picker.layout and picker.layout.results and picker.layout.results.border

  if border then
    border:change_title(title)
  end
end

local function attach_prompt_hint(prompt_bufnr, hint_results_title, normal_results_title, initial_text)
  local hint_visible = true

  local function update_hint()
    if not vim.api.nvim_buf_is_valid(prompt_bufnr) then return end

    local line = vim.api.nvim_buf_get_lines(prompt_bufnr, 0, 1, false)[1] or ""
    local normal_prefix = require("telescope.config").values.prompt_prefix or "> "
    local prompt_text = line:sub(#normal_prefix + 1)
    local should_show_hint = prompt_text == "" or prompt_text == initial_text

    if should_show_hint and not hint_visible then
      set_results_title(prompt_bufnr, hint_results_title)
      hint_visible = true
    elseif not should_show_hint and hint_visible then
      set_results_title(prompt_bufnr, normal_results_title)
      hint_visible = false
    end
  end

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    buffer = prompt_bufnr,
    callback = update_hint,
  })

  vim.schedule(update_hint)
end

local function add_prompt_hint(opts, hint_text, title)
  opts = opts or {}
  opts.preview = vim.tbl_deep_extend("force", opts.preview or {}, {
    treesitter = true,
  })

  local original_attach_mappings = opts.attach_mappings
  local initial_text = opts.default_text or ""
  local normal_title = title or opts.prompt_title or "Telescope"
  local hint_results_title = get_title_hint(hint_text)
  local normal_results_title = opts.results_title or "Results"
  opts.prompt_title = normal_title
  opts.results_title = hint_results_title

  opts.attach_mappings = function(prompt_bufnr, map)
    attach_prompt_hint(prompt_bufnr, hint_results_title, normal_results_title, initial_text)

    vim.schedule(function()
      set_results_title(prompt_bufnr, hint_results_title)
    end)

    if original_attach_mappings then
      return original_attach_mappings(prompt_bufnr, map)
    end

    return true
  end

  return opts
end

local function live_grep_args_with_hint(opts)
  opts = opts or {}

  local prompt_parser = require("telescope-live-grep-args.prompt_parser")
  local pickers = require("telescope.pickers")
  local sorters = require("telescope.sorters")
  local finders = require("telescope.finders")
  local make_entry = require("telescope.make_entry")
  local conf = require("telescope.config").values

  opts.auto_quoting = opts.auto_quoting == nil and true or opts.auto_quoting
  opts.mappings = opts.mappings or {}
  opts.vimgrep_arguments = opts.vimgrep_arguments or conf.vimgrep_arguments
  opts.entry_maker = opts.entry_maker or make_entry.gen_from_vimgrep(opts)
  opts.cwd = opts.cwd and vim.fn.expand(opts.cwd)
  opts.prompt_title = opts.prompt_title or "Live Grep (Args)"

  local attach_mappings = opts.attach_mappings
  opts.attach_mappings = function(prompt_bufnr, map)
    if attach_mappings and attach_mappings(prompt_bufnr, map) == false then
      return false
    end

    for mode, mappings in pairs(opts.mappings) do
      for key, action in pairs(mappings) do
        map(mode, key, action)
      end
    end

    return true
  end

  local additional_args = {}
  if opts.additional_args ~= nil then
    if type(opts.additional_args) == "function" then
      additional_args = opts.additional_args(opts)
    elseif type(opts.additional_args) == "table" then
      additional_args = opts.additional_args
    end
  end

  if opts.search_dirs then
    for i, path in ipairs(opts.search_dirs) do
      opts.search_dirs[i] = vim.fn.expand(path)
    end
  end

  local rg_opts_with_args = {
    ["-A"] = true,
    ["-B"] = true,
    ["-C"] = true,
    ["-e"] = true,
    ["-f"] = true,
    ["-g"] = true,
    ["-m"] = true,
    ["-t"] = true,
    ["-T"] = true,
    ["--after-context"] = true,
    ["--before-context"] = true,
    ["--context"] = true,
    ["--glob"] = true,
    ["--iglob"] = true,
    ["--ignore-file"] = true,
    ["--max-count"] = true,
    ["--regexp"] = true,
    ["--type"] = true,
    ["--type-not"] = true,
  }

  local function has_user_search_dir(prompt_parts)
    local positional_count = 0
    local skip_next = false

    for _, part in ipairs(prompt_parts) do
      if skip_next then
        skip_next = false
      elseif rg_opts_with_args[part] then
        skip_next = true
      elseif vim.startswith(part, "--") then
        local opt = part:match("^([^=]+)=")
        if opt and rg_opts_with_args[opt] then
          skip_next = false
        end
      elseif vim.startswith(part, "-") then
        -- flag-only or compact short option, not a search path
      else
        positional_count = positional_count + 1
        if positional_count > 1 then
          return true
        end
      end
    end

    return false
  end

  local function tbl_clone(original)
    local copy = {}
    for key, value in pairs(original) do
      copy[key] = value
    end
    return copy
  end

  local cmd_generator = function(prompt)
    if not prompt or prompt == "" then
      return nil
    end

    local args = vim.tbl_flatten({ tbl_clone(opts.vimgrep_arguments), tbl_clone(additional_args) })
    local prompt_parts = prompt_parser.parse(prompt, opts.auto_quoting)
    local search_dirs = opts.search_dirs

    if opts.force_search_root and not has_user_search_dir(prompt_parts) then
      search_dirs = { opts.force_search_root }
    end

    return vim.tbl_flatten({ args, prompt_parts, search_dirs })
  end

  pickers.new(opts, {
    prompt_title = opts.prompt_title,
    results_title = opts.results_title,
    finder = finders.new_job(cmd_generator, opts.entry_maker, opts.max_results, opts.cwd),
    previewer = conf.grep_previewer(opts),
    sorter = sorters.highlighter_only(opts),
    attach_mappings = opts.attach_mappings,
  }):find()
end

-- State for the current search mode
local M = {}

M.current_search_mode = "Project"

-- Function to set the search mode
function M.set_search_mode()
  local modes = { "Default(使用全局+Git的忽略规则)", "Project(项目目录下的ripignore)", "All(不忽略)", "Set Search Root", "Edit .ripignore" }
  vim.ui.select(modes, { prompt = "Select search mode:" }, function(choice)
    if not choice then return end

    if choice == "Set Search Root" then
      M.set_search_root()
    elseif choice == "Edit .ripignore" then
      local ripignore_path = setup_project_ripignore()
      if ripignore_path then
        vim.cmd('edit ' .. ripignore_path)
      end
    else
      -- Extract the actual mode name from the prompt text
      M.current_search_mode = string.match(choice, "^%w+")
      vim.notify("Telescope search mode set to: " .. M.current_search_mode, vim.log.levels.INFO, { title = "Telescope" })
    end
  end)
end

function M.set_search_root()
  local auto_root = get_auto_search_root()
  local current_root = custom_search_root or auto_root

  vim.ui.input({
    prompt = "Set Telescope search root (empty = auto Git root): ",
    default = current_root,
    completion = "dir",
  }, function(input)
    if input == nil then return end

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

function M.get_search_root()
  return get_search_root()
end

-- Unified search function that uses the current mode
function M.search(search_type)
  local telescope_builtin = require('telescope.builtin')
  local lga_helpers = require('telescope-live-grep-args.helpers')
  local root = get_search_root()
  local search_hint = get_search_hint(root)
  local find_files_hint = get_find_files_hint(root)

  local actions_map = {
    find_files = {
      Default = function()
        telescope_builtin.find_files(add_prompt_hint({ cwd = root }, find_files_hint, get_search_title("Find Files", root)))
      end,
      Project = function()
        local ripignore, root = setup_project_ripignore()
        if ripignore then
          telescope_builtin.find_files(add_prompt_hint({
            cwd = root,
            find_command = {
              'rg',
              '--files',
              '--hidden',
              '--no-ignore',
              '--no-config',
              string.format('--ignore-file=%s', ripignore),
              '--glob=!.git/',
            },
          }, get_find_files_hint(root), get_search_title("Find Files", root)))
        end
      end,
      All = function()
        telescope_builtin.find_files(add_prompt_hint({ cwd = root, find_command = { 'rg', '--files', '--hidden', '--no-ignore', '--no-config' } }, find_files_hint, get_search_title("Find Files", root)))
      end,
    },
    grep_word = {
      Default = function()
        local text = vim.fn.mode() == 'n' and vim.fn.expand("<cword>") or get_visual_selection()
        live_grep_args_with_hint(add_prompt_hint({
          cwd = root,
          force_search_root = root,
          default_text = lga_helpers.quote(vim.trim(text)),
          vimgrep_arguments = get_default_vimgrep_arguments(true),
        }, search_hint, get_search_title("Grep Word", root)))
      end,
      Project = function()
        local ripignore, root = setup_project_ripignore()
        if ripignore then
          local text = vim.fn.mode() == 'n' and vim.fn.expand("<cword>") or get_visual_selection()
          local opts = add_prompt_hint({
            cwd = root,
            force_search_root = root,
            default_text = lga_helpers.quote(vim.trim(text)),
            vimgrep_arguments = get_project_vimgrep_arguments(ripignore, true),
          }, get_search_hint(root), get_search_title("Grep Word", root))
          live_grep_args_with_hint(opts)
        end
      end,
      All = function()
        local text = vim.fn.mode() == 'n' and vim.fn.expand("<cword>") or get_visual_selection()
        live_grep_args_with_hint(add_prompt_hint({
          cwd = root,
          force_search_root = root,
          default_text = lga_helpers.quote(vim.trim(text)),
          vimgrep_arguments = get_all_vimgrep_arguments(true),
        }, search_hint, get_search_title("Grep Word", root)))
      end,
    },
    live_grep = {
      Default = function()
        live_grep_args_with_hint(add_prompt_hint({
          cwd = root,
          force_search_root = root,
          vimgrep_arguments = get_default_vimgrep_arguments(),
        }, search_hint, get_search_title("Live Grep", root)))
      end,
      Project = function()
        local ripignore, root = setup_project_ripignore()
        if ripignore then
          live_grep_args_with_hint(add_prompt_hint({
            cwd = root,
            force_search_root = root,
            vimgrep_arguments = get_project_vimgrep_arguments(ripignore),
          }, get_search_hint(root), get_search_title("Live Grep", root)))
        end
      end,
      All = function()
        live_grep_args_with_hint(add_prompt_hint({
          cwd = root,
          force_search_root = root,
          vimgrep_arguments = get_all_vimgrep_arguments(),
        }, search_hint, get_search_title("Live Grep", root)))
      end,
    },
  }

  if actions_map[search_type] and actions_map[search_type][M.current_search_mode] then
    actions_map[search_type][M.current_search_mode]()
  end
end

return M
