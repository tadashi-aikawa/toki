---@type overseer.TemplateDefinition
local util = require("overseer.template.util")
local template_problem_matcher = require("overseer.template.problem_matcher")

return {
  name = "pnpm check",
  builder = function()
    return {
      name = "biome check",
      cmd = { "pnpm" },
      args = { "check" },
      components = {
        { "restart_on_save" },
        { "on_complete_notify", on_change = true },
        { "on_output_parse", parser = template_problem_matcher.biome_check_parser },
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
