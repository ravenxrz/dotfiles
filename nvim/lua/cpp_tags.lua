-- Incremental index maintenance for the ctags + gtags based navigation in
-- cpp_navigation.lua. Two indexes are kept fresh on save:
--   * gtags (GTAGS/GRTAGS/GPATH): `global --single-update <file>` is cheap and
--     supports add/update/delete of a single file, so it runs on every save.
--   * ctags (tags): Universal Ctags has no real incremental mode (`--append`
--     leaves stale symbols behind, verified locally), so a full rebuild is run
--     asynchronously, debounced, and single-flighted.
--
-- gtags note: `global --single-update` resolves its path relative to the
-- current working directory, not the GTAGS root, and macOS symlinks make
-- `global -pr` return a /private prefix that will not match the buffer path.
-- We sidestep both by running it from the file's own directory with just the
-- basename.
--
-- Requires: universal-ctags + GNU global (`brew install universal-ctags global`).

local M = {}

-- Full rebuild commands, matching the ones documented in cpp_navigation.lua.
local CTAGS_ARGS = {
  "ctags", "-R",
  "--languages=C,C++",
  "--exclude=.git",
  "--exclude=build",
  "--exclude=third_party",
  ".",
}

local GTAGS_FILELIST_CMD =
  [[rg --files -g '!build/**' -g '!**/build/**' -g '!third_party/**' -g '!**/third_party/**' | gtags -f -]]

-- Debounce + single-flight state for the ctags full rebuild, keyed by root.
local ctags_debounce_ms = 1000 * 10 -- default: 10min
local ctags_timers = {}   -- root -> uv_timer
local ctags_running = {}  -- root -> true while a rebuild is in flight

local function has_exe(name)
  return vim.fn.executable(name) == 1
end

-- Walk upward from `start_dir` looking for a marker; returns the directory
-- containing it, or nil.
local function find_upward(start_dir, markers)
  local found = vim.fs.find(markers, { path = start_dir, upward = true })[1]
  if not found then
    return nil
  end
  return vim.fn.fnamemodify(found, ":p:h")
end

-- Run `global --single-update` for a single saved file. Cheap; runs every save.
local function gtags_update_file(file)
  if not has_exe("global") then
    return
  end

  local dir = vim.fn.fnamemodify(file, ":p:h")
  local base = vim.fn.fnamemodify(file, ":t")
  if dir == "" or base == "" then
    return
  end

  -- global exits 3 with "GTAGS not found" when the project has no gtags index;
  -- treat that (and any error) as a silent no-op.
  vim.system({ "global", "--single-update", base }, { cwd = dir }, function() end)
end

-- Kick off (debounced) a full ctags rebuild for the project owning `file`.
local function ctags_rebuild_debounced(file)
  if not has_exe("ctags") then
    return
  end

  local dir = vim.fn.fnamemodify(file, ":p:h")
  -- Only maintain tags for projects that already have an index; do not create
  -- one implicitly on the first save in an unrelated tree.
  local root = find_upward(dir, { "tags" }) or find_upward(dir, { "GTAGS", ".git" })
  if not root or vim.fn.filereadable(root .. "/tags") ~= 1 then
    return
  end

  if ctags_timers[root] then
    ctags_timers[root]:stop()
    ctags_timers[root]:close()
    ctags_timers[root] = nil
  end

  local timer = (vim.uv or vim.loop).new_timer()
  ctags_timers[root] = timer
  timer:start(ctags_debounce_ms, 0, vim.schedule_wrap(function()
    timer:stop()
    timer:close()
    ctags_timers[root] = nil

    if ctags_running[root] then
      return
    end
    ctags_running[root] = true

    vim.system(CTAGS_ARGS, { cwd = root }, function()
      ctags_running[root] = nil
    end)
  end))
end

-- BufWritePost entry point for c/cpp buffers.
function M.on_save(bufnr)
  local file = vim.api.nvim_buf_get_name(bufnr)
  if file == "" or vim.fn.filereadable(file) ~= 1 then
    return
  end

  gtags_update_file(file)
  ctags_rebuild_debounced(file)
end

-- Manual full rebuild of both indexes for the project owning the current file.
-- Purges stale ctags entries that incremental updates cannot remove.
function M.rebuild_all()
  local file = vim.api.nvim_buf_get_name(0)
  local start_dir = file ~= "" and vim.fn.fnamemodify(file, ":p:h") or vim.fn.getcwd()
  local root = find_upward(start_dir, { "tags", "GTAGS", ".git" }) or vim.fn.getcwd()

  if has_exe("ctags") then
    vim.notify("[cpp_tags] rebuilding ctags in " .. root .. " ...", vim.log.levels.INFO)
    vim.system(CTAGS_ARGS, { cwd = root }, vim.schedule_wrap(function(res)
      local level = res.code == 0 and vim.log.levels.INFO or vim.log.levels.WARN
      vim.notify("[cpp_tags] ctags rebuild done (exit " .. res.code .. ")", level)
    end))
  end

  if has_exe("global") and has_exe("rg") then
    vim.notify("[cpp_tags] rebuilding gtags in " .. root .. " ...", vim.log.levels.INFO)
    vim.system({ "sh", "-c", GTAGS_FILELIST_CMD }, { cwd = root }, vim.schedule_wrap(function(res)
      local level = res.code == 0 and vim.log.levels.INFO or vim.log.levels.WARN
      vim.notify("[cpp_tags] gtags rebuild done (exit " .. res.code .. ")", level)
    end))
  end
end

return M
