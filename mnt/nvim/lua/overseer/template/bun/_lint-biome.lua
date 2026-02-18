---@type overseer.TemplateDefinition
local util = require("overseer.template.util")
require("overseer.template.problem_matcher")

return {
  name = "bun lint",
  builder = function()
    local watch_paths = util.resolve_watch_paths({
      "src",
      "test",
      "tests",
      "config",
      "configs",
      "json",
    })
    return {
      name = "biome lint",
      cmd = { "bun" },
      args = { "lint" },
      components = {
        { "restart_on_save", paths = watch_paths },
        { "on_complete_notify", on_change = true },
        { "on_output_parse", problem_matcher = "$biome-lint" },
        { "on_result_diagnostics_quickfix_no_eventignore", open = true, close = true },
        "default",
      },
    }
  end,
}
