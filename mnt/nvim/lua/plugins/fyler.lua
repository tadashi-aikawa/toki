local preview_win
local preview_path
local preview_augroup
local fyler_win
local fyler_win_config
local fyler_origin_win
local close_preview

local function restore_origin_win(win)
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_set_current_win(win)
  end
end

local function focus_fyler()
  if fyler_win and vim.api.nvim_win_is_valid(fyler_win) then
    vim.api.nvim_set_current_win(fyler_win)
  end
end

local function focus_preview()
  if preview_win and vim.api.nvim_win_is_valid(preview_win) then
    vim.api.nvim_set_current_win(preview_win)
  end
end

local function prepare_preview_buffer(path)
  local buf = vim.fn.bufadd(path)
  vim.fn.bufload(buf)
  vim.bo[buf].buflisted = false

  if vim.bo[buf].filetype == "" then
    local filetype = vim.filetype.match({ filename = path, buf = buf })
    if filetype then
      vim.bo[buf].filetype = filetype
    end
  end

  if vim.bo[buf].syntax == "" and vim.bo[buf].filetype ~= "" then
    vim.bo[buf].syntax = vim.bo[buf].filetype
  end

  pcall(vim.treesitter.start, buf)

  return buf
end

local function set_preview_keymaps(buf)
  vim.keymap.set("n", "<C-w>h", focus_fyler, { buffer = buf, silent = true })
  vim.keymap.set("n", "<C-p>", close_preview, { buffer = buf, silent = true })
end

local function update_preview(entry)
  if not entry or entry.type ~= "file" then
    return
  end

  if not preview_win or not vim.api.nvim_win_is_valid(preview_win) then
    return
  end

  if preview_path == entry.path then
    return
  end

  local buf = prepare_preview_buffer(entry.path)
  vim.api.nvim_win_set_buf(preview_win, buf)
  set_preview_keymaps(buf)
  preview_path = entry.path
end

function close_preview()
  if preview_augroup then
    vim.api.nvim_del_augroup_by_id(preview_augroup)
  end
  preview_augroup = nil
  preview_path = nil

  if preview_win and vim.api.nvim_win_is_valid(preview_win) then
    vim.api.nvim_win_close(preview_win, true)
  end
  preview_win = nil

  if fyler_win and vim.api.nvim_win_is_valid(fyler_win) and fyler_win_config then
    vim.api.nvim_win_set_config(fyler_win, fyler_win_config)
  end
  fyler_win = nil
  fyler_win_config = nil
end

local function close_preview_before_action(action)
  return function(explorer)
    local origin_win = fyler_origin_win
    close_preview()
    explorer:action_call(action)

    if action == "n_close" then
      restore_origin_win(origin_win)
      fyler_origin_win = nil
    end
  end
end

local function close_preview_before_file_action(action)
  return function(explorer)
    local entry = explorer:cursor_node_entry()
    if entry and entry.type == "file" then
      close_preview()
    end

    explorer:action_call(action)
  end
end

local function toggle_preview(explorer)
  if preview_win then
    local preview_win_is_valid = vim.api.nvim_win_is_valid(preview_win)
    close_preview()
    if preview_win_is_valid then
      return
    end
  end

  local entry = explorer:cursor_node_entry()
  if not entry or entry.type ~= "file" then
    return
  end

  if not explorer.win or not vim.api.nvim_win_is_valid(explorer.win.winid) then
    return
  end

  fyler_win = explorer.win.winid
  fyler_win_config = vim.api.nvim_win_get_config(fyler_win)
  if explorer.win.origin_win and vim.api.nvim_win_is_valid(explorer.win.origin_win) then
    fyler_origin_win = explorer.win.origin_win
  else
    fyler_origin_win = nil
  end

  local margin = 2
  local total_width = math.floor(vim.o.columns * 0.95)
  local total_height = fyler_win_config.height
  local fyler_width = math.floor(total_width * 0.45)
  local preview_width = total_width - fyler_width - margin
  local row = fyler_win_config.row
  local col = math.floor((vim.o.columns - total_width) / 2)

  vim.api.nvim_win_set_config(
    fyler_win,
    vim.tbl_extend("force", fyler_win_config, {
      relative = "editor",
      row = row,
      col = col,
      width = fyler_width,
      height = total_height,
    })
  )

  local buf = prepare_preview_buffer(entry.path)

  preview_win = vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    row = row,
    col = col + fyler_width + margin,
    width = preview_width,
    height = total_height,
    style = "minimal",
    border = "rounded",
    zindex = 60,
  })

  vim.wo[preview_win].number = true
  vim.wo[preview_win].relativenumber = false
  vim.wo[preview_win].wrap = false
  set_preview_keymaps(buf)

  preview_path = entry.path
  preview_augroup = vim.api.nvim_create_augroup("fyler_preview", { clear = true })
  vim.api.nvim_create_autocmd("CursorMoved", {
    buffer = vim.api.nvim_win_get_buf(fyler_win),
    group = preview_augroup,
    callback = function()
      update_preview(explorer:cursor_node_entry())
    end,
  })

  vim.api.nvim_set_current_win(fyler_win)
end

return {
  "A7Lavinraj/fyler.nvim",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  keys = {
    { "<Space>t", "<cmd>Fyler kind=float<cr>", desc = "Open Fyler" },
  },
  config = function(_, opts)
    require("fyler").setup(opts)

    local refresh_generation = 0
    local group = vim.api.nvim_create_augroup("FylerAutoRefresh", { clear = true })

    vim.api.nvim_create_autocmd({ "DiagnosticChanged", "BufWritePost", "FocusGained", "TermClose" }, {
      group = group,
      callback = function()
        refresh_generation = refresh_generation + 1
        local current_generation = refresh_generation

        vim.defer_fn(function()
          if current_generation ~= refresh_generation then
            return
          end

          vim.api.nvim_exec_autocmds("User", { pattern = "DispatchRefresh" })
        end, 500)
      end,
    })
  end,
  opts = {
    integrations = {
      icon = "nvim_web_devicons",
    },
    views = {
      finder = {
        columns = {
          git = {
            symbols = {
              Untracked = "?",
              Added = "",
              Modified = "",
              Deleted = "",
              Renamed = "R",
              Copied = "C",
              Conflict = "!",
              Ignored = " ",
            },
          },
          diagnostic = {
            symbols = {
              Error = "",
              Warn = "",
              Info = "",
              Hint = "",
            },
          },
        },
        icon = {
          directory_empty = "",
          directory_expanded = "",
          directory_collapsed = "",
        },
        watcher = {
          enabled = true,
        },
        mappings = {
          ["q"] = close_preview_before_action("n_close"),
          ["<CR>"] = close_preview_before_file_action("n_select"),
          ["<C-CR>"] = close_preview_before_file_action("n_select_v_split"),
          ["<C-s>"] = close_preview_before_file_action("n_select_split"),
          ["<C-t>"] = close_preview_before_file_action("n_select_tab"),
          ["-"] = "GotoParent",
          ["="] = "GotoCwd",
          ["<C-]>"] = close_preview_before_file_action("n_goto_node"),
          ["<C-p>"] = toggle_preview,
          ["<C-w>l"] = focus_preview,
          ["zC"] = "CollapseAll",
          ["zc"] = "CollapseNode",

          -- Disable some default mappings
          ["|"] = "<nop>",
          ["^"] = "<nop>",
          ["."] = "<nop>",
          ["#"] = "<nop>",
          ["<BS>"] = "<nop>",
        },
      },
    },
  },
}
