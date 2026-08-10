-- remote_dev_sync.lua — 在状态栏近实时展示 remote-dev(Mutagen) 的同步状态
-- author: zhangxingrui
--
-- 痛点: 本地/远端改了文件, 不知道对端(远端 beta)是否已经同步。
-- 关键事实: 本地 mutagen daemon 同时掌握 alpha(本地) 与 beta(远端) 两端状态,
--           所以纯本地读取就能判断远端是否已追上——无需远端感知本地。
--
-- 数据源: `remote-dev porcelain [name]`(见 remote_dev/remote-dev), 每会话一行 TAB 分隔:
--           name  alpha_path  beta_host  status  conflicts  cycles  paused  beta_connected
--         带 name 时只查该会话, 很便宜。
--
-- 两档轮询(兼顾开销与手感):
--   1) 全局慢轮询: 低频(默认 15s)刷新*所有*会话, 负责兜底(远端->本地改动、其他会话)。
--   2) 当前文件快轮询: :w 保存后事件驱动, 只查*当前文件所属会话*(按 name), 以高频
--      (默认 400ms)突发轮询, 一旦确认落盘(或超时)立即停止。空闲时完全不快轮询。
--
-- 判定语义(写入感知 pending):
--   - :w 保存后, 记录该会话当前 cycles 作为 baseline 并标记 pending(显示"同步中"),
--     直到观察到 cycles 超过 baseline 且会话回到 Watching/0 冲突, 才转"已同步"。
--     这样能覆盖"刚存盘但还没传过去"的窗口, 而不是一看到空闲就误报已同步。
--
-- 用法: 在 init.lua 里 require("remote_dev_sync").setup({})
--       在 lualine 组件里调用 require("remote_dev_sync").component()/highlight()/has_session()

local M = {}

local uv = vim.uv or vim.loop

-- 按 alpha_path 建键的会话状态缓存
-- 每项: { name, alpha, beta_host, status, conflicts, cycles, paused, beta_connected }
M.sessions = {}

-- 按 alpha_path 记录"写入待确认"的 baseline cycles。
-- 存在该项 = 该会话有一次本地写入尚未确认落盘。
M.pending = {}

local defaults = {
  slow_interval = 15000, -- 全局慢轮询间隔(ms): 刷新所有会话
  fast_interval = 400, -- 当前文件快轮询间隔(ms): 保存后突发轮询单个会话
  fast_timeout = 30000, -- 快轮询最长持续(ms): 超时则放弃(交回慢轮询兜底)
  cmd = nil, -- 覆盖 remote-dev 可执行路径; nil 时自动探测
  icons = {
    synced = "✓",
    syncing = "⟳",
    conflict = "✗",
    paused = "⏸",
    disconnected = "⚠",
  },
}

local config = vim.deepcopy(defaults)
local slow_timer = nil
local inflight = { all = false, one = false }
local resolved_cmd = nil

-- 快轮询突发状态(单实例, 始终盯最近一次保存的会话)
local fast = { timer = nil, alpha = nil, name = nil, deadline = 0 }

-- 探测 remote-dev 可执行文件: 显式配置 > PATH > 常见 dotfiles 路径
local function resolve_cmd()
  if config.cmd and config.cmd ~= "" then
    return config.cmd
  end
  if resolved_cmd then
    return resolved_cmd
  end
  if vim.fn.executable("remote-dev") == 1 then
    resolved_cmd = "remote-dev"
    return resolved_cmd
  end
  local home = os.getenv("HOME") or ""
  local candidates = {
    home .. "/.dotfiles/remote_dev/remote-dev",
    home .. "/.config/dotfiles/remote_dev/remote-dev",
  }
  for _, path in ipairs(candidates) do
    if vim.fn.executable(path) == 1 then
      resolved_cmd = path
      return resolved_cmd
    end
  end
  return nil
end

-- Mutagen 模板里 Status 的空闲态。其余(Scanning/Reconciling/Staging...)都视为同步中。
local function is_idle(status)
  return status == "Watching" or status == "Watching for changes"
end

-- 解析 porcelain 输出为 { alpha_path -> session }
local function parse_lines(stdout)
  local map = {}
  for _, line in ipairs(vim.split(stdout or "", "\n", { trimempty = true })) do
    local f = vim.split(line, "\t", { plain = true })
    if #f >= 8 then
      local alpha = f[2]
      map[alpha] = {
        name = f[1],
        alpha = alpha,
        beta_host = f[3],
        status = f[4],
        conflicts = tonumber(f[5]) or 0,
        cycles = tonumber(f[6]) or 0,
        paused = f[7] == "true",
        beta_connected = f[8] == "true",
      }
    end
  end
  return map
end

-- 结算单个会话的写入待确认: 有冲突让位给冲突态; 否则等 cycles 超过 baseline 且回到空闲。
local function settle(alpha, s)
  local baseline = M.pending[alpha]
  if baseline == nil then
    return
  end
  if not s or s.conflicts > 0 then
    M.pending[alpha] = nil
  elseif is_idle(s.status) and s.cycles > baseline then
    M.pending[alpha] = nil
  end
end

-- 异步跑 `remote-dev porcelain [name]`, stdout 回调(已 vim.schedule)
local function run_porcelain(name, on_done)
  local cmd = resolve_cmd()
  if not cmd then
    return false
  end
  local args = { cmd, "porcelain" }
  if name and name ~= "" then
    table.insert(args, name)
  end

  if vim.system then
    vim.system(args, { text = true }, function(result)
      vim.schedule(function()
        on_done(result.stdout or "")
      end)
    end)
    return true
  end

  -- 老版本回退
  local out = {}
  vim.fn.jobstart(args, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      if data then
        vim.list_extend(out, data)
      end
    end,
    on_exit = function()
      vim.schedule(function()
        on_done(table.concat(out, "\n"))
      end)
    end,
  })
  return true
end

-- 全局慢轮询: 刷新所有会话(整表替换), 并结算所有 pending。
function M.poll_all()
  if inflight.all or not resolve_cmd() then
    return
  end
  inflight.all = true
  local started = run_porcelain(nil, function(stdout)
    inflight.all = false
    local fresh = parse_lines(stdout)
    M.sessions = fresh
    for alpha in pairs(M.pending) do
      settle(alpha, fresh[alpha])
    end
    pcall(vim.cmd, "redrawstatus")
  end)
  if not started then
    inflight.all = false
  end
end

-- 当前文件快轮询: 只查单个会话(按 name), 合并进缓存并结算该会话 pending。
function M.poll_one(name)
  if not name or name == "" then
    return
  end
  if inflight.one or not resolve_cmd() then
    return
  end
  inflight.one = true
  local started = run_porcelain(name, function(stdout)
    inflight.one = false
    local fresh = parse_lines(stdout)
    for alpha, s in pairs(fresh) do
      M.sessions[alpha] = s
      settle(alpha, s)
    end
    pcall(vim.cmd, "redrawstatus")
  end)
  if not started then
    inflight.one = false
  end
end

-- 向后兼容别名: 旧调用点(FocusGained/DirChanged/外部)默认走全局刷新。
M.poll = M.poll_all

local function stop_fast()
  if fast.timer then
    fast.timer:stop()
    fast.timer:close()
    fast.timer = nil
  end
  fast.alpha = nil
  fast.name = nil
  fast.deadline = 0
end

-- 对某会话启动/重定向快轮询突发: 标记 pending 并高频盯它, 直到落盘或超时。
local function start_fast(session)
  M.pending[session.alpha] = session.cycles -- 以写入前的 cycles 为 baseline
  fast.alpha = session.alpha
  fast.name = session.name
  fast.deadline = uv.now() + config.fast_timeout
  pcall(vim.cmd, "redrawstatus")

  if fast.timer then
    return -- 已在突发中: 上面已重定向 alpha/name 并续期 deadline
  end
  fast.timer = uv.new_timer()
  fast.timer:start(
    config.fast_interval,
    config.fast_interval,
    vim.schedule_wrap(function()
      if not fast.alpha then
        stop_fast()
        return
      end
      -- 结束条件: 已确认落盘(pending 清空) 或 超时放弃(交回慢轮询)
      if M.pending[fast.alpha] == nil or uv.now() > fast.deadline then
        M.pending[fast.alpha] = nil
        stop_fast()
        pcall(vim.cmd, "redrawstatus")
        return
      end
      M.poll_one(fast.name)
    end)
  )
end

-- 把当前 buffer 路径匹配到所属会话: alpha_path 是其前缀且最长者(支持嵌套 project)。
function M.current_session()
  local bufname = vim.api.nvim_buf_get_name(0)
  if bufname == "" then
    return nil
  end
  local path = vim.fs.normalize(bufname)
  local best, best_len = nil, -1
  for alpha, s in pairs(M.sessions) do
    local root = vim.fs.normalize(alpha)
    local root_slash = root:gsub("/+$", "") .. "/"
    if (path == root or path:sub(1, #root_slash) == root_slash) and #root > best_len then
      best, best_len = s, #root
    end
  end
  return best
end

-- lualine cond= 使用
function M.has_session()
  return M.current_session() ~= nil
end

-- 状态优先级: 暂停 > 远端断开 > 冲突 > 同步中/待确认 > 已同步
-- 返回 "state"; state ∈ paused/disconnected/conflict/syncing/synced
local function classify(s)
  if s.paused then
    return "paused"
  elseif not s.beta_connected then
    return "disconnected"
  elseif s.conflicts > 0 then
    return "conflict"
  elseif M.pending[s.alpha] ~= nil or not is_idle(s.status) then
    return "syncing"
  else
    return "synced"
  end
end

-- 状态栏文本组件; 无匹配会话返回空串(不占位)
function M.component()
  local s = M.current_session()
  if not s then
    return ""
  end
  local state = classify(s)
  local icon = config.icons[state] or ""
  local suffix = ""
  if state == "conflict" then
    suffix = " " .. tostring(s.conflicts)
  end
  return string.format("%s %s%s", icon, s.name, suffix)
end

-- 供 lualine color= 使用的高亮; 配合 light 主题
function M.highlight()
  local s = M.current_session()
  if not s then
    return nil
  end
  local state = classify(s)
  local colors = {
    synced = { fg = "#207520" }, -- 绿
    syncing = { fg = "#a06000" }, -- 黄/琥珀
    conflict = { fg = "#b02020" }, -- 红
    paused = { fg = "#808080" }, -- 灰
    disconnected = { fg = "#b02020" }, -- 红
  }
  return colors[state]
end

function M.setup(opts)
  config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
  resolved_cmd = nil

  -- 保存文件后: 对该文件所属会话立即启动快轮询突发(近实时反馈当前文件同步状态)。
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = vim.api.nvim_create_augroup("RemoteDevSyncWrite", { clear = true }),
    callback = function()
      local s = M.current_session()
      if s then
        start_fast(s)
      else
        -- 会话缓存可能还没建立: 先全局刷新一次, 再重试定位并起突发。
        M.poll_all()
        vim.defer_fn(function()
          local s2 = M.current_session()
          if s2 then
            start_fast(s2)
          end
        end, 300)
      end
    end,
  })

  -- 回到窗口/切目录时全局刷新(覆盖远端->本地方向的改动感知)
  vim.api.nvim_create_autocmd({ "FocusGained", "DirChanged" }, {
    group = vim.api.nvim_create_augroup("RemoteDevSyncRefresh", { clear = true }),
    callback = function()
      M.poll_all()
    end,
  })

  -- 全局慢轮询定时器
  if slow_timer then
    slow_timer:stop()
    slow_timer:close()
    slow_timer = nil
  end
  slow_timer = uv.new_timer()
  slow_timer:start(
    500,
    config.slow_interval,
    vim.schedule_wrap(function()
      M.poll_all()
    end)
  )
end

return M
