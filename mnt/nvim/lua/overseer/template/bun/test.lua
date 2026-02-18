---@type overseer.TemplateDefinition
return {
  name = "🎭bun test",
  builder = function()
    return {
      name = "bun test",
      strategy = {
        "orchestrator",
        tasks = {
          { "bun test" },
        },
      },
      components = {
        { "open_output", on_start = "never" },
        { "on_complete_notify", on_change = true, statuses = {} },
        {
          "on_children_status_sync",
          task_names = { "bun test" },
        },
        "default",
      },
    }
  end,
}
