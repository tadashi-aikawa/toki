---@type overseer.TemplateDefinition
local util = require("overseer.template.util")
local template_problem_matcher = require("overseer.template.problem_matcher")

return {
  name = "pnpm formatcheck prettier",
  builder = function()
    local watch_paths = util.resolve_watch_paths({ "app" })
    return {
      name = "pnpm formatcheck prettier",
      cmd = { "pnpm" },
      args = { "formatcheck" },
      components = {
        { "restart_on_save", paths = watch_paths },
        { "on_complete_notify", on_change = true },
        { "on_output_parse", parser = template_problem_matcher.prettier_check_parser },
        { "on_result_diagnostics_quickfix_no_eventignore", open = true, close = true },
        "default",
      },
    }
  end,
}
