local M = {}

local uv = vim.uv or vim.loop

local function ageHighlight(ts)
  if not ts then
    return "SnacksPickerAgeOld"
  end
  local now = os.time()
  local diff = now - ts
  if diff < 0 then
    diff = 0
  end
  local days = math.floor(diff / 86400)
  if days < 1 then
    return "SnacksPickerAgeFresh"
  end
  if days < 7 then
    return "SnacksPickerAgeWeek"
  end
  if days < 30 then
    return "SnacksPickerAgeMonth"
  end
  return "SnacksPickerAgeOld"
end

local formatAgeLabel = function(ts)
  if not ts then
    return nil, nil
  end
  local now = os.time()
  local diff = now - ts
  if diff < 0 then
    diff = 0
  end

  local minutes = math.floor(diff / 60)
  local hours = math.floor(diff / 3600)
  local days = math.floor(diff / 86400)

  local label
  if minutes < 60 then
    label = string.format("%dm", math.max(minutes, 1))
  elseif hours < 24 then
    label = string.format("%dh", hours)
  else
    label = string.format("%dd", days)
  end

  return string.format("%4s", label), ageHighlight(ts)
end

local function addItem(items, seen, path, root, ts)
  if path == "" or seen[path] then
    return
  end
  local label, label_hl = formatAgeLabel(ts)
  seen[path] = true
  items[#items + 1] = {
    text = path,
    file = path,
    cwd = root,
    label = label,
    label_hl = label_hl,
  }
end

local function formatStatusLabel(status)
  return string.format("%4s", status)
end

local function getMtimeSec(root, path)
  local fullpath = root .. "/" .. path
  local stat = uv.fs_stat(fullpath)
  if stat and stat.mtime then
    return stat.mtime.sec
  end
  return nil
end

local function addStatusItem(items, seen, root, path, status)
  if path == "" or seen[path] then
    return
  end
  local ts = getMtimeSec(root, path)
  seen[path] = true
  items[#items + 1] = {
    text = path,
    file = path,
    cwd = root,
    label = formatStatusLabel(status),
    label_hl = ageHighlight(ts),
  }
end

local function parseStatusLine(line)
  local xy, path = line:match("^(..)%s+(.*)$")
  if not xy or not path then
    return nil, nil
  end
  local arrow = path:find(" %-%> ", 1, true)
  if arrow then
    path = path:sub(arrow + 4)
  end
  return xy, path
end

local function collectStatus(items, seen, root, opts)
  local output = vim.fn.systemlist({ "git", "-C", root, "status", "--porcelain=1" })
  if vim.v.shell_error ~= 0 then
    return
  end

  for _, line in ipairs(output) do
    local xy, path = parseStatusLine(line)
    if xy and path then
      if xy == "??" then
        if opts.include_untracked then
          addStatusItem(items, seen, root, path, "??")
        end
      elseif opts.include_modified then
        addStatusItem(items, seen, root, path, xy)
      end
    end
  end
end

function M.picker()
  Snacks.picker.pick("git_recent")
end

function M.source_config()
  return {
    finder = function(opts, ctx)
      local root = ctx:git_root()
      if not root then
        Snacks.notify.warn("Gitリポジトリの外では使えません")
        return {}
      end

      local seen = {}
      local items = {}

      if opts.include_modified or opts.include_untracked then
        collectStatus(items, seen, root, opts)
      end

      local args = { "git", "-C", root, "log", "--name-only", "--pretty=format:%ct%x09%s" }
      if opts.max_count then
        table.insert(args, "-n")
        table.insert(args, tostring(opts.max_count))
      end

      local output = vim.fn.systemlist(args)
      if vim.v.shell_error ~= 0 then
        Snacks.notify.warn("git log を実行できませんでした")
        return items
      end

      local last_ts = nil
      for _, line in ipairs(output) do
        local ts_line = line:match("^(%d+)\t.*$")
        if ts_line then
          last_ts = tonumber(ts_line)
          goto continue
        end

        local path = vim.trim(line)
        if path ~= "" and last_ts then
          addItem(items, seen, path, root, last_ts)
        end
        ::continue::
      end

      return items
    end,
    format = function(item, picker)
      local label = item.label
      local label_hl = item.label_hl
      if label then
        item.label = nil
      end
      local ret = Snacks.picker.format.file(item, picker)
      if label then
        table.insert(ret, 1, { label, label_hl or "SnacksPickerLabel" })
        table.insert(ret, 2, { " ", virtual = true })
        item.label = label
      end
      return ret
    end,
    matcher = { fuzzy = false },
    sort = { fields = { "idx", "score:desc" } },
    hidden = true,
    include_modified = true,
    include_untracked = true,
  }
end

function M.setup_highlights()
  vim.api.nvim_set_hl(0, "SnacksPickerAgeFresh", { link = "DiagnosticInfo" })
  vim.api.nvim_set_hl(0, "SnacksPickerAgeWeek", { link = "DiagnosticHint" })
  vim.api.nvim_set_hl(0, "SnacksPickerAgeMonth", { link = "Comment" })
  vim.api.nvim_set_hl(0, "SnacksPickerAgeOld", { link = "LineNr" })
end

return M
