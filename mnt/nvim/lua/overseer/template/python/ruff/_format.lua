---@type overseer.TemplateDefinition
local util = require("overseer.template.util")
require("overseer.template.problem_matcher")

return {
  name = "ruff format",
  builder = function()
    return {
      name = "ruff format",
      cmd = { "ruff" },
      args = { "format", "--check", "--output-format", "concise" },
      components = {
        { "restart_on_save" },
        { "on_complete_notify", on_change = true },
        { "on_output_parse", problem_matcher = "$ruff-format" },
        { "on_result_diagnostics_quickfix_no_eventignore", open = true, close = true },
        "default",
      },
    }
  end,
}
