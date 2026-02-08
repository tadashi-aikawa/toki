---@type overseer.TemplateDefinition
return {
  name = "🦉bun typecheck",
  builder = function()
    return {
      cmd = { "bun" },
      args = { "typecheck" },
      components = {
        { "on_complete_notify", on_change = true },
        "on_result_diagnostics_trouble",
        "default",
      },
    }
  end,
}
