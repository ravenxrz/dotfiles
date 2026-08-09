-- grug-far 自动历史记录增强
--
-- grug-far 自带的 autoSave 只在 replace / sync all / 关闭搜索 buffer 时写 history，
-- 普通的“边输入边搜索”不会入库；而且它只有基于行数的 maxHistoryLines，没有“按条数”限制。
-- 这里做两件事：
--   1. 每次防抖搜索“成功完成”后，自动把当前查询追加到 history。
--   2. 用一个统一的 writer 替换 history.addHistoryEntry，让所有入库路径都按“条数”截断。
--
-- 实现依赖 grug-far 内部结构（针对 lazy-lock 里锁定的版本），若升级插件后行为异常，
-- 优先核对 grug-far/tasks.lua:finishTask 与 grug-far/history.lua 的入库格式。

local M = {}

-- 与 grug-far/history.lua 保持一致的分隔符
local continuation_prefix = "| "
local engine_field_sep = "|"

-- 复刻 grug-far/history.lua 的 formatInputValue：多行值用 "| " 续行前缀
local function format_input_value(value)
  local lines = vim.split(value, "\n")
  local result = {}
  for i, line in ipairs(lines) do
    table.insert(result, i == 1 and line or continuation_prefix .. line)
  end
  return table.concat(result, "\n")
end

-- 按“条目”截断：每个条目以 "Engine:" 行开头，条目之间以空行分隔。
-- 保留最新的 max_items 条（history 是新的在前），并去掉末尾多余空行。
local function trim_to_max_items(contents, max_items)
  if not max_items or max_items <= 0 then
    return contents
  end

  local lines = vim.split(contents, "\n")
  local engine_count = 0
  local cut_index = nil
  for i, line in ipairs(lines) do
    if vim.startswith(line, "Engine:") then
      engine_count = engine_count + 1
      if engine_count == max_items + 1 then
        cut_index = i
        break
      end
    end
  end

  if not cut_index then
    return contents
  end

  local kept = vim.list_slice(lines, 1, cut_index - 1)
  while #kept > 0 and kept[#kept] == "" do
    table.remove(kept)
  end
  return table.concat(kept, "\n")
end

-- 统一的入库函数：追加当前查询 -> 去重(与最新条目) -> 按条数截断 -> 写回。
-- 单次 read-modify-write，天然被 500ms 防抖串行化，无需担心竞态。
---@param context table grug.far Context
---@param buf integer
---@param notify boolean|nil 是否弹出提示（手动 historyAdd 时为 true）
local function add_history_entry(context, buf, notify)
  local inputs = require("grug-far.inputs")
  local utils = require("grug-far.utils")
  local history = require("grug-far.history")

  local values = inputs.getValues(context, buf)

  local inputs_len = 0
  for _, input in ipairs(context.engine.inputs) do
    inputs_len = inputs_len + #(values[input.name] or "")
  end
  if inputs_len == 0 then
    return -- 什么都没有，不入库
  end

  local history_filename = history.getHistoryFilename(context)
  local max_items = M.max_items

  local callback = vim.schedule_wrap(function(err)
    if notify then
      if err then
        vim.notify("grug-far: could not add to history: " .. err, vim.log.levels.ERROR)
      else
        vim.notify("grug-far: added current search to history!", vim.log.levels.INFO)
      end
    end
  end)

  utils.readFileAsync(history_filename, function(err, contents)
    if err then
      callback(err)
      return
    end

    vim.schedule(function()
      local entry = "\n\nEngine: "
        .. context.engine.type
        .. (context.replacementInterpreter and engine_field_sep .. context.replacementInterpreter.type or "")
      for _, input in ipairs(context.engine.inputs) do
        entry = entry .. "\n" .. input.label .. ": " .. format_input_value(values[input.name] or "")
      end
      entry = entry .. "\n"

      -- 与最新一条去重（避免同一查询连续入库）
      local new_contents = contents or ""
      if not vim.startswith(new_contents, entry) then
        new_contents = entry .. new_contents
      end

      new_contents = trim_to_max_items(new_contents, max_items)

      utils.overwriteFileAsync(history_filename, new_contents, callback)
    end)
  end)
end

-- 拿到 context 对应的 buf（内部结构，加 pcall 兜底）
local function buf_of_context(context)
  local ok, instances = pcall(require, "grug-far.instances")
  if not ok then
    return nil
  end
  local instance = instances.get_instance(context.options.instanceName)
  return instance and instance._buf or nil
end

---@param opts table|nil { max_items = integer }
function M.setup(opts)
  opts = opts or {}
  M.max_items = opts.max_items or 30

  if M._patched then
    return
  end
  M._patched = true

  local history = require("grug-far.history")
  local tasks = require("grug-far.tasks")

  -- 1) 用统一 writer 替换 addHistoryEntry：所有入库路径（search/replace/syncAll/
  --    bufDelete/手动 add）都会走 add_history_entry，从而都受“条数”限制。
  history.addHistoryEntry = function(context, buf, notify)
    local ok, err = pcall(add_history_entry, context, buf, notify)
    if not ok then
      vim.notify("grug-far history: " .. tostring(err), vim.log.levels.ERROR)
    end
  end

  -- 2) 在 finishTask 上挂钩：只在“搜索任务成功完成”时入库。
  --    - 只处理 type == 'search'（sync/replace 有各自的 autoSave）
  --    - 跳过被打断的任务（边打字被后续搜索取代、或命中 maxSearchMatches 提前中止）
  --    - 只在 status == 'success' 且实际有搜索词时入库，避免仅剩过滤器默认值时的噪声
  local orig_finish_task = tasks.finishTask
  tasks.finishTask = function(context, task)
    local is_search = task.type == "search"
    local was_aborted = task.isAborted

    orig_finish_task(context, task)

    if not (is_search and not was_aborted) then
      return
    end
    if context.state.status ~= "success" then
      return
    end

    local buf = buf_of_context(context)
    if not buf or not vim.api.nvim_buf_is_valid(buf) then
      return
    end

    -- 只有真正输入了搜索词才入库（过滤掉只有默认 Files Filter 的空搜索）
    local ok, values = pcall(function()
      return require("grug-far.inputs").getValues(context, buf)
    end)
    if not ok or not values.search or values.search == "" then
      return
    end

    history.addHistoryEntry(context, buf)
  end
end

return M
