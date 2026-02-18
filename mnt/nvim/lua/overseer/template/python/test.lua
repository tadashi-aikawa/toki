---@type overseer.TemplateDefinition
return {
  name = "🎭python test",
  builder = function()
    return {
      name = "python test",
      strategy = {
        "orchestrator",
        tasks = {
          { "python unittest" },
        },
      },
      components = {
        { "open_output", on_start = "never" },
        { "on_complete_notify", on_change = true, statuses = {} },
        {
          "on_children_status_sync",
          task_names = { "python unittest" },
        },
        "default",
      },
    }
  end,
}
