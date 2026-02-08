---@type overseer.TemplateDefinition
return {
  name = "🦉bun test",
  builder = function()
    return {
      cmd = { "bun" },
      args = { "test" },
      components = {
        { "on_complete_notify", on_change = true },
        "on_result_diagnostics_trouble",
        "default",
      },
    }
  end,
}
