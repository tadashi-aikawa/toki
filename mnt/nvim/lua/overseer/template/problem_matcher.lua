local problem_matcher = require("overseer.vscode.problem_matcher")
local M = {}

problem_matcher.register_problem_matcher("$biome-lint", {
  fileLocation = { "relative", "${cwd}" },
  severity = "error",
  pattern = {
    {
      vim_regexp = "\\v^(.+):(\\d+):(\\d+)\\s+",
      file = 1,
      line = 2,
      column = 3,
    },
    {
      vim_regexp = "\\v^\\s*✖\\s+(.+)$",
      message = 1,
    },
  },
})

problem_matcher.register_problem_matcher("$ruff-check", {
  fileLocation = { "relative", "${cwd}" },
  severity = "warning",
  pattern = {
    vim_regexp = "\\v^(.*):(\\d+):(\\d+):\\s+([^: ]+)%(\\s+\\[[^\\]]+\\])?%(:|\\s)\\s*(.*)$",
    file = 1,
    line = 2,
    column = 3,
    code = 4,
    message = 5,
  },
})

problem_matcher.register_problem_matcher("$ruff-format", {
  fileLocation = { "relative", "${cwd}" },
  severity = "warning",
  pattern = {
    vim_regexp = "\\v^(.*):(\\d+):(\\d+):\\s+([^:]+):\\s+(.*)$",
    file = 1,
    line = 2,
    column = 3,
    code = 4,
    message = 5,
  },
})

--- Strip ANSI/terminal control sequences (e.g. ESC[33m, ESC[?25h).
---@param line string
---@return string
local function strip_ansi(line)
  return line:gsub("\27%[[0-9;?]*[%a]", "")
end

--- Parser for `prettier --check` output.
--- Returns quickfix entries with line/column so items are jumpable.
---@param line string
---@return nil|vim.quickfix.entry
M.prettier_check_parser = function(line)
  local normalized = vim.trim(strip_ansi(line):gsub("\r$", ""))
  local file = normalized:match("^%[warn%]%s+(.+)$")
  if not file then
    return nil
  end
  if file:match("^Code style issues found") then
    return nil
  end
  file = vim.trim(file)
  if file == "" then
    return nil
  end
  return {
    filename = file,
    lnum = 1,
    col = 1,
    text = file,
    type = "W",
  }
end

return M
