---@type overseer.TemplateDefinition
local util = require("overseer.template.util")

return {
  name = "pnpm formatcheck",
  builder = function()
    local watch_paths = util.resolve_watch_paths({ "app" })
    return {
      name = "pnpm formatcheck",
      cmd = { "pnpm" },
      args = { "formatcheck" },
      components = {
        { "restart_on_save", paths = watch_paths },
        { "on_complete_notify", on_change = true },
        -- TODO: 追加したい
        -- { "on_output_parse", problem_matcher = "$tsc" },
        -- "on_result_diagnostics",
        -- { "on_result_diagnostics_trouble", args = { "focus=false" } },
        "default",
      },
    }
  end,
}
