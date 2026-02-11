---@type overseer.TemplateDefinition
local util = require("overseer.template.util")

return {
  name = "pnpm typecheck-silent",
  builder = function()
    local watch_paths = util.resolve_watch_paths({ "app" })
    return {
      name = "pnpm typecheck-silent",
      cmd = { "pnpm" },
      args = { "typecheck" },
      components = {
        { "restart_on_save", paths = watch_paths },
        { "on_complete_notify", on_change = true },
        "default",
      },
    }
  end,
}
