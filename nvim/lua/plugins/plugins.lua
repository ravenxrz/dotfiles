return {
  {
    "yorickpeterse/nvim-window",
    keys = {
      { "<C-s>", "<cmd>lua require('nvim-window').pick()<cr>", desc = "nvim-window: Jump to window" },
    },
    config = true,
  },
  {
    "hedyhli/outline.nvim",
    config = function()
      require("outline").setup({
        -- Your setup opts here (leave empty to use defaults)
      })
    end,
  },
  {
    "stevearc/dressing.nvim",
  },
  {
    "kevinhwang91/nvim-bqf",
    ft = "qf",
    opts = {
      preview = {
        winblend = 0,
        win_height = 30,
        win_vheight = 30,
      },
      filter = {
        fzf = {
          extra_opts = {
            "--bind",
            "ctrl-o:toggle-all",
            "--color",
            table.concat({
              "fg:#1f2328",
              "fg+:#111827",
              "bg:-1",
              "bg+:#dbeafe",
              "hl:#9a3412",
              "hl+:#7c2d12",
              "info:#374151",
              "prompt:#1d4ed8",
              "pointer:#b45309",
              "marker:#047857",
              "spinner:#6b7280",
              "header:#374151",
            }, ","),
          },
        },
      },
      func_map = {
        openc = "o",
        pscrollup = "<C-u>",
        pscrolldown = "<C-d>",
        fzffilter = "f",
      },
    },
  },
  {
    "junegunn/fzf",
    build = "./install --bin",
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "helix",
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    },
    keys = {
      {
        "<leader>?",
        function()
          require("which-key").show({ global = false })
        end,
        desc = "Buffer Local Keymaps (which-key)",
      },
    },
  },
  {
    "ggandor/leap.nvim",
    url = "https://codeberg.org/andyg/leap.nvim",
    config = function()
      -- require('leap').create_default_mappings()
      require("leap").init_highlight(true)
    end,
  },
  {
    "shellRaining/hlchunk.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("hlchunk").setup({
        chunk = {
          enable = false,
        },
        indent = {
          enable = true,
        },
        blank = {
          enable = false,
        },
        line_num = {
          enable = false,
        },
      })
    end,
  },
  {
    "nvim-tree/nvim-tree.lua",
    config = function()
      require("nvim-tree").setup({
        sort = {
          sorter = "case_sensitive",
        },
        view = {
          width = 40,
        },
        renderer = {
          group_empty = true,
        },
        filters = {
          git_ignored = true,
          dotfiles = true,
        },
        on_attach = function(bufnr)
          local api = require("nvim-tree.api")
          local function opts(desc)
            return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
          end
          -- default mappings
          api.config.mappings.default_on_attach(bufnr)
          -- custom mappings
          vim.keymap.set("n", "<BS>", api.tree.change_root_to_parent, opts("Up"))
          vim.keymap.set("n", ".", api.tree.change_root_to_node, opts("CD"))
          vim.keymap.set("n", "p", api.node.open.edit, opts("Open"))
          vim.keymap.set("n", "o", api.node.open.no_window_picker, opts("Open"))
          vim.keymap.set("n", "L", api.node.open.no_window_picker, opts("Open"))
          vim.keymap.set("n", "H", api.node.navigate.parent_close, opts("Parent Close"))
          vim.keymap.set("n", "i", api.node.show_info_popup, opts("Info"))
          vim.keymap.set("n", "I", function()
            api.filter.dotfiles.toggle()
            api.filter.git.ignored.toggle()
          end, opts("Toggle Hidden and Git Ignored"))
          vim.keymap.del("n", "<C-e>", { buffer = bufnr })
        end,
      })
    end,
  },
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup({
        signs = {
          add = { text = "│" },
          change = { text = "│" },
          delete = { text = "_" },
          topdelete = { text = "‾" },
          changedelete = { text = "~" },
          untracked = { text = "┆" },
        },
        signcolumn = true, -- Toggle with `:Gitsigns toggle_signs`
        numhl = false,     -- Toggle with `:Gitsigns toggle_numhl`
        linehl = false,    -- Toggle with `:Gitsigns toggle_linehl`
        word_diff = false, -- Toggle with `:Gitsigns toggle_word_diff`
        watch_gitdir = {
          follow_files = true,
        },
        auto_attach = true,
        attach_to_untracked = false,
        current_line_blame = true, -- Toggle with `:Gitsigns toggle_current_line_blame`
        current_line_blame_opts = {
          virt_text = true,
          virt_text_pos = "eol", -- 'eol' | 'overlay' | 'right_align'
          delay = 1000,
          ignore_whitespace = false,
          virt_text_priority = 100,
        },
        current_line_blame_formatter = "<author>, <author_time:%Y-%m-%d> - <summary>",
        sign_priority = 6,
        update_debounce = 100,
        status_formatter = nil,  -- Use default
        max_file_length = 40000, -- Disable if file is longer than this (in lines)
        preview_config = {
          -- Options passed to nvim_open_win
          border = "single",
          style = "minimal",
          relative = "cursor",
          row = 0,
          col = 1,
        },
      })
    end,
  },
  {
    "sindrets/diffview.nvim",
  },
  {
    "numToStr/Comment.nvim",
    event = { "BufReadPost" },
    opts = {
      ---Add a space b/w comment and the line
      padding = true,
      ---Whether the cursor should stay at its position
      sticky = true,
      ---Lines to be ignored while (un)comment
      ignore = nil,
      ---LHS of toggle mappings in NORMAL mode
      toggler = {
        ---Line-comment toggle keymap
        line = "gcc",
        ---Block-comment toggle keymap
        block = "gbc",
      },
      ---LHS of operator-pending mappings in NORMAL and VISUAL mode
      opleader = {
        ---Line-comment keymap
        line = "gc",
        ---Block-comment keymap
        block = "gb",
      },
      ---LHS of extra mappings
      extra = {
        ---Add comment on the line above
        above = "gcO",
        ---Add comment on the line below
        below = "gco",
        ---Add comment at the end of line
        eol = "gcA",
      },
      ---Enable keybindings
      ---NOTE: If given `false` then the plugin won't create any mappings
      mappings = {
        ---Operator-pending mapping; `gcc` `gbc` `gc[count]{motion}` `gb[count]{motion}`
        basic = true,
        ---Extra mapping; `gco`, `gcO`, `gcA`
        extra = true,
      },
      ---Function to call before (un)comment
      pre_hook = nil,
      ---Function to call after (un)comment
      post_hook = nil,
    },
  },
  {
    "nvim-telescope/telescope.nvim",
    branch = "master",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "ravenxrz/telescope-live-grep-args.nvim",
        version = "^1.0.0",
      },
    },
    config = function()
      local actions = require("telescope.actions")
      local telescope = require("telescope")
      telescope.setup({
        defaults = {
          sorting_strategy = "ascending", -- display results top->bottom
          -- nvim-treesitter (master branch) ships markdown injection queries that assume
          -- the old single-node match format; on Neovim 0.11 match captures are node
          -- lists, so its `set-lang-from-info-string!` directive throws
          -- "attempt to call method 'range' (a nil value)" the first time the preview
          -- parses a markdown file. Disable treesitter highlighting for markdown in the
          -- previewer (falls back to regex/syntax highlight, which is fine for a preview).
          preview = {
            treesitter = {
              disable = { "markdown", "markdown.mdx" },
            },
          },
          layout_config = {
            horizontal = {
              prompt_position = "top",
            },
            vertical = {
              prompt_position = "top",
            },
          },

          path_display = function(_, path)
            local tail = vim.fs.basename(path)
            local parent = vim.fs.dirname(path)
            if parent == "." then
              return tail
            end
            return string.format("%s (%s)", tail, parent)
          end,
          mappings = {
            i = {
              ["<C-j>"] = actions.cycle_history_next,
              ["<C-k>"] = actions.cycle_history_prev,
            },
            n = {
              ["<C-j>"] = actions.cycle_history_next,
              ["<C-k>"] = actions.cycle_history_prev,
            },
          },
        },
      })
      telescope.load_extension("live_grep_args")
    end,
  },
  {
    "akinsho/toggleterm.nvim",
    keys = {
      "<C-\\>",
      "<C-t>",
      "<leader>gg",
      "<leader>cc",
      "<leader>gt",
      "<leader>gb",
    },
    version = "*",
    config = function()
      require("toggleterm").setup({
        open_mapping = [[<c-\>]],
        hide_numbers = false,
        shade_filetypes = {},
        shade_terminals = true,
        shading_factor = 3,
        start_in_insert = true,
        insert_mappings = true,
        persist_size = true,
        direction = "float",
        close_on_exit = true,
        shell = vim.o.shell,
        winbar = {
          enabled = true,
          name_formatter = function(term)
            return string.format("%d:%s", term.id, term:_display_name())
          end,
        },
        float_opts = {
          winblend = 0,
          border = "curved",
          title_pos = "center",
          width = function()
            return vim.o.columns
          end,
          height = function()
            return vim.o.lines - vim.o.cmdheight
          end,
          row = 0,
          col = 0,
          highlights = {
            border = "Normal",
            background = "Normal",
          },
        },
      })
      -- toggleterm
      -- lazygit and tig
      local Terminal = require("toggleterm.terminal").Terminal
      local lazygit = Terminal:new({
        cmd = "lazygit",
        direction = "float",
        display_name = "lazygit",
      })
      local traex = Terminal:new({
        cmd = "traex",
        direction = "float",
        display_name = "traex",
      })
      function _lazygit_toggle()
        lazygit:toggle()
      end
      function _traex_toggle()
        traex:toggle()
      end

      vim.api.nvim_set_keymap("n", "<leader>gg", "<cmd>lua _lazygit_toggle()<CR>", { noremap = true, silent = true })
      vim.api.nvim_set_keymap("n", "<leader>cc", "<cmd>lua _traex_toggle()<CR>", { noremap = true, silent = true })
      -- vim.api.nvim_set_keymap(
      --   "n",
      --   "<leader>gt",
      --   "<cmd>TermExec cmd='tig %' go_back=1 direction=float<CR>",
      --   { noremap = true, silent = true }
      -- )
      vim.api.nvim_set_keymap("n", "<leader>gt", "<cmd>G blame<CR>", { noremap = true, silent = true })
      vim.api.nvim_set_keymap(
        "n",
        "<leader>gb",
        "<cmd>Gitsigns blame<CR>",
        { noremap = true, silent = true }
      )
      vim.api.nvim_set_keymap("t", "<c-q>", "<cmd>bd!<cr>", { noremap = true, silent = true })
      -- select/switch among open terminals
      vim.api.nvim_set_keymap("n", "<C-t>", "<cmd>TermSelect<CR>", { noremap = true, silent = true })
      vim.api.nvim_set_keymap("t", "<C-t>", "<cmd>TermSelect<CR>", { noremap = true, silent = true })
    end,
  },
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = true,
    -- config = function()
    --   require("nvim-autopairs").setup({
    --     disable_filetype = { "TelescopePrompt", "vim", "spectre_panel", "dap-repl" },
    --   })
    --   -- add auto pair when auto completion down
    --   local cmp_autopairs = require("nvim-autopairs.completion.cmp")
    --   local cmp = require("cmp")
    --   cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
    -- end,
  },
  {
    "utilyre/sentiment.nvim",
    version = "*",
    event = "VeryLazy", -- keep for lazy loading
    opts = {
      -- config
    },
    init = function()
      -- `matchparen.vim` needs to be disabled manually in case of lazy loading
      vim.g.loaded_matchparen = 1
    end,
  },
  {
    "MagicDuck/grug-far.nvim",
    -- cmd = { "GrugFar" },
    config = function()
      require("grug-far").setup({
        -- windowCreationCommand = 'topleft split',
        -- 不读取全局 ~/.ripgreprc（其中用 glob 排除了 third_party 等目录，
        -- 会导致 grug-far 永远搜不到这些内容）。要过滤的目录改为在
        -- search_toggle.lua 的默认 Files Filter 里显式声明，方便按需删改。
        -- --no-ignore-vcs：不尊重 .gitignore/.git/info/exclude，这样能搜到被 git
        -- 忽略的文件（比如构建生成的头文件 src/pagestore/api/psterr.h 里的枚举
        -- 定义）；third_party/build/.tmp 等仍由默认 Files Filter 排除。
        engines = {
          ripgrep = {
            extraArgs = "--no-config --no-ignore-vcs",
          },
        },
        keymaps = {
          replace = { n = "<localleader>r" },
          qflist = { n = "<C-q>" },
          syncLocations = { n = "<localleader>s" },
          syncLine = { n = "<localleader>l" },
          -- <localleader>q 被 autocmds.lua 重绑为 hide（关窗保留输入），
          -- 这里把会销毁 buffer/丢失输入的内置 close 动作挪到 <localleader>Q。
          close = { n = "<localleader>Q" },
          historyOpen = { n = "<localleader>t" },
          historyAdd = { n = "<localleader>a" },
          refresh = { n = "<localleader>f" },
          openLocation = { n = "<localleader>o" },
          openNextLocation = { n = "<localleader>j" },
          openPrevLocation = { n = "<localleader>k" },
          gotoLocation = { n = "<enter>" },
          pickHistoryEntry = { n = "<enter>" },
          abort = { n = "<localleader>b" },
          help = { n = "g?" },
          toggleShowCommand = { n = "<localleader>c" },
          swapEngine = { n = "<localleader>e" },
          previewLocation = { n = "<localleader>p" },
          swapReplacementInterpreter = { n = "<localleader>x" },
        },
        -- ... options, see Configuration section below ...
        -- ... there are no required options atm...
      })

      -- 每次搜索完成自动写 history，并把 history 限制在 max_items 条
      require("grug_far_history").setup({ max_items = 30 })
    end,
  },
  {
    "nvim-lualine/lualine.nvim",
    enabled = true,
    dependencies = {
      "nvim-tree/nvim-web-devicons",
      "arkav/lualine-lsp-progress",
    },
    config = function()
      require("lualine").setup({
        options = {
          icons_enabled = true,
          theme = "auto",
          component_separators = { left = "", right = "" },
          section_separators = { left = "", right = "" },
          disabled_filetypes = {
            statusline = {},
            winbar = {},
          },
          ignore_focus = {},
          always_divide_middle = true,
          globalstatus = false,
          refresh = {
            statusline = 1000,
            tabline = 1000,
            winbar = 1000,
          },
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "branch" },
          lualine_c = {
            -- {
            -- "filename",
            -- path = 1, -- 0: Just the filename
            -- 1: Relative path
            -- 2: Absolute path
            -- 3: Absolute path, with tilde as the home directory
            -- 4: Filename and parent dir, with tilde as the home directory
            -- },
            {
              function()
                local call_graph = require("call_graph")
                if call_graph.is_reuse_buf() then
                  return "cg:" .. tostring(vim.api.nvim_get_current_buf()) .. " reuse"
                else
                  return "cg:" .. tostring(vim.api.nvim_get_current_buf()) .. " not reuse"
                end
              end,
            },
            {
              function()
                if Make.flying_make_job_id then
                  return "compile:" .. tostring(Make.flying_make_job_id)
                end
                return ""
              end,
            },
            "lsp_progress",
          },
          lualine_x = {
            --[[ 'diff', ]]
            {
              function()
                return require("remote_dev_sync").component()
              end,
              cond = function()
                return require("remote_dev_sync").has_session()
              end,
              color = function()
                return require("remote_dev_sync").highlight()
              end,
            },
            "diagnostics",
            "filetype",
            "encoding",
            {
              function()
                local tabstop = vim.opt.tabstop:get() -- 获取当前的 tabstop 数
                return "Tab:" .. tabstop
              end,
            },
            "fileformat",
          },
          lualine_y = {},
          lualine_z = { "location" },
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = { "filename" },
          lualine_x = { "location" },
          lualine_y = {},
          lualine_z = {},
        },
        tabline = {},
        winbar = {
          -- lualine_c = {
          --   "navic",
          --   -- Component specific options
          --   color_correction = nil, -- Can be nil, "static" or "dynamic". This option is useful only when you have highlights enabled.
          --   -- Many colorschemes don't define same backgroud for nvim-navic as their lualine statusline backgroud.
          --   -- Setting it to "static" will perform a adjustment once when the component is being setup. This should
          --   --   be enough when the lualine section isn't changing colors based on the mode.
          --   -- Setting it to "dynamic" will keep updating the highlights according to the current modes colors for
          --   --   the current section.
          --   navic_opts = nil -- lua table with same format as setup's option. All options except "lsp" options take effect when set here.
          -- },
        },
        inactive_winbar = {},
        extensions = {},
      })
    end,
  },
  {
    "SmiteshP/nvim-navic",
    enabled = true,
    opts = {
      icons = {
        File = "󰈙 ",
        Module = " ",
        Namespace = "󰌗 ",
        Package = " ",
        Class = "󰌗 ",
        Method = "󰆧 ",
        Property = " ",
        Field = " ",
        Constructor = " ",
        Enum = "󰕘",
        Interface = "󰕘",
        Function = "󰊕 ",
        Variable = "󰆧 ",
        Constant = "󰏿 ",
        String = "󰀬 ",
        Number = "󰎠 ",
        Boolean = "◩ ",
        Array = "󰅪 ",
        Object = "󰅩 ",
        Key = "󰌋 ",
        Null = "󰟢 ",
        EnumMember = " ",
        Struct = "󰌗 ",
        Event = " ",
        Operator = "󰆕 ",
        TypeParameter = "󰊄 ",
      },
      lsp = {
        auto_attach = true,
        preference = nil,
      },
      highlight = false,
      separator = " > ",
      depth_limit = 0,
      depth_limit_indicator = "..",
      safe_output = true,
      lazy_update_context = false,
      click = false,
      format_text = function(text)
        return text
      end,
    },
  },
  {
    "utilyre/barbecue.nvim",
    name = "barbecue",
    version = "*",
    dependencies = {
      "SmiteshP/nvim-navic",
      "nvim-tree/nvim-web-devicons", -- optional dependency
    },
    opts = {
      -- configurations go here
    },
  },
  {
    "okuuva/auto-save.nvim",
    cmd = "ASToggle",                         -- optional for lazy loading on command
    event = { "InsertLeave", "TextChanged" }, -- optional for lazy loading on trigger events
    config = function()
      require("auto-save").setup({
        enabled = true,                                                -- start auto-save when the plugin is loaded (i.e. when your package manager loads it)
        trigger_events = {                                             -- See :h events
          immediate_save = { "BufLeave", "FocusLost", "InsertLeave" }, -- vim events that trigger an immediate save
          defer_save = { "TextChanged" },                              -- vim events that trigger a deferred save (saves after `debounce_delay`)
          cancel_deferred_save = { "InsertEnter" },                    -- vim events that cancel a pending deferred save
        },
        -- function that takes the buffer handle and determines whether to save the current buffer or not
        -- return true: if buffer is ok to be saved
        -- return false: if it's not ok to be saved
        -- if set to `nil` then no specific condition is applied
        condition = function(buf)
          local fn = vim.fn
          local utils = require("auto-save.utils.data")
          -- don't save for `sql` file types
          if utils.not_in(fn.getbufvar(buf, "&filetype"), { "lua", "NvimTree", "neo-tree", "mysql" }) then
            return true
          end
          return false
        end,
        noautocmd = true,
        write_all_buffers = false, -- write all buffers when the current one meets `condition`
        debounce_delay = 500,      -- delay after which a pending save is executed
        -- log debug messages to 'auto-save.log' file in neovim cache directory, set to `true` to enable
        debug = false,
      })
    end,
  },
  { "famiu/bufdelete.nvim" },
  {
    "simeji/winresizer",
    keys = {
      "<C-e>",
    },
  },
  {
    "Shatur/neovim-session-manager",
    config = function()
      local Path = require("plenary.path")
      local config = require("session_manager.config")
      require("session_manager").setup({
        sessions_dir = Path:new(vim.fn.stdpath("data"), "sessions"), -- The directory where the session files will be saved.
        -- session_filename_to_dir = session_filename_to_dir,     -- Function that replaces symbols into separators and colons to transform filename into a session directory.
        -- dir_to_session_filename = dir_to_session_filename,     -- Function that replaces separators and colons into special symbols to transform session directory into a filename. Should use `vim.loop.cwd()` if the passed `dir` is `nil`.
        autoload_mode = config.AutoloadMode.CurrentDir, -- Define what to do when Neovim is started without arguments. Possible values: Disabled, CurrentDir, LastSession
        autosave_last_session = true,                   -- Automatically save last session on exit and on session switch.
        autosave_ignore_not_normal = true,              -- Plugin will not save a session when no buffers are opened, or all of them aren't writable or listed.
        autosave_ignore_dirs = {},                      -- A list of directories where the session will not be autosaved.
        autosave_ignore_filetypes = {                   -- All buffers of these file types will be closed before the session is saved.
          "gitcommit",
          "gitrebase",
          "NvimTree",
          "Outline",
          "neo-tree",
          "ai-review",
        },
        autosave_ignore_buftypes = { "nofile" }, -- All buffers of these buffer types will be closed before the session is saved.
        autosave_only_in_session = false,        -- Always autosaves session. If true, only autosaves after a session is active.
        max_path_length = 80,                    -- Shorten the display path if length exceeds this threshold. Use 0 if don't want to shorten the path at all.
      })
    end,
  },
  { "s1n7ax/nvim-window-picker" },
  {
    "RRethy/vim-illuminate",
    config = function()
      -- 设置高亮颜色
      -- default configuration
      require("illuminate").configure({
        -- providers: provider used to get references in the buffer, ordered by priority
        providers = {
          "lsp",
          -- "treesitter",
          "regex",
        },
        -- delay: delay in milliseconds
        delay = 500,
        -- filetype_overrides: filetype specific overrides.
        -- The keys are strings to represent the filetype while the values are tables that
        -- supports the same keys passed to .configure except for filetypes_denylist and filetypes_allowlist
        filetype_overrides = {},
        -- filetypes_denylist: filetypes to not illuminate, this overrides filetypes_allowlist
        filetypes_denylist = {
          -- 'dirbuf',
          -- 'dirvish',
          -- 'fugitive',
          -- 'neo-tree',
        },
        -- filetypes_allowlist: filetypes to illuminate, this is overridden by filetypes_denylist
        -- You must set filetypes_denylist = {} to override the defaults to allow filetypes_allowlist to take effect
        filetypes_allowlist = {
          "cpp",
          "c",
          "py",
          "lua",
          "sh",
          "proto",
        },
        -- modes_denylist: modes to not illuminate, this overrides modes_allowlist
        -- See `:help mode()` for possible values
        modes_denylist = {},
        -- modes_allowlist: modes to illuminate, this is overridden by modes_denylist
        -- See `:help mode()` for possible values
        modes_allowlist = {},
        -- providers_regex_syntax_denylist: syntax to not illuminate, this overrides providers_regex_syntax_allowlist
        -- Only applies to the 'regex' provider
        -- Use :echom synIDattr(synIDtrans(synID(line('.'), col('.'), 1)), 'name')
        providers_regex_syntax_denylist = {},
        -- providers_regex_syntax_allowlist: syntax to illuminate, this is overridden by providers_regex_syntax_denylist
        -- Only applies to the 'regex' provider
        -- Use :echom synIDattr(synIDtrans(synID(line('.'), col('.'), 1)), 'name')
        providers_regex_syntax_allowlist = {},
        -- under_cursor: whether or not to illuminate under the cursor
        under_cursor = true,
        -- large_file_cutoff: number of lines at which to use large_file_config
        -- The `under_cursor` option is disabled when this cutoff is hit
        large_file_cutoff = nil,
        -- large_file_config: config to use for large files (based on large_file_cutoff).
        -- Supports the same keys passed to .configure
        -- If nil, vim-illuminate will be disabled for large files.
        large_file_overrides = nil,
        -- min_count_to_highlight: minimum number of matches required to perform highlighting
        min_count_to_highlight = 1,
        -- should_enable: a callback that overrides all other settings to
        -- enable/disable illumination. This will be called a lot so don't do
        -- anything expensive in it.
        should_enable = function(_)
          return true
        end,
        -- case_insensitive_regex: sets regex case sensitivity
        case_insensitive_regex = false,
      })

      -- change the highlight style
      vim.api.nvim_set_hl(0, "IlluminatedWordText", { link = "LspReferenceText" })
      vim.api.nvim_set_hl(0, "IlluminatedWordRead", { link = "LspReferenceRead" })
      vim.api.nvim_set_hl(0, "IlluminatedWordWrite", { link = "LspReferenceWrite" })

      --- auto update the highlight style on colorscheme change
      vim.api.nvim_create_autocmd({ "ColorScheme" }, {
        pattern = { "*" },
        callback = function(_)
          vim.api.nvim_set_hl(0, "IlluminatedWordText", { link = "LspReferenceText" })
          vim.api.nvim_set_hl(0, "IlluminatedWordRead", { link = "LspReferenceRead" })
          vim.api.nvim_set_hl(0, "IlluminatedWordWrite", { link = "LspReferenceWrite" })
        end,
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    version = "*",
    build = ":TSUpdate",
    opts = {
      ensure_installed = {
        "c",
        "cpp",
        "json",
        "yaml",
        "python",
        "lua",
      },
      sync_install = false,
      highlight = {
        enable = false,
      },
      indent = {
        enable = false,
      },
    },
    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      require("nvim-treesitter-textobjects").setup({
        select = {
          -- Automatically jump forward to textobj, similar to targets.vim
          lookahead = true,
          -- You can choose the select mode (default is charwise 'v')
          --
          -- Can also be a function which gets passed a table with the keys
          -- * query_string: eg '@function.inner'
          -- * method: eg 'v' or 'o'
          -- and should return the mode ('v', 'V', or '<c-v>') or a table
          -- mapping query_strings to modes.
          selection_modes = {
            ["@parameter.outer"] = "v", -- charwise
            ["@function.outer"] = "V",  -- linewise
            ["@class.outer"] = "<c-v>", -- blockwise
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
          include_surrounding_whitespace = false,
        },
        move = {
          -- whether to set jumps in the jumplist
          set_jumps = true,
        },
      })

      -- keymaps
      -- You can use the capture groups defined in `textobjects.scm`
      -- for select
      vim.keymap.set({ "x", "o" }, "af", function()
        require("nvim-treesitter-textobjects.select").select_textobject("@function.outer", "textobjects")
      end)
      vim.keymap.set({ "x", "o" }, "if", function()
        require("nvim-treesitter-textobjects.select").select_textobject("@function.inner", "textobjects")
      end)
      vim.keymap.set({ "x", "o" }, "ac", function()
        require("nvim-treesitter-textobjects.select").select_textobject("@class.outer", "textobjects")
      end)
      vim.keymap.set({ "x", "o" }, "ic", function()
        require("nvim-treesitter-textobjects.select").select_textobject("@class.inner", "textobjects")
      end)
      -- You can also use captures from other query groups like `locals.scm`
      vim.keymap.set({ "x", "o" }, "as", function()
        require("nvim-treesitter-textobjects.select").select_textobject("@local.scope", "locals")
      end)

      -- for move
      local function safe_ts_move(method, query, query_group)
        return function()
          local ok_move, move = pcall(require, "nvim-treesitter-textobjects.move")
          if not ok_move then
            vim.notify("nvim-treesitter-textobjects.move is not available", vim.log.levels.WARN)
            return
          end
          local fn = move[method]
          if type(fn) ~= "function" then
            vim.notify("Unknown Tree-sitter move method: " .. tostring(method), vim.log.levels.WARN)
            return
          end
          local ok, err = pcall(fn, query, query_group)
          if not ok then
            vim.notify(
              string.format("Tree-sitter move failed for %s in %s: %s", vim.inspect(query), tostring(query_group), err),
              vim.log.levels.WARN
            )
          end
        end
      end

      vim.keymap.set({ "n", "x", "o" }, "]f", function()
        require("treesitter_function_move").goto_next()
      end)
      vim.keymap.set({ "n", "x", "o" }, "[f", function()
        require("treesitter_function_move").goto_previous()
      end)

      vim.keymap.set({ "n", "x", "o" }, "]m", safe_ts_move("goto_next_start", "@function.outer", "textobjects"))
      vim.keymap.set({ "n", "x", "o" }, "]]", safe_ts_move("goto_next_start", "@class.outer", "textobjects"))
      -- You can also pass a list to group multiple queries.
      vim.keymap.set({ "n", "x", "o" }, "]o",
        safe_ts_move("goto_next_start", { "@loop.inner", "@loop.outer" }, "textobjects"))
      -- You can also use captures from other query groups like `locals.scm` or `folds.scm`
      vim.keymap.set({ "n", "x", "o" }, "]s", safe_ts_move("goto_next_start", "@local.scope", "locals"))
      vim.keymap.set({ "n", "x", "o" }, "]z", safe_ts_move("goto_next_start", "@fold", "folds"))

      vim.keymap.set({ "n", "x", "o" }, "]M", safe_ts_move("goto_next_end", "@function.outer", "textobjects"))
      vim.keymap.set({ "n", "x", "o" }, "][", safe_ts_move("goto_next_end", "@class.outer", "textobjects"))

      vim.keymap.set({ "n", "x", "o" }, "[m", safe_ts_move("goto_previous_start", "@function.outer", "textobjects"))
      vim.keymap.set({ "n", "x", "o" }, "[[", safe_ts_move("goto_previous_start", "@class.outer", "textobjects"))

      vim.keymap.set({ "n", "x", "o" }, "[M", safe_ts_move("goto_previous_end", "@function.outer", "textobjects"))
      vim.keymap.set({ "n", "x", "o" }, "[]", safe_ts_move("goto_previous_end", "@class.outer", "textobjects"))

      --   require("nvim-treesitter.configs").setup({
      --     textobjects = {
      --       select = {
      --         enable = true,
      --         -- Automatically jump forward to textobj, similar to targets.vim
      --         lookahead = true,
      --         keymaps = {
      --           -- You can use the capture groups defined in textobjects.scm
      --           ["af"] = "@function.outer",
      --           ["if"] = "@function.inner",
      --           ["ac"] = "@class.outer",
      --           -- You can optionally set descriptions to the mappings (used in the desc parameter of
      --           -- nvim_buf_set_keymap) which plugins like which-key display
      --           ["ic"] = { query = "@class.inner", desc = "Select inner part of a class region" },
      --           -- You can also use captures from other query groups like `locals.scm`
      --           ["as"] = { query = "@scope", query_group = "locals", desc = "Select language scope" },
      --         },
      --         -- You can choose the select mode (default is charwise 'v')
      --         --
      --         -- Can also be a function which gets passed a table with the keys
      --         -- * query_string: eg '@function.inner'
      --         -- * method: eg 'v' or 'o'
      --         -- and should return the mode ('v', 'V', or '<c-v>') or a table
      --         -- mapping query_strings to modes.
      --         selection_modes = {
      --           ["@parameter.outer"] = "v", -- charwise
      --           ["@function.outer"] = "V",  -- linewise
      --           ["@class.outer"] = "<c-v>", -- blockwise
      --         },
      --         -- If you set this to `true` (default is `false`) then any textobject is
      --         -- extended to include preceding or succeeding whitespace. Succeeding
      --         -- whitespace has priority in order to act similarly to eg the built-in
      --         -- `ap`.
      --         --
      --         -- Can also be a function which gets passed a table with the keys
      --         -- * query_string: eg '@function.inner'
      --         -- * selection_mode: eg 'v'
      --         -- and should return true or false
      --         include_surrounding_whitespace = true,
      --       },
      --       move = {
      --         enable = true,
      --         set_jumps = true, -- whether to set jumps in the jumplist
      --         goto_next_start = {
      --           ["]f"] = "@custom.function.declare",
      --           -- ["]f"] = "@function.outer",
      --           ["]]"] = { query = "@class.outer", desc = "Next class start" },
      --           --
      --           -- You can use regex matching (i.e. lua pattern) and/or pass a list in a "query" key to group multiple queires.
      --           ["]o"] = "@loop.*",
      --           -- ["]o"] = { query = { "@loop.inner", "@loop.outer" } }
      --           --
      --           -- You can pass a query group to use query from `queries/<lang>/<query_group>.scm file in your runtime path.
      --           -- Below example nvim-treesitter's `locals.scm` and `folds.scm`. They also provide highlights.scm and indent.scm.
      --           ["]s"] = { query = "@scope", query_group = "locals", desc = "Next scope" },
      --           ["]z"] = { query = "@fold", query_group = "folds", desc = "Next fold" },
      --         },
      --         goto_next_end = {
      --           ["]F"] = "@function.outer",
      --           ["]["] = "@class.outer",
      --         },
      --         goto_previous_start = {
      --           ["[f"] = "@custom.function.declare",
      --           -- ["[f"] = "@function.outer",
      --           ["[["] = "@class.outer",
      --         },
      --         goto_previous_end = {
      --           ["[F"] = "@function.outer",
      --           ["[]"] = "@class.outer",
      --         },
      --       },
      --     },
      --   })
    end,
  },
  -- ,
  {
    "kylechui/nvim-surround",
    version = "*", -- Use for stability; omit to use `main` branch for the latest features
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup({
        -- Configuration here, or leave empty to use defaults
      })
    end,
  },
  {
    "alexghergh/nvim-tmux-navigation",
    opts = {
      disable_when_zoomed = true, -- defaults to false
    },
    config = function(_, opts)
      local nav = require("nvim-tmux-navigation")
      nav.setup(opts)

      -- Prevent wrap-around: when the current tmux pane is already at the
      -- edge in the requested direction, stay put instead of jumping to the
      -- opposite side. tmux's `select-pane -L/-D/-U/-R` wraps by default, and
      -- the plugin calls it directly (bypassing our tmux.conf keybindings), so
      -- the no-wrap guard has to be applied here too.
      local tmux_util = require("nvim-tmux-navigation.tmux_util")
      local edge_flag = {
        h = "pane_at_left",
        j = "pane_at_bottom",
        k = "pane_at_top",
        l = "pane_at_right",
      }
      local orig_change_pane = tmux_util.tmux_change_pane
      function tmux_util.tmux_change_pane(direction)
        local flag = edge_flag[direction]
        if flag then
          local socket = vim.fn.split(vim.env.TMUX, ",")[1]
          local at_edge = vim.fn.system(
            "tmux -S " .. socket .. " display-message -p '#{" .. flag .. "}'"
          )
          if vim.trim(at_edge) == "1" then
            return -- already at the tmux edge; do not wrap
          end
        end
        orig_change_pane(direction)
      end
    end,
  },
  {
    "folke/lazydev.nvim",
    ft = "lua", -- only load on lua files
    opts = {
      library = {
        -- See the configuration section for more details
        -- Load luvit types when the `vim.uv` word is found
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
  },
  {
    "kevinhwang91/nvim-ufo",
    dependencies = {
      "kevinhwang91/promise-async",
    },
    config = function()
      local handler = function(virtText, lnum, endLnum, width, truncate)
        local newVirtText = {}
        local suffix = (" 󰁂 %d "):format(endLnum - lnum)
        local sufWidth = vim.fn.strdisplaywidth(suffix)
        local targetWidth = width - sufWidth
        local curWidth = 0
        for _, chunk in ipairs(virtText) do
          local chunkText = chunk[1]
          local chunkWidth = vim.fn.strdisplaywidth(chunkText)
          if targetWidth > curWidth + chunkWidth then
            table.insert(newVirtText, chunk)
          else
            chunkText = truncate(chunkText, targetWidth - curWidth)
            local hlGroup = chunk[2]
            table.insert(newVirtText, { chunkText, hlGroup })
            chunkWidth = vim.fn.strdisplaywidth(chunkText)
            -- str width returned from truncate() may less than 2nd argument, need padding
            if curWidth + chunkWidth < targetWidth then
              suffix = suffix .. (" "):rep(targetWidth - curWidth - chunkWidth)
            end
            break
          end
          curWidth = curWidth + chunkWidth
        end
        table.insert(newVirtText, { suffix, "MoreMsg" })
        return newVirtText
      end

      local ufo = require("ufo")
      ufo.setup({
        fold_virt_text_handler = handler,
        provider_selector = function()
          return { "treesitter", "indent" }
        end,
      })
      vim.api.nvim_set_hl(0, "UfoFoldedBg", { bg = nil, fg = nil })
      vim.api.nvim_set_hl(0, "UfoFoldedFg", { link = "Comment" })
      vim.keymap.set("n", "zR", ufo.openAllFolds)
      vim.keymap.set("n", "zM", ufo.closeAllFolds)
    end,
  },
  {
    "tpope/vim-dadbod",
  },
  {
    "kristijanhusak/vim-dadbod-ui",
    dependencies = {
      { "tpope/vim-dadbod",                     lazy = true },
      { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true }, -- Optional
    },
    cmd = {
      "DBUI",
      "DBUIToggle",
      "DBUIAddConnection",
      "DBUIFindBuffer",
    },
    init = function()
      -- Your DBUI configuration
      vim.g.db_ui_use_nerd_fonts = 1
    end,
  },
  -- Lua
  {
    "folke/zen-mode.nvim",
    opts = {
      window = {
        backdrop = 0.95, -- shade the backdrop of the Zen window. Set to 1 to keep the same as Normal
        -- height and width can be:
        -- * an absolute number of cells when > 1
        -- * a percentage of the width / height of the editor when <= 1
        -- * a function that returns the width or the height
        width = 160, -- width of the Zen window
        height = 1,  -- height of the Zen window
        -- by default, no options are changed for the Zen window
        -- uncomment any of the options below, or add other vim.wo options you want to apply
        options = {
          -- signcolumn = "no", -- disable signcolumn
          -- number = false, -- disable number column
          -- relativenumber = false, -- disable relative numbers
          -- cursorline = false, -- disable cursorline
          -- cursorcolumn = false, -- disable cursor column
          -- foldcolumn = "0", -- disable fold column
          -- list = false, -- disable whitespace characters
        },
      },
    },
  },
  {
    "norcalli/nvim-colorizer.lua",
    opts = {},
  },
  {
    {
      "akinsho/bufferline.nvim",
      version = "*",
      lazy = false,
      dependencies = { "nvim-tree/nvim-web-devicons" }, -- 可选图标
      opts = {}
    },
  },
  {
    "nvim-telescope/telescope-frecency.nvim",
    -- install the latest stable version
    version = "*",
    config = function()
      require("telescope").load_extension "frecency"
    end,
  }
}
