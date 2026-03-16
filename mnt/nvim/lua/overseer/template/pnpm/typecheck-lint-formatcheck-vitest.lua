---@type overseer.TemplateDefinition
return {
  name = "🎭pnpm typecheck/lint(oxlint)/formatcheck(prettier)/vitest",
  builder = function()
    return {
      name = "pnpm typecheck/lint(oxlint)/formatcheck(prettier)/vitest",
      strategy = {
        "orchestrator",
        tasks = {
          {
            "pnpm typecheck",
            "pnpm lint oxlint",
            "pnpm formatcheck prettier",
            "pnpm test vitest",
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
            "oxlint",
            "prettier",
            "vitest",
          },
        },
        "default",
      },
    }
  end,
}
