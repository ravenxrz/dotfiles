return {
  "nvim-telescope/telescope-live-grep-args.nvim",
  -- dependencies = {
  --   { "nvim-telescope/telescope.nvim" },
  -- },
  lazy = false,
  config = function() require("telescope").load_extension "live_grep_args" end,
}
