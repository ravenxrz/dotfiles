return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    { "nvim-telescope/telescope-fzf-native.nvim", enabled = vim.fn.executable "make" == 1, build = "make" },
  },
  cmd = "Telescope",
  opts = function()
    local my_actions = {}
    my_actions.top = function(prompt_bufnr) vim.cmd ":normal! zt" end
    local transform_mod = require("telescope.actions.mt").transform_mod
    my_actions = transform_mod(my_actions)

    local actions = require "telescope.actions"
    local get_icon = require("astronvim.utils").get_icon
    return {
      defaults = {
        git_worktrees = vim.g.git_worktrees,
        prompt_prefix = get_icon("Selected", 1),
        selection_caret = get_icon("Selected", 1),
        path_display = { "truncate" },
        sorting_strategy = "ascending",
        wrap_result = true,
        layout_config = {
          horizontal = { prompt_position = "top", preview_width = 0.55 },
          vertical = { mirror = false },
          -- width = 0.87,
          -- height = 0.80,
          width = 0.99,
          height = 0.99,
          preview_cutoff = 120,
        },
        mappings = {
          i = {
            ["<C-n>"] = actions.cycle_history_next,
            ["<C-p>"] = actions.cycle_history_prev,
            ["<C-j>"] = actions.move_selection_next,
            ["<C-k>"] = actions.move_selection_previous,
            ["<C-h>"] = actions.select_horizontal + my_actions.top,
            ["<C-v>"] = actions.select_vertical + my_actions.top,
            ["<CR>"] = actions.select_default + my_actions.top,
          },
          n = {
            q = actions.close,
            ["<C-n>"] = actions.cycle_history_next,
            ["<C-p>"] = actions.cycle_history_prev,
            ["<C-j>"] = actions.move_selection_next,
            ["<C-k>"] = actions.move_selection_previous,
            ["<C-h>"] = actions.select_horizontal + my_actions.top,
            ["<C-v>"] = actions.select_vertical + my_actions.top,
            ["<CR>"] = actions.select_default + my_actions.top,
          },
        },
      },
      -- pickers = {
      --   find_files = {
      --     cmd = "rg --files | rg ",
      --   }
      -- }
    }
  end,
  config = require "plugins.configs.telescope",
}
