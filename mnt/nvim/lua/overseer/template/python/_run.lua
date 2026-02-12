---@type overseer.TemplateDefinition
local util = require("overseer.template.util")

return {
  name = "python run",
  builder = function()
    return {
      name = "python run",
      cmd = { "python" },
      args = { "main.py" },
      components = {
        { "restart_on_save" },
        { "on_complete_notify", on_change = true },
        { "on_output_parse" },
        "on_result_diagnostics",
        { "on_result_diagnostics_trouble", args = { "focus=false" } },
        "default",
      },
    }
  end,
}
