---@type overseer.TemplateDefinition
local util = require("overseer.template.util")
local template_problem_matcher = require("overseer.template.problem_matcher")

return {
  name = "bun check",
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
      name = "biome check",
      cmd = { "bun" },
      args = { "check" },
      components = {
        { "restart_on_save", paths = watch_paths },
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
