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
  line = line:gsub("\27%]8;;[^\7]*\7", "")
  line = line:gsub("\27%]8;;.-\27\\", "")
  return line:gsub("\27%[[0-9;?]*[%a]", "")
end

---@param message string
---@return string
local function normalize_biome_message(message)
  local cleaned = vim.trim(message)
  cleaned = cleaned:gsub("%s+━+$", "")
  cleaned = cleaned:gsub("%s+", " ")

  local code = cleaned:match("^([%a]+/[%w%-%._/]+)")
  if code then
    if cleaned:find("FIXABLE", 1, true) then
      return string.format("%s (FIXABLE)", code)
    end
    return code
  end

  return cleaned
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

--- Parser for `biome check` output.
--- Handles both lint and format headers.
---@param line string
---@return nil|vim.quickfix.entry
M.biome_check_parser = function(line)
  local normalized = vim.trim(strip_ansi(line):gsub("\r$", ""))
  if normalized == "" then
    return nil
  end

  local filename, lnum, col, message = normalized:match("^([^:]+):(%d+):(%d+)%s+(.+)$")
  if filename and lnum and col and message then
    return {
      filename = vim.trim(filename),
      lnum = tonumber(lnum),
      col = tonumber(col),
      text = normalize_biome_message(message),
    }
  end

  local format_file = normalized:match("^(.+)%s+format%s+━+")
  if format_file then
    return {
      filename = vim.trim(format_file),
      lnum = 1,
      col = 1,
      text = "format (would change)",
    }
  end

  return nil
end

--- Parser for `ruff format --check` output in stable mode.
--- Captures lines like: "Would reformat: path/to/file.py"
---@param line string
---@return nil|vim.quickfix.entry
M.ruff_format_check_parser = function(line)
  local normalized = vim.trim(strip_ansi(line):gsub("\r$", ""))
  if normalized == "" then
    return nil
  end

  local file = normalized:match("^Would reformat:%s+(.+)$")
  if not file then
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
    text = "format (would change)",
    type = "W",
  }
end

--- Parser for `ruff check --output-format concise` output.
--- Handles ANSI/OSC8-decorated lines by normalizing them first.
---@param line string
---@return nil|vim.quickfix.entry
M.ruff_check_parser = function(line)
  local normalized = vim.trim(strip_ansi(line):gsub("\r$", ""))
  if normalized == "" then
    return nil
  end

  local filename, lnum, col, code, message =
    normalized:match("^([^:]+):(%d+):(%d+):%s+([^: ]+)%s*(.*)$")
  if not filename or not lnum or not col or not code then
    return nil
  end

  filename = vim.trim(filename)
  if filename == "" then
    return nil
  end

  local text = vim.trim(string.format("%s %s", code, message or ""))
  if text == "" then
    text = code
  end

  return {
    filename = filename,
    lnum = tonumber(lnum),
    col = tonumber(col),
    text = text,
    type = "W",
  }
end

return M
