-- codecompanion_status.lua — 在状态栏近实时展示 CodeCompanion chat 的运行状态
-- author: zhangxingrui
--
-- 痛点: chat 在后台跑(提交、工具执行、compaction)时状态栏没有任何提示; 更糟的是
--       工具需要授权(ToolApprovalRequested)时, 若焦点不在 chat 缓冲区, 很容易错过,
--       整轮就卡住不动。
--
-- 数据源: CodeCompanion 通过 `User` 自动命令派发一组事件(见 utils.fire -> 事件名带
--         "CodeCompanion" 前缀), 每个事件的 data 里带 bufnr。纯本地事件驱动, 零轮询开销。
--
-- 状态模型(按 chat 缓冲区):
--   M.chats[bufnr] = { state = "working" | "approving" | "idle", name? }
--   聚合优先级: approving > working > idle。任一 chat 在 approving 就整体 approving,
--   否则任一 working 就 working, 都没有就不显示。ChatDone/Stopped/Closed 直接删除该项。
--
-- 定时器: 只有当存在 working 的 chat 时, 才起一个 ~120ms 的 uv 定时器推进 spinner 帧并
--         redrawstatus; approving 是静态图标不需要动画; 全空闲则停表, 零开销。
--
-- 用法: 在 init.lua 里 require("features.codecompanion_status").setup({})
--       在 lualine 组件里调用 require("features.codecompanion_status").component()/highlight()/active()

local M = {}

local uv = vim.uv or vim.loop

-- 按 chat 缓冲区(bufnr)记录状态。每项: { state, name? }
-- 只保留 working/approving 的活跃 chat; 结束(Done/Stopped/Closed)即删除。
M.chats = {}

local defaults = {
  spinner_interval = 120, -- spinner 帧推进间隔(ms)
  icons = {
    approving = "⏸", -- 等待授权(静态)
  },
  notify = {
    enabled = true, -- 授权/完成时弹右上角 toast(走 vim.notify -> nvim-notify)
    approve_timeout = false, -- 授权 toast 不自动消失(false=常驻, 直到授权结束)
    done_timeout = 3000, -- 完成 toast 自动消失(ms)
  },
}

local config = vim.deepcopy(defaults)

-- 纯 Lua braille spinner 序列, 无依赖
local frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
local frame = 1

local spin_timer = nil
local group = nil

-- 每个 chat 缓冲区一个 nvim-notify 句柄, 用于原地 replace(多 chat 并行时不刷屏)。
-- notif[bufnr] = <notify record> (来自 vim.notify 返回值)
local notif = {}

-- ── 状态聚合 ────────────────────────────────────────────────────────────────

-- 是否存在 working 的 chat(spinner 是否需要转)
local function any_working()
  for _, c in pairs(M.chats) do
    if c.state == "working" then
      return true
    end
  end
  return false
end

-- 聚合出全局状态与(若在等待授权)工具名
-- 返回 state ∈ nil/"working"/"approving", name?
function M.aggregate()
  local has_working = false
  local approve_name = nil
  local has_approving = false
  for _, c in pairs(M.chats) do
    if c.state == "approving" then
      has_approving = true
      approve_name = c.name
    elseif c.state == "working" then
      has_working = true
    end
  end
  if has_approving then
    return "approving", approve_name
  end
  if has_working then
    return "working"
  end
  return nil
end

-- ── spinner 定时器 ──────────────────────────────────────────────────────────

-- 按需启停 spinner: 有 working 就转, 否则停表。任何调用都会顺带刷新一次状态栏。
local function ensure_timer()
  if any_working() then
    if not spin_timer then
      spin_timer = uv.new_timer()
      spin_timer:start(
        0,
        config.spinner_interval,
        vim.schedule_wrap(function()
          frame = (frame % #frames) + 1
          pcall(vim.cmd, "redrawstatus")
        end)
      )
    end
  elseif spin_timer then
    spin_timer:stop()
    spin_timer:close()
    spin_timer = nil
  end
  pcall(vim.cmd, "redrawstatus")
end

-- ── 每个 chat 的 toast(nvim-notify) ─────────────────────────────────────────

-- 取某 chat 缓冲区的可读标签: 优先用我们派生的标题(见 codecompanion.lua 的 title autocmd),
-- 否则退回 "CC #<bufnr>"。多 chat 并行时用它区分是哪一路。
local function chat_label(bufnr)
  local ok, chat_mod = pcall(require, "codecompanion.interactions.chat")
  if ok and bufnr then
    local chat = chat_mod.buf_get_chat(bufnr)
    if chat then
      local title = (chat.opts and chat.opts.title) or chat.title
      if type(title) == "string" and title ~= "" then
        return title
      end
    end
  end
  return "CC #" .. tostring(bufnr)
end

-- 弹/更新某 chat 的 toast。用 replace 句柄原地更新: 同一个 chat 从"运行->等待授权->完成"
-- 复用一条通知, 不刷屏; 不同 chat 各占一条(按 bufnr 分句柄)。
--   msg    显示文案
--   level  vim.log.levels.*
--   title  toast 标题(用 chat 标签)
--   timeout number|false; false=常驻(授权待办), 数字=自动消失(ms)
local function toast(bufnr, msg, level, title, timeout)
  if not config.notify.enabled or not bufnr then
    return
  end
  local opts = {
    title = title,
    timeout = timeout,
    replace = notif[bufnr], -- 有旧句柄就原地替换
    hide_from_history = false,
  }
  local ok, rec = pcall(vim.notify, msg, level, opts)
  if ok then
    notif[bufnr] = rec -- 记住句柄, 供下次 replace
  end
end

-- 丢弃某 chat 的 toast 句柄(不主动关闭, 让它按自身 timeout 淡出)。
local function drop_toast(bufnr)
  if bufnr then
    notif[bufnr] = nil
  end
end

-- ── lualine 接口 ────────────────────────────────────────────────────────────

-- lualine cond= 使用: 无活跃 chat 时不占位
function M.active()
  return M.aggregate() ~= nil
end

-- 状态栏文本组件
function M.component()
  local state, name = M.aggregate()
  if not state then
    return ""
  end
  if state == "approving" then
    local suffix = name and (" " .. name) or ""
    return string.format("%s CC approve%s", config.icons.approving, suffix)
  end
  -- working: braille spinner + 标签
  return string.format("%s CC", frames[frame])
end

-- 供 lualine color= 使用; 配合 light 主题, 复用 remote_dev_sync 的配色风格
function M.highlight()
  local state = M.aggregate()
  if state == "approving" then
    return { fg = "#b02020" } -- 红: 需要人介入
  elseif state == "working" then
    return { fg = "#a06000" } -- 黄/琥珀: 运行中
  end
  return nil
end

-- ── 事件接线 ────────────────────────────────────────────────────────────────

local function set_state(bufnr, state, name)
  if not bufnr then
    return
  end
  local c = M.chats[bufnr] or {}
  c.state = state
  if name ~= nil then
    c.name = name
  end
  M.chats[bufnr] = c
  ensure_timer()
end

local function clear(bufnr)
  if not bufnr then
    return
  end
  M.chats[bufnr] = nil
  ensure_timer()
end

function M.setup(opts)
  config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})

  group = vim.api.nvim_create_augroup("CodeCompanionStatus", { clear = true })

  -- 注册一个 User 事件监听(pattern 为完整的 "CodeCompanion<Event>")
  local function on(event, cb)
    vim.api.nvim_create_autocmd("User", {
      group = group,
      pattern = "CodeCompanion" .. event,
      callback = cb,
    })
  end

  -- 提交 / 工具启动 / compaction 都算"运行中"
  for _, e in ipairs({ "ChatSubmitted", "ToolsStarted", "ChatCompacting" }) do
    on(e, function(ev)
      set_state(ev.data and ev.data.bufnr, "working")
    end)
  end

  -- 需要授权: 记下工具名, 转 approving, 弹右上角常驻 toast(WARN, 直到授权结束)
  on("ToolApprovalRequested", function(ev)
    local bufnr = ev.data and ev.data.bufnr
    local name = ev.data and ev.data.name
    set_state(bufnr, "approving", name)
    toast(
      bufnr,
      "⚠ 需要授权: " .. (name or "unknown") .. "\n切到该 chat 用内置 accept/reject",
      vim.log.levels.WARN,
      chat_label(bufnr),
      config.notify.approve_timeout
    )
  end)

  -- 授权结束: 回到 working; 用一条短暂 toast 顶掉常驻的授权提醒(区分 accept/reject)
  on("ToolApprovalFinished", function(ev)
    local bufnr = ev.data and ev.data.bufnr
    set_state(bufnr, "working")
    local choice = ev.data and ev.data.choice
    toast(
      bufnr,
      "授权: " .. (choice or "done"),
      vim.log.levels.INFO,
      chat_label(bufnr),
      config.notify.done_timeout
    )
  end)

  -- chat 完成: 弹完成 toast(INFO), 删除状态并丢弃句柄
  on("ChatDone", function(ev)
    local bufnr = ev.data and ev.data.bufnr
    toast(bufnr, "✓ 完成", vim.log.levels.INFO, chat_label(bufnr), config.notify.done_timeout)
    clear(bufnr)
    drop_toast(bufnr)
  end)

  -- chat 停止/关闭: 删除状态并丢弃句柄(停止时给一条提示, 关闭则静默)
  on("ChatStopped", function(ev)
    local bufnr = ev.data and ev.data.bufnr
    toast(bufnr, "⏹ 已停止", vim.log.levels.INFO, chat_label(bufnr), config.notify.done_timeout)
    clear(bufnr)
    drop_toast(bufnr)
  end)
  on("ChatClosed", function(ev)
    local bufnr = ev.data and ev.data.bufnr
    clear(bufnr)
    drop_toast(bufnr)
  end)

  -- 退出前收拾定时器
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      if spin_timer then
        spin_timer:stop()
        spin_timer:close()
        spin_timer = nil
      end
    end,
  })
end

return M
