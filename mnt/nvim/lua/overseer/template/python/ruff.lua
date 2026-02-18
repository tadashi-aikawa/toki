---@type overseer.TemplateDefinition
return {
  name = "🎭ruff format/check",
  builder = function()
    return {
      name = "ruff format/check",
      strategy = {
        "orchestrator",
        tasks = {
          { "ruff format", "ruff check" },
        },
      },
      components = {
        { "open_output", on_start = "never" },
        { "on_complete_notify", on_change = true, statuses = {} },
        {
          "on_children_status_sync",
          task_names = { "ruff format", "ruff check" },
        },
        "default",
      },
    }
  end,
}
