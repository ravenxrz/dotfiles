return {
  {
    dir = vim.fn.stdpath("config"),
    name = "ai-review.nvim",
    dependencies = {
      "lewis6991/gitsigns.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    cmd = {
      "AiReviewOpen",
      "AiReviewClose",
      "AiReviewToggle",
      "AiReviewRefresh",
      "AiReviewToggleConflictDiff",
    },
    keys = {
      { "<leader>ar", function() require("ai_review").toggle() end, desc = "AI Review" },
      { "<leader>gp", function() require("ai_review.diff_view").toggle_current_hunk() end, desc = "AI Review conflict diff" },
    },
    config = function()
      require("ai_review").setup({
        sidebar = {
          side = "right",
          width = 50,
        },
        icons = {
          title = "󰚩",
          git = "",
          file = "󰈙",
          pending = "●",
          accepted = "✓",
          rejected = "✗",
          expanded = "▾",
          collapsed = "▸",
          added = "+",
          deleted = "-",
        },
        keymaps = {
          jump = { "<CR>", "o" },
          preview = "p",
          accept = { "a", "s" },
          reject = { "x", "r" },
          unstage = "u",
          accept_file = "A",
          reject_file = "X",
          unstage_file = "U",
          refresh = "R",
          filter = "F",
          help = "?",
          close = "q",
          next_hunk = "]g",
          prev_hunk = "[g",
          expand_all = "zR",
          collapse_all = "zM",
        },
        git = {
          root_cache = true,
          max_diff_lines = 20000,
        },
        submodules = {
          enabled = false,
          recursive = true,
          max_depth = nil,
          include_untracked = true,
          max_untracked_files = 200,
          max_untracked_file_size = 256 * 1024,
        },
        scanner = {
          async = true,
          concurrency = 8,
          render_debounce_ms = 80,
          git_timeout_ms = 5000,
        },
      })
    end,
  },
  {
    "ravenxrz/bookmarks.nvim",
    config = function()
      local function set_bookmark_highlight()
        vim.api.nvim_set_hl(0, "BookmarkLine", { bg = "#98FB98" })
      end

      require("bookmarks").setup()
      set_bookmark_highlight()

      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("BookmarkHighlight", { clear = true }),
        callback = set_bookmark_highlight,
      })
    end,
  },
  {
    "ravenxrz/call-graph.nvim",
    opts = {
      log_level = "info",
      reuse_buf = true, -- Whether to reuse the same buffer for call graphs generated multiple times
      auto_toggle_hl = true, -- Whether to automatically highlight
      hl_delay_ms = 200, -- Interval time for automatic highlighting
      in_call_max_depth = 99, -- Maximum search depth for incoming calls
      ref_call_max_depth = 3, -- Maximum search depth for reference calls
      export_mermaid_graph = true, -- Whether to export the Mermaid graph
    },
    cmd = { "CallGraphI", "CallGraphR", "CallGraphLog",  "CallGraphOpenMermaidGraph", "CallGraphHistory", "CallGraphO" },
    branch = "main",
  },
  {
    "ravenxrz/custom_make.nvim",
    config = function ()
        require("custom_make").setup({})
    end
  }
}
