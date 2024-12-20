---@class GhActionsConfig
local defaultConfig = {
  --- The browser executable path to open workflow runs/jobs in
  ---@type string|nil
  browser = nil,
  --- Interval to refresh in seconds
  refresh_interval = 10,
  --- How much workflow runs and jobs should be indented
  indent = 2,
  --- Allowed hosts to fetch data from, github.com is always allowed
  --- @type string[]
  allowed_hosts = {},
  ---@class GhActionsIcons
  icons = {
    workflow_dispatch = '⚡️',
    ---@class GhActionsIconsConclusion
    conclusion = {
      success = '✓',
      failure = 'X',
      startup_failure = 'X',
      cancelled = '⊘',
      skipped = '◌',
      action_required = '⚠',
    },
    ---@class GhActionsIconsStatus
    status = {
      unknown = '?',
      pending = '○',
      queued = '○',
      requested = '○',
      waiting = '○',
      in_progress = '●',
    },
  },
  ---@class GhActionsHighlights
  highlights = {
    GhActionsRunIconSuccess = { link = 'LspDiagnosticsVirtualTextHint' },
    GhActionsRunIconFailure = { link = 'LspDiagnosticsVirtualTextError' },
    GhActionsRunIconStartup_failure = {
      link = 'LspDiagnosticsVirtualTextError',
    },
    GhActionsRunIconPending = { link = 'LspDiagnosticsVirtualTextWarning' },
    GhActionsRunIconRequested = { link = 'LspDiagnosticsVirtualTextWarning' },
    GhActionsRunIconWaiting = { link = 'LspDiagnosticsVirtualTextWarning' },
    GhActionsRunIconIn_progress = { link = 'LspDiagnosticsVirtualTextWarning' },
    GhActionsRunIconCancelled = { link = 'Comment' },
    GhActionsRunIconSkipped = { link = 'Comment' },
    GhActionsRunCancelled = { link = 'Comment' },
    GhActionsRunSkipped = { link = 'Comment' },
    GhActionsJobCancelled = { link = 'Comment' },
    GhActionsJobSkipped = { link = 'Comment' },
    GhActionsStepCancelled = { link = 'Comment' },
    GhActionsStepSkipped = { link = 'Comment' },
  },
  split = {
    relative = 'editor',
    position = 'right',
    size = 60,
    win_options = {
      wrap = false,
      number = false,
      foldlevel = nil,
      foldcolumn = '0',
      cursorcolumn = false,
      signcolumn = 'no',
    },
  },
}

local M = {
  options = defaultConfig,
}

---@param opts? GhActionsConfig
function M.setup(opts)
  opts = opts or {}

  M.options = vim.tbl_deep_extend('force', defaultConfig, opts)
  M.options.allowed_hosts = M.options.allowed_hosts or {}
  table.insert(M.options.allowed_hosts, 'github.com')
end

return M
