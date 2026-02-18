---@type overseer.TemplateDefinition
return {
  name = "🎭pnpm typecheck/check(biome)",
  builder = function()
    return {
      name = "pnpm typecheck/check(biome)",
      strategy = {
        "orchestrator",
        tasks = {
          {
            "pnpm typecheck",
            "pnpm check",
          },
        },
      },
      components = {
        { "open_output", on_start = "never" },
        { "on_complete_notify", on_change = true, statuses = {} },
        {
          "on_children_status_sync",
          task_names = {
            "tsc?",
            "biome check",
          },
        },
        "default",
      },
    }
  end,
}
