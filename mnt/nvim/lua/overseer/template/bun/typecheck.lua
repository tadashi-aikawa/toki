---@type overseer.TemplateDefinition
return {
  name = "🎭bun typecheck",
  builder = function()
    return {
      name = "bun typecheck",
      strategy = {
        "orchestrator",
        tasks = {
          { "bun typecheck" },
        },
      },
      components = {
        { "open_output", on_start = "never" },
        { "on_complete_notify", on_change = true, statuses = {} },
        {
          "on_children_status_sync",
          task_names = { "tsc?" },
        },
        {
          "on_complete_trouble_close_if_clean",
          task_names = { "tsc?" },
        },
        "default",
      },
    }
  end,
}
