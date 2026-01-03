-- COMMIT_EDITMSG を開いたときにステージ済み差分をコメントとして末尾へ追記する

local function is_commit_editmsg()
  return vim.fn.expand("%:t") == "COMMIT_EDITMSG"
end

local function git_command(git_dir, repo_root, args)
  local command = { "git", "--git-dir=" .. git_dir, "--work-tree=" .. repo_root }
  vim.list_extend(command, args)
  return vim.fn.systemlist(command)
end

local function resolve_git_paths()
  local commit_path = vim.fn.expand("%:p")
  local git_dir = vim.fn.fnamemodify(commit_path, ":h")
  local repo_root = vim.fn.fnamemodify(git_dir, ":h")
  if git_dir == "" or repo_root == "" then
    return nil, nil
  end
  return git_dir, repo_root
end

local function fetch_recent_logs(git_dir, repo_root)
  local logs = git_command(git_dir, repo_root, {
    "log",
    "-30",
    "--pretty=%s",
  })
  if vim.v.shell_error ~= 0 then
    return {}
  end
  return logs
end

local function should_prefer_japanese(log_lines)
  if #log_lines == 0 then
    return true
  end
  local re = vim.regex("\\v[ぁ-んァ-ン一-龠々〆ヵヶー]+")
  for _, line in ipairs(log_lines) do
    if re:match_str(line) then
      return true
    end
  end
  return false
end

local function fetch_staged_diff(git_dir, repo_root)
  local diff = git_command(git_dir, repo_root, {
    "diff",
    "--cached",
  })
  if vim.v.shell_error ~= 0 or #diff == 0 then
    return nil
  end
  return diff
end

local function build_header_lines(log_lines, use_japanese)
  local header = {}
  local has_logs = #log_lines > 0
  if use_japanese then
    table.insert(header, "# 以下の差分を参考にコミットメッセージを書いて。")
    table.insert(header, "# コミットメッセージは日本語で書いてください。英語は禁止！")
    table.insert(
      header,
      "# Conventional Commitを採用しています。直近のコミットメッセージを参考にしてください。"
    )
    table.insert(header, "# ")
    if has_logs then
      table.insert(header, "# 直近のコミットメッセージ（最新30件）:")
    end
  else
    table.insert(header, "# Write the commit message referring to the staged diff.")
    table.insert(header, "# Must write the commit message in English.")
    table.insert(header, "# We use Conventional Commit. Please refer to recent commit messages.")
    table.insert(header, "# ")
    if has_logs then
      table.insert(header, "# Recent commit messages (latest 30):")
    end
  end
  return header
end

local function build_log_lines(log_lines)
  local lines = {}
  for _, msg in ipairs(log_lines) do
    if msg ~= "" then
      table.insert(lines, "# - " .. msg)
    end
  end
  if #lines > 0 then
    table.insert(lines, "# ")
  end
  return lines
end

local function build_diff_lines(diff_lines)
  local lines = { "# --- Staged Diff (for Copilot) ---" }
  for _, line in ipairs(diff_lines) do
    table.insert(lines, "# " .. line)
  end
  return lines
end

local function build_injected_lines(log_lines, diff_lines, use_japanese)
  local lines = { "" }
  vim.list_extend(lines, build_header_lines(log_lines, use_japanese))
  vim.list_extend(lines, build_log_lines(log_lines))
  vim.list_extend(lines, build_diff_lines(diff_lines))
  return lines
end

if not is_commit_editmsg() then
  return
end

if vim.b._commit_diff_injected then
  return
end
-- 同一バッファでの重複挿入を防ぐ
vim.b._commit_diff_injected = true

local git_dir, repo_root = resolve_git_paths()
if git_dir == nil or repo_root == nil then
  return
end

local log_lines = fetch_recent_logs(git_dir, repo_root)
local use_japanese = should_prefer_japanese(log_lines)

local diff_lines = fetch_staged_diff(git_dir, repo_root)
if diff_lines == nil then
  return
end

vim.api.nvim_buf_set_lines(0, -1, -1, false, build_injected_lines(log_lines, diff_lines, use_japanese))
