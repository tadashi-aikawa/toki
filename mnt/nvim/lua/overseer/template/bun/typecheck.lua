---@type overseer.TemplateDefinition
return {
  name = "🦉bun typecheck",
  builder = function()
    return {
      name = "bun typecheck",
      cmd = { "bun" },
      args = { "typecheck" },
      components = {
        { "on_complete_notify", on_change = true },
        { "on_output_parse", problem_matcher = "$tsc" },
        "on_result_diagnostics",
        { "on_result_diagnostics_trouble", args = { "focus=false" } },
        {
          "on_complete_trouble_close_if_clean",
          task_names = { "bun test", "bun lint", "bun typecheck" },
        },
        "default",
      },
    }
  end,
}
