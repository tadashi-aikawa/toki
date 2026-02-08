local M = {}

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
