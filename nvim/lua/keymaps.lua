local opts = { noremap = true, silent = true }

-- Shorten function name
local keymap = vim.keymap.set

--Remap space as leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

keymap("i", "jk", "<Esc>", opts)

keymap("n", "j", "gj", opts)
keymap("n", "k", "gk", opts)

keymap("n", "<C-h>", "<cmd>NvimTmuxNavigateLeft<CR>", opts)
keymap("n", "<C-j>", "<Cmd>NvimTmuxNavigateDown<CR>", opts)
keymap("n", "<C-k>", "<Cmd>NvimTmuxNavigateUp<CR>", opts)
keymap("n", "<C-l>", "<Cmd>NvimTmuxNavigateRight<CR>", opts)

-- Navigate line
keymap("n", "H", "^", opts)
keymap("n", "L", "$", opts)
keymap("v", "H", "^", opts)
keymap("v", "L", "$", opts)

-- Visual --
-- Stay in indent mode
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)

-- no highlight
keymap("n", "<leader>h", ":nohl<cr>", opts)

-- save all buffer
keymap("n", "<leader>w", "<cmd>wa<cr>", opts)
-- exit cur window
keymap("n", "<leader>q", "<cmd>q<cr>", opts)
-- exit all
keymap("n", "<C-q>", "<cmd>wqa!<cr>", opts)

-- p does not replace reigster
keymap("v", "p", '"_dP', opts)

-- Nvim tree
keymap("n", "<leader>e", "<cmd>NvimTreeToggle<cr>", opts)
keymap("n", "<leader>o", "<cmd>NvimTreeFindFile!<cr>", opts)

-- Buffer
keymap("n", "E", "<cmd>BufferLineCyclePrev<cr>", opts)
keymap("n", "R", "<cmd>BufferLineCycleNext<cr>", opts)

keymap("n", "<leader>bp", "<cmd>BufferLineTogglePin<cr>", opts)
keymap("n", "<leader>bb", "<cmd>BufferLinePick<cr>", opts)
-- buffer delete
keymap("n", "<leader>bd", "<cmd>lua require('bufdelete').bufdelete(0, true)<cr>", opts)

-- Gitsigns
keymap("n", "<leader>gp", "<cmd>Gitsigns preview_hunk<cr>", opts)
keymap("n", "<leader>gr", "<cmd>Gitsigns reset_hunk<cr>", opts)
keymap("n", "<leader>gs", "<cmd>Gitsigns stage_hunk<cr>", opts)
keymap("n", "<leader>gl", "<cmd>Gitsigns blame_line<cr>", opts)
keymap("n", "<leader>gb", "<cmd>Gitsigns blame<cr>", opts)
keymap("n", "]g", "<cmd>Gitsigns next_hunk<cr>", opts)
keymap("n", "[g", "<cmd>Gitsigns prev_hunk<cr>", opts)

-- diffview
keymap("n", "<leader>gc", "<cmd>DiffviewFileHistory<cr>", opts)
keymap("n", "<leader>gf", "<cmd>DiffviewFileHistory --follow %<cr>", opts)
keymap("n", "<leader>gh", "<cmd>DiffviewOpen HEAD<cr>", opts)
keymap("n", "<leader>go", "<cmd>DiffviewClose<cr>", opts)

-- Telescope
keymap("n", "<leader>r", function()
  require("telescope_prompt_guard").guard_initial_a()
  vim.schedule(function()
    require("telescope").extensions.frecency.frecency()
  end)
end, opts)
keymap("n", "<leader>D", "<cmd>Telescope diagnostics<cr>", opts)
keymap("n", "<leader>f<cr>", "<cmd>Telescope resume<cr>", opts)
keymap("n", "<leader>fb", "<cmd>Telescope buffers theme=ivy<cr>", opts)
keymap("n", "<leader>ff", function()
  require("search_toggle").find_files()
end, { desc = "Find files" })
keymap("n", "<leader>fm", ':lua require("search_toggle").open_search_menu()<cr>', { desc = "Search menu" })
keymap(
  "n",
  "<leader>s",
  function()
    require("telescope.builtin").lsp_document_symbols({
      symbol_width = 55,
      fname_width = 25
    })
  end,
  { desc = "Document symbols" }
)
keymap("n", "<leader>S", function()
  require("telescope.builtin").lsp_dynamic_workspace_symbols({
    symbol_width = 55,
    fname_width = 25
  })
end, { desc = "Workspace symbols" })
keymap("n", "gr", "<cmd>Telescope lsp_references<cr>", opts)
keymap("n", "gd", "<cmd>Telescope lsp_definitions<cr>", opts)


-- outline
keymap("n", "<leader>lo", "<cmd>Outline<CR>", opts)

-- search & replace config
keymap("n", "<leader>fg", function()
  require("search_toggle").open_grug_far()
end, { desc = "Grug-far: open search" })
keymap("n", "<leader>fw", function()
  require("search_toggle").open_grug_far_with_cword()
end, { desc = "Grug-far: search current word" })
keymap("v", "<leader>fw", function()
  require("search_toggle").open_grug_far_with_visual_selection()
end, { desc = "Grug-far: search visual selection" })
keymap("n", "<leader>fr", function()
  require("search_toggle").open_grug_far()
end, { desc = "Search and replace" })

-- session manager
keymap("n", "<leader>P", "<cmd>SessionManager! load_session<cr>", opts)

-- lsp
keymap("n", "<leader>li", "<cmd>LspInfo<cr>", opts)

-- DB
keymap("n", "<leader>dB", "<cmd>DBUIToggle<cr>", opts)

-- diff
keymap("n", "<leader>dd", "<cmd>diffthis<cr>", opts)
keymap("n", "<leader>do", "<cmd>diffoff<cr>", opts)

-- leap
keymap("n", "t", "<Plug>(leap-forward)", opts)
keymap("n", "T", "<Plug>(leap-backward)", opts)
keymap("n", "gs", "<Plug>(leap-from-window)", opts)

-- quickfix
local function is_quickfix_open()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].buftype == 'quickfix' then
      return true
    end
  end
  return false
end

local function goto_next_qf_or_diff()
  if is_quickfix_open() then
    vim.cmd("cnext")
  else
    vim.cmd("normal! ]c")
  end
end

local function goto_prev_qf_or_diff()
  if is_quickfix_open() then
    vim.cmd("cprev")
  else
    vim.cmd("normal! [c")
  end
end

keymap("n", "]c", goto_next_qf_or_diff, opts)
keymap("n", "[c", goto_prev_qf_or_diff, opts)

-- zenmode
keymap("n", "<leader>zz", "<cmd>ZenMode<cr>", opts)

-- call_graph.nvim plugin
keymap("n", "<leader>ci", "<cmd>CallGraphI<cr>", opts)
keymap("n", "<leader>cr", "<cmd>CallGraphR<cr>", opts)
keymap("n", "<leader>co", "<cmd>CallGraphO<cr>", opts)
keymap("n", "<leader>cm", "<cmd>CallGraphOpenMermaidGraph<cr>", opts)
keymap("n", "<leader>cl", "<cmd>CallGraphOpenLastestGraph<cr>", opts)
keymap("n", "<leader>ch", "<cmd>CallGraphHistory<cr>", opts)
keymap("n", "<leader>cc", "<cmd>CallGraphClearHistory<cr>", opts)


-- custom_make.plugin
keymap("n", "<leader>mm", "<cmd>Make<cr> ", opts)
keymap("n", "<leader>mr", "<cmd>MakeRun<cr>", opts)
keymap("n", "<leader>ms", "<cmd>MakeSelect<cr>", opts)
keymap("n", "<leader>mk", "<cmd>KillMake<cr>", opts)

-- change macro keyshort for not interrupting cmp plugin
keymap("n", "Q", "q", opts)
keymap("n", "q", "<Nop>", opts)

-- highlight current line
keymap("n", "<leader>bm", function()
  require("bookmarks").toggle_bookmark()
end, opts)
keymap("n", "<leader>bc", function()
  require("bookmarks").clear_current_buffer_bookmarks()
end, opts)
keymap("n", "<leader>bC", function()
  require("bookmarks").clear_all_bookmarks()
end, opts)
keymap("n", "<leader>bs", function()
  require("bookmarks").list_current_buffer_bookmarks()
end, opts)
keymap("n", "<leader>bS", function()
  require("bookmarks").list_all_buffer_bookmarks()
end, opts)
keymap("n", "]b", function()
  require("bookmarks").goto_next_bookmark()
end, opts)
keymap("n", "[b", function()
  require("bookmarks").goto_prev_bookmark()
end, opts)

-- cppp header/source switch
keymap("n", "<leader>j", "<cmd>LspClangdSwitchSourceHeader<cr>", opts)

keymap("n", "yb", "<cmd>CopyBreakPoint<cr>", opts)
keymap("n", "yf", "<cmd>CopyFileName<cr>", opts)
keymap("n", "yF", "<cmd>CopyFilePath<cr>", opts)
keymap("n", "yo", "<cmd>CopyFileNameWoExt<cr>", opts)
keymap("n", "yO", "<cmd>CopyFilePathWoExt<cr>", opts)
keymap("n", "yr", "<cmd>CopyRelativeFilePath<cr>", opts)
keymap("n", "ym", "<cmd>CopyFuncName<cr>", opts)

-- plugin dev
keymap("n", "<leader>t", "<cmd>PlenaryBustedFile %<cr>", opts)

-- send content to codex CLI in a tmux pane (paste only, no submit)
local codex_send = require('codex_send')
keymap('v', '<C-c>', codex_send.send_selection,
  vim.tbl_extend('force', opts, { desc = 'Send selection text to codex (tmux, no submit)' }))
keymap('v', '<C-l>', codex_send.send_lines,
  vim.tbl_extend('force', opts, { desc = 'Send selection line range to codex (tmux, no submit)' }))

-- 运行时切换目标 pane，例如 :CodexPane mysession:0.1
vim.api.nvim_create_user_command('CodexPane', function(o)
  codex_send.set_pane(o.args)
end, { nargs = 1 })
