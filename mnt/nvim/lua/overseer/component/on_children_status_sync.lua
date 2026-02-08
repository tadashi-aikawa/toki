local constants = require("overseer.constants")
local task_list = require("overseer.task_list")

local STATUS = constants.STATUS

local function list_children(parent_task)
  return task_list.list_tasks({
    include_ephemeral = true,
    filter = function(task)
      return task.parent_id == parent_task.id
    end,
  })
end

local function filter_children(children, task_names)
  if vim.tbl_isempty(task_names) then
    return children
  end

  local name_map = {}
  for _, name in ipairs(task_names) do
    name_map[name] = true
  end

  local ret = {}
  for _, child in ipairs(children) do
    if name_map[child.name] then
      table.insert(ret, child)
    end
  end

  return ret
end

local function aggregate_status(children)
  if vim.tbl_isempty(children) then
    return nil
  end

  local all_success = true
  local all_complete = true
  local any_canceled = false

  for _, child in ipairs(children) do
    if child.status == STATUS.FAILURE then
      return STATUS.FAILURE
    end
    if child.status ~= STATUS.SUCCESS then
      all_success = false
    end
    if child.status == STATUS.CANCELED then
      any_canceled = true
    elseif child.status == STATUS.RUNNING or child.status == STATUS.PENDING then
      all_complete = false
    end
  end

  if all_success then
    return STATUS.SUCCESS
  end
  if all_complete and any_canceled then
    return STATUS.CANCELED
  end

  return nil
end

local function update_status(task, new_status)
  if not new_status or task.status == new_status then
    return
  end

  task.status = new_status
  task:dispatch("on_status", task.status)
end

---@type overseer.ComponentFileDefinition
return {
  desc = "Sync orchestrator status from child task results",
  params = {
    task_names = {
      desc = "Only track these child task names",
      type = "list",
      subtype = { type = "string" },
      optional = true,
    },
  },
  constructor = function(params)
    local task_names = params.task_names or {}

    return {
      on_other_task_status = function(_, task, other_task)
        if task:is_disposed() then
          return
        end
        if not task.strategy or task.strategy.name ~= "orchestrator" then
          return
        end
        if not task:is_complete() then
          return
        end
        if other_task.parent_id ~= task.id then
          return
        end

        local children = list_children(task)
        local targets = filter_children(children, task_names)
        local new_status = aggregate_status(targets)
        update_status(task, new_status)
      end,
    }
  end,
}
