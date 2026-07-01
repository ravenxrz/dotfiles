local M = {
  root = nil,
  files = {},
  expanded = {},
  rejected_log = {},
  filter = "all",
  sidebar_win = nil,
  sidebar_buf = nil,
  source_win = nil,
  line_map = {},
}

function M.reset_for_root(root)
  if M.root ~= root then
    M.root = root
    M.files = {}
    M.expanded = {}
    M.rejected_log = {}
    M.filter = "all"
    M.line_map = {}
  end
end

local function patch_signature(hunk)
  return table.concat(hunk and hunk.patch or {}, "\n")
end

function M.mark_hunk_status(hunk, status)
  if not hunk or not status then
    return
  end
  hunk.status = status
  if status == "accepted" then
    hunk.id = hunk.file .. ":accepted:" .. tostring(vim.loop.hrtime())
  elseif status == "rejected" then
    hunk.id = hunk.file .. ":rejected:" .. tostring(vim.loop.hrtime())
    hunk.patch_signature = patch_signature(hunk)
  end
end

function M.add_rejected(hunk)
  if not hunk then
    return
  end
  local copy = vim.deepcopy(hunk)
  copy.status = "rejected"
  copy.id = copy.file .. ":rejected:" .. tostring(vim.loop.hrtime())
  copy.patch_signature = patch_signature(copy)
  table.insert(M.rejected_log, 1, copy)
end

function M.remove_rejected(hunk)
  if not hunk then
    return
  end
  local sig = hunk.patch_signature or patch_signature(hunk)
  for i = #M.rejected_log, 1, -1 do
    local item = M.rejected_log[i]
    if item.id == hunk.id or (item.file == hunk.file and (item.patch_signature or patch_signature(item)) == sig) then
      table.remove(M.rejected_log, i)
      return
    end
  end
end

function M.rejected_files()
  local pending_signatures = {}
  for _, file in ipairs(M.files or {}) do
    for _, hunk in ipairs(file.pending or {}) do
      pending_signatures[patch_signature(hunk)] = true
    end
  end

  local by_path = {}
  local files = {}
  for _, hunk in ipairs(M.rejected_log) do
    local sig = hunk.patch_signature or patch_signature(hunk)
    if not pending_signatures[sig] then
      if not by_path[hunk.file] then
        by_path[hunk.file] = {
          path = hunk.file,
          status = "modified",
          added = 0,
          deleted = 0,
          pending = {},
          accepted = {},
          rejected = {},
        }
        table.insert(files, by_path[hunk.file])
      end
      table.insert(by_path[hunk.file].rejected, hunk)
    end
  end
  return files
end

function M.counts()
  local files, pending, accepted, rejected = 0, 0, 0, 0
  for _, file in ipairs(M.files or {}) do
    files = files + 1
    pending = pending + #file.pending
    accepted = accepted + #file.accepted
    rejected = rejected + #file.rejected
  end
  return files, pending, accepted, rejected
end

return M
