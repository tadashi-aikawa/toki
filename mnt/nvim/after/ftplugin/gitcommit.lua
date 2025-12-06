-- COMMIT_EDITMSGを開いたときにステージ済み差分をコメントとして末尾へ追記する
local filename = vim.fn.expand("%:t")
if filename ~= "COMMIT_EDITMSG" then
  return
end

if vim.b._commit_diff_injected then
  return
end
vim.b._commit_diff_injected = true

local commit_path = vim.fn.expand("%:p")
local git_dir = vim.fn.fnamemodify(commit_path, ":h")
local repo_root = vim.fn.fnamemodify(git_dir, ":h")
if git_dir == "" or repo_root == "" then
  return
end

local prefer_japanese = true
local log_lines = vim.fn.systemlist({
  "git",
  "--git-dir=" .. git_dir,
  "--work-tree=" .. repo_root,
  "log",
  "-10",
  "--pretty=%s",
})
if vim.v.shell_error == 0 and #log_lines > 0 then
  prefer_japanese = false
  local re = vim.regex("\\v[ぁ-んァ-ン一-龠々〆ヵヶー]+")
  for _, line in ipairs(log_lines) do
    if re:match_str(line) then
      prefer_japanese = true
      break
    end
  end
else
  log_lines = {}
end

local diff_lines = vim.fn.systemlist({
  "git",
  "--git-dir=" .. git_dir,
  "--work-tree=" .. repo_root,
  "diff",
  "--cached",
})
if vim.v.shell_error ~= 0 or #diff_lines == 0 then
  return
end

local lines = { "" }
if prefer_japanese then
  table.insert(lines, "# 以下の差分を参考にコミットメッセージを書いて。")
  table.insert(lines, "# コミットメッセージは日本語で書いてください。")
  table.insert(
    lines,
    "# Conventional Commitを採用しています。直近のコミットメッセージを参考にしてください。"
  )
  table.insert(lines, "# ")
  if #log_lines > 0 then
    table.insert(lines, "# 直近のコミットメッセージ（最新10件）:")
  end
else
  table.insert(lines, "# Write the commit message referring to the staged diff.")
  table.insert(lines, "# Write the commit message in English.")
  table.insert(lines, "# We use Conventional Commit. Please refer to recent commit messages.")
  table.insert(lines, "# ")
  if #log_lines > 0 then
    table.insert(lines, "# Recent commit messages (latest 10):")
  end
end

for _, msg in ipairs(log_lines) do
  if msg ~= "" then
    table.insert(lines, "# - " .. msg)
  end
end
table.insert(lines, "# ")

table.insert(lines, "# --- Staged Diff (for Copilot) ---")

for _, line in ipairs(diff_lines) do
  table.insert(lines, "# " .. line)
end

vim.api.nvim_buf_set_lines(0, -1, -1, false, lines)
