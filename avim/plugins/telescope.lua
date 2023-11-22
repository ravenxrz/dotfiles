return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    { "nvim-telescope/telescope-fzf-native.nvim", enabled = vim.fn.executable "make" == 1, build = "make" },
    { "nvim-telescope/telescope-live-grep-args.nvim" },
  },
  cmd = "Telescope",
  opts = function()
    local actions = require "telescope.actions"
    local get_icon = require("astronvim.utils").get_icon
    return {
      defaults = {
        git_worktrees = vim.g.git_worktrees,
        prompt_prefix = get_icon("Selected", 1),
        selection_caret = get_icon("Selected", 1),
        path_display = { "smart" },
        sorting_strategy = "ascending",
        layout_config = {
          horizontal = {
            prompt_position = "top" --[[ , preview_width = 0.55  ]],
          },
          vertical = { mirror = false },
          width = 0.88,
          height = 0.80,
          preview_cutoff = 120,
        },
        mappings = {
          i = {
            ["<C-n>"] = actions.cycle_history_next,
            ["<C-p>"] = actions.cycle_history_prev,
            ["<C-j>"] = actions.move_selection_next,
            ["<C-k>"] = actions.move_selection_previous,
          },
          n = { q = actions.close },
        },
      },
      pickers = {
        find_files = {
          find_command = { "fd", "--type", "f", "--strip-cwd-prefix", "-I" },
          hidden = true,
        },
      },
    }
  end,
  config = require "plugins.configs.telescope",
}
