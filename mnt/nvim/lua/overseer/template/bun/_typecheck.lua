---@type overseer.TemplateDefinition
local util = require("overseer.template.util")

return {
  name = "bun typecheck",
  builder = function()
    local watch_paths = util.resolve_watch_paths({ "src", "test", "tests" })
    return {
      name = "bun typecheck",
      cmd = { "bun" },
      args = { "typecheck" },
      components = {
        { "restart_on_save", paths = watch_paths },
        { "on_complete_notify", on_change = true },
        { "on_output_parse", problem_matcher = "$tsc" },
        { "on_result_diagnostics_quickfix", open = true, close = true },
        "default",
      },
    }
  end,
}
