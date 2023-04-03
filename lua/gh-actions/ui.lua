local Split = require("nui.split")
local utils = require("gh-actions.utils")

local split = Split({
  position = "right",
  size = 60,
  win_options = {
    wrap = false,
    number = false,
    foldlevel = nil,
    foldcolumn = "0",
    cursorcolumn = false,
    signcolumn = "no",
  },
})

---@class GhActionsRenderLocation
---@field value any
---@field kind string
---@field from integer
---@field to integer

local M = {
  split = split,
  render_state = {
    repo = nil,
    workflows = {},
    workflow_runs = {},
  },
  -- TODO: While rendering, store row/line (start line,end line) and kind
  ---@type GhActionsRenderLocation[]
  locations = {},
  -- TODO: Maybe switch to codicons via nerdfont
  --       https://microsoft.github.io/vscode-codicons/dist/codicon.html
  --       https://www.nerdfonts.com/cheat-sheet
  icons = {
    conclusion = {
      success = "✓",
      failure = "X",
      cancelled = "⊘",
    },
    status = {
      unknown = "?",
      pending = "●",
      requested = "●",
      waiting = "●",
      in_progress = "●",
    },
  },
}

---@param run GhWorkflowRun
---@return string
local function get_workflow_run_icon(run)
  if not run then
    return M.icons.status.unknown
  end

  if run.status == "completed" then
    return M.icons.conclusion[run.conclusion] or run.conclusion
  end

  return M.icons.status[run.status] or M.icons.status.unknown
end

---@param runs GhWorkflowRun[]
---@return table<number, GhWorkflowRun[]>
local function group_by_workflow(runs)
  local m = {}

  for _, run in ipairs(runs) do
    m[run.workflow_id] = m[run.workflow_id] or {}
    table.insert(m[run.workflow_id], run)
  end

  return m
end

local function renderTitle()
  if not M.render_state.repo then
    return { "Github Workflows", "" }
  end

  return { string.format("Github Workflows for %s", M.render_state.repo), "" }
end

local function get_current_line(line)
  return line or vim.api.nvim_win_get_cursor(split.winid)[1]
end

---TODO: This should be a local function
---@param line? integer
---@return GhWorkflow|nil
function M.get_workflow(line)
  line = get_current_line(line)

  for _, loc in ipairs(M.locations) do
    if loc.kind == "workflow" and line >= loc.from and line <= loc.to then
      return loc.value
    end
  end
end

---TODO: This should be a local function
---@param line? integer
---@return GhWorkflowRun|nil
function M.get_workflow_run(line)
  line = get_current_line(line)

  for _, loc in ipairs(M.locations) do
    if loc.kind == "workflow_run" and line >= loc.from and line <= loc.to then
      return loc.value
    end
  end
end

---@class TextSegment
---@field str string
---@field hl string

---@alias Line TextSegment[]

---@param line Line
local function get_line_str(line)
  return table.concat(
    vim.tbl_map(function(segment)
      return segment.str
    end, line),
    ""
  )
end

---@param workflows GhWorkflow[]
---@param workflow_runs GhWorkflowRun[]
---@return table
local function renderWorkflows(workflows, workflow_runs)
  ---@type Line[]
  local lines = {}
  local workflow_runs_by_workflow_id = group_by_workflow(workflow_runs)
  local currentline = 2

  for _, workflow in ipairs(workflows) do
    currentline = currentline + 1
    local runs = workflow_runs_by_workflow_id[workflow.id] or {}
    local runs_n = math.min(5, #runs)

    table.insert(M.locations, {
      kind = "workflow",
      value = workflow,
      from = currentline,
      to = currentline + runs_n,
    })

    -- TODO Render ⚡️ or ✨ if workflow has workflow dispatch
    table.insert(lines, { { str = string.format("%s %s", get_workflow_run_icon(runs[1]), workflow.name) } })

    -- TODO cutting down on how many we list here, as we fetch 100 overall repo
    -- runs on opening the split. I guess we do want to have this configurable.
    for _, run in ipairs({ unpack(runs, 1, runs_n) }) do
      currentline = currentline + 1

      table.insert(M.locations, {
        kind = "workflow_run",
        value = run,
        from = currentline,
        to = currentline,
      })

      table.insert(lines, {
        {
          str = string.format("  %s %s", get_workflow_run_icon(run), run.head_commit.message:gsub("\n.*", "")),
        },
      })
    end

    if #runs > 0 then
      currentline = currentline + 1
      table.insert(lines, { { str = "" } })
    end
  end

  return lines
end

local function is_visible()
  return split.bufnr ~= nil and vim.bo[split.bufnr] ~= nil
end

function M.render()
  M.locations = {}

  if not is_visible() then
    return
  end

  vim.bo[split.bufnr].modifiable = true
  local lines = vim.tbl_flatten({
    renderTitle(),
    vim.tbl_map(get_line_str, renderWorkflows(M.render_state.workflows, M.render_state.workflow_runs)),
  })

  vim.api.nvim_buf_set_lines(split.bufnr, 0, -1, false, lines)
  vim.bo[split.bufnr].modifiable = false
end

M.render = utils.debounced(vim.schedule_wrap(M.render))

---@class GhActionsRenderState
---@field workflows GhWorkflow[]
---@field workflow_runs GhWorkflowRun[]

---@param fn fun(render_state: GhActionsRenderState): GhActionsRenderState|nil
function M.update_state(fn)
  M.render_state = fn(M.render_state) or M.render_state

  M.render()
end

---@class GhActionsRenderOptions
---@field icons? { conclusion?: table, status?: table }

---@param render_options? GhActionsRenderOptions
function M.setup(render_options)
  render_options = render_options or {}

  M.icons = vim.tbl_deep_extend("force", {}, M.icons, render_options.icons or {})
end

function M.open()
  split:mount()

  M.render()
end

function M.close()
  split:unmount()
end

return M
