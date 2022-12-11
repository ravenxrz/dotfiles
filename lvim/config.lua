--[[
lvim is the global options object
Linters should be
filled in as strings with either
a global executable or a path to
an executable
]]
-- THESE ARE EXAMPLE CONFIGS FEEL FREE TO CHANGE TO WHATEVER YOU WANT

-- general
lvim.log.level = "warn"
lvim.format_on_save.enabled = false -- lvim.colorscheme = "lunar"
-- themes: https://vimcolorschemes.com/
lvim.colorscheme = "gruvbox"
-- to disable icons and use a minimalist setup, uncomment the following
-- lvim.use_icons = false

--  options
vim.opt["foldlevel"] = 99
vim.opt["foldmethod"] = "expr"
vim.opt["foldexpr"] = "nvim_treesitter#foldexpr()"


-- keymappings [view all the defaults by pressing <leader>Lk]
lvim.leader = "space"
-- add your own keymapping
lvim.keys.normal_mode["<C-s>"] = ":w<cr>"
lvim.keys.normal_mode["E"] = ":BufferLineCyclePrev<CR>"
lvim.keys.normal_mode["R"] = ":BufferLineCycleNext<CR>"
lvim.keys.normal_mode["H"] = "^"
lvim.keys.normal_mode["L"] = "$"
lvim.keys.normal_mode["Q"] = "q"
lvim.keys.normal_mode["<leader>h"] = ":nohl<cr>"
lvim.keys.normal_mode["<leader>j"] = ":ClangdSwitchSourceHeader<cr>"
lvim.keys.normal_mode["<leader>o"] = ":Vista!!<cr>"
lvim.keys.normal_mode["<leader>q"] = ":bd<cr>"
lvim.keys.normal_mode["q"] = "<Nop>"
lvim.keys.normal_mode["n"] = "nzzzv"
lvim.keys.normal_mode["N"] = "Nzzzv"
lvim.keys.normal_mode["J"] = "mzJ`z"
-- lvim.keys.normal_mode["j"] = "jzz"
-- lvim.keys.normal_mode["k"] = "kzz"

lvim.keys.visual_mode["p"] = "P"
lvim.keys.visual_mode["H"] = "^"
lvim.keys.visual_mode["L"] = "$"



-- lsp
lvim.keys.normal_mode["<leader>in"] = ":lua vim.lsp.buf.incoming_calls()<cr>"
lvim.keys.visual_mode["<leader>lf"] = "<ESC><cmd>lua vim.lsp.buf.range_formatting()<CR>"
lvim.keys.normal_mode["<leader>ln"] = "<ESC><cmd>lua vim.lsp.buf.rename()<CR>"
-- telescope
lvim.keys.normal_mode["<leader>F"] = ":lua require('telescope').extensions.live_grep_args.live_grep_args(require('telescope.themes').get_ivy())<cr>"
lvim.keys.normal_mode["<leader>r"] = ":Telescope oldfiles<cr>"
lvim.keys.normal_mode["<leader>S"] = ":lua require('telescope.builtin').lsp_dynamic_workspace_symbols()<cr>"
-- hop
lvim.keys.normal_mode["f"] = "<cmd>lua require'hop'.hint_char1({ direction = require'hop.hint'.HintDirection.AFTER_CURSOR, current_line_only = true })<cr>" lvim.keys.normal_mode["F"] = "<cmd>lua require'hop'.hint_char1({ direction = require'hop.hint'.HintDirection.BEFORE_CURSOR, current_line_only = true })<cr>"
lvim.keys.normal_mode["<space>s"] = "<cmd>HopChar2<cr>"


-- unmap a default keymapping
-- vim.keymap.del("n", "q")
-- override a default keymapping
-- lvim.keys.normal_mode["<C-q>"] = ":q<cr>" -- or vim.keymap.set("n", "<C-q>", ":q<cr>" )

-- Change Telescope navigation to use j and k for navigation and n and p for history in both input and normal mode.
-- we use protected-mode (pcall) just in case the plugin wasn't loaded yet.
local _, actions = pcall(require, "telescope.actions")
lvim.builtin.telescope.defaults.mappings = {
  -- for input mode
  i = {
    ["<C-j>"] = actions.move_selection_next,
    ["<C-k>"] = actions.move_selection_previous,
    ["<C-n>"] = actions.cycle_history_next,
    ["<C-p>"] = actions.cycle_history_prev,
  },
  -- for normal mode
  n = {
    ["<C-j>"] = actions.move_selection_next,
    ["<C-k>"] = actions.move_selection_previous,
  },
}

-- Change theme settings
-- lvim.builtin.theme.options.dim_inactive = true
-- lvim.builtin.theme.options.style = "storm"

-- Use which-key to add extra bindings with the leader-key prefix
lvim.builtin.which_key.mappings["P"] = { "<cmd>Telescope projects<CR>", "Projects" }
lvim.builtin.which_key.mappings["t"] = {
  name = "+Trouble",
  r = { "<cmd>Trouble lsp_references<cr>", "References" },
  f = { "<cmd>Trouble lsp_definitions<cr>", "Definitions" },
  d = { "<cmd>Trouble document_diagnostics<cr>", "Diagnostics" },
  q = { "<cmd>Trouble quickfix<cr>", "QuickFix" },
  l = { "<cmd>Trouble loclist<cr>", "LocationList" },
  w = { "<cmd>Trouble workspace_diagnostics<cr>", "Workspace Diagnostics" },
  t = { "<cmd>TodoTrouble<cr>", "Todo" }
}

-- TODO: User Config for predefined plugins
-- After changing plugin config exit and reopen LunarVim, Run :PackerInstall :PackerCompile
lvim.builtin.alpha.active = true
lvim.builtin.alpha.mode = "dashboard"
lvim.builtin.terminal.active = true
-- nvim tree
lvim.builtin.nvimtree.setup.view.side = "right"
lvim.builtin.nvimtree.setup.view.adaptive_size = true
lvim.builtin.nvimtree.setup.renderer.icons.show.git = false
-- cmp
lvim.builtin.cmp.cmdline.enable = true
-- gitsigns
lvim.builtin.gitsigns.opts.current_line_blame = false
lvim.builtin.gitsigns.opts.current_line_blame_opts.virt_text_pos = "right_align"
lvim.builtin.gitsigns.opts.current_line_blame_opts.delay = 200
-- buffer line
lvim.builtin.bufferline.highlights.buffer_selected = {
  bold = true,
  fg = "#ffd43b"
}


-- if you don't want all the parsers change this to a table of the ones you want
lvim.builtin.treesitter.ensure_installed = {
  "bash",
  "c",
  "javascript",
  "json",
  "lua",
  "python",
  "typescript",
  "tsx",
  "css",
  "rust",
  "java",
  "yaml",
}

lvim.builtin.treesitter.ignore_install = { "haskell" }
lvim.builtin.treesitter.highlight.enable = true

-- generic LSP settings

-- -- make sure server will always be installed even if the server is in skipped_servers list
lvim.lsp.installer.setup.ensure_installed = {
  "clangd",
}
-- -- change UI setting of `LspInstallInfo`
-- -- see <https://github.com/williamboman/nvim-lsp-installer#default-configuration>
-- lvim.lsp.installer.setup.ui.check_outdated_servers_on_open = false
-- lvim.lsp.installer.setup.ui.border = "rounded"
-- lvim.lsp.installer.setup.ui.keymaps = {
--     uninstall_server = "d",
--     toggle_server_expand = "o",
-- }

-- ---@usage disable automatic installation of servers
lvim.lsp.installer.setup.automatic_installation = false
-- disable diagnostics which is super annoying in my case
-- vim.lsp.handlers["textDocument/publishDiagnostics"] = function() end

-- ---configure a server manually. !!Requires `:LvimCacheReset` to take effect!!
-- ---see the full default list `:lua print(vim.inspect(lvim.lsp.automatic_configuration.skipped_servers))`
-- vim.list_extend(lvim.lsp.automatic_configuration.skipped_servers, { "clangd" })
-- local opts = {} -- check the lspconfig documentation for a list of all possible options
require("lvim.lsp.manager").setup("pyright", {
  settings = {
    python = {
      analysis = {
        autoSearchPaths = true,
        diagnosticMode = "openFilesOnly",
        useLibraryCodeForTypes = true,
        typeCheckingMode = "off",
        autoImportCompletions = true
      }
    }
  },
})


-- ---remove a server from the skipped list, e.g. eslint, or emmet_ls. !!Requires `:LvimCacheReset` to take effect!!
-- ---`:LvimInfo` lists which server(s) are skipped for the current filetype
-- lvim.lsp.automatic_configuration.skipped_servers = vim.tbl_filter(function(server)
--   return server ~= "pylsp"
-- end, lvim.lsp.automatic_configuration.skipped_servers)

-- -- you can set a custom on_attach function that will be used for all the language servers
-- -- See <https://github.com/neovim/nvim-lspconfig#keybindings-and-completion>
-- lvim.lsp.on_attach_callback = function(client, bufnr)
-- require "lsp_signature".on_attach()
-- end

-- -- set a formatter, this will override the language server formatting capabilities (if it exists)
local formatters = require "lvim.lsp.null-ls.formatters"
formatters.setup {
  { command = "black", filetypes = { "python" } },
  -- { command = "isort", filetypes = { "python" } },
  -- {
  --   -- each formatter accepts a list of options identical to https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md#Configuration
  --   command = "prettier",
  --   ---@usage arguments to pass to the formatter
  --   -- these cannot contain whitespaces, options such as `--line-width 80` become either `{'--line-width', '80'}` or `{'--line-width=80'}`
  --   extra_args = { "--print-with", "100" },
  --   ---@usage specify which filetypes to enable. By default a providers will attach to all the filetypes it supports.
  --   filetypes = { "typescript", "typescriptreact" },
  -- },
}

-- -- set additional linters
-- local linters = require "lvim.lsp.null-ls.linters"
-- linters.setup {
--   -- { command = "flake8", filetypes = { "python" } },
--   -- {
--   --   -- each linter accepts a list of options identical to https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md#Configuration
--   --   command = "shellcheck",
--   --   ---@usage arguments to pass to the formatter
--   --   -- these cannot contain whitespaces, options such as `--line-width 80` become either `{'--line-width', '80'}` or `{'--line-width=80'}`
--   --   extra_args = { "--severity", "warning" },
--   -- },
--   {
--     command = "cpplint",
--     ---@usage specify which filetypes to enable. By default a providers will attach to all the filetypes it supports.
--     filetypes = { "c", "cpp" },
--   },
-- }

-- lvim.builtin.cmp

-- Additional Plugins
lvim.plugins = {
  {
    "folke/trouble.nvim",
    cmd = "TroubleToggle",
  },
  { -- better quick fix
    "kevinhwang91/nvim-bqf",
    config = function()
      require('bqf').setup(
        {
          func_map = {
            pscrollup = "<C-u>",
            pscrolldown = "<C-d>"
          },
        }
      )
    end
  },
  { -- only works on https://github.com/universal-ctags/ctags
    "liuchengxu/vista.vim",
    config = function()
      vim.cmd([[ 
      let g:vista_sidebar_position = 'vertical topleft' 
      let g:vista_default_executive = 'nvim_lsp' 
      ]])
    end
  },
  { -- telescope instant searching
    "nvim-telescope/telescope-live-grep-args.nvim"
  },
  {
    "ldelossa/litee.nvim",
    config = function()
      require("litee.lib").setup({})
    end
  },
  { -- calltree
    "ldelossa/litee-calltree.nvim",
    config = function()
      require("litee.calltree").setup({
        -- NOTE: the plugin is in-progressing
        on_open = "pannel", -- pannel | popout
        hide_cursor = false,
        keymaps = {
          expand = "o",
          collapse = "zc",
          collapse_all = "zM",
          jump = "<CR>",
          jump_split = "s",
          jump_vsplit = "v",
          jump_tab = "t",
          hover = "i",
          details = "d",
          close = "X",
          close_panel_pop_out = "<C-c>",
          help = "?",
          hide = "H",
          switch = "S",
          focus = "f"
        },
      })
    end
  },
  { -- vscode theme
    "Mofiqul/vscode.nvim"
  },
  { -- hop
    "phaazon/hop.nvim",
    branch = 'v2', -- optional but strongly recommended
    config = function()
      -- you can configure Hop the way you like here; see :h hop-config
      require 'hop'.setup { keys = 'etovxqpdygfblzhckisuran' }
    end
  },
  { -- resize window
    "simeji/winresizer"
  },
  { -- vim clip on server
    "wincent/vim-clipper",
    config = function()
      vim.cmd([[
      let g:ClipperAddress="127.0.0.1"
      let g:ClipperPort=8377
      let g:ClipperAuto=1
      call clipper#set_invocation('netcat -c 127.0.0.1 8377')
    ]] )
    end
  },
  { -- log file content highlighting
    "mtdl9/vim-log-highlighting"
  },
  {
    "tpope/vim-surround"
  },
  { -- theme
    "morhetz/gruvbox"
  },
  {
    "folke/todo-comments.nvim",
    config = function()
      require("todo-comments").setup {}
    end
  },
  { -- auto save
    "pocco81/auto-save.nvim"
  },
  {
    "p00f/clangd_extensions.nvim",
    after = "mason-lspconfig.nvim", -- make sure to load after mason-lspconfig
    config = function()
      require("clangd_extensions").setup {
        server = require "lvim.lsp".get_common_opts()
      }
    end
  }
}

-- Autocommands (https://neovim.io/doc/user/autocmd.html)
-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = "zsh",
--   callback = function()
--     -- let treesitter use bash highlight for zsh files as well
--     require("nvim-treesitter.highlight").attach(0, "bash")
--   end,
-- })
--
vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  command = "set tabstop=2  shiftwidth=2"
})
