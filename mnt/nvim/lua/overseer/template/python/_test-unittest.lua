---@type overseer.TemplateDefinition
local util = require("overseer.template.util")
local test_parser = require("overseer.template.test_parser")

return {
  name = "python unittest",
  builder = function()
    return {
      name = "python unittest",
      cmd = { "python" },
      args = { "-m", "unittest", "discover", "-v" },
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
