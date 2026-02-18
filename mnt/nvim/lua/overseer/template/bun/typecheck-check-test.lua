---@type overseer.TemplateDefinition
return {
  name = "🎭bun typecheck/check(biome)/test",
  builder = function()
    return {
      name = "bun typecheck/check(biome)/test",
      strategy = {
        "orchestrator",
        tasks = {
          { "bun typecheck", "bun check", "bun test" },
        },
      },
      components = {
        { "open_output", on_start = "never" },
        { "on_complete_notify", on_change = true, statuses = {} },
        {
          "on_children_status_sync",
          task_names = { "tsc?", "biome check", "bun test" },
        },
        {
          "on_complete_trouble_close_if_clean",
          task_names = { "bun test", "biome check", "tsc?" },
        },
        "default",
      },
    }
  end,
}
