---@type overseer.TemplateDefinition
local template_problem_matcher = require("overseer.template.problem_matcher")

return {
  name = "pnpm lint oxlint",
  builder = function()
    return {
      name = "oxlint",
      cmd = { "pnpm" },
      args = { "lint" },
      components = {
        { "restart_on_save" },
        { "on_complete_notify", on_change = true },
        { "on_output_parse", parser = template_problem_matcher.create_oxlint_lint_parser() },
        {
          "on_result_diagnostics_quickfix_no_eventignore",
          open = true,
          close = true,
          merge_by_task = true,
          show_task_name = true,
        },
        "default",
      },
    }
  end,
}
