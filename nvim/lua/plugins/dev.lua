return {
  {
    "ravenxrz/bookmarks.nvim",
    config = true,
  },
  {
    "ravenxrz/call-graph.nvim",
    opts = {
      log_level = "info",
      reuse_buf = true, -- Whether to reuse the same buffer for call graphs generated multiple times
      auto_toggle_hl = true, -- Whether to automatically highlight
      hl_delay_ms = 200, -- Interval time for automatic highlighting
      in_call_max_depth = 5, -- Maximum search depth for incoming calls
      ref_call_max_depth = 3, -- Maximum search depth for reference calls
      export_mermaid_graph = true, -- Whether to export the Mermaid graph
    },
    cmd = { "CallGraphI", "CallGraphR", "CallGraphLog", "CallGraphToggleReuseBuf", "CallGraphOpenMermaidGraph" },
    branch = "main",
  },
}
