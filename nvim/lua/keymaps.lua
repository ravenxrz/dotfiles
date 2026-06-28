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

-- Neo tree
-- keymap("n", "<leader>e", "<cmd>Neotree toggle<cr>", opts)
-- keymap("n", "<leader>fo", "<cmd>Neotree reveal<cr>", opts)

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
-- keymap("n", "<leader>bd", "<cmd>BufferClose<cr>", opts)

-- Gitsigns
keymap("n", "<leader>gp", "<cmd>Gitsigns preview_hunk<cr>", opts)
keymap("n", "<leader>gr", "<cmd>Gitsigns reset_hunk<cr>", opts)
keymap("n", "<leader>gs", "<cmd>Gitsigns stage_hunk<cr>", opts)
keymap("n", "<leader>gl", "<cmd>Gitsigns blame_line<cr>", opts)
keymap("n", "]g", "<cmd>Gitsigns next_hunk<cr>", opts)
keymap("n", "[g", "<cmd>Gitsigns prev_hunk<cr>", opts)

-- diffview
keymap("n", "<leader>gc", "<cmd>DiffviewFileHistory<cr>", opts)
keymap("n", "<leader>gf", "<cmd>DiffviewFileHistory --follow %<cr>", opts)
keymap("n", "<leader>gh", "<cmd>DiffviewOpen HEAD<cr>", opts)
keymap("n", "<leader>go", "<cmd>DiffviewClose<cr>", opts)

-- Telescope
local function clear_telescope_prompt_if_single_a(prompt_bufnr)
  local ok, state = pcall(require, "telescope.state")
  if ok then
    local status = state.get_status(prompt_bufnr)
    if status and status.picker then
      local ok_prompt, prompt = pcall(function()
        return status.picker:_get_prompt()
      end)
      if ok_prompt then
        if prompt == "A" then
          status.picker:reset_prompt("")
          return true
        end
      end
    end
  end

  return false
end

local function guard_initial_telescope_prompt_a()
  local started_at = vim.uv and vim.uv.now() or vim.loop.now()
  local group = vim.api.nvim_create_augroup("my-telescope-clear-initial-a", { clear = true })

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "TelescopePrompt",
    callback = function(event)
      local prompt_bufnr = event.buf

      vim.api.nvim_create_autocmd({ "TextChangedI", "CursorMovedI" }, {
        group = group,
        buffer = prompt_bufnr,
        callback = function()
          clear_telescope_prompt_if_single_a(prompt_bufnr)

          local now = vim.uv and vim.uv.now() or vim.loop.now()
          if now - started_at > 2000 then
            pcall(vim.api.nvim_del_augroup_by_id, group)
          end
        end,
      })

      for i = 1, 20 do
        vim.defer_fn(function()
          clear_telescope_prompt_if_single_a(prompt_bufnr)
        end, i * 50)
      end
    end,
  })

  for i = 1, 20 do
    vim.defer_fn(function()
      local ok, state = pcall(require, "telescope.state")
      if not ok then return end

      for _, prompt_bufnr in ipairs(state.get_existing_prompt_bufnrs()) do
        clear_telescope_prompt_if_single_a(prompt_bufnr)
      end
    end, i * 50)
  end
end

keymap("n", "<leader>r", function()
  guard_initial_telescope_prompt_a()
  vim.schedule(function()
    require("telescope").extensions.frecency.frecency()
  end)
end, opts)
-- keymap("n", "<leader>r", "<cmd>Telescope oldfiles<cr>", opts)
keymap("n", "<leader>D", "<cmd>Telescope diagnostics<cr>", opts)
keymap("n", "<leader>f<cr>", "<cmd>Telescope resume<cr>", opts)
keymap("n", "<leader>fb", "<cmd>Telescope buffers theme=ivy<cr>", opts)


-- telescope
local ts = require('telescope_search')
-- Keymap to set the mode
keymap("n", "<leader>fM", ts.set_search_mode, { desc = "Set Telescope search mode" })
-- Keymaps for searching, which now use the selected mode
keymap("n", "<leader>ff", function() ts.search('find_files') end, { desc = "Find files (using current mode)" })
keymap("n", "<leader>fw", function() ts.search('grep_word') end, { desc = "Grep word (using current mode)" })
keymap("v", "<leader>fw", function() ts.search('grep_word') end, { desc = "Grep selected word (using current mode)" })
keymap("n", "<leader>fg", function() ts.search('live_grep') end, { desc = "Live grep (using current mode)" })
keymap("n", "<leader>fm", function() ts.search('cpp_functions') end,
  { desc = "Find C++ function declaration/definition" })
-- Command to set the mode
vim.api.nvim_create_user_command('SetTelescopeSearchMode', ts.set_search_mode, {})
vim.api.nvim_create_user_command('SetTelescopeSearchRoot', ts.set_search_root, {})
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
--
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
keymap("n", "<leader>j", "<cmd>LspClangdSwitchSourceHeader<cr>", opts)
-- goto definition, use clangd first, if clangd is avaiable, otherwise, use ctags (built ctags fitst by ctags -R --languages=C,C++ --exclude=.git --exclude=build --exclude=third_party .)
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "c", "cpp", "objc", "objcpp", "cuda" },
  callback = function(event)
    keymap("n", "gd", function()
      local clients = vim.lsp.get_clients({ bufnr = event.buf })
      local word = vim.fn.expand("<cword>")
      local function current_word_is_scope_qualifier()
        local cursor = vim.api.nvim_win_get_cursor(0)
        local line = vim.api.nvim_get_current_line()
        local cursor_col = cursor[2] + 1
        local escaped = vim.pesc(word)
        local search_start = 1

        while true do
          local start_col, end_col = line:find("%f[%w_]" .. escaped .. "%f[^%w_]", search_start)
          if not start_col then
            return false
          end

          if start_col <= cursor_col and cursor_col <= end_col then
            return line:sub(end_col + 1, end_col + 2) == "::"
          end

          search_start = end_col + 1
        end
      end

      local function collect_type_tags()
        local type_tags = {}
        local matches = vim.fn.taglist("^" .. vim.fn.escape(word, "\\") .. "$")
        for _, item in ipairs(matches) do
          if item.kind == "c" or item.kind == "s" or item.kind == "t" or item.kind == "n" then
            table.insert(type_tags, item)
          end
        end

        return type_tags
      end

      local function collect_macro_definition_tags()
        local macro_tags = {}
        local matches = vim.fn.taglist("^" .. vim.fn.escape(word, "\\") .. "$")
        for _, item in ipairs(matches) do
          if item.kind == "d" then
            table.insert(macro_tags, item)
          end
        end

        return macro_tags
      end

      local function current_word_left_qualifier()
        local cursor = vim.api.nvim_win_get_cursor(0)
        local line = vim.api.nvim_get_current_line()
        local cursor_col = cursor[2] + 1
        local escaped = vim.pesc(word)
        local search_start = 1

        while true do
          local start_col, end_col = line:find("%f[%w_]" .. escaped .. "%f[^%w_]", search_start)
          if not start_col then
            return nil
          end

          if start_col <= cursor_col and cursor_col <= end_col then
            if line:sub(start_col - 2, start_col - 1) ~= "::" then
              return nil
            end

            return line:sub(1, start_col - 3):match("([%w_]+)%s*$")
          end

          search_start = end_col + 1
        end
      end

      local function collect_qualified_member_tags()
        local qualifier = current_word_left_qualifier()
        if not qualifier then
          return {}
        end

        local member_tags = {}
        local matches = vim.fn.taglist("^" .. vim.fn.escape(word, "\\") .. "$")
        for _, item in ipairs(matches) do
          local class = item.class or ""
          if class == qualifier or class:sub(-#qualifier - 2) == "::" .. qualifier then
            table.insert(member_tags, item)
          end
        end

        return member_tags
      end

      local function current_definition_class()
        local cursor = vim.api.nvim_win_get_cursor(0)
        for lnum = cursor[1], 1, -1 do
          local line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1] or ""
          local class = line:match("([%w_:]+)::" .. vim.pesc(word) .. "%s*%(")
          if class then
            return class:match("([%w_]+)$")
          end
        end

        return nil
      end

      local function count_signature_args(params)
        if not params then
          return nil
        end

        params = params:match("^%s*(.-)%s*$")
        if params == "" or params == "void" then
          return 0
        end

        local count = 1
        local angle_depth = 0
        local paren_depth = 0
        for idx = 1, #params do
          local char = params:sub(idx, idx)
          if char == "<" then
            angle_depth = angle_depth + 1
          elseif char == ">" and angle_depth > 0 then
            angle_depth = angle_depth - 1
          elseif char == "(" then
            paren_depth = paren_depth + 1
          elseif char == ")" and paren_depth > 0 then
            paren_depth = paren_depth - 1
          elseif char == "," and angle_depth == 0 and paren_depth == 0 then
            count = count + 1
          end
        end

        return count
      end

      local function current_signature_arg_count()
        return count_signature_args(vim.api.nvim_get_current_line():match("%((.*)%)"))
      end

      local function tag_signature_arg_count(item)
        return count_signature_args((item.cmd or ""):match("%((.*)%)"))
      end

      local function filter_by_current_signature(items)
        local arg_count = current_signature_arg_count()
        if not arg_count then
          return items
        end

        local filtered = {}
        for _, item in ipairs(items) do
          if tag_signature_arg_count(item) == arg_count then
            table.insert(filtered, item)
          end
        end

        if vim.tbl_isempty(filtered) then
          return items
        end

        return filtered
      end

      local function collect_member_declarations(class)
        local class_tags = vim.fn.taglist("^" .. vim.fn.escape(class, "\\") .. "$")
        local class_tag
        for _, item in ipairs(class_tags) do
          if item.kind == "c" or item.kind == "s" then
            class_tag = item
            break
          end
        end
        if not class_tag then
          return {}
        end

        local ok, lines = pcall(vim.fn.readfile, class_tag.filename)
        if not ok then
          return {}
        end

        local results = {}
        local class_line = 1
        for idx, line in ipairs(lines) do
          if line:find("%f[%w_]" .. vim.pesc(class) .. "%f[^%w_]") then
            class_line = idx
            break
          end
        end

        local brace_depth = 0
        local in_class = false
        for idx = class_line, #lines do
          local line = lines[idx]
          if not in_class and line:find("{") then
            in_class = true
          end

          if in_class then
            if line:find("%f[%w_]" .. vim.pesc(word) .. "%f[^%w_]%s*%(") and line:find(";") then
              local start_col = line:find("%f[%w_]" .. vim.pesc(word) .. "%f[^%w_]")
              local is_destructor = start_col and line:sub(1, start_col - 1):find("~%s*$")
              if not is_destructor then
                table.insert(results, {
                  name = word,
                  filename = class_tag.filename,
                  lnum = idx,
                  col = start_col or 1,
                  source = "decl",
                })
              end
            end

            for char in line:gmatch(".") do
              if char == "{" then
                brace_depth = brace_depth + 1
              elseif char == "}" then
                brace_depth = brace_depth - 1
                if brace_depth <= 0 then
                  return results
                end
              end
            end
          end
        end

        return results
      end

      local function current_enclosing_class()
        local cursor = vim.api.nvim_win_get_cursor(0)
        for lnum = cursor[1], 1, -1 do
          local line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1] or ""
          local class = line:match("^%s*class%s+([%w_]+)") or line:match("^%s*struct%s+([%w_]+)")
          if class then
            return class
          end
        end

        return nil
      end

      local function collect_member_counterpart_tags()
        local class = current_definition_class() or current_enclosing_class()
        if not class then
          return {}
        end

        local exact = vim.fn.taglist("^" .. vim.fn.escape(word, "\\") .. "$")
        local matches = {}
        for _, item in ipairs(exact) do
          local item_class = item.class or ""
          if item_class == class or item_class:sub(-#class - 2) == "::" .. class then
            table.insert(matches, item)
          end
        end

        return filter_by_current_signature(matches)
      end

      local function current_word_is_constructor_declaration()
        local class = current_enclosing_class()
        if class ~= word then
          return false
        end

        local line = vim.api.nvim_get_current_line()
        return line:find("^%s*" .. vim.pesc(word) .. "%s*%([^;]*%)%s*;") ~= nil
      end

      local function collect_local_declarations()
        local escaped = vim.pesc(word)
        local cursor = vim.api.nvim_win_get_cursor(0)
        local function current_function_start_line()
          if vim.treesitter and vim.treesitter.get_node then
            local ok, node = pcall(vim.treesitter.get_node, { bufnr = event.buf })
            if ok and node then
              while node do
                local node_type = node:type()
                if node_type == "function_definition" or node_type == "lambda_expression" then
                  local start_row = node:range()
                  return start_row + 1
                end
                node = node:parent()
              end
              return nil
            end
          end

          for lnum = cursor[1], 1, -1 do
            local line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1] or ""
            local trimmed = line:match("^%s*(.-)%s*$")
            local first_word = trimmed:match("^(%w+)")
            local is_control_block = (
              (first_word == "if" or first_word == "for" or first_word == "while" or first_word == "switch" or
                first_word == "catch") and trimmed:find("^%w+%s*%(")
            ) or first_word == "else"
            if not is_control_block and trimmed:find("%)%s*[%w_:<>%s%*&]*%s*{%s*$") then
              return lnum
            end
          end

          return math.max(cursor[1] - 200, 1)
        end

        local first_line = current_function_start_line()
        if not first_line then
          return {}
        end
        local lines = vim.api.nvim_buf_get_lines(0, first_line - 1, cursor[1] - 1, false)
        local results = {}
        local function_line = lines[1] or ""
        local params = function_line:match("%((.*)%)%s*[%w_:<>%s%*&]*%s*{%s*$")
        if params then
          local start_col = params:find("%f[%w_]" .. escaped .. "%f[^%w_]")
          if start_col then
            local params_start_col = function_line:find("%(") or 1
            table.insert(results, {
              name = word,
              filename = vim.api.nvim_buf_get_name(0),
              lnum = first_line,
              col = params_start_col + start_col,
              source = "param",
            })
          end
        end

        for idx = #lines, 1, -1 do
          local line = lines[idx]
          local is_auto_decl = line:find("^%s*auto%s+[%*&%s]*" .. escaped .. "%f[^%w_]%s*[=;({]")
          local is_typed_decl = line:find("^%s*[%w_:<>%,%s]+[%*&%s]+" .. escaped .. "%f[^%w_]%s*[=;({]")

          if is_auto_decl or is_typed_decl then
            local lnum = first_line + idx - 1
            local start_col = line:find("%f[%w_]" .. escaped .. "%f[^%w_]")
            table.insert(results, {
              name = word,
              filename = vim.api.nvim_buf_get_name(0),
              lnum = lnum,
              col = start_col or 1,
              source = "local",
            })
          end
        end

        return results
      end

      local function jump_to_tag_item(item)
        local filename = item.filename
        local scode = item.cmd and item.cmd:match("^/(.*)/$") or nil
        local lnum = item.lnum or 1
        local name = item.name

        vim.cmd("edit " .. vim.fn.fnameescape(filename))
        if scode then
          scode = scode:gsub([[\/]], "/"):gsub("[%]~*]", function(x)
            return "\\" .. x
          end)
          vim.cmd("keepjumps normal! gg")
          vim.fn.search(scode, "W")
        else
          vim.api.nvim_win_set_cursor(0, { lnum, 0 })
        end

        local cursor = vim.api.nvim_win_get_cursor(0)
        local line = vim.api.nvim_get_current_line()
        local start_col = line:find("%f[%w_]" .. vim.pesc(name) .. "%f[^%w_]")
        if start_col then
          vim.api.nvim_win_set_cursor(0, { cursor[1], start_col - 1 })
        end
        vim.cmd("normal! zz")
      end

      local function lsp_location_has_word(location)
        local uri = location.uri or location.targetUri
        local range = location.range or location.targetSelectionRange or location.targetRange
        if not uri or not range then
          return false
        end

        local filename = vim.uri_to_fname(uri)
        local lnum = range.start.line + 1
        local ok, lines = pcall(vim.fn.readfile, filename, "", lnum)
        if not ok or not lines[lnum] then
          return false
        end

        return lines[lnum]:find("%f[%w_]" .. vim.pesc(word) .. "%f[^%w_]") ~= nil
      end

      local function jump_to_tag()
        local matches = vim.fn.taglist("^" .. vim.fn.escape(word, "\\") .. "$")
        if vim.tbl_isempty(matches) then
          matches = vim.fn.taglist(word)
        end
        local candidates = collect_local_declarations()
        local seen = {}
        for _, item in ipairs(matches) do
          local key = table.concat({ item.filename or "", item.cmd or "", item.name or "", item.lnum or "" }, "\t")
          if not seen[key] then
            seen[key] = true
            table.insert(candidates, item)
          end
        end

        if #candidates == 1 then
          jump_to_tag_item(candidates[1])
          return
        end

        local ok, pickers = pcall(require, "telescope.pickers")
        if ok and not vim.tbl_isempty(candidates) then
          local finders = require("telescope.finders")
          local actions = require("telescope.actions")
          local action_state = require("telescope.actions.state")
          local conf = require("telescope.config").values
          local previewers = require("telescope.previewers")

          pickers.new({}, {
            prompt_title = "Ctags: " .. word,
            finder = finders.new_table({
              results = candidates,
              entry_maker = function(item)
                local filename = vim.fn.fnamemodify(item.filename, ":.")
                local location = item.cmd or (item.lnum and tostring(item.lnum)) or 1
                local source = item.source and ("[" .. item.source .. "] ") or ""
                local display = string.format("%s%s:%s %s", source, filename, location, item.name)
                return {
                  value = item,
                  display = display,
                  ordinal = item.name .. " " .. filename .. " " .. (item.class or "") .. " " .. (item.source or ""),
                  filename = item.filename,
                  scode = item.cmd and item.cmd:match("^/(.*)/$") or nil,
                  lnum = item.lnum or 1,
                }
              end,
            }),
            previewer = previewers.ctags.new({}),
            sorter = conf.generic_sorter({}),
            attach_mappings = function(prompt_bufnr)
              actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                if not selection then return end

                jump_to_tag_item(selection.value)
              end)
              return true
            end,
          }):find()
          return
        end

        vim.cmd("tjump " .. vim.fn.escape(word, [[\ ]]))
      end

      if current_word_is_constructor_declaration() then
        local constructor_definitions = collect_member_counterpart_tags()
        if #constructor_definitions == 1 then
          jump_to_tag_item(constructor_definitions[1])
          return
        end
      end

      local definition_class = current_definition_class()
      if definition_class then
        local member_declarations = collect_member_declarations(definition_class)
        if #member_declarations == 1 then
          jump_to_tag_item(member_declarations[1])
          return
        end
      end

      local type_tags = collect_type_tags()
      if #type_tags == 1 then
        jump_to_tag_item(type_tags[1])
        return
      end

      local macro_tags = collect_macro_definition_tags()
      if #macro_tags == 1 then
        jump_to_tag_item(macro_tags[1])
        return
      end

      local local_declarations = collect_local_declarations()
      if #local_declarations == 1 then
        jump_to_tag_item(local_declarations[1])
        return
      end

      local qualified_member_tags = collect_qualified_member_tags()
      if #qualified_member_tags == 1 then
        jump_to_tag_item(qualified_member_tags[1])
        return
      end

      local member_counterpart_tags = collect_member_counterpart_tags()
      if #member_counterpart_tags == 1 then
        jump_to_tag_item(member_counterpart_tags[1])
        return
      end

      local exact_tags = vim.fn.taglist("^" .. vim.fn.escape(word, "\\") .. "$")
      if #exact_tags == 1 then
        jump_to_tag_item(exact_tags[1])
        return
      end

      if #clients > 0 then
        local offset_encoding = clients[1].offset_encoding or "utf-16"
        local params = vim.lsp.util.make_position_params(0, offset_encoding)

        vim.lsp.buf_request(event.buf, "textDocument/definition", params, function(err, result, ctx, config)
          if err or not result or vim.tbl_isempty(result) then
            jump_to_tag()
            return
          end

          local locations = vim.islist(result) and result or { result }

          if #locations == 1 then
            if not lsp_location_has_word(locations[1]) then
              jump_to_tag()
              return
            end

            vim.lsp.util.jump_to_location(locations[1], offset_encoding, true)
            return
          end

          local items = vim.lsp.util.locations_to_items(locations, offset_encoding)
          local ok, pickers = pcall(require, "telescope.pickers")
          if not ok then
            vim.fn.setqflist({}, " ", { title = "LSP definitions", items = items })
            vim.cmd("copen")
            return
          end

          local finders = require("telescope.finders")
          local actions = require("telescope.actions")
          local action_state = require("telescope.actions.state")
          local conf = require("telescope.config").values

          pickers.new({}, {
            prompt_title = "LSP Definitions",
            finder = finders.new_table({
              results = items,
              entry_maker = function(item)
                local filename = vim.fn.fnamemodify(item.filename, ":.")
                local display = string.format("%s:%d:%d %s", filename, item.lnum, item.col, item.text)
                return {
                  value = item,
                  display = display,
                  ordinal = display,
                }
              end,
            }),
            sorter = conf.generic_sorter({}),
            attach_mappings = function(prompt_bufnr)
              actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                if not selection then return end

                local item = selection.value
                vim.cmd("edit " .. vim.fn.fnameescape(item.filename))
                vim.api.nvim_win_set_cursor(0, { item.lnum, math.max(item.col - 1, 0) })
                vim.cmd("normal! zv")
              end)
              return true
            end,
          }):find()
        end)
      else
        jump_to_tag()
      end
    end, { buffer = event.buf, desc = "Go to definition via LSP, fallback to ctags" })
  end,
})

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
