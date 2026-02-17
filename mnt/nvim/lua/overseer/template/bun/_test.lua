---@type overseer.TemplateDefinition
local util = require("overseer.template.util")
local test_parser = require("overseer.template.test_parser")

return {
  name = "bun test",
  builder = function()
    local watch_paths = util.resolve_watch_paths({ "src", "test", "tests" })

    return {
      name = "bun test",
      cmd = { "bun" },
      args = { "run", "test" },
      components = {
        { "restart_on_save", paths = watch_paths },
        { "on_complete_notify", on_change = true },
        { "on_output_parse", parser = test_parser.create_bun_test_parser() },
        { "on_result_diagnostics_quickfix_no_eventignore", open = true, close = true },
        "default",
      },
    }
  end,
}
