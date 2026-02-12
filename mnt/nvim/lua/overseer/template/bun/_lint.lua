---@type overseer.TemplateDefinition
local util = require("overseer.template.util")
local problem_matcher = require("overseer.vscode.problem_matcher")

problem_matcher.register_problem_matcher("$bun-lint", {
  fileLocation = { "relative", "${cwd}" },
  severity = "error",
  pattern = {
    {
      vim_regexp = "\\v^(.+):(\\d+):(\\d+)\\s+",
      file = 1,
      line = 2,
      column = 3,
    },
    {
      vim_regexp = "\\v^\\s*✖\\s+(.+)$",
      message = 1,
    },
  },
})

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
      name = "bun lint",
      cmd = { "bun" },
      args = { "lint" },
      components = {
        { "restart_on_save", paths = watch_paths },
        { "on_complete_notify", on_change = true },
        { "on_output_parse", problem_matcher = "$bun-lint" },
        { "on_result_diagnostics_quickfix_no_eventignore", open = true, close = true },
        "default",
      },
    }
  end,
}
