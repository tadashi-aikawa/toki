---@type overseer.TemplateDefinition
return {
  name = "🎭pnpm typecheck",
  builder = function()
    return {
      name = "pnpm typecheck",
      strategy = {
        "orchestrator",
        tasks = {
          { "pnpm typecheck" },
        },
      },
      components = {
        { "open_output", on_start = "never" },
        { "on_complete_notify", on_change = true, statuses = {} },
        {
          "on_children_status_sync",
          task_names = { "pnpm typecheck" },
        },
        {
          "on_complete_trouble_close_if_clean",
          task_names = { "pnpm typecheck" },
        },
        "default",
      },
    }
  end,
}
