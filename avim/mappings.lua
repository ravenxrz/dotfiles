-- Mapping data with "desc" stored directly by vim.keymap.set().
--
-- Please use this mappings table to set keyboard mapping since this is the
-- lower level configuration and more robust one. (which-key will
-- automatically pick-up stored data by this setting.)
return {
  -- first key is the mode
  n = {
    -- second key is the lefthand side of the map

    -- navigate buffer tabs with `H` and `L`
    -- L = {
    --   function() require("astronvim.utils.buffer").nav(vim.v.count > 0 and vim.v.count or 1) end,
    --   desc = "Next buffer",
    -- },
    -- H = {
    --   function() require("astronvim.utils.buffer").nav(-(vim.v.count > 0 and vim.v.count or 1)) end,
    --   desc = "Previous buffer",
    -- },

    -- mappings seen under group name "Buffer"
    ["<leader>bD"] = {
      function()
        require("astronvim.utils.status").heirline.buffer_picker(
          function(bufnr) require("astronvim.utils.buffer").close(bufnr) end
        )
      end,
      desc = "Pick to close",
    },
    -- tables with the `name` key will be registered with which-key if it's installed
    -- this is useful for naming menus
    ["<leader>b"] = { name = "Buffers" },
    -- quick save
    ["<C-s>"] = { ":w!<cr>", desc = "Save File" }, -- change description but the same command
    -- buffer navigate
    ["R"] = {
      function() require("astronvim.utils.buffer").nav(vim.v.count > 0 and vim.v.count or 1) end,
      desc = "Next buffer",
    },
    ["E"] = {
      function() require("astronvim.utils.buffer").nav(-(vim.v.count > 0 and vim.v.count or 1)) end,
      desc = "Previous buffer",
    },
    -- line naviate
    ["H"] = { "^", desc = "Next buffer" },
    ["L"] = { "$", desc = "Previous buffer" },
    ["<C-\\>"] = { "<cmd>ToggleTerm<cr>", desc = "Toggle terminal" },
    -- open recent open files
    ["<leader>r"] = { "<cmd>Telescope oldfiles<cr>", desc = "Open recent files" },
    -- open recent projects
    ["<leader>P"] = { "<cmd>SessionManager! load_session<cr>", desc = "Search sessions" },
    -- lsp, open workspace symbol
    ["<leader>s"] = {
      function()
        local aerial_avail, _ = pcall(require, "aerial")
        if aerial_avail then
          require("telescope").extensions.aerial.aerial()
        else
          require("telescope.builtin").lsp_document_symbols()
        end
      end,
      desc = "Search symbols",
    },
    -- outline
    -- ["<F7>"] = { function() require("aerial").toggle() end, desc = "Symbols outline" },
  },
  t = {
    -- setting a mapping to false will disable it
    -- ["<esc>"] = false,
    ["<C-\\>"] = { "<cmd>ToggleTerm<cr>", desc = "Toggle terminal" },
  },
}
