---@type overseer.TemplateDefinition
return {
  name = "🎭pnpm test/typecheck/formatcheck",
  builder = function()
    return {
      name = "pnpm test/typecheck/formatcheck",
      strategy = {
        "orchestrator",
        tasks = {
          {
            "🦉pnpm test",
            "🦉pnpm typecheck-silent",
            "🦉pnpm formatcheck",
          },
        },
      },
      components = {
        { "open_output", on_start = "never" },
        { "on_complete_notify", on_change = true, statuses = {} },
        {
          "on_children_status_sync",
          task_names = {
            "pnpm test",
            "pnpm typecheck-silent",
            "pnpm formatcheck",
          },
        },
        {
          "on_complete_trouble_close_if_clean",
          task_names = {
            "pnpm test",
            "pnpm typecheck-silent",
            "pnpm formatcheck",
          },
        },
        "default",
      },
    }
  end,
}
