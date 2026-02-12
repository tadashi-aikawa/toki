---@type overseer.TemplateDefinition
local util = require("overseer.template.util")

return {
  name = "bun test",
  builder = function()
    local watch_paths = util.resolve_watch_paths({ "src", "test", "tests" })
    local function create_parser()
      local pending_error = nil
      local pending_details = {}

      return function(line)
        local err = line:match("^error:%s*(.+)$")
        if err then
          pending_error = err
          pending_details = {}
          return
        end

        if pending_error then
          local detail = line:match("^(Expected:.+)$") or line:match("^(Received:.+)$")
          if detail then
            table.insert(pending_details, detail)
            return
          end
        end

        local path, lnum, col = line:match("%((.+):(%d+):(%d+)%)")
        if path and lnum and col then
          local msg = pending_error or "Test failed"
          if #pending_details > 0 then
            msg = msg .. " | " .. table.concat(pending_details, " ")
          end
          pending_error = nil
          pending_details = {}
          return {
            filename = path,
            lnum = tonumber(lnum),
            col = tonumber(col),
            text = msg,
            type = "E",
          }
        end
      end
    end

    return {
      name = "bun test",
      cmd = { "bun" },
      args = { "test" },
      components = {
        { "restart_on_save", paths = watch_paths },
        { "on_complete_notify", on_change = true },
        { "on_output_parse", parser = create_parser() },
        { "on_result_diagnostics_quickfix_no_eventignore", open = true, close = true },
        "default",
      },
    }
  end,
}
