local config = require("ai_review.config")

local M = {}
local root_cache = {}

local function normalize(path)
  if not path or path == "" then
    return path
  end
  return vim.fn.fnamemodify(path, ":p"):gsub("/+$", "")
end

local function systemlist(cmd)
  local out = vim.fn.systemlist(cmd)
  local code = vim.v.shell_error
  return code, out
end

function M.find_root(start_path)
  local path = start_path
  if not path or path == "" then
    path = vim.api.nvim_buf_get_name(0)
  end
  if path == "" then
    path = vim.loop.cwd()
  end
  local dir = vim.fn.isdirectory(path) == 1 and path or vim.fn.fnamemodify(path, ":h")
  dir = normalize(dir)

  if config.options.git.root_cache and root_cache[dir] then
    return root_cache[dir]
  end

  local code, out = systemlist({ "git", "-C", dir, "rev-parse", "--show-toplevel" })
  if code ~= 0 or not out[1] or out[1] == "" then
    return nil, table.concat(out, "\n")
  end
  local root = normalize(out[1])
  if config.options.git.root_cache then
    root_cache[dir] = root
  end
  return root
end

function M.run(root, args)
  local cmd = { "git", "-C", root }
  vim.list_extend(cmd, args)
  local code, out = systemlist(cmd)
  return code, out
end

local function limited(out)
  local max_lines = config.options.git.max_diff_lines
  if max_lines and #out > max_lines then
    local trimmed = vim.list_slice(out, 1, max_lines)
    table.insert(trimmed, "")
    table.insert(trimmed, "[ai-review] diff truncated because it exceeded max_diff_lines")
    return trimmed
  end
  return out
end

function M.diff(root)
  local code, out = M.run(root, { "diff", "--unified=0", "--no-ext-diff", "--no-color" })
  return code, limited(out)
end

function M.cached_diff(root)
  local code, out = M.run(root, { "diff", "--cached", "--unified=0", "--no-ext-diff", "--no-color" })
  return code, limited(out)
end

function M.status(root)
  return M.run(root, { "status", "--porcelain=v1" })
end

function M.add_file(root, file)
  return M.run(root, { "add", "--", file })
end

function M.restore_file(root, file)
  return M.run(root, { "restore", "--", file })
end

function M.unstage_file(root, file)
  return M.run(root, { "restore", "--staged", "--", file })
end

local function quote_patch_path(path)
  -- Keep simple relative paths readable. Git accepts a/ and b/ prefixes here.
  return path
end

local function build_hunk_patch(hunk)
  if not hunk or not hunk.file or not hunk.patch or #hunk.patch == 0 then
    return nil, "empty hunk patch"
  end

  local file = quote_patch_path(hunk.file)
  local lines = {
    "diff --git a/" .. file .. " b/" .. file,
    "--- a/" .. file,
    "+++ b/" .. file,
  }
  vim.list_extend(lines, hunk.patch)

  local patch = table.concat(lines, "\n")
  if not patch:match("\n$") then
    patch = patch .. "\n"
  end
  return patch
end

local function apply_hunk_patch(root, hunk, opts)
  local patch, err = build_hunk_patch(hunk)
  if not patch then
    return 1, { err }
  end
  opts = opts or {}
  local cmd = { "git", "-C", root, "apply", "--unidiff-zero", "--whitespace=nowarn" }
  if opts.cached then
    table.insert(cmd, "--cached")
  end
  if opts.reverse then
    table.insert(cmd, "--reverse")
  end
  table.insert(cmd, "-")
  local out = vim.fn.systemlist(cmd, patch)
  return vim.v.shell_error, out
end

function M.apply_reverse_hunk(root, hunk)
  return apply_hunk_patch(root, hunk, { reverse = true })
end

function M.apply_hunk(root, hunk)
  return apply_hunk_patch(root, hunk, {})
end

function M.apply_hunk_to_index(root, hunk)
  return apply_hunk_patch(root, hunk, { cached = true })
end

function M.unapply_hunk_from_index(root, hunk)
  return apply_hunk_patch(root, hunk, { cached = true, reverse = true })
end

function M.delete_untracked(root, file)
  local full = root .. "/" .. file
  return vim.fn.delete(full)
end

return M
