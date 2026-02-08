---@type overseer.TemplateDefinition
return {
  name = "🦉bun lint",
  builder = function()
    return {
      cmd = { "bun" },
      args = { "lint" },
      components = {
        { "on_complete_notify", on_change = true },
        "on_result_diagnostics_trouble",
        "default",
      },
    }
  end,
}
