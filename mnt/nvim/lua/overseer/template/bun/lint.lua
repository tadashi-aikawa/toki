---@type overseer.TemplateDefinition
local util = require("overseer.template.util")

return {
  name = "bun lint",
  builder = function()
    local watch_paths = util.resolve_watch_paths({
      "src",
      "test",
      "tests",
      "config",
      "configs",
      "json",
    })
    local function create_parser()
      local pending = nil

      return function(line)
        if line:match("^%$%s") then
          return
        end

        local filename, lnum, col = line:match("^(.+):(%d+):(%d+)%s+")
        if filename and lnum and col then
          pending = {
            filename = filename,
            lnum = tonumber(lnum),
            col = tonumber(col),
          }
          return
        end

        local msg = line:match("^%s*✖%s+(.+)$")
        if msg and pending then
          local item = {
            filename = pending.filename,
            lnum = pending.lnum,
            col = pending.col,
            text = msg,
            type = "E",
          }
          pending = nil
          return item
        end
      end
    end

    return {
      name = "bun lint",
      cmd = { "bun" },
      args = { "lint" },
      components = {
        { "restart_on_save", paths = watch_paths },
        { "on_complete_notify", on_change = true },
        { "on_output_parse", parser = create_parser() },
        "on_result_diagnostics",
        { "on_result_diagnostics_trouble", args = { "focus=false" } },
        "default",
      },
    }
  end,
}
