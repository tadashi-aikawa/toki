---@type overseer.TemplateDefinition
local bun_util = require("overseer.template.bun.util")

return {
  name = "🦉bun typecheck",
  builder = function()
    local watch_paths = bun_util.resolve_watch_paths({ "src", "test", "tests" })
    return {
      name = "bun typecheck",
      cmd = { "bun" },
      args = { "typecheck" },
      components = {
        { "restart_on_save", paths = watch_paths },
        { "on_complete_notify", on_change = true },
        { "on_output_parse", problem_matcher = "$tsc" },
        "on_result_diagnostics",
        { "on_result_diagnostics_trouble", args = { "focus=false" } },
        "default",
      },
    }
  end,
}
