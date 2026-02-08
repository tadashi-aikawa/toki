---@type overseer.TemplateDefinition
return {
  name = "🦉bun typecheck/lint/test",
  builder = function()
    return {
      name = "bun typecheck/lint/test",
      strategy = {
        "orchestrator",
        tasks = {
          { "🦉bun typecheck", "🦉bun lint", "🦉bun test" },
        },
      },
      components = {
        "restart_on_save",
        { "open_output", on_start = "never" },
        { "on_complete_notify", on_change = true, statuses = {} },
        "default",
      },
    }
  end,
}
