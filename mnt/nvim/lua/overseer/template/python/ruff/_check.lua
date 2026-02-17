---@type overseer.TemplateDefinition
local util = require("overseer.template.util")
require("overseer.template.problem_matcher")

return {
  name = "ruff check",
  builder = function()
    return {
      name = "ruff check",
      cmd = { "ruff" },
      args = { "check", "--output-format", "concise" },
      components = {
        { "restart_on_save" },
        { "on_complete_notify", on_change = true },
        { "on_output_parse", problem_matcher = "$ruff-check" },
        { "on_result_diagnostics_quickfix_no_eventignore", open = true, close = true },
        "default",
      },
    }
  end,
}
