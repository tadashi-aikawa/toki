---@type overseer.TemplateDefinition
local util = require("overseer.template.util")
local problem_matcher = require("overseer.vscode.problem_matcher")

problem_matcher.register_problem_matcher("$ruff-check", {
  fileLocation = { "relative", "${cwd}" },
  severity = "warning",
  pattern = {
    vim_regexp = "\\v^(.*):(\\d+):(\\d+):\\s+([^: ]+)%(\\s+\\[[^\\]]+\\])?%(:|\\s)\\s*(.*)$",
    file = 1,
    line = 2,
    column = 3,
    code = 4,
    message = 5,
  },
})

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
