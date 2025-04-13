local opts = { noremap = true, silent = true }

-- Shorten function name
local keymap = vim.keymap.set

--Remap space as leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

keymap("i", "jk", "<Esc>", opts)

-- Better window navigation
-- keymap("n", "<C-h>", "<C-w>h", opts)
-- keymap("n", "<C-j>", "<C-w>j", opts)
-- keymap("n", "<C-k>", "<C-w>k", opts)
-- keymap("n", "<C-l>", "<C-w>l", opts)

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
keymap("n", "<leader>e", "<cmd>Neotree toggle<cr>", opts)
keymap("n", "<leader>o", "<cmd>Neotree reveal<cr>", opts)

-- Buffer
-- keymap("n", "E", "<cmd>BufferPrevious<cr>", opts)
-- keymap("n", "R", "<cmd>BufferNext<cr>", opts)

-- keymap("n", "<leader>bp", "<cmd>BufferPin<cr>", opts)
-- keymap("n", "<leader>bb", "<cmd>BufferPick<cr>", opts)
-- buffer delete
keymap("n", "<leader>bd", "<cmd>lua require('bufdelete').bufdelete(0, true)<cr>", opts)
-- keymap("n", "<leader>bd", "<cmd>BufferClose<cr>", opts)

-- Gitsigns
keymap("n", "<leader>gp", "<cmd>Gitsigns preview_hunk<cr>", opts)
keymap("n", "<leader>gr", "<cmd>Gitsigns reset_hunk<cr>", opts)
keymap("n", "<leader>gs", "<cmd>Gitsigns stage_hunk<cr>", opts)
keymap("n", "<leader>gl", "<cmd>Gitsigns blame_line<cr>", opts)
keymap("n", "]g", "<cmd>Gitsigns next_hunk<cr>", opts)
keymap("n", "[g", "<cmd>Gitsigns prev_hunk<cr>", opts)
keymap("n", "<leader>gf", "<cmd>Telescope git_file_history<cr>", opts)

-- Telescope
-- keymap("n", "<leader>r", "<cmd>Telescope oldfiles<cr>", opts)
keymap("n", "<leader>r", "<cmd>Telescope frecency<cr>", opts)
keymap("n", "<leader>D", "<cmd>Telescope diagnostics<cr>", opts)
keymap("n", "<leader>f<cr>", "<cmd>Telescope resume<cr>", opts)
keymap("n", "<leader>ff", "<cmd>Telescope find_files<cr>", opts)
keymap("n", "<leader>fb", "<cmd>Telescope buffers theme=ivy<cr>", opts)
keymap(
  "n",
  "<leader>fw",
  "<cmd>lua require('telescope-live-grep-args.shortcuts').grep_word_under_cursor({postfix=''})<cr>",
  opts
)
keymap(
  "v",
  "<leader>fw",
  "<cmd>lua require('telescope-live-grep-args.shortcuts').grep_visual_selection({postfix=''})<cr>",
  opts
)
keymap("n", "<leader>fg", "<cmd>lua require('telescope').extensions.live_grep_args.live_grep_args()<cr>", opts)
-- no ignore, no config
keymap(
  "n",
  "<leader>fF",
  "<cmd>Telescope find_files find_command=rg,--no-ignore,--hidden,--files,--no-config<cr>",
  opts
)
keymap(
  "n",
  "<leader>fW",
  "<cmd>lua require('telescope-live-grep-args.shortcuts').grep_word_under_cursor({postfix=' --no-ignore --no-config'})<cr>",
  opts
)

keymap(
  "v",
  "<leader>fW",
  "<cmd>lua require('telescope-live-grep-args.shortcuts').grep_visual_selection({postfix=' --no-ignore --no-config'})<cr>",
  opts
)
keymap(
  "n",
  "<leader>s",
  "<cmd>lua require('telescope.builtin').lsp_document_symbols({symbol_width = 55, fname_width = 25})<cr>",
  opts
)
keymap("n", "<leader>S", "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>", opts)
keymap("n", "gr", "<cmd>Telescope lsp_references<cr>", opts)
keymap("n", "gd", "<cmd>Telescope lsp_definitions<cr>", opts)

-- outline
-- keymap("n", "<leader>lo", "<cmd>AerialToggle!<cr>", opts)
keymap("n", "<leader>lo", "<cmd>Outline<CR>", opts)

-- lazygit
-- keymap("n", "<leader>gg", "<cmd>LazyGit<cr>", opts)

-- search & replace config
keymap("n", "<leader>fr", "<cmd>GrugFar<cr>", opts)
-- keymap("n", "<leader>fg", "<cmd>GrugFar<cr>", opts)
-- keymap("n", "<leader>fw", "<cmd>lua require('grug-far').open({ prefills = { search = vim.fn.expand('<cword>') } })<cr>",
--   opts)
-- keymap("n", "<leader>fc",
--   "<cmd>lua require('grug-far').open({ prefills = { paths = vim.fn.expand('%'),  search = vim.fn.expand('<cword>')  } })<cr>",
--   opts)
-- keymap("v", "<leader>fw",
--   ":<C-u>lua require('grug-far').with_visual_selection({ prefills = { search = vim.fn.expand('<cword>') } })<cr>", opts)

-- session manager
keymap("n", "<leader>P", "<cmd>SessionManager! load_session<cr>", opts)

-- lsp
keymap("n", "<leader>li", "<cmd>LspInfo<cr>", opts)

-- dap
-- keymap("n", "<leader>dt", "<cmd>lua require('dapui').toggle()<cr>", opts)
-- keymap("n", "<leader>dT", "<cmd>lua require('dapui').float_element('stacks', {})<cr>", opts)
-- keymap("n", "<leader>db", "<cmd>lua require'dap'.toggle_breakpoint()<cr>", opts)
-- keymap("n", "<leader>dB", "<cmd>lua require'dap'.toggle_breakpoint(vim.fn.input('Breakpoint condition: '))<cr>", opts)
-- keymap("n", "<leader>dc", "<cmd>DapContinue<cr>", opts)
-- keymap("n", "<leader>dn", "<cmd>lua require'dap'.step_over()<cr>", opts)
-- keymap("n", "<leader>ds", "<cmd>lua require'dap'.step_into()<cr>", opts)
-- keymap("n", "<leader>df", "<cmd>lua require'dap'.step_out()<cr>", opts)
-- keymap("n", "<leader>dk", "<cmd>lua require'dap'.terminate()<cr>", opts)
-- keymap("n", "<leader>de", "<cmd>lua require('dapui').eval()<cr>", opts)
-- keymap("n", "<leader>d<cr>", "<cmd>lua require'dap'.run_last()<cr>", opts)

-- diff
keymap("n", "<leader>dd", "<cmd>diffthis<cr>", opts)
keymap("n", "<leader>do", "<cmd>diffoff<cr>", opts)

-- leap
keymap("n", "t", "<Plug>(leap-forward)", opts)
keymap("n", "T", "<Plug>(leap-backward)", opts)
keymap("n", "gs", "<Plug>(leap-from-window)", opts)

-- quickfix
keymap("n", "]c", "<cmd>cn<cr>", opts)
keymap("n", "[c", "<cmd>cp<cr>", opts)

-- zenmode
keymap("n", "<leader>zz", "<cmd>ZenMode<cr>", opts)
-- foucs
keymap("n", "<leader>zf", "<cmd>FocusToggle<cr>", opts)

-- neogen
-- keymap("n", "<leader>c", "<cmd>Neogen<cr>", opts)

-- trouble
-- keymap("n", "<leader>d", "<cmd>Trouble diagnostics toggle filter.buf=0 win.position=bottom<cr>", opts)
-- keymap("n", "<leader>D", "<cmd>Trouble diagnostics toggle win.position=bottom<cr>", opts)
-- keymap("n", "<leader>lo", "<cmd>Trouble symbols toggle focus=true win.position=right<cr>", opts)
-- keymap("n", "gr", "<cmd>Trouble lsp_references focus=true win.position=bottom<cr>", opts)
-- keymap("n", "<leader>in", "<cmd>Trouble lsp_incoming_calls focus=true win.position=right<cr>", opts)
keymap("n", "<leader>ci", "<cmd>CallGraphI<cr>", opts)
keymap("n", "<leader>cr", "<cmd>CallGraphR<cr>", opts)
keymap("n", "<leader>cb", "<cmd>CallGraphToggleReuseBuf<cr>", opts)
keymap("n", "<leader>cm", "<cmd>CallGraphOpenMermaidGraph<cr>", opts)

keymap("n", "<leader>ml", "<cmd>MakeLast<cr>", opts)
-- keymap("n", "<leader>ih", "<cmd>CallGraphToggleAutoHighlight<cr>", opts)
-- keymap("n", "<leader>tq", "<cmd>Trouble qflist toggle<cr>", opts)

-- liteecall
-- keymap("n", "<leader>in", "<cmd>lua vim.lsp.buf.incoming_calls()<cr>", opts)
-- keymap("n", "<leader>on", "<cmd>lua vim.lsp.buf.outgoing_calls()<cr>", opts)

-- change macro keyshort for not interrupting cmp plugin
keymap("n", "Q", "q", opts)
keymap("n", "q", "<Nop>", opts)

-- sniprun
keymap(
  "n",
  "<leader><enter>",
  ":let b:caret=winsaveview() <CR> | :%SnipRun <CR>| :call winrestview(b:caret) <CR>",
  opts
)
keymap("v", "<leader><enter>", "<Plug>SnipRun", opts)

-- highlight current line
keymap("n", "<leader>bb", function()
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
-- keymap("n", "]m", "<Nop>", opts)
-- keymap("n", "[m", "<Nop>", opts)
keymap("n", "]b", "<Nop>", opts)
keymap("n", "[b", "<Nop>", opts)
keymap("n", "]b", function()
  require("bookmarks").goto_next_bookmark()
end, opts)
keymap("n", "[b", function()
  require("bookmarks").goto_prev_bookmark()
end, opts)

-- cppp header/source switch
keymap("n", "<leader>j", "<cmd>ClangdSwitchSourceHeader<cr>", opts)

-- codeverse
vim.cmd([[
let g:codeverse_disable_bindings = v:true
inoremap <script><silent><nowait><expr> <C-b> marscode#Accept()
]])
-- keymap("i", "<C-[", "<Plug>(codeverse-previous)", opts)
-- keymap("i", "<C-]", "<Plug>(codeverse-next-or-complete)", opts)

keymap("n", "yb", "<cmd>CopyBreakPoint<cr>", opts)
keymap("n", "yf", "<cmd>CopyFileName<cr>", opts)
keymap("n", "yF", "<cmd>CopyFilePath<cr>", opts)
keymap("n", "yo", "<cmd>CopyFileNameWoExt<cr>", opts)
keymap("n", "yO", "<cmd>CopyFilePathWoExt<cr>", opts)
keymap("n", "ym", "<cmd>CopyFuncName<cr>", opts)

-- plugin dev
keymap("n", "<leader>t", "<cmd>PlenaryBustedFile %<cr>", opts)
