-- Mapping data with "desc" stored directly by vim.keymap.set().
--
-- Please use this mappings table to set keyboard mapping since this is the
-- lower level configuration and more robust one. (which-key will
-- automatically pick-up stored data by this setting.)
return {
  -- first key is the mode
  n = {
    -- tables with the `name` key will be registered with which-key if it's installed
    -- this is useful for naming menus
    ["<leader>b"] = { name = "Buffers" },
    -- quick save
    ["<C-s>"] = { "<cmd>w!<cr>", desc = "Save File" }, -- change description but the same command
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
    -- focuse current file
    ["<leader>o"] = {
      "<cmd>Neotree reveal<CR>",
      desc = "Toggle Explorer Focus",
    },
    -- search
    ["<leader>fw"] = {
      "<cmd>lua require('telescope-live-grep-args.shortcuts').grep_word_under_cursor({ postfix =  ' -w -F ' })<CR>",
      desc = "Search current word",
    },
    ["<leader>fg"] = {
      "<cmd>lua require('telescope').extensions.live_grep_args.live_grep_args()<CR>",
      desc = "Live search",
    },
    -- open recent open files
    ["<leader>r"] = { "<cmd>Telescope oldfiles<cr>", desc = "Open recent files" },
    -- open recent projects
    ["<leader>P"] = { "<cmd>SessionManager! load_session<cr>", desc = "Search sessions" },
    -- leap
    ["t"] = { "<Plug>(leap-forward-to)", desc = "Leap forward to" },
    ["T"] = { "<Plug>(leap-backward-to)", desc = "leap backward to" },
    --  current file history
    ["<leader>gD"] = { "<cmd>DiffviewFileHistory %<cr>", desc = "Current File Git History" },
    -- clangd switch
    ["<leader>j"] = { "<cmd>ClangdSwitchSourceHeader<cr>", desc = "C/Cpp Switch Header" },
    -- nohl
    ["<leader>h"] = { "<cmd>nohl<cr>", desc = "No highlight" },
    -- reset git hunk
    ["<leader>gr"] = { function() require("gitsigns").reset_hunk() end, desc = "Reset Git hunk" },
    -- lazygit
    ["<leader>gg"] = { "<cmd>LazyGitCurrentFile<cr>", desc = "Reset Git hunk" },
    -- swap buf
    ["<leader><leader>h"] = { "<cmd>lua require('smart-splits').swap_buf_left()<cr>", desc = "Swap buf left" },
    ["<leader><leader>l"] = { "<cmd>lua require('smart-splits').swap_buf_right()<cr>", desc = "Swap buf right" },
    ["<leader><leader>j"] = { "<cmd>lua require('smart-splits').swap_buf_down()<cr>", desc = "Swap buf down" },
    ["<leader><leader>k"] = { "<cmd>lua require('smart-splits').swap_buf_up()<cr>", desc = "Swap buf up" },
    -- spectre: find & replace
    ["<leader>F"] = {
      "<cmd>lua require('spectre').open_file_search({select_word=true})<cr><cr>",
      desc = "Toggle Spectre",
    },
  },
  t = {
    -- setting a mapping to false will disable it
    -- ["<esc>"] = false,
    ["<C-\\>"] = { "<cmd>ToggleTerm<cr>", desc = "Toggle terminal" },
  },
  v = {
    ["H"] = { "^", desc = "Next buffer" },
    ["L"] = { "$", desc = "Previous buffer" },
    ["p"] = { '"_dP', desc = "Paste" },
    ["<leader>fw"] = {
      "<cmd>lua require('telescope-live-grep-args.shortcuts').grep_visual_selection({ postfix =  ' -w -F ' })<CR>",
      desc = "Search current word",
    },
    ["<leader>hh"] = {
      ":<c-u>HSHighlight<CR>",
      desc = "Highlight",
    },
    ["<leader>hr"] = {
      ":<c-u>HSRmHighlight<cr>",
      desc = "Rm Highlight",
    },
  },
}
