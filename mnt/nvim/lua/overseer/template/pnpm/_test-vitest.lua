---@type overseer.TemplateDefinition
local util = require("overseer.template.util")
local test_parser = require("overseer.template.test_parser")

return {
  name = "pnpm test vitest",
  builder = function()
    local watch_paths = util.resolve_watch_paths({ "app" })
    return {
      name = "pnpm test vitest",
      cmd = { "pnpm" },
      args = { "test", "--", "--reporter=basic", "--no-color" },
      components = {
        { "restart_on_save", paths = watch_paths },
        { "on_complete_notify", on_change = true },
        { "on_output_parse", parser = test_parser.create_vitest_parser() },
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
