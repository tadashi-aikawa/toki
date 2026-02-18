---@type overseer.TemplateDefinition
return {
  name = "🎭bun typecheck/formatcheck/vitest",
  builder = function()
    return {
      name = "bun typecheck/formatcheck/vitest",
      strategy = {
        "orchestrator",
        tasks = {
          { "bun typecheck", "bun formatcheck", "bun vitest" },
        },
      },
      components = {
        { "open_output", on_start = "never" },
        { "on_complete_notify", on_change = true, statuses = {} },
        {
          "on_children_status_sync",
          task_names = { "tsc?", "prettier", "vitest" },
        },
        {
          "on_complete_trouble_close_if_clean",
          task_names = { "tsc?", "prettier", "vitest" },
        },
        "default",
      },
    }
  end,
}
