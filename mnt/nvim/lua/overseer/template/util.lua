local files = require("overseer.files")

local M = {}

M.resolve_watch_paths = function(paths)
  local ret = {}
  for _, path in ipairs(paths) do
    if files.exists(path) then
      table.insert(ret, path)
    end
  end
  if vim.tbl_isempty(ret) then
    return nil
  end
  return ret
end

return M
