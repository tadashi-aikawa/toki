---@type overseer.TemplateDefinition
return {
  name = "🎭pnpm typecheck/test(vitest)/formatcheck(prettier)",
  builder = function()
    return {
      name = "pnpm typecheck/test(vitest)/formatcheck(prettier)",
      strategy = {
        "orchestrator",
        tasks = {
          {
            "pnpm test vitest",
            "pnpm typecheck",
            "pnpm formatcheck prettier",
          },
        },
      },
      components = {
        { "open_output", on_start = "never" },
        { "on_complete_notify", on_change = true, statuses = {} },
        {
          "on_children_status_sync",
          task_names = {
            "vitest",
            "tsc?",
            "prettier",
          },
        },
        {
          "on_complete_trouble_close_if_clean",
          task_names = {
            "vitest",
            "tsc?",
            "prettier",
          },
        },
        "default",
      },
    }
  end,
}
