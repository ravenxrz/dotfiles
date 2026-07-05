local M = {}

local keymap = vim.keymap.set

local function echo_status(message)
  vim.api.nvim_echo({ { message, "ModeMsg" } }, false, {})
end

local function clear_echo_status()
  vim.api.nvim_echo({ { "", "None" } }, false, {})
end

local function sync_systemlist(args, cwd)
  if vim.system then
    local result = vim.system(args, { text = true, cwd = cwd }):wait()
    local stdout = result.stdout or ""
    return result.code == 0, vim.split(stdout, "\n", { trimempty = true })
  end

  local previous_cwd = vim.fn.getcwd()
  if cwd and cwd ~= "" then
    vim.cmd("lcd " .. vim.fn.fnameescape(cwd))
  end

  local lines = vim.fn.systemlist(args)
  local ok = vim.v.shell_error == 0
  if cwd and cwd ~= "" then
    vim.cmd("lcd " .. vim.fn.fnameescape(previous_cwd))
  end

  return ok, lines
end

local function goto_definition(bufnr)
  local event = { buf = bufnr }
  local word = vim.fn.expand("<cword>")
  local buffer_name = vim.api.nvim_buf_get_name(bufnr)
  local command_cwd = buffer_name ~= "" and vim.fn.fnamemodify(buffer_name, ":p:h") or vim.fn.getcwd()
  local async_gtags_root_cache = nil
  
    local function async_systemlist(args, callback, cwd)
      local run_cwd = cwd or command_cwd
      if vim.system then
        vim.system(args, { text = true, cwd = run_cwd }, function(result)
          vim.schedule(function()
            local stdout = result.stdout or ""
            local lines = vim.split(stdout, "\n", { trimempty = true })
            callback(result.code == 0, lines)
          end)
        end)
        return
      end
  
      local stdout = {}
      local stderr = {}
      vim.fn.jobstart(args, {
        cwd = run_cwd,
        stdout_buffered = true,
        stderr_buffered = true,
        on_stdout = function(_, data)
          if data then
            vim.list_extend(stdout, data)
          end
        end,
        on_stderr = function(_, data)
          if data then
            vim.list_extend(stderr, data)
          end
        end,
        on_exit = function(_, code)
          vim.schedule(function()
            local lines = {}
            for _, line in ipairs(stdout) do
              if line ~= "" then
                table.insert(lines, line)
              end
            end
            callback(code == 0, lines, stderr)
          end)
        end,
      })
    end
  
    local function async_gtags_root(callback)
      if async_gtags_root_cache then
        callback(async_gtags_root_cache)
        return
      end
  
      async_systemlist({ "global", "-pr" }, function(ok, lines)
        local root = ok and lines[1] or nil
        if not root or root == "" then
          callback(nil)
          return
        end
  
        async_gtags_root_cache = root
        callback(root)
      end)
    end
  
    local function gtags_abs_path(root, filename)
      if filename:sub(1, 1) == "/" then
        return filename
      end
  
      return root .. "/" .. filename
    end
  
    local function parse_gtags_x(lines, source, name, root)
      if not root then
        return {}
      end
  
      local items = {}
      for _, line in ipairs(lines) do
        local _, lnum, filename, text = line:match("^(%S+)%s+(%d+)%s+(%S+)%s?(.*)$")
        if filename and lnum then
          local abs_filename = gtags_abs_path(root, filename)
          local col = 1
          if text and text ~= "" then
            col = text:find("%f[%w_]" .. vim.pesc(name) .. "%f[^%w_]") or 1
          end
          table.insert(items, {
            name = name,
            filename = abs_filename,
            lnum = tonumber(lnum),
            col = col,
            text = text or "",
            source = source,
          })
        end
      end
  
      return items
    end
  
    local function parse_gtags_grep_x(lines, source, name, root)
      if not root then
        return {}
      end
  
      local items = {}
      for _, line in ipairs(lines) do
        local _, lnum, filename, text = line:match("^(%S+)%s+(%d+)%s+(%S+)%s?(.*)$")
        if filename and lnum then
          local abs_filename = gtags_abs_path(root, filename)
          local col = 1
          if text and text ~= "" then
            col = text:find("%f[%w_]" .. vim.pesc(name) .. "%f[^%w_]") or 1
          end
          table.insert(items, {
            name = name,
            filename = abs_filename,
            lnum = tonumber(lnum),
            col = col,
            text = text or "",
            source = source,
          })
        end
      end
  
      return items
    end
  
    local function dedupe_items(items)
      local seen = {}
      local deduped = {}
      for _, item in ipairs(items) do
        local key = table.concat({ item.filename or "", item.lnum or "", item.name or "", item.text or "" }, "\t")
        if not seen[key] then
          seen[key] = true
          table.insert(deduped, item)
        end
      end
  
      return deduped
    end
  
    local function async_gtags_query(args, parser, source, name, callback)
      async_gtags_root(function(root)
        if not root then
          callback({})
          return
        end
  
          async_systemlist(args, function(ok, lines)
            if not ok then
              callback({})
              return
            end

            callback(parser(lines, source, name or word, root))
          end, root)
        end)
      end
  
    local function async_collect_gtags_definitions(symbol, callback)
      async_gtags_query({ "global", "-x", "--literal", symbol }, parse_gtags_x, "def", symbol, function(items)
        if not vim.tbl_isempty(items) then
          callback(items)
          return
        end
  
        async_gtags_query({ "global", "-sx", "--literal", symbol }, parse_gtags_x, "sym", symbol, function(symbol_items)
          if not vim.tbl_isempty(symbol_items) then
            callback(symbol_items)
            return
          end
  
          async_gtags_query({ "global", "-gx", "--literal", symbol }, parse_gtags_grep_x, "grep", symbol, callback)
        end)
      end)
    end
  
    local function async_collect_gtags_grep(pattern, source, name, callback)
      async_gtags_query({ "global", "-gx", pattern }, parse_gtags_grep_x, source, name, callback)
    end
  
    local function ctags_tag_filename(root, tag)
      local filename = tag.filename or tag.file
      if not filename or filename == "" then
        return nil
      end
  
      if filename:sub(1, 1) == "/" then
        return filename
      end
  
      return root .. "/" .. filename
    end
  
    local function ctags_tag_line(filename, tag, symbol, line_predicate)
      local lnum = tonumber(tag.line)
      local text = ""
      local ok_lines, lines = pcall(vim.fn.readfile, filename)
      if not ok_lines then
        return lnum, text
      end
  
      if lnum and lines[lnum] and (not line_predicate or line_predicate(lines[lnum])) then
        return lnum, lines[lnum]
      end

      local cmd = tag.cmd
      if type(cmd) == "string" then
        local exact = cmd:match("^/%^(.*)%$/$") or cmd:match("^/%^(.*)%$/;$")
        if exact then
          local unescaped = exact:gsub("\\/", "/"):gsub("\\\\", "\\")
          for idx, line in ipairs(lines) do
            if line == unescaped and (not line_predicate or line_predicate(line)) then
              return idx, line
            end
          end
        end
      end
  
      for idx, line in ipairs(lines) do
        if line_predicate then
          if line_predicate(line) then
            return idx, line
          end
        elseif line:find("%f[%w_]" .. vim.pesc(symbol) .. "%f[^%w_]") then
          return idx, line
        end
      end
  
      return nil, text
    end
  
    local function collect_ctags_definitions(symbol)
      local tag_pattern = "^" .. vim.fn.escape(symbol, [[\^$.*~/[]]) .. "$"
      local ok, tags = pcall(vim.fn.taglist, tag_pattern)
      if not ok or vim.tbl_isempty(tags) then
        return {}
      end
  
      local items = {}
      for _, tag in ipairs(tags) do
        local root = tag.tagfile and vim.fn.fnamemodify(tag.tagfile, ":p:h") or vim.fn.getcwd()
        local filename = ctags_tag_filename(root, tag)
        if filename then
          local lnum, text = ctags_tag_line(filename, tag, symbol)
          if lnum then
            local col = text:find("%f[%w_]" .. vim.pesc(symbol) .. "%f[^%w_]") or 1
            table.insert(items, {
              name = symbol,
              filename = filename,
              lnum = lnum,
              col = col,
              text = text,
              source = "ctags",
            })
          end
        end
      end
  
      return dedupe_items(items)
    end
  
    local function collect_definition_tags(symbol)
      return collect_ctags_definitions(symbol)
    end
  
    local function filter_definition_tags(items, source, predicate)
      local matches = {}
      for _, item in ipairs(items) do
        if predicate(item) then
          if source then
            item.source = source
          end
          table.insert(matches, item)
        end
      end
  
      return matches
    end
  
    local function collect_filtered_definition_tags(symbol, source, predicate)
      return filter_definition_tags(collect_ctags_definitions(symbol), source, predicate)
    end
  
    local function item_is_type_definition(item, symbol)
      local text = item.text or ""
      local escaped = vim.pesc(symbol)
      return text:find("^%s*class%s+" .. escaped .. "%f[^%w_]")
          or text:find("^%s*struct%s+" .. escaped .. "%f[^%w_]")
          or text:find("^%s*enum%s+" .. escaped .. "%f[^%w_]")
          or text:find("^%s*using%s+" .. escaped .. "%f[^%w_]")
          or text:find("^%s*typedef%s+.*%f[%w_]" .. escaped .. "%f[^%w_]")
          or text:find("^%s*#%s*define%s+" .. escaped .. "%f[^%w_]")
    end
  
    local function item_is_preferred_type_definition(item, symbol)
      local text = item.text or ""
      local escaped = vim.pesc(symbol)
      return text:find("{", 1, true)
          or text:find("^%s*using%s+" .. escaped .. "%f[^%w_]")
          or text:find("^%s*typedef%s+.*%f[%w_]" .. escaped .. "%f[^%w_]")
          or text:find("^%s*#%s*define%s+" .. escaped .. "%f[^%w_]")
    end
  
    local function prefer_complete_type_definitions(items, symbol)
      items = dedupe_items(items)
      local preferred = {}
      for _, item in ipairs(items) do
        if item_is_preferred_type_definition(item, symbol) then
          table.insert(preferred, item)
        end
      end
  
      if not vim.tbl_isempty(preferred) then
        return preferred
      end
  
      return items
    end
  
    local function collect_ctags_type_tags(symbol)
      local tag_pattern = "^" .. vim.fn.escape(symbol, [[\^$.*~/[]]) .. "$"
      local ok, tags = pcall(vim.fn.taglist, tag_pattern)
      if not ok or vim.tbl_isempty(tags) then
        return {}
      end
  
      local items = {}
      for _, tag in ipairs(tags) do
        local root = tag.tagfile and vim.fn.fnamemodify(tag.tagfile, ":p:h") or vim.fn.getcwd()
        local filename = ctags_tag_filename(root, tag)
        if filename and filename ~= "" then
          local lnum, text = ctags_tag_line(filename, tag, symbol, function(line)
            return item_is_type_definition({ text = line }, symbol)
          end)
  
          if lnum and item_is_type_definition({ text = text }, symbol) then
            local col = text:find("%f[%w_]" .. vim.pesc(symbol) .. "%f[^%w_]") or 1
            table.insert(items, {
              name = symbol,
              filename = filename,
              lnum = lnum,
              col = col,
              text = text,
              source = "ctags",
            })
          end
        end
      end
  
      return prefer_complete_type_definitions(items, symbol)
    end
  
    local function current_word_is_scope_qualifier()
      local node = treesitter_node_at_cursor()
      return node ~= nil
          and node:type() == "namespace_identifier"
          and treesitter_node_text(node) == word
          and treesitter_ancestor(node, "qualified_identifier") ~= nil
    end
  
    local function collect_type_tags_for(symbol)
      local exact_type_tags = collect_filtered_definition_tags(symbol, "type", function(item)
        return item_is_type_definition(item, symbol)
      end)
      if not vim.tbl_isempty(exact_type_tags) then
        return prefer_complete_type_definitions(exact_type_tags, symbol)
      end
  
      local ctags_type_tags = collect_ctags_type_tags(symbol)
      if not vim.tbl_isempty(ctags_type_tags) then
        return ctags_type_tags
      end
  
      return {}
    end
  
    local function collect_type_tags()
      return collect_type_tags_for(word)
    end
  
    local function async_collect_gtags_type_tags(symbol, callback)
      async_collect_gtags_definitions(symbol, function(definition_items)
        local exact_type_tags = filter_definition_tags(definition_items, "type", function(item)
          return item_is_type_definition(item, symbol)
        end)
        if not vim.tbl_isempty(exact_type_tags) then
          callback(prefer_complete_type_definitions(exact_type_tags, symbol))
          return
        end
  
        local patterns = {
          "^[[:space:]]*(class|struct)[[:space:]]+" .. symbol .. "([^[:alnum:]_]|$)",
          "^[[:space:]]*using[[:space:]]+" .. symbol .. "([^[:alnum:]_]|$)",
          "^[[:space:]]*typedef[[:space:]].*([^[:alnum:]_]|^)" .. symbol .. "[[:space:]]*;",
        }
        local pending = #patterns
        local type_tags = {}
  
        for _, pattern in ipairs(patterns) do
          async_collect_gtags_grep(pattern, "type", symbol, function(items)
            vim.list_extend(type_tags, items)
            pending = pending - 1
            if pending > 0 then
              return
            end
  
            type_tags = dedupe_items(type_tags)
            local definitions = {}
            for _, item in ipairs(type_tags) do
              if item_is_type_definition(item, symbol) then
                table.insert(definitions, item)
              end
            end
  
            if not vim.tbl_isempty(definitions) then
              callback(prefer_complete_type_definitions(definitions, symbol))
              return
            end
  
            callback(type_tags)
          end)
        end
      end)
    end
  
    local function treesitter_node_at_cursor()
      if not vim.treesitter then
        return nil
      end
  
      if vim.treesitter.get_node then
        local ok, node = pcall(vim.treesitter.get_node, { bufnr = event.buf })
        if ok and node then
          return node
        end
      end
  
      local cursor = vim.api.nvim_win_get_cursor(0)
      local ok, parser = pcall(vim.treesitter.get_parser, event.buf)
      if not ok or not parser then
        return nil
      end
  
      local trees = parser:parse()
      local tree = trees and trees[1]
      if not tree then
        return nil
      end
  
      local row = cursor[1] - 1
      local col = cursor[2]
      return tree:root():descendant_for_range(row, col, row, col)
    end
  
    local function treesitter_ancestor(node, node_type)
      while node do
        if node:type() == node_type then
          return node
        end
        node = node:parent()
      end
  
      return nil
    end
  
    local function treesitter_node_text(node)
      local ok, text = pcall(vim.treesitter.get_node_text, node, event.buf)
      if ok then
        return text
      end
  
      return ""
    end
  
    local function treesitter_node_text_for_buf(node, bufnr)
      local ok, text = pcall(vim.treesitter.get_node_text, node, bufnr)
      if ok then
        return text
      end
  
      return ""
    end
  
    local function treesitter_find_child(node, node_type)
      if not node then
        return nil
      end
  
      for child in node:iter_children() do
        if child:type() == node_type then
          return child
        end
      end
  
      return nil
    end
  
    local function treesitter_class_has_body(node)
      return treesitter_find_child(node, "field_declaration_list") ~= nil
    end
  
    local function treesitter_walk(node, callback)
      if not node then
        return nil
      end
  
      local result = callback(node)
      if result ~= nil then
        return result
      end
  
      for child in node:iter_children() do
        result = treesitter_walk(child, callback)
        if result ~= nil then
          return result
        end
      end
  
      return nil
    end
  
    local function treesitter_range_item(node, filename, name, source, bufnr)
      local start_row, start_col = node:range()
      return {
        name = name,
        filename = filename,
        lnum = start_row + 1,
        col = start_col + 1,
        text = treesitter_node_text_for_buf(node, bufnr or event.buf),
        source = source,
      }
    end
  
    local function treesitter_current_class_name()
      local class_node = treesitter_ancestor(treesitter_node_at_cursor(), "class_specifier")
      if not treesitter_class_has_body(class_node) then
        return nil
      end
  
      local name_node = treesitter_find_child(class_node, "type_identifier")
      if name_node then
        return treesitter_node_text(name_node)
      end
  
      return nil
    end
  
    local function treesitter_current_function_node()
      return treesitter_ancestor(treesitter_node_at_cursor(), "function_definition")
    end
  
    local function treesitter_function_class_name(function_node)
      if not function_node then
        return nil
      end
  
      local declarator = treesitter_find_child(function_node, "function_declarator")
      if not declarator then
        return nil
      end
  
      local qualified = treesitter_find_child(declarator, "qualified_identifier")
      if not qualified then
        return nil
      end
  
      for child in qualified:iter_children() do
        if child:type() == "namespace_identifier" then
          return treesitter_node_text(child):match("([%w_]+)$")
        end
      end
  
      return nil
    end
  
    local function treesitter_current_definition_class()
      return treesitter_function_class_name(treesitter_current_function_node())
    end
  
    local function current_word_is_identifier()
      local node = treesitter_node_at_cursor()
      if not node then
        return false
      end
  
      local node_type = node:type()
      return (node_type == "identifier" or node_type == "field_identifier")
          and treesitter_node_text(node) == word
    end
  
    local function current_word_is_declaration_context_identifier()
      local node = treesitter_node_at_cursor()
      if not node then
        return false
      end
  
      local node_type = node:type()
      return (node_type == "identifier" or node_type == "field_identifier" or node_type == "type_identifier")
          and treesitter_node_text(node) == word
          and (
            treesitter_ancestor(node, "field_declaration") ~= nil
            or treesitter_ancestor(node, "declaration") ~= nil
          )
          and treesitter_ancestor(node, "function_declarator") == nil
    end
  
    local function current_word_is_field_type()
      local node = treesitter_node_at_cursor()
      if not node then
        return false
      end
  
      return node:type() == "type_identifier"
          and treesitter_node_text(node) == word
          and treesitter_ancestor(node, "field_declaration") ~= nil
    end
  
    local function filter_macro_definition_tags(items)
      local macro_tags = {}
      for _, item in ipairs(items) do
        if (item.text or ""):find("^%s*#define%s+" .. vim.pesc(word) .. "%f[^%w_]") then
          item.source = "macro"
          table.insert(macro_tags, item)
        end
      end
  
      return macro_tags
    end
  
    local function current_word_left_qualifier()
      local node = treesitter_node_at_cursor()
      if not node or treesitter_node_text(node) ~= word then
        return nil
      end
  
      local qualified = treesitter_ancestor(node, "qualified_identifier")
      if not qualified then
        return nil
      end
  
      local qualifier = treesitter_find_child(qualified, "namespace_identifier")
      if qualifier and qualifier:id() ~= node:id() then
        return treesitter_node_text(qualifier)
      end
  
      return nil
    end

    local function current_member_call_receiver()
      local node = treesitter_node_at_cursor()
      if not node or treesitter_node_text(node) ~= word then
        return nil
      end

      local _, start_col = node:range()
      local prefix = vim.api.nvim_get_current_line():sub(1, start_col)
      return prefix:match("([%w_:]+)%s*%-%>%s*$") or prefix:match("([%w_:]+)%s*%.%s*$")
    end

    local function type_basename(type_name)
      if not type_name then
        return nil
      end

      type_name = type_name:gsub("^%s+", ""):gsub("%s+$", "")
      type_name = type_name:gsub("^const%s+", ""):gsub("^volatile%s+", "")
      return type_name:match("([%w_]+)%s*$")
    end

    local function declaration_type_from_line(line, identifier)
      local escaped = vim.pesc(identifier)
      local before = line:match("^(.-)%f[%w_]" .. escaped .. "%f[^%w_]")
      if not before then
        return nil
      end

      before = before:gsub("[&*]%s*$", ""):gsub("%s+$", "")
      local type_name = before:match("([%w_:<>]+)%s*$")
      return type_basename(type_name)
    end

    local function infer_identifier_type(identifier)
      if not identifier then
        return nil
      end

      local files = { vim.api.nvim_buf_get_name(0) }
      local header = files[1]:gsub("%.cc$", ".h"):gsub("%.cpp$", ".h"):gsub("%.cxx$", ".h")
      if header ~= files[1] and vim.fn.filereadable(header) == 1 then
        table.insert(files, header)
      end

      for _, filename in ipairs(files) do
        local ok, lines = pcall(vim.fn.readfile, filename)
        if ok then
          for _, line in ipairs(lines) do
            local type_name = declaration_type_from_line(line, identifier)
            if type_name then
              return type_name
            end
          end
        end
      end

      return nil
    end

    local function collect_qualified_member_tags()
      local qualifier = current_word_left_qualifier()
      if not qualifier then
        return {}
      end
  
      local member_tags = {}
      local matches = collect_filtered_definition_tags(word, nil, function(item)
        return item.text:find("%f[%w_]" .. vim.pesc(qualifier) .. "%f[^%w_]::%s*~?%s*" .. vim.pesc(word) .. "%s*%(")
      end)
      for _, item in ipairs(matches) do
        table.insert(member_tags, item)
      end
  
      return member_tags
    end
  
    local function current_definition_class()
      local node = treesitter_node_at_cursor()
      if not node then
        return nil
      end
  
      local function_node = treesitter_ancestor(node, "function_definition")
      if not function_node then
        return nil
      end
  
      local declarator = treesitter_ancestor(node, "function_declarator")
      if not declarator or not treesitter_ancestor(declarator, "function_definition") then
        return nil
      end
  
      local current_text = treesitter_node_text(node)
      if current_text ~= word then
        return nil
      end
  
      return treesitter_function_class_name(function_node)
    end
  
    local function current_enclosing_definition_class()
      return treesitter_current_definition_class()
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
  
    local function complete_signature_text_from_lines(lines, start_idx)
      local parts = {}
      for idx = start_idx, #lines do
        local line = lines[idx] or ""
        table.insert(parts, line)
        if line:find("[;{]") then
          break
        end
      end
  
      return table.concat(parts, " ")
    end
  
    local function complete_signature_text_from_file(filename, lnum)
      local ok, lines = pcall(vim.fn.readfile, filename)
      if not ok then
        return ""
      end
  
      return complete_signature_text_from_lines(lines, lnum)
    end
  
    local function current_signature_arg_count()
      local cursor = vim.api.nvim_win_get_cursor(0)
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      local text = complete_signature_text_from_lines(lines, cursor[1])
      return count_signature_args(text:match("%((.*)%)"))
    end
  
    local function tag_signature_arg_count(item)
      local text = item.text or ""
      if item.filename and item.lnum then
        text = complete_signature_text_from_file(item.filename, item.lnum)
      end
  
      return count_signature_args(text:match("%((.*)%)"))
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

    local function collect_receiver_member_tags()
      local receiver = current_member_call_receiver()
      local receiver_type = infer_identifier_type(receiver)
      if not receiver_type then
        return {}
      end

      local matches = collect_filtered_definition_tags(word, nil, function(item)
        return (item.text or ""):find("%f[%w_]" .. vim.pesc(receiver_type) .. "%f[^%w_]::%s*~?%s*" .. vim.pesc(word) .. "%s*%(")
      end)

      return filter_by_current_signature(matches)
    end
  
    local function current_word_is_destructor()
      local node = treesitter_node_at_cursor()
      local declarator = treesitter_ancestor(node, "function_declarator")
      return declarator ~= nil
          and treesitter_node_text(declarator):find("^%s*~") ~= nil
          and treesitter_node_text(node) == word
    end
  
    local function collect_member_declarations(class)
      local filename = vim.api.nvim_buf_get_name(0)
      if current_definition_class() then
        local candidate = filename:gsub("%.cc$", ".h"):gsub("%.cpp$", ".h"):gsub("%.cxx$", ".h")
        if candidate ~= filename and vim.fn.filereadable(candidate) == 1 then
          filename = candidate
        end
      end
  
      local bufnr = filename == vim.api.nvim_buf_get_name(0) and event.buf or vim.fn.bufadd(filename)
      vim.fn.bufload(bufnr)
      local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "cpp")
      if not ok or not parser then
        return {}
      end
  
      local tree = parser:parse()[1]
      if not tree then
        return {}
      end
  
      local class_node = treesitter_walk(tree:root(), function(node)
        if node:type() ~= "class_specifier" then
          return nil
        end
  
        if not treesitter_class_has_body(node) then
          return nil
        end
  
        local name_node = treesitter_find_child(node, "type_identifier")
        if name_node and treesitter_node_text_for_buf(name_node, bufnr) == class then
          return node
        end
  
        return nil
      end)
      if not class_node then
        return {}
      end
  
      local results = {}
      treesitter_walk(class_node, function(node)
        if node:type() ~= "function_declarator" then
          return nil
        end
  
        if not treesitter_ancestor(node, "field_declaration") and not treesitter_ancestor(node, "declaration") then
          return nil
        end
  
        local name_node = treesitter_walk(node, function(child)
          local child_type = child:type()
          if child_type == "identifier" or child_type == "field_identifier" then
            if treesitter_node_text_for_buf(child, bufnr) == word then
              return child
            end
          end
          return nil
        end)
        if not name_node then
          return nil
        end
  
        local start_row, start_col = name_node:range()
        table.insert(results, {
          name = word,
          filename = filename,
          lnum = start_row + 1,
          col = start_col + 1,
          text = treesitter_node_text_for_buf(node, bufnr),
          source = "decl",
        })
        return nil
      end)
  
      if current_word_is_destructor() then
        local destructor_results = {}
        for _, item in ipairs(results) do
          if item.text:find("^%s*~") then
            table.insert(destructor_results, item)
          end
        end
        if not vim.tbl_isempty(destructor_results) then
          return filter_by_current_signature(destructor_results)
        end
      end
  
      return filter_by_current_signature(results)
    end
  
    local function current_enclosing_class()
      return treesitter_current_class_name()
    end
  
    local function collect_member_counterpart_tags()
      local class = current_enclosing_definition_class() or current_enclosing_class()
      if not class then
        return {}
      end
  
      local matches = collect_filtered_definition_tags(word, nil, function(item)
        return item.text:find("%f[%w_]" .. vim.pesc(class) .. "%f[^%w_]::%s*~?%s*" .. vim.pesc(word) .. "%s*%(")
      end)
  
      return filter_by_current_signature(matches)
    end
  
    local function collect_member_definition_tags(class)
      if not class then
        return {}
      end
  
      local matches = collect_filtered_definition_tags(word, "def", function(item)
        return (item.text or ""):find("%f[%w_]" .. vim.pesc(class) .. "%f[^%w_]::%s*~?%s*" .. vim.pesc(word) .. "%s*%(")
      end)
  
      return filter_by_current_signature(matches)
    end
  
    local function current_word_is_constructor_declaration()
      if current_enclosing_class() ~= word then
        return false
      end
  
      local node = treesitter_node_at_cursor()
      return treesitter_node_text(node) == word
          and (
            treesitter_ancestor(node, "function_declarator") ~= nil
            or treesitter_ancestor(node, "call_expression") ~= nil
          )
          and (
            treesitter_ancestor(node, "declaration") ~= nil
            or treesitter_ancestor(node, "field_declaration") ~= nil
          )
          and treesitter_ancestor(node, "function_definition") == nil
    end
  
    local function current_word_is_member_declaration()
      if not current_enclosing_class() then
        return false
      end
  
      local node = treesitter_node_at_cursor()
      return treesitter_node_text(node) == word
          and treesitter_ancestor(node, "function_declarator") ~= nil
          and (
            treesitter_ancestor(node, "field_declaration") ~= nil
            or treesitter_ancestor(node, "declaration") ~= nil
          )
          and node:type() ~= "type_identifier"
    end
  
    local function collect_current_member_variable_declaration()
      local cursor = vim.api.nvim_win_get_cursor(0)
      local node = treesitter_node_at_cursor()
      if not node
          or (node:type() ~= "field_identifier" and node:type() ~= "identifier")
          or treesitter_node_text(node) ~= word
          or (
            not treesitter_ancestor(node, "field_declaration")
            and not treesitter_ancestor(node, "declaration")
          )
          or treesitter_ancestor(node, "function_declarator")
          or treesitter_ancestor(node, "function_definition") then
        return {}
      end
  
      local line = vim.api.nvim_get_current_line()
      local _, start_col = node:range()
      return {
        {
          name = word,
          filename = vim.api.nvim_buf_get_name(0),
          lnum = cursor[1],
          col = start_col + 1,
          text = line,
          source = "member",
        },
      }
    end
  
    local function collect_class_member_variable_declaration(class)
      local filename = vim.api.nvim_buf_get_name(0)
      local candidate = filename:gsub("%.cc$", ".h"):gsub("%.cpp$", ".h"):gsub("%.cxx$", ".h")
      if candidate == filename and (
            filename:find("%.h$") or filename:find("%.hpp$") or filename:find("%.hxx$") or filename:find("%.hh$")
          ) then
        candidate = filename
      end
  
      if vim.fn.filereadable(candidate) ~= 1 then
        return {}
      end
  
      local bufnr = candidate == filename and event.buf or vim.fn.bufadd(candidate)
      if candidate ~= filename then
        vim.fn.bufload(bufnr)
      end
      local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "cpp")
      if not ok or not parser then
        return {}
      end
  
      local tree = parser:parse()[1]
      if not tree then
        return {}
      end
  
      local function find_class(class_name)
        return treesitter_walk(tree:root(), function(node)
          if node:type() ~= "class_specifier" then
            return nil
          end
  
          if not treesitter_class_has_body(node) then
            return nil
          end
  
          local name_node = treesitter_find_child(node, "type_identifier")
          if name_node and treesitter_node_text_for_buf(name_node, bufnr) == class_name then
            return node
          end
  
          return nil
        end)
      end
  
      local function find_field(class_node)
        return treesitter_walk(class_node, function(node)
          local node_type = node:type()
          if node_type ~= "field_identifier" and node_type ~= "identifier" then
            return nil
          end
  
          if treesitter_node_text_for_buf(node, bufnr) == word
              and (
                treesitter_ancestor(node, "field_declaration")
                or treesitter_ancestor(node, "declaration")
              )
              and not treesitter_ancestor(node, "function_declarator") then
            return treesitter_range_item(node, candidate, word, "member", bufnr)
          end
  
          return nil
        end)
      end
  
      local class_node = find_class(class)
      local result = class_node and find_field(class_node) or nil
      if result then
        return { result }
      end
  
      local base_class
      if class_node then
        base_class = treesitter_walk(class_node, function(node)
          if node:type() == "base_class_clause" then
            local name_node = treesitter_walk(node, function(child)
              if child:type() == "type_identifier" then
                return child
              end
              return nil
            end)
            return name_node and treesitter_node_text_for_buf(name_node, bufnr) or false
          end
          return nil
        end)
      end
  
      if base_class then
        local base_node = find_class(base_class)
        result = base_node and find_field(base_node) or nil
        if result then
          return { result }
        end
      end
  
      return {}
    end
  
    local function filter_out_destructor_definitions(items)
      local filtered = {}
      for _, item in ipairs(items) do
        if not (item.text or ""):find("::%s*~%s*" .. vim.pesc(word) .. "%s*%(") then
          table.insert(filtered, item)
        end
      end
  
      return filtered
    end
  
    local function filter_destructor_items(items)
      local filtered = {}
      for _, item in ipairs(items) do
        if (item.text or ""):find("~%s*" .. vim.pesc(word) .. "%s*%(") then
          table.insert(filtered, item)
        end
      end
  
      return filter_by_current_signature(filtered)
    end
  
    local function collect_constructor_definitions()
      local class = current_enclosing_class()
      if class ~= word then
        return {}
      end
  
      local matches = collect_filtered_definition_tags(word, nil, function(item)
        return (item.text or ""):find("%f[%w_]" .. vim.pesc(class) .. "%f[^%w_]::%s*" .. vim.pesc(class) .. "%s*%(")
      end)
  
      return filter_by_current_signature(matches)
    end
  
    local function collect_local_declarations()
      local cursor = vim.api.nvim_win_get_cursor(0)
      local cursor_node = treesitter_node_at_cursor()
      local scope = treesitter_ancestor(treesitter_node_at_cursor(), "function_definition")
          or treesitter_ancestor(treesitter_node_at_cursor(), "lambda_expression")
      if not scope then
        return {}
      end
      local results = {}
      local cursor_row = cursor[1] - 1
      local cursor_col = cursor[2]
      local filename = vim.api.nvim_buf_get_name(0)
  
      local function before_cursor(node)
        local start_row, start_col = node:range()
        return start_row < cursor_row or (start_row == cursor_row and start_col < cursor_col)
      end
  
      treesitter_walk(scope, function(node)
        if cursor_node and node:id() == cursor_node:id() then
          return nil
        end

        if not before_cursor(node) then
          return nil
        end
  
        local node_type = node:type()
        if node_type ~= "identifier" and node_type ~= "field_identifier" then
          return nil
        end
  
        if treesitter_node_text(node) ~= word then
          return nil
        end
  
        local source
        if treesitter_ancestor(node, "parameter_declaration") then
          source = "param"
        elseif treesitter_ancestor(node, "declaration")
            or (
              treesitter_ancestor(node, "for_range_loop")
              and (
                treesitter_ancestor(node, "reference_declarator")
                or treesitter_ancestor(node, "pointer_declarator")
                or treesitter_ancestor(node, "init_declarator")
              )
            ) then
          source = "local"
        else
          return nil
        end
  
        local start_row, start_col = node:range()
        table.insert(results, {
          name = word,
          filename = filename,
          lnum = start_row + 1,
          col = start_col + 1,
          text = treesitter_node_text(node),
          source = source,
        })
        return nil
      end)
  
      if #results > 1 then
        table.sort(results, function(a, b)
          if a.lnum == b.lnum then
            return a.col > b.col
          end
          return a.lnum > b.lnum
        end)
        return { results[1] }
      end
  
      return results
    end
  
    local function jump_to_gtags_item(item)
      local filename = item.filename
      local lnum = item.lnum or 1
      local name = item.name
  
      vim.cmd("edit " .. vim.fn.fnameescape(filename))
      vim.api.nvim_win_set_cursor(0, { lnum, math.max((item.col or 1) - 1, 0) })
  
      local cursor = vim.api.nvim_win_get_cursor(0)
      local line = vim.api.nvim_get_current_line()
      local start_col = line:find("%f[%w_]" .. vim.pesc(name) .. "%f[^%w_]")
      if start_col then
        vim.api.nvim_win_set_cursor(0, { cursor[1], start_col - 1 })
      end
      vim.cmd("normal! zz")
    end
  
    local function show_gtags_quickfix(title, candidates)
      if vim.tbl_isempty(candidates) then
        return false
      end

      local qf_items = {}
      for _, item in ipairs(candidates) do
        local source = item.source and ("[" .. item.source .. "] ") or ""
        table.insert(qf_items, {
          filename = item.filename,
          lnum = item.lnum or 1,
          col = item.col or 1,
          text = source .. (item.text or item.name or ""),
        })
      end

      vim.fn.setqflist({}, " ", { title = title, items = qf_items })
      vim.cmd("copen")
      return true
    end
  
    local function jump_to_gtags_definitions(matches)
      matches = matches or collect_definition_tags(word)
      local candidates = collect_local_declarations()
      vim.list_extend(candidates, matches)
      candidates = dedupe_items(candidates)
  
      if #candidates == 1 then
        jump_to_gtags_item(candidates[1])
        return
      end
  
      if show_gtags_quickfix("Gtags Definitions: " .. word, candidates) then
        return
      end
  
      vim.notify("No gtags definition found for " .. word, vim.log.levels.WARN)
    end
  
    local function jump_to_type_tags()
      local type_tags = collect_type_tags()
      if #type_tags == 1 then
        jump_to_gtags_item(type_tags[1])
        return true
      end
  
      if #type_tags > 1 then
        return show_gtags_quickfix("Gtags Types: " .. word, type_tags)
      end
  
      return false
    end
  
    local function jump_to_ctags_type_tags()
      local type_tags = collect_ctags_type_tags(word)
      if #type_tags == 1 then
        jump_to_gtags_item(type_tags[1])
        return true
      end
  
      if #type_tags > 1 then
        return show_gtags_quickfix("Ctags Types: " .. word, type_tags)
      end
  
      return false
    end
  
    local function show_or_jump_gtags_definitions(matches)
      local candidates = collect_local_declarations()
      vim.list_extend(candidates, matches)
      candidates = dedupe_items(candidates)
  
      if #candidates == 1 then
        jump_to_gtags_item(candidates[1])
        return true
      end
  
      return show_gtags_quickfix("Gtags Definitions: " .. word, candidates)
    end
  
    local function async_jump_to_gtags()
      echo_status("Searching gtags for " .. word .. "...")
  
      async_collect_gtags_definitions(word, function(definitions)
        clear_echo_status()

        if current_word_is_destructor() then
          local definition_class = current_definition_class()
          if definition_class then
            local destructor_definitions = filter_by_current_signature(filter_definition_tags(definitions, nil, function(item)
              return (item.text or ""):find("%f[%w_]" .. vim.pesc(definition_class) .. "%f[^%w_]::%s*~%s*" .. vim.pesc(word) .. "%s*%(")
            end))
            if #destructor_definitions == 1 then
              jump_to_gtags_item(destructor_definitions[1])
              return
            end
          end
        end
  
        if current_word_is_constructor_declaration() then
          local class = current_enclosing_class()
          local constructor_definitions = filter_by_current_signature(filter_definition_tags(definitions, nil, function(item)
            return class and (item.text or ""):find("%f[%w_]" .. vim.pesc(class) .. "%f[^%w_]::%s*" .. vim.pesc(class) .. "%s*%(")
          end))
          if #constructor_definitions == 1 then
            jump_to_gtags_item(constructor_definitions[1])
            return
          end
        end
  
        local declaration_class = current_word_is_member_declaration() and current_enclosing_class() or nil
        if declaration_class then
          local member_definitions = filter_by_current_signature(filter_definition_tags(definitions, "def", function(item)
            return (item.text or ""):find("%f[%w_]" .. vim.pesc(declaration_class) .. "%f[^%w_]::%s*~?%s*" .. vim.pesc(word) .. "%s*%(")
          end))
          if #member_definitions == 1 then
            jump_to_gtags_item(member_definitions[1])
            return
          end
        end
  
        local qualifier = current_word_left_qualifier()
        if qualifier then
          local qualified_member_tags = filter_definition_tags(definitions, nil, function(item)
            return (item.text or ""):find("%f[%w_]" .. vim.pesc(qualifier) .. "%f[^%w_]::%s*~?%s*" .. vim.pesc(word) .. "%s*%(")
          end)
          if #qualified_member_tags == 1 then
            jump_to_gtags_item(qualified_member_tags[1])
            return
          end
        end
  
      local member_class = current_enclosing_definition_class() or current_enclosing_class()
      if member_class then
        local member_counterpart_tags = filter_by_current_signature(filter_definition_tags(definitions, nil, function(item)
          return (item.text or ""):find("%f[%w_]" .. vim.pesc(member_class) .. "%f[^%w_]::%s*~?%s*" .. vim.pesc(word) .. "%s*%(")
        end))
          if #member_counterpart_tags == 1 then
            jump_to_gtags_item(member_counterpart_tags[1])
            return
          end
        end
  
        local macro_tags = filter_macro_definition_tags(definitions)
        if #macro_tags == 1 then
          jump_to_gtags_item(macro_tags[1])
          return
        end
  
        if #definitions == 1 then
          jump_to_gtags_item(definitions[1])
          return
        end
  
        if #definitions > 1 and show_gtags_quickfix("Gtags Definitions: " .. word, definitions) then
          return
        end
  
        async_collect_gtags_type_tags(word, function(type_tags)
          if #type_tags == 1 then
            jump_to_gtags_item(type_tags[1])
            return
          end
  
          if #type_tags > 1 and show_gtags_quickfix("Gtags Types: " .. word, type_tags) then
            return
          end
  
          if show_or_jump_gtags_definitions(definitions) then
            return
          end
  
          vim.notify("No gtags definition found for " .. word, vim.log.levels.WARN)
        end)
      end)
    end
  
    local function jump_to_gtags()
      if current_word_is_destructor() then
        local definition_class = current_definition_class()
        if definition_class then
          local member_declarations = filter_destructor_items(collect_member_declarations(definition_class))
          if #member_declarations == 1 then
            jump_to_gtags_item(member_declarations[1])
            return
          end
        end
  
        local destructor_definitions = filter_destructor_items(collect_member_counterpart_tags())
        if #destructor_definitions == 1 then
          jump_to_gtags_item(destructor_definitions[1])
          return
        end
      end
  
      if current_word_is_constructor_declaration() then
        local constructor_definitions = collect_constructor_definitions()
        if #constructor_definitions == 1 then
          jump_to_gtags_item(constructor_definitions[1])
          return
        end
      end
  
      if current_word_is_declaration_context_identifier() and jump_to_ctags_type_tags() then
        return
      end
  
      local declaration_class = current_word_is_member_declaration() and current_enclosing_class() or nil
      if declaration_class then
        local member_definitions = collect_member_definition_tags(declaration_class)
        if #member_definitions == 1 then
          jump_to_gtags_item(member_definitions[1])
          return
        end
      end
  
      local definition_class = current_definition_class()
      if definition_class then
        local member_declarations = collect_member_declarations(definition_class)
        if #member_declarations == 1 then
          jump_to_gtags_item(member_declarations[1])
          return
        end
      end
  
      if current_word_is_identifier() then
        local receiver_member_tags = collect_receiver_member_tags()
        if #receiver_member_tags == 1 then
          jump_to_gtags_item(receiver_member_tags[1])
          return
        end

        local definition_member_class = current_enclosing_definition_class()
        if definition_member_class then
          local class_member_variables = collect_class_member_variable_declaration(definition_member_class)
          if #class_member_variables == 1 then
            jump_to_gtags_item(class_member_variables[1])
            return
          end
        end
      end
  
      local local_declarations = collect_local_declarations()
      if #local_declarations == 1 then
        jump_to_gtags_item(local_declarations[1])
        return
      end
  
      local member_variables = collect_current_member_variable_declaration()
      if #member_variables == 1 then
        vim.notify("Already at member declaration: " .. word, vim.log.levels.INFO)
        jump_to_gtags_item(member_variables[1])
        return
      end
  
      local member_class = current_enclosing_definition_class() or current_enclosing_class()
      if member_class then
        local class_member_variables = collect_class_member_variable_declaration(member_class)
        if #class_member_variables == 1 then
          jump_to_gtags_item(class_member_variables[1])
          return
        end
      end
  
      local qualified_member_tags = collect_qualified_member_tags()
      if #qualified_member_tags == 1 then
        jump_to_gtags_item(qualified_member_tags[1])
        return
      end
  
      local member_counterpart_tags = collect_member_counterpart_tags()
      if #member_counterpart_tags == 1 then
        jump_to_gtags_item(member_counterpart_tags[1])
        return
      end
  
      local definitions = collect_definition_tags(word)
  
      local macro_tags = filter_macro_definition_tags(definitions)
      if #macro_tags == 1 then
        jump_to_gtags_item(macro_tags[1])
        return
      end
  
      if #definitions == 1 then
        jump_to_gtags_item(definitions[1])
        return
      end
  
      if #definitions > 1 then
        if show_gtags_quickfix("Gtags Definitions: " .. word, definitions) then
          return
        end
      end
  
      if jump_to_type_tags() then
        return
      end
  
      async_jump_to_gtags()
    end
  
    if current_word_is_constructor_declaration() then
      jump_to_gtags()
      return
    end
  
    if current_word_is_member_declaration() then
      jump_to_gtags()
      return
    end
  
    if current_word_is_field_type() then
      if jump_to_type_tags() then
        return
      end
  
      jump_to_gtags()
      return
    end
  
    if current_word_is_declaration_context_identifier() then
      if jump_to_ctags_type_tags() then
        return
      end
    end
  
    if current_definition_class() then
      jump_to_gtags()
      return
    end
  
    if current_word_is_identifier() then
      local receiver_member_tags = collect_receiver_member_tags()
      if #receiver_member_tags == 1 then
        jump_to_gtags_item(receiver_member_tags[1])
        return
      end

      local definition_member_class = current_enclosing_definition_class()
      if definition_member_class then
        local class_member_variables = collect_class_member_variable_declaration(definition_member_class)
        if #class_member_variables == 1 then
          jump_to_gtags_item(class_member_variables[1])
          return
        end
      end
    end
  
    local enclosing_member_class = current_enclosing_definition_class() or current_enclosing_class()
    if enclosing_member_class then
      local class_member_variables = collect_class_member_variable_declaration(enclosing_member_class)
      if #class_member_variables == 1 then
        jump_to_gtags_item(class_member_variables[1])
        return
      end
    end
  
    jump_to_gtags()
end

local function gtags_reference_picker(command_specs, title, source, fallback_specs)
    return function()
      local word = vim.fn.expand("<cword>")
      local buffer_name = vim.api.nvim_buf_get_name(0)
      local command_cwd = buffer_name ~= "" and vim.fn.fnamemodify(buffer_name, ":p:h") or vim.fn.getcwd()
      local root_ok, root_lines = sync_systemlist({ "global", "-pr" }, command_cwd)
      local root = root_lines[1]
      if not root_ok or not root or root == "" then
        vim.notify("No GTAGS database found", vim.log.levels.WARN)
        return
      end
  
      if type(command_specs[1]) == "string" then
        command_specs = { command_specs }
      end
      if fallback_specs and type(fallback_specs[1]) == "string" then
        fallback_specs = { fallback_specs }
      end
  
      local function collect_lines(specs)
        local result = {}
        if not specs then
          return result
        end
  
        for _, args in ipairs(specs) do
          local command = vim.deepcopy(args)
          table.insert(command, word)
          local ok, command_lines = sync_systemlist(command, root)
          if ok then
            vim.list_extend(result, command_lines)
          end
        end
  
        return result
      end
  
      local lines = collect_lines(command_specs)
      if vim.tbl_isempty(lines) then
        lines = collect_lines(fallback_specs)
      end
  
      if vim.tbl_isempty(lines) then
        vim.notify("No gtags result found for " .. word, vim.log.levels.WARN)
        return
      end
  
      local items = {}
      local seen = {}
      for _, line in ipairs(lines) do
        local _, lnum, filename, text = line:match("^(%S+)%s+(%d+)%s+(%S+)%s?(.*)$")
        if filename and lnum then
          if filename:sub(1, 1) ~= "/" then
            filename = vim.fn.fnamemodify(root .. "/" .. filename, ":p")
          end
          local col = 1
          if text and text ~= "" then
            col = text:find("%f[%w_]" .. vim.pesc(word) .. "%f[^%w_]") or 1
          end
  
          local key = table.concat({ filename, lnum, text or "" }, "\t")
          if not seen[key] then
            seen[key] = true
            table.insert(items, {
              name = word,
              filename = filename,
              lnum = tonumber(lnum),
              col = col,
              text = text or "",
              source = source,
            })
          end
        end
      end
  
      local function jump(item)
        vim.cmd("edit " .. vim.fn.fnameescape(item.filename))
        vim.api.nvim_win_set_cursor(0, { item.lnum or 1, math.max((item.col or 1) - 1, 0) })
        vim.cmd("normal! zz")
      end
  
      if #items == 1 then
        jump(items[1])
        return
      end

      local qf_items = {}
      for _, item in ipairs(items) do
        table.insert(qf_items, {
          filename = item.filename,
          lnum = item.lnum or 1,
          col = item.col or 1,
          text = "[" .. item.source .. "] " .. item.text,
        })
      end
      vim.fn.setqflist({}, " ", { title = title .. ": " .. word, items = qf_items })
      vim.cmd("copen")
    end
  end
  
-- This depends on ctags and global
-- installed by 
  -- brew install universal-ctags
  -- brew install global
-- usage:
  -- 1. ctags -R --languages=C,C++ --exclude=.git --exclude=build --exclude=third_party
  -- 2. rg --files -g '!build/**' -g '!**/build/**' -g '!third_party/**' -g '!**/third_party/**' | gtags -f -
function M.setup_buffer(bufnr)
  keymap("n", "gD", function()
    goto_definition(bufnr)
  end, { buffer = bufnr, desc = "Go to definition via treesitter, gtags, and ctags" })

  keymap("n", "gd", function()
    vim.lsp.buf.definition()
  end, { buffer = bufnr, desc = "Go to definition via LSP" })

  keymap("n", "gR", gtags_reference_picker({ "global", "-rx", "--literal" }, "Gtags References", "ref",
    { "global", "-sx", "--literal" }),
    { buffer = bufnr, desc = "Find references via gtags" })

  keymap("n", "gr", function()
    vim.lsp.buf.references()
  end, { buffer = bufnr, desc = "Find references via LSP" })
end

return M
