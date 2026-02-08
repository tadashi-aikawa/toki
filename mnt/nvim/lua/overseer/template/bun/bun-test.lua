---@type overseer.TemplateDefinition
return {
  name = "🎭bun test",
  builder = function()
    return {
      name = "bun test",
      strategy = {
        "orchestrator",
        tasks = {
          { "🦉bun test" },
        },
      },
      components = {
        "restart_on_save",
        { "open_output", on_start = "never" },
        { "on_complete_notify", on_change = true, statuses = {} },
        {
          "on_complete_trouble_close_if_clean",
          task_names = { "bun test" },
        },
        "default",
      },
    }
  end,
}
