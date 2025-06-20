--
-- copy filename / filename wo extensions/full path/breakpoint
--
local send2clipboard = function(text)
  vim.fn.setreg("+", text)
end
local copy_cur_filename = function()
  local filename = vim.fn.expand("%:t")
  send2clipboard(filename)
  print("copy filename:" .. filename)
end
local copy_cur_filename_wo_ext = function()
  local filename = vim.fn.expand("%:t")
  local filename_wo_ext = vim.fn.fnamemodify(filename, ":r")
  send2clipboard(filename_wo_ext)
  print("copy filename wo ext:" .. filename_wo_ext)
end
local copy_cur_file_path = function()
  local file_path = vim.fn.expand("%:p")
  send2clipboard(file_path)
  print("copy file path:" .. file_path)
end
local copy_cur_file_path_wo_ext = function()
  local file_path = vim.fn.expand("%:p")
  local filepath_wo_ext = vim.fn.fnamemodify(file_path, ":r")
  send2clipboard(filepath_wo_ext)
  print("copy file path wo ext:" .. filepath_wo_ext)
end
local copy_cur_breakpoint = function()
  local file_name = vim.fn.expand("%:t")
  -- get current line number
  local line_number = vim.fn.line(".")
  local breakpoint = file_name .. ":" .. line_number
  send2clipboard(breakpoint)
  print("copy breakpoint:" .. breakpoint)
end

local function get_current_function_name()
  -- 获取当前缓冲区的 ID
  local bufnr = vim.api.nvim_get_current_buf()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  row = row - 1 -- 调整为 0 索引

  local clients = vim.lsp.get_active_clients({ bufnr = bufnr })
  if #clients == 0 then
    vim.notify("No LSP client is attached to this buffer.", vi.log.levels.WARN)
    return
  end

  local params = { textDocument = vim.lsp.util.make_text_document_params(bufnr) }
  local result = nil
  for _, client in ipairs(clients) do
    result = client.request_sync("textDocument/documentSymbol", params, 2000, bufnr)
    if result and result.result then
      break
    end
  end

  if not result or not result.result then
    vim.notify("Failed to get document symbols from LSP.", vim.log.levels.WARN)
    return
  end

  local function find_function_symbol(symbols)
    local kind = vim.lsp.protocol.SymbolKind
    local expect_kind = {
      kind.Constructor,
      kind.Function,
      kind.Method,
    }
    for _, symbol in ipairs(symbols) do
      if vim.tbl_contains(expect_kind, symbol.kind) then
        local range = symbol.location and symbol.location.range or symbol.range
        if
            range
            and range.start.line <= row
            and range["end"].line >= row
            and (
              range.start.line ~= range["end"].line
              or (range.start.character <= col and range["end"].character >= col)
            )
        then
          return symbol.name
        end
      end
      if symbol.children then
        local child_result = find_function_symbol(symbol.children)
        if child_result then
          return child_result
        end
      end
    end
    return nil
  end

  local function_name = find_function_symbol(result.result)
  if function_name then
    return function_name
  else
    return nil
  end
end

local function copy_cursor_func_name()
  local func_name = get_current_function_name()
  if func_name == nil then
    return
  end
  send2clipboard(func_name)
  print("copy func_name:" .. func_name)
end

vim.api.nvim_create_user_command("CopyFileName", copy_cur_filename, {})
vim.api.nvim_create_user_command("CopyFileNameWoExt", copy_cur_filename_wo_ext, {})
vim.api.nvim_create_user_command("CopyFilePath", copy_cur_file_path, {})
vim.api.nvim_create_user_command("CopyFilePathWoExt", copy_cur_file_path_wo_ext, {})
vim.api.nvim_create_user_command("CopyBreakPoint", copy_cur_breakpoint, {})
vim.api.nvim_create_user_command("CopyFuncName", copy_cursor_func_name, {})



