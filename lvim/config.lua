--[[
Linters should be
filled in as strings with either
a global executable or a path to
an executable
]]
local home = os.getenv("HOME")
package.path = home .. "/.dotfiles/lvim/?.lua"

-- THESE ARE EXAMPLE CONFIGS FEEL FREE TO CHANGE TO WHATEVER YOU WANT
-- general
lvim.log.level = "warn"
lvim.format_on_save.enabled = false -- lvim.colorscheme = "lunar"
-- themes: https://vimcolorschemes.com/

-- lightscheme base16-atelier-seaside-light
lvim.colorscheme = "darkplus"
-- lvim.colorscheme = "colorscheme rose-pine"
-- to disable icons and use a minimalist setup, uncomment the following
-- lvim.use_icons = false

--  options
vim.opt.foldlevel = 99
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"


-- keymappings [view all the defaults by pressing <leader>Lk]
lvim.leader                        = "space"
-- add your own keymapping
lvim.keys.normal_mode["<C-s>"]     = ":w<cr>"
lvim.keys.normal_mode["E"]         = ":BufferLineCyclePrev<CR>"
lvim.keys.normal_mode["R"]         = ":BufferLineCycleNext<CR>"
lvim.keys.normal_mode["H"]         = "^"
lvim.keys.normal_mode["L"]         = "$"
lvim.keys.normal_mode["Q"]         = "q"
lvim.keys.normal_mode["<leader>h"] = ":nohl<cr>"
lvim.keys.normal_mode["<leader>j"] = ":ClangdSwitchSourceHeader<cr>"
lvim.keys.normal_mode["<leader>H"] = ":ClangdTypeHierarchy<cr>"
lvim.keys.normal_mode["<leader>o"] = ":Vista!!<cr>"
lvim.keys.normal_mode["<leader>q"] = ":bd<cr>"
lvim.keys.normal_mode["q"]         = "<Nop>"
lvim.keys.normal_mode["n"]                               = "nzzzv"
lvim.keys.normal_mode["N"]                               = "Nzzzv"
lvim.keys.normal_mode["J"]                               = "mzJ`z"

lvim.keys.visual_mode["p"]         = "P"
lvim.keys.visual_mode["H"]         = "^"
lvim.keys.visual_mode["L"]         = "$"
-- lvim.keys.visual_mode["J"]         = ":m '>+1<CR>gv=gv"
-- lvim.keys.visual_mode["K"]         = ":m '<-2<CR>gv=gv"



-- lsp
-- lvim.keys.normal_mode["<leader>in"]                   = ":lua vim.lsp.buf.incoming_calls()<cr>"
lvim.keys.visual_mode["<leader>lf"]                      = "<ESC><cmd>lua vim.lsp.buf.range_formatting()<CR>"
lvim.keys.normal_mode["<leader>ln"]                      = "<cmd>lua vim.lsp.buf.rename()<CR>"
lvim.keys.normal_mode["<leader>r"]                       = ":Telescope oldfiles<cr>"

lvim.builtin.which_key.mappings.f                        = nil
lvim.builtin.which_key.mappings.s                        = nil
lvim.builtin.which_key.mappings.d                        = nil

-- FzfLua config
lvim.keys.term_mode["<C-h>"]                             = false
lvim.keys.term_mode["<C-j>"]                             = false
lvim.keys.term_mode["<C-k>"]                             = false
lvim.keys.term_mode["<C-l>"]                             = false

-- TODO
--  disable lvim builtin config
--  ["gr"] = { "<cmd>lua vim.lsp.buf.references()<cr>", "Goto references" },
lvim.keys.normal_mode["gr"]                              = ":Telescope lsp_references theme=get_ivy<cr>"
lvim.keys.normal_mode["<leader>s"]                       = ":Telescope lsp_document_symbols theme=get_ivy<cr>"
lvim.keys.normal_mode["<leader>S"]                       = ":Telescope lsp_workspace_symbols theme=get_ivy<cr>"
lvim.keys.normal_mode["<leader>ff"]                      = ":Telescope find_files theme=dropdown<cr>"
lvim.keys.normal_mode["<leader>fg"]                      = ":lua require('telescope').extensions.live_grep_args.live_grep_args(require('telescope.themes').get_ivy({}))<CR>"
lvim.keys.normal_mode["<leader>fw"]                      = ":lua require('telescope-live-grep-args.shortcuts').grep_word_under_cursor()<CR>"
lvim.keys.normal_mode["<leader>fb"]                      = ":Telescope buffers theme=get_ivy<cr>"
lvim.keys.normal_mode["<leader>fc"]                      = ":Telescope colorscheme<cr>"
lvim.keys.normal_mode["<leader>fr"]                      = ":Telescope resume<cr>"
-- lvim.keys.normal_mode["<leader>in"]                      = ":FzfLua lsp_incoming_calls<cr>"
-- lvim.keys.normal_mode["<leader>fw"]                      = ":FzfLua grep_cword<cr>"
-- lvim.keys.visual_mode["v"]                               = ":<c-u>FzfLua grep_visual<cr>"

-- leap
lvim.keys.normal_mode["t"]                               = "<Plug>(leap-forward-to)"
lvim.keys.normal_mode["T"]                               = "<Plug>(leap-backward-to)"

-- undo tree
lvim.keys.normal_mode["<leader>u"]                       = ":UndotreeToggle<cr>"

-- indentlines
lvim.builtin.indentlines.options.use_treesitter          = true
lvim.builtin.indentlines.options.show_current_context    = true

-- lualine
-- show file path
lvim.builtin.lualine.sections.lualine_c                  = { { 'filename', path = 1 } }

-- auto pairs
lvim.builtin.autopairs.disable_filetype                  = { "TelescopePrompt", "spectre_panel", "repl" }

-- dap
-- lvim.builtin.which_key.mappings.d                   = {
--   name = "Debug",
--   h = { "<cmd>lua require'dap.ui.widgets'.hover()<cr>", "Hover Variables" },
--   x = { "<cmd>lua require'dap'.terminate()<cr>", "Terminate" },
--   t = { "<cmd>lua require'dap'.toggle_breakpoint()<cr>", "Toggle Breakpoint" },
--   b = { "<cmd>lua require'dap'.step_back()<cr>", "Step Back" },
--   c = { "<cmd>lua require'dap'.continue()<cr>", "Continue" },
--   C = { "<cmd>lua require'dap'.run_to_cursor()<cr>", "Run To Cursor" },
--   d = { "<cmd>lua require'dap'.disconnect()<cr>", "Disconnect" },
--   g = { "<cmd>lua require'dap'.session()<cr>", "Get Session" },
--   i = { "<cmd>lua require'dap'.step_into()<cr>", "Step Into" },
--   o = { "<cmd>lua require'dap'.step_over()<cr>", "Step Over" },
--   u = { "<cmd>lua require'dap'.step_out()<cr>", "Step Out" },
--   p = { "<cmd>lua require'dap'.pause()<cr>", "Pause" },
--   r = { "<cmd>lua require'dap'.repl.toggle()<cr>", "Toggle Repl" },
--   s = { "<cmd>lua require'dap'.continue()<cr>", "Start" },
--   q = { "<cmd>lua require'dap'.close()<cr>", "Quit" },
--   U = { "<cmd>lua require'dapui'.toggle()<cr>", "Toggle UI" },
-- }

-- unmap a default keymapping
-- vim.keymap.del("n", "q")
-- override a default keymapping
-- lvim.keys.normal_mode["<C-q>"] = ":q<cr>" -- or vim.keymap.set("n", "<C-q>", ":q<cr>" )

-- Change Telescope navigation to use j and k for navigation and n and p for history in both input and normal mode.
-- we use protected-mode (pcall) just in case the plugin wasn't loaded yet.
local _, actions                                         = pcall(require, "telescope.actions")
lvim.builtin.telescope.defaults.mappings                 = {
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
lvim.builtin.telescope.pickers.find_files                = {
  find_command = { "fd", "--type", "f", "--strip-cwd-prefix" },
  hidden = true
}

-- Change theme settings
-- lvim.builtin.theme.options.dim_inactive = true
-- lvim.builtin.theme.options.style = "storm"

-- Use which-key to add extra bindings with the leader-key prefix
lvim.builtin.which_key.mappings["P"]                     = { "<cmd>SessionManager load_session<CR>", "Projects" }

-- TODO: User Config for predefined plugins
-- After changing plugin config exit and reopen LunarVim, Run :PackerInstall :PackerCompile
lvim.builtin.alpha.active                                = false
lvim.builtin.alpha.mode                                  = "dashboard"

lvim.builtin.terminal.active                             = true
-- nvim tree
lvim.builtin.nvimtree.setup.view.side                    = "left"
lvim.builtin.nvimtree.setup.view.adaptive_size           = true
lvim.builtin.nvimtree.setup.renderer.icons.show.git      = false
lvim.builtin.nvimtree.setup.renderer.symlink_destination = false

-- lvim.lsp.diagnostics.virtual_textmp
vim.diagnostic.config(
  {
    virtual_text = false
  }
)


lvim.builtin.cmp.cmdline.enable                                  = true
-- table.insert(lvim.builtin.cmp.sources, {
--   name = 'nvim_lsp_signature_help'
-- });
--
-- gitsigns
lvim.builtin.gitsigns.opts.current_line_blame                    = false
lvim.builtin.gitsigns.opts.current_line_blame_opts.virt_text_pos = "right_align"
lvim.builtin.gitsigns.opts.current_line_blame_opts.delay         = 200
-- buffer line
lvim.builtin.bufferline.highlights.buffer_selected               = {
  bold = true,
  fg = "#ffd43b"
}


-- if you don't want all the parsers change this to a table of the ones you want
lvim.builtin.treesitter.ensure_installed = {
  "bash",
  "c",
  "cpp",
  "json",
  "lua",
  "python",
  "yaml",
}

lvim.builtin.treesitter.ignore_install = { "haskell" }
lvim.builtin.treesitter.highlight.enable = true

-- generic LSP settings

-- -- make sure server will always be installed even if the server is in skipped_servers list
lvim.lsp.installer.setup.ensure_installed = {
  -- "clangd",
  "pyright",
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
lvim.lsp.installer.setup.automatic_installation = true

-- disable diagnostics which is super annoying in my case
-- lvim.diagnostic.config({ virtual_text = false })
-- vim.lsp.handlers["textDocument/publishDiagnostics"] = function() end

-- ---configure a server manually. !!Requires `:LvimCacheReset` to take effect!!
-- ---see the full default list `:lua print(vim.inspect(lvim.lsp.automatic_configuration.skipped_servers))`
-- vim.list_extend(lvim.lsp.automatic_configuration.skipped_servers, { "clangd" })
-- local opts = {} -- check the lspconfig documentation for a list of all possible options
--
---@diagnostic disable-next-line: missing-parameter
vim.list_extend(lvim.lsp.automatic_configuration.skipped_servers, { "pyright", "clangd" })
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
  { command = "yapf", filetypes = { "python" } },
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

lvim.lsp.null_ls.setup.on_init = function(new_client, _)
  new_client.offset_encoding = "utf-16"
end


-- Additional Plugins
lvim.plugins = {
  {
    "aserowy/tmux.nvim",
    config = function()
      return require("tmux").setup(
        {
          copy_sync = {
            -- enables copy sync. by default, all registers are synchronized.
            -- to control which registers are synced, see the `sync_*` options.
            enable = true,
            -- ignore specific tmux buffers e.g. buffer0 = true to ignore the
            -- first buffer or named_buffer_name = true to ignore a named tmux
            -- buffer with name named_buffer_name :)
            ignore_buffers = { empty = false },
            -- TMUX >= 3.2: all yanks (and deletes) will get redirected to system
            -- clipboard by tmux
            redirect_to_clipboard = false,
            -- offset controls where register sync starts
            -- e.g. offset 2 lets registers 0 and 1 untouched
            register_offset = 0,
            -- overwrites vim.g.clipboard to redirect * and + to the system
            -- clipboard using tmux. If you sync your system clipboard without tmux,
            -- disable this option!
            sync_clipboard = true,
            -- synchronizes registers *, +, unnamed, and 0 till 9 with tmux buffers.
            sync_registers = true,
            -- syncs deletes with tmux clipboard as well, it is adviced to
            -- do so. Nvim does not allow syncing registers 0 and 1 without
            -- overwriting the unnamed register. Thus, ddp would not be possible.
            sync_deletes = true,
            -- syncs the unnamed register with the first buffer entry from tmux.
            sync_unnamed = true,
          },
          navigation = {
            -- cycles to opposite pane while navigating into the border
            cycle_navigation = true,
            -- enables default keybindings (C-hjkl) for normal mode
            enable_default_keybindings = true,
            -- prevents unzoom tmux when navigating beyond vim border
            persist_zoom = false,
          },
          resize = {
            -- enables default keybindings (A-hjkl) for normal mode
            enable_default_keybindings = false,
            -- sets resize steps for x axis
            resize_step_x = 1,
            -- sets resize steps for y axis
            resize_step_y = 1,
          }
        }
      )
    end
  },
  {
    "mbbill/undotree",
    config = function()
    end
  },
  {
    "MTDL9/vim-log-highlighting"
  },
  {
    -- only works on https://github.com/universal-ctags/ctags
    "liuchengxu/vista.vim",
    config = function()
      vim.cmd([[
      let g:vista_sidebar_position = 'vertical botright'
      let g:vista_default_executive = 'nvim_lsp'
      ]])
    end
  },
  {
    "Shatur/neovim-session-manager"
  },
  {
    "ggandor/leap.nvim",
    commit = "27489b8698f23a83ebdec07688860fd19ff4d28b"
  },
  { -- resize window
    "simeji/winresizer"
  },
  {
    -- vim clip on server
    "wincent/vim-clipper",
    config = function()
      vim.cmd([[
      let g:ClipperAddress="127.0.0.1"
      let g:ClipperPort=8377
      let g:ClipperAuto=1
      call clipper#set_invocation('netcat -c 127.0.0.1 8377')
    ]])
    end
  },
  { -- theme
    "morhetz/gruvbox"
  },
  {
    "RRethy/nvim-base16"
  },
  {
    "lunarvim/colorschemes"
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
      local provider = "clangd"
      local clangd_flags = {
        -- 在后台自动分析文件（基于complie_commands)
        "--compile-commands-dir=build",
        "--background-index",
        "--completion-style=detailed",
        -- 同时开启的任务数量
        "--all-scopes-completion=true",
        "--recovery-ast",
        "--suggest-missing-includes",
        -- 告诉clangd用那个clang进行编译，路径参考which clang++的路径
        "--query-driver=/usr/locla/bin/clang++,/usr/bin/g++",
        "--clang-tidy",
        -- 全局补全（会自动补充头文件）
        "--all-scopes-completion",
        "--cross-file-rename",
        -- 更详细的补全内容
        "--completion-style=detailed",
        "--function-arg-placeholders=false",
        -- 补充头文件的形式
        "--header-insertion=never",
        -- pch优化的位置
        "--pch-storage=memory",
        "--offset-encoding=utf-16",
        "-j=12",
      }

      local custom_on_attach = function(client, bufnr)
        require("lvim.lsp").common_on_attach(client, bufnr)
        require("clangd_extensions.inlay_hints").setup_autocmd()
        require("clangd_extensions.inlay_hints").set_inlay_hints()
      end


      local custom_on_init = function(client, bufnr)
        require("lvim.lsp").common_on_init(client, bufnr)
        require("clangd_extensions.config").setup {}
        require("clangd_extensions.ast").init()
        vim.cmd [[
              command ClangdToggleInlayHints lua require('clangd_extensions.inlay_hints').toggle_inlay_hints()
              command -range ClangdAST lua require('clangd_extensions.ast').display_ast(<line1>, <line2>)
              command ClangdTypeHierarchy lua require('clangd_extensions.type_hierarchy').show_hierarchy()
              command ClangdSymbolInfo lua require('clangd_extensions.symbol_info').show_symbol_info()
              command -nargs=? -complete=customlist,s:memuse_compl ClangdMemoryUsage lua require('clangd_extensions.memory_usage').show_memory_usage('<args>' == 'expand_preamble')
              ]]
      end

      local opts = {
        cmd = { provider, unpack(clangd_flags) },
        on_attach = custom_on_attach,
        on_init = custom_on_init,
      }

      require("lvim.lsp.manager").setup("clangd", opts)
    end
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    commit = "c81382328ad47c154261d1528d7c921acad5eae5",
    config = function()
      require 'nvim-treesitter.configs'.setup {
        textobjects = {
          select = {
            enable = true,
            -- Automatically jump forward to textobj, similar to targets.vim
            lookahead = true,
            keymaps = {
              -- You can use the capture groups defined in textobjects.scm
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["ac"] = "@class.outer",
              -- You can optionally set descriptions to the mappings (used in the desc parameter of
              -- nvim_buf_set_keymap) which plugins like which-key display
              ["ic"] = { query = "@class.inner", desc = "Select inner part of a class region" },
            },
            -- You can choose the select mode (default is charwise 'v')
            --
            -- Can also be a function which gets passed a table with the keys
            -- * query_string: eg '@function.inner'
            -- * method: eg 'v' or 'o'
            -- and should return the mode ('v', 'V', or '<c-v>') or a table
            -- mapping query_strings to modes.
            selection_modes = {
              ['@parameter.outer'] = 'v', -- charwise
              ['@function.outer'] = 'V',  -- linewise
              ['@class.outer'] = '<c-v>', -- blockwise
            },
            -- If you set this to `true` (default is `false`) then any textobject is
            -- extended to include preceding or succeeding whitespace. Succeeding
            -- whitespace has priority in order to act similarly to eg the built-in
            -- `ap`.
            --
            -- Can also be a function which gets passed a table with the keys
            -- * query_string: eg '@function.inner'
            -- * selection_mode: eg 'v'
            -- and should return true of false
            include_surrounding_whitespace = true,
          },
          move = {
            enable = true,
            set_jumps = false, -- whether to set jumps in the jumplist
            goto_next_start = {
              ["]]"] = "@function.outer",
              -- ["]["] = "@function.outer",
            },
            goto_next_end = {
              ["]["] = "@function.outer",
              -- ["]["] = "@class.outer",
            },
            goto_previous_start = {
              ["[["] = "@function.outer",
              -- ["[]"] = "@function.outer",
            },
            goto_previous_end = {
              ["[]"] = "@function.outer",
              -- ["[]"] = "@class.outer",
            },
          },
          lsp_interop = {
            enable = true,
            border = 'none',
            peek_definition_code = {
              ["<leader>pf"] = "@function.outer",
              ["<leader>pF"] = "@class.outer",
            },
          },
        },
      }
    end
  },
  {
    "nvim-telescope/telescope-live-grep-args.nvim",
    config = function()
      require("telescope").load_extension("live_grep_args")
    end
  }
}

vim.cmd([[
  let g:undotree_WindowLayout = 2
]])


--- dap config
-- load non-standard json file
-- require('dap.ext.vscode').json_decode = require 'json5'.parse
-- require('dap.ext.vscode').load_launchjs()
-- require("dap.dap-lldb")
-- require("dap.dap-cppdbg")

-- Autocommands (https://neovim.io/doc/user/autocmd.html)
-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = "zsh",
--   callback = function()
--     -- let treesitter use bash highlight for zsh files as well
--     require("nvim-treesitter.highlight").attach(0, "bash")
--   end,
-- })
--


-- 大文件读取优化
vim.cmd([[
augroup LargeFile
        let g:large_file = 3145728 " 3MB

        " Set options:
        "   eventignore+=FileType (no syntax highlighting etc
        "   assumes FileType always on)
        "   noswapfile (save copy of file)
        "   bufhidden=unload (save memory when other file is viewed)
        "   buftype=nowritefile (is read-only)
        "   undolevels=-1 (no undo possible)
        au BufReadPre *
                \ let f=expand("<afile>") |
                \ if getfsize(f) > g:large_file |
                        \ set eventignore+=FileType |
                        \ setlocal noswapfile bufhidden=unload buftype=nowrite undolevels=-1 filetype=off lazyredraw eventignore=all nohidden syntax=off
                \ else |
                        \ set eventignore-=FileType |
                \ endif
augroup END
]])


-- edit file:linenumber directly
function edit_file_with_linenumber(args)
  local file, line = string.match(args, "(.-):(%d+)$")
  if file and vim.fn.filereadable(file) == 1 then
    vim.cmd("e " .. file .. "|" .. line)
  else
    vim.cmd("e " .. args)
  end
end

vim.cmd([[
  :command! -nargs=1 E lua edit_file_with_linenumber(<f-args>)
]])

vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  command = "set tabstop=2  shiftwidth=2 expandtab"
})
