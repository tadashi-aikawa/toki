local M = {}

local task_list = require("overseer.task_list")

local state = {
  completed = {},
}

local function all_completed(task_names)
  for _, name in ipairs(task_names) do
    if not state.completed[name] then
      return false
    end
  end
  return true
end

local function has_task_diagnostics(task_names)
  for _, name in ipairs(task_names) do
    local ns = vim.api.nvim_create_namespace(name)
    local diags = vim.diagnostic.get(nil, { namespace = ns })
    if not vim.tbl_isempty(diags) then
      return true
    end
  end
  return false
end

local function list_child_tasks(parent_task)
  return task_list.list_tasks({
    include_ephemeral = true,
    filter = function(task)
      return task.parent_id == parent_task.id
    end,
  })
end

local function all_children_completed(children, task_names)
  local by_name = {}
  for _, child in ipairs(children) do
    by_name[child.name] = child
  end

  for _, name in ipairs(task_names) do
    local child = by_name[name]
    if not child or not child:is_complete() then
      return false
    end
  end
  return true
end

local function normalize_task_names(task_names, children)
  if not vim.tbl_isempty(task_names) then
    return task_names
  end

  local names = {}
  for _, child in ipairs(children) do
    table.insert(names, child.name)
  end
  return names
end

---@type overseer.ComponentFileDefinition
return {
  desc = "Close Trouble when all named tasks have completed and are clean",
  params = {
    task_names = {
      desc = "Task names that must complete before closing Trouble",
      type = "list",
      subtype = { type = "string" },
    },
  },
  constructor = function(params)
    local task_names = params.task_names or {}

    return {
      on_complete = function(_, task)
        if task.strategy and task.strategy.name == "orchestrator" then
          local children = list_child_tasks(task)
          local target_names = normalize_task_names(task_names, children)

          if vim.tbl_isempty(target_names) then
            return
          end

          if not all_children_completed(children, target_names) then
            return
          end

          if has_task_diagnostics(target_names) then
            return
          end

          vim.schedule(function()
            vim.cmd.Trouble({ args = { "diagnostics", "close" } })
          end)
          return
        end

        for _, name in ipairs(task_names) do
          if task.name == name then
            state.completed[name] = true
            break
          end
        end

        if vim.tbl_isempty(task_names) or not all_completed(task_names) then
          return
        end

        if has_task_diagnostics(task_names) then
          return
        end

        vim.schedule(function()
          vim.cmd.Trouble({ args = { "diagnostics", "close" } })
        end)
        state.completed = {}
      end,
    }
  end,
}
