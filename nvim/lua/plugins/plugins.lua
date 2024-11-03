return {
	{
		"folke/trouble.nvim",
		cmd = "Trouble",
	},
	{
		"stevearc/dressing.nvim",
	},
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {
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
		"folke/zen-mode.nvim",
		cmd = { "ZenMode" },
		opts = {
			-- your configuration comes here
			-- or leave it empty to use the default settings
			-- refer to the configuration section below
			window = {
				backdrop = 1, -- shade the backdrop of the Zen window. Set to 1 to keep the same as Normal
				-- height and width can be:
				-- * an absolute number of cells when > 1
				-- * a percentage of the width / height of the editor when <= 1
				-- * a function that returns the width or the height
				width = 140, -- width of the Zen window
				height = 1, -- height of the Zen window
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
			plugins = {
				options = {
					enabled = true,
					ruler = false, -- disables the ruler text in the cmd line area
					showcmd = false, -- disables the command in the last line of the screen
					-- you may turn on/off statusline in zen mode by setting 'laststatus'
					-- statusline will be shown only if 'laststatus' == 3
					laststatus = 0, -- turn off the statusline in zen mode
				},
			},
		},
	},
	{
		"ggandor/leap.nvim",
		config = function()
			-- require('leap').create_default_mappings()
			require("leap").init_highlight(true)
		end,
	},
	{
		"lukas-reineke/indent-blankline.nvim",
		main = "ibl",
		opts = {
			indent = {
				char = {
					"│",
				},
			},
			whitespace = { highlight = { "Whitespace", "NonText" } },
			scope = { show_start = false, show_end = false },
		},
		-- config = function()
		--   require("ibl").setup()

		-- require("indent_blankline").setup { -- for version2
		--   buftype_exclude = { "terminal", "nowrite", "help" },
		--   show_trailing_blankline_indent = false,
		--   show_end_of_line = false,
		-- }
		-- end
	},
	{
		"nvim-neo-tree/neo-tree.nvim",
		cmd = {
			"Neotree",
		},
		branch = "v3.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
			"MunifTanjim/nui.nvim",
			-- "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
		},
		config = function()
			require("neo-tree").setup({
				close_if_last_window = false, -- Close Neo-tree if it is the last window left in the tab
				enable_git_status = false,
				enable_diagnostics = false,
				open_files_do_not_replace_types = { "terminal", "trouble", "qf" }, -- when opening files, do not use windows containing these filetypes or buftypes
				sort_case_insensitive = false, -- used when sorting files and directories in the tree
				window = {
					position = "left",
					width = 40,
					mapping_options = {
						noremap = true,
						nowait = true,
					},
					mappings = {
						["<cr>"] = "open",
						["o"] = "open",
						["l"] = "open",
						["<esc>"] = "cancel", -- close preview or floating neo-tree window
						-- Read `# Preview Mode` for more information
						["<C-h>"] = "open_split",
						["<C-v>"] = "open_vsplit",
						["h"] = "close_node",
						-- ['C'] = 'close_all_subnodes',
						["z"] = "close_all_nodes",
						--["Z"] = "expand_all_nodes",
						["a"] = {
							"add",
							-- this command supports BASH style brace expansion ("x{a,b,c}" -> xa,xb,xc). see `:h neo-tree-file-actions` for details
							-- some commands may take optional config options, see `:h neo-tree-mappings` for details
							config = {
								show_path = "none", -- "none", "relative", "absolute"
							},
						},
						["A"] = "add_directory", -- also accepts the optional config.show_path option like "add". this also supports BASH style brace expansion.
						["d"] = "delete",
						["r"] = "rename",
						["y"] = "copy_to_clipboard",
						["x"] = "cut_to_clipboard",
						["p"] = "paste_from_clipboard",
						["c"] = "copy", -- takes text input for destination, also accepts the optional config.show_path option like "add":
						-- ["c"] = {
						--  "copy",
						--  config = {
						--    show_path = "none" -- "none", "relative", "absolute"
						--  }
						--}
						["m"] = "move", -- takes text input for destination, also accepts the optional config.show_path option like "add".
						["q"] = "close_window",
						["R"] = "refresh",
						["g?"] = "show_help",
						["<"] = "prev_source",
						[">"] = "next_source",
						["i"] = "show_file_details",
						["/"] = "noop",
						["?"] = "noop",
						["Y"] = function(state)
							-- NeoTree is based on [NuiTree](https://github.com/MunifTanjim/nui.nvim/tree/main/lua/nui/tree)
							-- The node is based on [NuiNode](https://github.com/MunifTanjim/nui.nvim/tree/main/lua/nui/tree#nuitreenode)
							local node = state.tree:get_node()
							local filepath = node:get_id()
							local filename = node.name
							local modify = vim.fn.fnamemodify

							local results = {
								filepath,
								modify(filepath, ":."),
								modify(filepath, ":~"),
								filename,
								modify(filename, ":r"),
								modify(filename, ":e"),
							}

							vim.ui.select({
								"1. Absolute path: " .. results[1],
								"2. Path relative to CWD: " .. results[2],
								"3. Path relative to HOME: " .. results[3],
								"4. Filename: " .. results[4],
								"5. Filename without extension: " .. results[5],
								"6. Extension of the filename: " .. results[6],
							}, { prompt = "Choose to copy to clipboard:" }, function(choice)
								if choice == nil then
									return
								end
								local i = tonumber(choice:sub(1, 1))
								local result = results[i]
								vim.fn.setreg("*", result)
								vim.notify("Copied: " .. result)
							end)
						end,
					},
				},
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
				numhl = false, -- Toggle with `:Gitsigns toggle_numhl`
				linehl = false, -- Toggle with `:Gitsigns toggle_linehl`
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
				status_formatter = nil, -- Use default
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
		commit = "d90956833d7c27e73c621a61f20b29fdb7122709",
		-- tag = '0.1.6',
		dependencies = {
			"nvim-lua/plenary.nvim",
			{
				"nvim-telescope/telescope-live-grep-args.nvim",
				version = "^1.0.0",
			},
			{
				"isak102/telescope-git-file-history.nvim",
				dependencies = {
					"tpope/vim-fugitive",
				},
			},
		},
		config = function()
			local function filename_first(_, path)
				local tail = vim.fs.basename(path)
				local parent = vim.fs.dirname(path)
				if parent == "." then
					return tail
				end
				return string.format("%s\t\t%s", tail, parent)
			end

			local actions = require("telescope.actions")
			local telescope = require("telescope")
			local open_with_trouble = require("trouble.sources.telescope").open
			telescope.setup({
				defaults = {
					-- sorting_strategy = "ascending", -- display results top->bottom
					-- layout_config = {
					--   prompt_position = "top",
					-- },
					path_display = function(opts, path)
						local tail = vim.fs.basename(path)
						local parent = vim.fs.dirname(path)
						if parent == "." then
							return tail
						end
						return string.format("%s (%s)", tail, parent)
					end,
					mappings = {
						i = {
							["<c-t>"] = open_with_trouble,
							["<C-j>"] = actions.cycle_history_next,
							["<C-k>"] = actions.cycle_history_prev,
						},
						n = {
							["<c-t>"] = open_with_trouble,
							["<C-j>"] = actions.cycle_history_next,
							["<C-k>"] = actions.cycle_history_prev,
						},
					},
				},
			})
			telescope.load_extension("live_grep_args")
			telescope.load_extension("git_file_history")
		end,
	},
	{
		"stevearc/aerial.nvim",
		event = "LspAttach",
		opts = {},
		dependencies = {
			-- "nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons",
		},
	},
	{
		"akinsho/toggleterm.nvim",
		keys = {
			"<C-\\>",
			"<leader>gg",
			"<leader>gt",
			"<leader>gb",
		},
		version = "*",
		config = function()
			require("toggleterm").setup({
				size = 40,
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
				float_opts = {
					border = "curved",
					winblend = 0,
					border = "single",
					width = 300,
					height = 100,
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
			})
			function _lazygit_toggle()
				lazygit:toggle()
			end

			vim.api.nvim_set_keymap(
				"n",
				"<leader>gg",
				"<cmd>lua _lazygit_toggle()<CR>",
				{ noremap = true, silent = true }
			)
			vim.api.nvim_set_keymap(
				"n",
				"<leader>gt",
				"<cmd>TermExec cmd='tig %' go_back=1 direction=float<CR>",
				{ noremap = true, silent = true }
			)
			vim.api.nvim_set_keymap(
				"n",
				"<leader>gb",
				"<cmd>TermExec cmd='tig blame %' go_back=1 direction=float<CR>",
				{ noremap = true, silent = true }
			)
			vim.api.nvim_set_keymap("t", "<c-q>", "<cmd>bd!<cr>", { noremap = true, silent = true })
		end,
	},
	{
		"windwp/nvim-autopairs",
		dependencies = {
			"hrsh7th/nvim-cmp", -- Autocompletion plugin
		},
		event = "InsertEnter",
		config = function()
			require("nvim-autopairs").setup({
				disable_filetype = { "TelescopePrompt", "vim", "spectre_panel", "dap-repl" },
			})
			-- add auto pair when auto completion down
			local cmp_autopairs = require("nvim-autopairs.completion.cmp")
			local cmp = require("cmp")
			cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
		end,
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
		cmd = { "GrugFar" },
		config = function()
			require("grug-far").setup({
				-- ... options, see Configuration section below ...
				-- ... there are no required options atm...
			})
		end,
	},
	{
		"romgrk/barbar.nvim",
		dependencies = {
			"lewis6991/gitsigns.nvim", -- OPTIONAL: for git status
			"nvim-tree/nvim-web-devicons", -- OPTIONAL: for file icons
		},
		init = function()
			vim.g.barbar_auto_setup = false
		end,
		opts = {
			icons = {
				pinned = { button = "", filename = true },
			},
			-- lazy.nvim will automatically call setup for you. put your options here, anything missing will use the default:
			-- animation = true,
			-- insert_at_start = true,
			-- …etc.
		},
		version = "^1.0.0", -- optional: only update when a new 1.x version is released
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
						{
							"filename",
							path = 1, -- 0: Just the filename
							-- 1: Relative path
							-- 2: Absolute path
							-- 3: Absolute path, with tilde as the home directory
							-- 4: Filename and parent dir, with tilde as the home directory
						},
						"lsp_progress",
					},
					lualine_x = {
						--[[ 'diff', ]]
						"diagnostics",
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
		cmd = "ASToggle", -- optional for lazy loading on command
		event = { "InsertLeave", "TextChanged" }, -- optional for lazy loading on trigger events
		config = function()
			require("auto-save").setup({
				enabled = true, -- start auto-save when the plugin is loaded (i.e. when your package manager loads it)
				execution_message = {
					enabled = false,
					message = function() -- message to print on save
						return ("AutoSave: saved at " .. vim.fn.strftime("%H:%M:%S"))
					end,
					dim = 0.18, -- dim the color of `message`
					cleaning_interval = 1250, -- (milliseconds) automatically clean MsgArea after displaying `message`. See :h MsgArea
				},
				trigger_events = { -- See :h events
					immediate_save = { "BufLeave", "FocusLost" }, -- vim events that trigger an immediate save
					defer_save = { "InsertLeave", "TextChanged" }, -- vim events that trigger a deferred save (saves after `debounce_delay`)
					cancel_defered_save = { "InsertEnter" }, -- vim events that cancel a pending deferred save
				},
				-- function that takes the buffer handle and determines whether to save the current buffer or not
				-- return true: if buffer is ok to be saved
				-- return false: if it's not ok to be saved
				-- if set to `nil` then no specific condition is applied
				condition = function(buf)
					local fn = vim.fn
					local utils = require("auto-save.utils.data")
					-- don't save for `sql` file types
					if utils.not_in(fn.getbufvar(buf, "&filetype"), { "lua", "NvimTree" }) then
						return true
					end
					return false
				end,
				write_all_buffers = false, -- write all buffers when the current one meets `condition`
				noautocmd = false, -- do not execute autocmds when saving
				debounce_delay = 1000, -- delay after which a pending save is executed
				-- log debug messages to 'auto-save.log' file in neovim cache directory, set to `true` to enable
				debug = false,
			})
		end,
	},
	-- { "famiu/bufdelete.nvim" },
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
				autosave_last_session = true, -- Automatically save last session on exit and on session switch.
				autosave_ignore_not_normal = true, -- Plugin will not save a session when no buffers are opened, or all of them aren't writable or listed.
				autosave_ignore_dirs = {}, -- A list of directories where the session will not be autosaved.
				autosave_ignore_filetypes = { -- All buffers of these file types will be closed before the session is saved.
					"gitcommit",
					"gitrebase",
				},
				autosave_ignore_buftypes = {}, -- All buffers of these bufer types will be closed before the session is saved.
				autosave_only_in_session = false, -- Always autosaves session. If true, only autosaves after a session is active.
				max_path_length = 80, -- Shorten the display path if length exceeds this threshold. Use 0 if don't want to shorten the path at all.
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
				should_enable = function(bufnr)
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
				callback = function(ev)
					vim.api.nvim_set_hl(0, "IlluminatedWordText", { link = "LspReferenceText" })
					vim.api.nvim_set_hl(0, "IlluminatedWordRead", { link = "LspReferenceRead" })
					vim.api.nvim_set_hl(0, "IlluminatedWordWrite", { link = "LspReferenceWrite" })
				end,
			})
		end,
	},
	-- {
	-- 	"andersevenrud/nvim_context_vt",
	-- 	event = "VeryLazy",
	-- 	config = function()
	-- 		require("nvim_context_vt").setup({
	-- 			-- Enable by default. You can disable and use :NvimContextVtToggle to maually enable.
	-- 			-- Default: true
	-- 			enabled = true,
	--
	-- 			-- Override default virtual text prefix
	-- 			-- Default: '-->'
	-- 			prefix = "",
	--
	-- 			-- Override the internal highlight group name
	-- 			-- Default: 'ContextVt'
	-- 			highlight = "ContextVt",
	--
	-- 			-- Disable virtual text for given filetypes
	-- 			-- Default: { 'markdown' }
	-- 			disable_ft = { "markdown" },
	--
	-- 			-- Disable display of virtual text below blocks for indentation based languages like Python
	-- 			-- Default: false
	-- 			disable_virtual_lines = false,
	--
	-- 			-- Same as above but only for spesific filetypes
	-- 			-- Default: {}
	-- 			disable_virtual_lines_ft = { "yaml" },
	--
	-- 			-- How many lines required after starting position to show virtual text
	-- 			-- Default: 1 (equals two lines total)
	-- 			min_rows = 5,
	--
	-- 			-- Same as above but only for spesific filetypes
	-- 			-- Default: {}
	-- 			min_rows_ft = {},
	-- 		})
	-- 	end,
	-- },
	{
		"nvim-treesitter/nvim-treesitter",
		version = "*",
		-- commit = "1b050206e490a4146cdf25c7b38969c1711b5620",
		build = ":TSUpdate",
		config = function()
			local configs = require("nvim-treesitter.configs")
			configs.setup({
				ensure_installed = {
					"cpp",
					"json",
					"yaml",
				},
				sync_install = false,
				highlight = {
					enable = false,
					use_languagetree = false,
					disable = function(lang, bufnr)
						local buf_name = vim.api.nvim_buf_get_name(bufnr)
						local file_size = vim.api.nvim_call_function("getfsize", { buf_name })
						return file_size > 30 * 1024
					end,
					additional_vim_regex_highlighting = false,
				},
				indent = {
					enable = false,
					-- disable = {
					--   "python"
					-- }
				},
			})
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
		},
		config = function()
			require("nvim-treesitter.configs").setup({
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
							-- You can also use captures from other query groups like `locals.scm`
							["as"] = { query = "@scope", query_group = "locals", desc = "Select language scope" },
						},
						-- You can choose the select mode (default is charwise 'v')
						--
						-- Can also be a function which gets passed a table with the keys
						-- * query_string: eg '@function.inner'
						-- * method: eg 'v' or 'o'
						-- and should return the mode ('v', 'V', or '<c-v>') or a table
						-- mapping query_strings to modes.
						selection_modes = {
							["@parameter.outer"] = "v", -- charwise
							["@function.outer"] = "V", -- linewise
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
						-- and should return true or false
						include_surrounding_whitespace = true,
					},
					move = {
						enable = true,
						set_jumps = true, -- whether to set jumps in the jumplist
						goto_next_start = {
							["]f"] = "@function.outer",
							["]]"] = { query = "@class.outer", desc = "Next class start" },
							--
							-- You can use regex matching (i.e. lua pattern) and/or pass a list in a "query" key to group multiple queires.
							["]o"] = "@loop.*",
							-- ["]o"] = { query = { "@loop.inner", "@loop.outer" } }
							--
							-- You can pass a query group to use query from `queries/<lang>/<query_group>.scm file in your runtime path.
							-- Below example nvim-treesitter's `locals.scm` and `folds.scm`. They also provide highlights.scm and indent.scm.
							["]s"] = { query = "@scope", query_group = "locals", desc = "Next scope" },
							["]z"] = { query = "@fold", query_group = "folds", desc = "Next fold" },
						},
						goto_next_end = {
							["]F"] = "@function.outer",
							["]["] = "@class.outer",
						},
						goto_previous_start = {
							["[f"] = "@function.outer",
							["[["] = "@class.outer",
						},
						goto_previous_end = {
							["[F"] = "@function.outer",
							["[]"] = "@class.outer",
						},
					},
				},
			})
		end,
	},
	{
		"iamcco/markdown-preview.nvim",
		enabled = vim.fn.executable("npm") == 1,
		cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
		build = "cd app && npm install",
		init = function()
			vim.g.mkdp_filetypes = { "markdown" }
			vim.g.mkdp_auto_close = 1
			vim.g.mkdp_command_for_global = 1
			vim.g.mkdp_combine_preview = 1

			local function load_then_exec(cmd)
				return function()
					vim.cmd.delcommand(cmd)
					require("lazy").load({ plugins = { "markdown-preview.nvim" } })
					vim.api.nvim_exec_autocmds("BufEnter", {}) -- commands appear only after BufEnter
					vim.cmd(cmd)
				end
			end

			---Fixes "No command :MarkdownPreview"
			---https://github.com/iamcco/markdown-preview.nvim/issues/585#issuecomment-1724859362
			for _, cmd in pairs({ "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle" }) do
				vim.api.nvim_create_user_command(cmd, load_then_exec(cmd), {})
			end
		end,
	},
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
		"akinsho/git-conflict.nvim",
		version = "*",
		config = true,
		opts = {
			default_mappings = {
				ours = "co",
				theirs = "ct",
				none = "c0",
				both = "cb",
				next = "]x",
				prev = "[x",
			}, -- disable buffer local mapping created by this plugin
			default_commands = true, -- disable commands created by this plugin
			disable_diagnostics = false, -- This will disable the diagnostics in a buffer whilst it is conflicted
			list_opener = "copen", -- command or function to open the conflicts list
			highlights = { -- They must have background color, otherwise the default color will be used
				incoming = "DiffAdd",
				current = "DiffText",
			},
		},
	},
	{
		"Pocco81/HighStr.nvim",
	},
}
