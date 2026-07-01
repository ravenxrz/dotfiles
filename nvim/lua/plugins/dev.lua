return {
  {
    dir = vim.fn.stdpath("config"),
    name = "ai-review.nvim",
    dependencies = {
      "lewis6991/gitsigns.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    keys = {
      { "<leader>ar", function() require("ai_review").toggle() end, desc = "AI Review" },
    },
    config = function()
      require("ai_review").setup({
        sidebar = {
          side = "left",
          width = 50,
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
