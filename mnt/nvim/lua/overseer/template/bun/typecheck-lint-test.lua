---@type overseer.TemplateDefinition
return {
  name = "🎭bun typecheck/lint/test",
  builder = function()
    return {
      name = "bun typecheck/lint/test",
      strategy = {
        "orchestrator",
        tasks = {
          { "bun typecheck", "bun lint", "bun test" },
        },
      },
      components = {
        { "open_output", on_start = "never" },
        { "on_complete_notify", on_change = true, statuses = {} },
        {
          "on_children_status_sync",
          task_names = { "bun typecheck", "bun lint", "bun test" },
        },
        {
          "on_complete_trouble_close_if_clean",
          task_names = { "bun test", "bun lint", "bun typecheck" },
        },
        "default",
      },
    }
  end,
}
