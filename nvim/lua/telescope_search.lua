-- Helper function to create a project-specific .ripignore if it doesn't exist
local function setup_project_ripignore()
  local root = get_project_root()
  if not root then return nil end

  local ripignore_path = root .. '/.ripignore'
  local file = io.open(ripignore_path, "r")
  if not file then
    vim.notify("Creating .ripignore at " .. root, vim.log.levels.INFO, { title = "Telescope" })
    file = io.open(ripignore_path, "w")
    if file then
      file:write("build/\n")
      file:write("third_party/\n")
      file:close()
    else
      vim.notify("Error: Could not create .ripignore file at " .. ripignore_path, vim.log.levels.ERROR)
      return nil
    end
  else
    file:close()
  end
  return ripignore_path
end

-- State for the current search mode
local M = {}

M.current_search_mode = "Project"

-- Function to set the search mode
function M.set_search_mode()
  local modes = { "Default(使用全局+Git的忽略规则)", "Project(项目目录下的ripignore)", "All(不忽略)", "Edit .ripignore" }
  vim.ui.select(modes, { prompt = "Select search mode:" }, function(choice)
    if not choice then return end

    if choice == "Edit .ripignore" then
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

-- Unified search function that uses the current mode
function M.search(search_type)
  local telescope_builtin = require('telescope.builtin')
  local lga_shortcuts = require('telescope-live-grep-args.shortcuts')
  local live_grep_args = require('telescope').extensions.live_grep_args.live_grep_args

  local actions_map = {
    find_files = {
      Default = function() telescope_builtin.find_files() end,
      Project = function()
        local ripignore = setup_project_ripignore()
        if ripignore then
          local find_cmd = { 'rg', '--files', '--hidden', '--no-ignore-parent', '--no-ignore-vcs', '--no-config', string
              .format('--ignore-file=%s', ripignore) }
          telescope_builtin.find_files({ find_command = { 'rg', '--files', '--hidden', '--no-ignore-parent', '--no-ignore-vcs', '--no-config', string.format('--ignore-file=%s', ripignore) } })
        end
      end,
      All = function() telescope_builtin.find_files({ find_command = { 'rg', '--files', '--hidden', '--no-ignore', '--no-config' } }) end,
    },
    grep_word = {
      Default = function()
        if vim.fn.mode() == 'n' then
          lga_shortcuts.grep_word_under_cursor()
        else
          lga_shortcuts.grep_visual_selection()
        end
      end,
      Project = function()
        local ripignore = setup_project_ripignore()
        if ripignore then
          local opts = {
            prefix = string.format('--no-ignore --no-config --no-ignore-vcs --ignore-file %s ',
              vim.fn.shellescape(ripignore))
          }
          if vim.fn.mode() == 'n' then
            lga_shortcuts.grep_word_under_cursor(opts)
          else
            lga_shortcuts.grep_visual_selection(opts)
          end
        end
      end,
      All = function()
        local opts = { prefix = '--no-ignore --no-config --no-ignore-vsc ' }
        if vim.fn.mode() == 'n' then
          lga_shortcuts.grep_word_under_cursor(opts)
        else
          lga_shortcuts.grep_visual_selection(opts)
        end
      end,
    },
    live_grep = {
      Default = function() live_grep_args() end,
      Project = function()
        local ripignore = setup_project_ripignore()
        if ripignore then
          live_grep_args({
            vimgrep_arguments = {
              'rg',
              '--color=never',
              '--no-heading',
              '--with-filename',
              '--line-number',
              '--column',
              '--smart-case',
              '--no-ignore',
              '--no-config',
              '--no-ignore-vcs',
              string.format('--ignore-file=%s', ripignore),
            },
          })
        end
      end,
      All = function() live_grep_args({ vimgrep_arguments = { 'rg', '--color=never', '--no-heading', '--with-filename', '--line-number', '--column', '--smart-case', '--no-ignore', '--no-config', '--no-ignore-vsc' } }) end,
    },
  }

  if actions_map[search_type] and actions_map[search_type][M.current_search_mode] then
    actions_map[search_type][M.current_search_mode]()
  end
end

return M
