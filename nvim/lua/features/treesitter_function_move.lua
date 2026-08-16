local M = {}

local CUSTOM_CAPTURE = "custom.function.declare"
local FUNCTION_OUTER_CAPTURE = "function.outer"

local function range_to_item(bufnr, node, source)
  if not node then
    return nil
  end

  local values = { node:range(true) }
  if #values ~= 6 then
    local srow, scol, erow, ecol = node:range(false)
    if srow == nil or scol == nil or erow == nil or ecol == nil then
      return nil
    end
    local start_offset = vim.api.nvim_buf_get_offset(bufnr, srow)
    local end_offset = vim.api.nvim_buf_get_offset(bufnr, erow)
    if start_offset < 0 or end_offset < 0 then
      return nil
    end
    values = { srow, scol, start_offset + scol, erow, ecol, end_offset + ecol }
  end

  for i = 1, 6 do
    if type(values[i]) ~= "number" then
      return nil
    end
  end

  return {
    start_row = values[1],
    start_col = values[2],
    start_byte = values[3],
    end_row = values[4],
    end_col = values[5],
    end_byte = values[6],
    source = source,
  }
end

local function first_named_descendant_matching(node, wanted_types)
  if not node then
    return nil
  end
  if wanted_types[node:type()] then
    return node
  end
  for child in node:iter_children() do
    if child:named() then
      local found = first_named_descendant_matching(child, wanted_types)
      if found then
        return found
      end
    end
  end
  return nil
end

local function function_name_node_from_outer(node)
  -- Best effort across common parsers. For C/C++/Lua/Python, function names are
  -- usually one of these named descendants. If this heuristic misses a language,
  -- we still fall back to the outer function node start.
  return first_named_descendant_matching(node, {
    identifier = true,
    field_identifier = true,
    type_identifier = true,
    destructor_name = true,
    operator_name = true,
    property_identifier = true,
  })
end

local function query_for(lang, group)
  local ok, query = pcall(vim.treesitter.query.get, lang, group)
  if ok then
    return query
  end
  return nil
end

local function collect_capture_items(bufnr, capture, group, source, name_from_function_outer)
  local ok_parser, parser = pcall(vim.treesitter.get_parser, bufnr)
  if not ok_parser or not parser then
    return {}, "no parser for current buffer"
  end

  parser:parse(true)

  local items = {}
  local saw_query = false
  local saw_capture_name = false

  parser:for_each_tree(function(tree, lang_tree)
    local lang = lang_tree:lang()
    local query = query_for(lang, group)
    if not query then
      return
    end
    saw_query = true

    for _, cap in ipairs(query.captures or {}) do
      if cap == capture then
        saw_capture_name = true
        break
      end
    end

    local root = tree:root()
    local start_row, _, end_row, _ = root:range()
    for _, match, _ in query:iter_matches(root, bufnr, start_row, end_row + 1) do
      for id, nodes in pairs(match) do
        if query.captures[id] == capture then
          if type(nodes) ~= "table" then
            nodes = { nodes }
          end
          for _, node in ipairs(nodes) do
            local target_node = name_from_function_outer and function_name_node_from_outer(node) or node
            local item = range_to_item(bufnr, target_node or node, source)
            if item then
              table.insert(items, item)
            end
          end
        end
      end
    end
  end)

  local reason = nil
  if not saw_query then
    reason = "no textobjects query for current parser language"
  elseif not saw_capture_name then
    reason = "capture @" .. capture .. " is not defined for current parser language"
  elseif #items == 0 then
    reason = "capture @" .. capture .. " matched no valid ranges"
  end

  return items, reason
end

local function sort_and_dedupe(items)
  table.sort(items, function(a, b)
    if a.start_byte == b.start_byte then
      if a.start_row == b.start_row then
        return a.start_col < b.start_col
      end
      return a.start_row < b.start_row
    end
    return a.start_byte < b.start_byte
  end)

  local deduped = {}
  local last_key = nil
  for _, item in ipairs(items) do
    local key = table.concat({ item.start_row, item.start_col, item.start_byte, item.end_row, item.end_col, item.end_byte }, ":")
    if key ~= last_key then
      table.insert(deduped, item)
      last_key = key
    end
  end
  return deduped
end

local function should_skip_buffer(bufnr)
  local bo = vim.bo[bufnr]
  return bo.buftype ~= "" or bo.filetype == ""
end

local function collect_function_name_items(bufnr)
  if should_skip_buffer(bufnr) then
    return {}, "skip buffer without ordinary filetype/parser"
  end

  local custom_items, custom_reason = collect_capture_items(bufnr, CUSTOM_CAPTURE, "textobjects", "custom", false)
  if #custom_items > 0 then
    return sort_and_dedupe(custom_items), nil
  end

  local fallback_items, fallback_reason = collect_capture_items(bufnr, FUNCTION_OUTER_CAPTURE, "textobjects", "function.outer", true)
  if #fallback_items > 0 then
    return sort_and_dedupe(fallback_items), "using @function.outer fallback; @" .. CUSTOM_CAPTURE .. " unavailable: " .. tostring(custom_reason)
  end

  return {}, table.concat({
    "@" .. CUSTOM_CAPTURE .. ": " .. tostring(custom_reason),
    "@" .. FUNCTION_OUTER_CAPTURE .. ": " .. tostring(fallback_reason),
  }, "; ")
end

local function current_byte(bufnr)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  row = row - 1
  local offset = vim.api.nvim_buf_get_offset(bufnr, row)
  if offset < 0 then
    return 0
  end
  return offset + col
end

local function jump_to_item(item)
  if not item then
    return false
  end
  vim.cmd("normal! m'")
  vim.api.nvim_win_set_cursor(0, { item.start_row + 1, item.start_col })
  return true
end

local function maybe_notify_fallback(reason)
  if reason and vim.g.treesitter_function_move_notify_fallback == true then
    vim.notify(reason, vim.log.levels.INFO)
  end
end

function M.goto_next()
  local bufnr = vim.api.nvim_get_current_buf()
  local items, reason = collect_function_name_items(bufnr)
  if #items == 0 then
    if reason ~= "skip buffer without ordinary filetype/parser" then
      vim.notify("No Tree-sitter function captures found: " .. tostring(reason), vim.log.levels.WARN)
    end
    return
  end
  maybe_notify_fallback(reason)

  local pos = current_byte(bufnr)
  local count = vim.v.count1
  local target = nil
  for _, item in ipairs(items) do
    if item.start_byte > pos then
      target = item
      count = count - 1
      if count == 0 then
        break
      end
    end
  end

  if not target then
    vim.notify("No next function capture", vim.log.levels.WARN)
    return
  end

  jump_to_item(target)
end

function M.goto_previous()
  local bufnr = vim.api.nvim_get_current_buf()
  local items, reason = collect_function_name_items(bufnr)
  if #items == 0 then
    if reason ~= "skip buffer without ordinary filetype/parser" then
      vim.notify("No Tree-sitter function captures found: " .. tostring(reason), vim.log.levels.WARN)
    end
    return
  end
  maybe_notify_fallback(reason)

  local pos = current_byte(bufnr)
  local count = vim.v.count1
  local target = nil
  for i = #items, 1, -1 do
    local item = items[i]
    if item.start_byte < pos then
      target = item
      count = count - 1
      if count == 0 then
        break
      end
    end
  end

  if not target then
    vim.notify("No previous function capture", vim.log.levels.WARN)
    return
  end

  jump_to_item(target)
end

-- Exposed for ad-hoc debugging from :lua.
function M.debug_items()
  local items, reason = collect_function_name_items(vim.api.nvim_get_current_buf())
  return items, reason
end

return M
