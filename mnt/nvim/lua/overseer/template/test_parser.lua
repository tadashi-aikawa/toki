local M = {}

---@param line string
---@return string
local function strip_ansi(line)
  return line:gsub("\27%[[0-9;?]*[%a]", "")
end

---@param line string
---@return string
local function normalize_line(line)
  return strip_ansi(line):gsub("\r$", "")
end

---@param path string
---@return boolean
local function is_probably_file_path(path)
  if path == "" then
    return false
  end
  if path:match("^node:") then
    return false
  end
  if path:match("^https?://") then
    return false
  end
  if path:find("/", 1, true) or path:find("\\", 1, true) then
    return true
  end
  if path:match("%.[%w_%-]+$") then
    return true
  end
  return false
end

---@param token string|nil
---@return string|nil, number|nil, number|nil
local function parse_location_token(token)
  if not token then
    return nil, nil, nil
  end
  token = vim.trim(token)
  token = token:gsub("^%((.+)%)$", "%1")
  local path, lnum, col = token:match("^(.+):(%d+):(%d+)$")
  if not path then
    return nil, nil, nil
  end
  path = vim.trim(path)
  path = path:gsub("^at%s+", "")
  path = path:gsub("^([^%w%./~\\]+)%s*", "")
  if not is_probably_file_path(path) then
    return nil, nil, nil
  end
  return path, tonumber(lnum), tonumber(col)
end

---@param line string
---@return string|nil, number|nil, number|nil
local function extract_location_from_bun_line(line)
  local normalized = normalize_line(line)
  local token = normalized:match("%(([^()]+:%d+:%d+)%)")
  return parse_location_token(token)
end

---@param line string
---@return string|nil, number|nil, number|nil
local function extract_location_from_vitest_line(line)
  local normalized = normalize_line(line)
  local candidates = {
    normalized:match("%(([^()]+:%d+:%d+)%)"),
    normalized:match("^%s*at%s+(.+:%d+:%d+)%s*$"),
    normalized:match("^%s*[^%w%s]+%s+(.+:%d+:%d+)%s*$"),
    normalized:match("^%s*(.+:%d+:%d+)%s*$"),
  }
  for _, token in pairs(candidates) do
    local path, lnum, col = parse_location_token(token)
    if path and lnum and col then
      return path, lnum, col
    end
  end
  return nil, nil, nil
end

---@return overseer.ParseFn
M.create_bun_test_parser = function()
  local pending_error = nil
  local pending_details = {}

  return function(line)
    local normalized = normalize_line(line)
    local err = normalized:match("^error:%s*(.+)$")
    if err then
      pending_error = err
      pending_details = {}
      return nil
    end

    if pending_error then
      local detail = normalized:match("^(Expected:.+)$") or normalized:match("^(Received:.+)$")
      if detail then
        table.insert(pending_details, detail)
        return nil
      end
    end

    local path, lnum, col = extract_location_from_bun_line(normalized)
    if path and lnum and col then
      local msg = pending_error or "Test failed"
      if #pending_details > 0 then
        msg = msg .. " | " .. table.concat(pending_details, " ")
      end
      pending_error = nil
      pending_details = {}
      return {
        filename = path,
        lnum = lnum,
        col = col,
        text = msg,
        type = "E",
      }
    end

    return nil
  end
end

---@return overseer.ParseFn
M.create_vitest_parser = function()
  local pending_error = nil
  local pending_details = {}
  local pending_fail_context = nil

  return function(line)
    local normalized = normalize_line(line)
    if vim.trim(normalized) == "" then
      return nil
    end

    local fail_context = normalized:match("^%s*FAIL%s+(.+)$")
    if fail_context then
      pending_fail_context = vim.trim(fail_context)
      pending_error = nil
      pending_details = {}
      return nil
    end

    local err_kind, err_msg = normalized:match("^%s*([%w_.]+Error):%s*(.+)$")
    if err_kind and err_msg then
      pending_error = err_kind .. ": " .. err_msg
      return nil
    end
    local generic_error = normalized:match("^%s*Error:%s*(.+)$")
    if generic_error then
      pending_error = "Error: " .. generic_error
      return nil
    end

    local expected = normalized:match("^%s*Expected:%s*(.+)$")
    if expected then
      table.insert(pending_details, "Expected: " .. expected)
      return nil
    end
    local received = normalized:match("^%s*Received:%s*(.+)$")
    if received then
      table.insert(pending_details, "Received: " .. received)
      return nil
    end

    local path, lnum, col = extract_location_from_vitest_line(normalized)
    if path and lnum and col then
      local msg = pending_error or pending_fail_context or "Vitest failed"
      if #pending_details > 0 then
        msg = msg .. " | " .. table.concat(pending_details, " ")
      end
      pending_error = nil
      pending_details = {}
      return {
        filename = path,
        lnum = lnum,
        col = col,
        text = msg,
        type = "E",
      }
    end

    return nil
  end
end

return M
