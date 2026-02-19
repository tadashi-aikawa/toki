---@type overseer.TemplateDefinition
local util = require("overseer.template.util")
local test_parser = require("overseer.template.test_parser")

return {
  name = "▶︎mise test django unittest onetime",
  builder = function()
    return {
      name = "mise test django unittest onetime",
      cmd = { "mise" },
      args = { "test" },
      components = {
        { "restart_on_save" },
        { "on_complete_notify", on_change = true },
        { "on_output_parse", parser = test_parser.create_unittest_parser() },
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
