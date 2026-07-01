local M = {}

local links = {
  AiReviewTitle = "Title",
  AiReviewRoot = "Directory",
  AiReviewSeparator = "Comment",
  AiReviewFile = "Directory",
  AiReviewStats = "Comment",
  AiReviewHelp = "Comment",
  AiReviewPending = "DiagnosticWarn",
  AiReviewAccepted = "DiffAdd",
  AiReviewRejected = "DiffDelete",
  AiReviewMuted = "Comment",
  AiReviewLineNr = "LineNr",
  AiReviewDiffFooter = "Comment",
  AiReviewDiffCurrentLabel = "DiffAdd",
  AiReviewDiffOriginalLabel = "DiffDelete",
  AiReviewDiffSeparator = "Comment",
  AiReviewDiffEndLabel = "DiffText",
  AiReviewDiffHeader = "Title",
}

local function set_link(group, target)
  vim.api.nvim_set_hl(0, group, { link = target, default = true })
end

local function set_soft_diff_highlights()
  if vim.o.background == "dark" then
    vim.api.nvim_set_hl(0, "AiReviewDiffOriginal", { bg = "#4a2c2f", default = true })
    vim.api.nvim_set_hl(0, "AiReviewDiffCurrent", { bg = "#2d432d", default = true })
  else
    vim.api.nvim_set_hl(0, "AiReviewDiffOriginal", { bg = "#ffd6d6", default = true })
    vim.api.nvim_set_hl(0, "AiReviewDiffCurrent", { bg = "#d6efd6", default = true })
  end
end

function M.setup()
  for group, target in pairs(links) do
    set_link(group, target)
  end
  set_soft_diff_highlights()
end

return M
