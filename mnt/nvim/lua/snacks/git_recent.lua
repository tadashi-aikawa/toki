local M = {}

local uv = vim.uv or vim.loop

---@class SnacksGitRecentOpts
---@field include_modified? boolean
---@field include_untracked? boolean
---@field max_commit_count? integer  -- git log の最大コミット数
---@field max_count? integer         -- 表示エントリ数の最大数
---@field hidden? boolean           -- Snacks側オプションを渡すことがあるなら許容
---@field matcher? table            -- 同上（必要ならより厳密化）
---@field sort? table               -- 同上

---@param ts? integer
---@return string hl
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
  -- ここにはこないはずだが一応定義
  return "SnacksPickerAgeOld"
end

---@param ts? integer
---@return string|nil label
---@return string|nil hl
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

---@param items table
---@param seen table<string, boolean>
---@param path string
---@param root string
---@param ts? integer
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

---@param root string
---@param path string
---@return integer|nil
local function getMtimeSec(root, path)
  local fullpath = root .. "/" .. path
  local stat = uv.fs_stat(fullpath)
  if stat and stat.mtime then
    return stat.mtime.sec
  end
  return nil
end

---@param items table
---@param seen table<string, boolean>
---@param root string
---@param path string
---@param status string
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

---@param line string
---@return string|nil xy
---@return string|nil path
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

---@param items table
---@param seen table<string, boolean>
---@param root string
---@param opts SnacksGitRecentOpts
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

---@param opts? SnacksGitRecentOpts
function M.picker(opts)
  Snacks.picker.pick("git_recent", opts)
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

      local args = { "git", "-C", root, "log", "--name-only", "--pretty=format:%ct%x09%s", "--since='30 days ago'" }
      if opts.max_commit_count then
        table.insert(args, "-n")
        table.insert(args, tostring(opts.max_commit_count))
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

      if opts.max_count then
        local count = math.min(#items, opts.max_count)
        local limited_items = {}
        for i = 1, count do
          limited_items[i] = items[i]
        end
        return limited_items
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
    matcher = {
      fuzzy = false,
      on_match = function(matcher, item)
        local pos = matcher:positions(item).text or {}
        local last_sep = item.file:match("^.*()/") or 0
        local basename_match = false
        for _, p in ipairs(pos) do
          if p > last_sep then
            basename_match = true
            break
          end
        end
        item.basename_match = basename_match
      end,
    },
    sort = { fields = { "basename_match", "idx" } },
    hidden = true,
    include_modified = true,
    include_untracked = true,
  }
end

function M.setup_highlights()
  vim.api.nvim_set_hl(0, "SnacksPickerAgeFresh", { link = "DiagnosticWarn" })
  vim.api.nvim_set_hl(0, "SnacksPickerAgeWeek", { link = "DiagnosticHint" })
  vim.api.nvim_set_hl(0, "SnacksPickerAgeMonth", { link = "Comment" })
  vim.api.nvim_set_hl(0, "SnacksPickerAgeOld", { link = "LineNr" })
end

return M
