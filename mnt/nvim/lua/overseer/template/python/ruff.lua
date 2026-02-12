---@type overseer.TemplateDefinition
return {
  name = "🎭ruff",
  builder = function()
    return {
      name = "ruff",
      strategy = {
        "orchestrator",
        tasks = {
          { "ruff format", "ruff check" },
        },
      },
      components = {
        { "open_output", on_start = "never" },
        { "on_complete_notify", on_change = true, statuses = {} },
        {
          "on_children_status_sync",
          task_names = { "ruff format", "ruff check" },
        },
        {
          "on_complete_trouble_close_if_clean",
          task_names = { "ruff format", "ruff check" },
        },
        "default",
      },
    }
  end,
}
