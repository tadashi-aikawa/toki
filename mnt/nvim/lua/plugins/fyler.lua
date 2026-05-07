local preview_win
local preview_path
local preview_buf
local preview_buf_is_scratch
local preview_augroup
local fyler_win
local fyler_win_config
local fyler_origin_win
local close_preview

local FLOAT_MIN_WIDTH = 40
local FLOAT_MAX_WIDTH = 120
local PREVIEW_MIN_WIDTH = 80
local PREVIEW_TOTAL_MAX_WIDTH = 240

local function fit_width(max_width)
  return math.max(1, math.min(math.floor(vim.o.columns * 0.95), max_width))
end

local function center_col(width)
  return math.floor((vim.o.columns - width) / 2)
end

local function display_width(text)
  return vim.fn.strdisplaywidth(tostring(text or ""))
end

local function fyler_content_width(winid, namespace)
  if not winid or not vim.api.nvim_win_is_valid(winid) then
    return 0
  end

  local bufnr = vim.api.nvim_win_get_buf(winid)
  local content_width = 0

  for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
    content_width = math.max(content_width, display_width(line))
  end

  if namespace then
    local ok, extmarks = pcall(vim.api.nvim_buf_get_extmarks, bufnr, namespace, 0, -1, { details = true })
    if ok then
      for _, extmark in ipairs(extmarks) do
        local details = extmark[4] or {}
        local virt_text_width = 0
        for _, chunk in ipairs(details.virt_text or {}) do
          virt_text_width = virt_text_width + display_width(chunk[1])
        end

        content_width = math.max(content_width, (details.virt_text_win_col or extmark[3] or 0) + virt_text_width)
      end
    end
  end

  return content_width
end

local function patch_fyler_display_width()
  local UiComponent = require("fyler.lib.ui.component")
  local Renderer = require("fyler.lib.ui.renderer")

  if Renderer._toki_display_width_patched then
    return
  end
  Renderer._toki_display_width_patched = true

  UiComponent.width = function(self)
    if self.tag == "text" then
      local text = self.value
      if text == nil and self.option and self.option.virt_text then
        text = self.option.virt_text[1][1]
      end
      return display_width(text)
    end

    if self.tag == "row" then
      local width = 0
      for i = 1, #self.children do
        width = width + self.children[i]:width()
      end

      return width
    end

    if self.children then
      local width = 0
      for i = 1, #self.children do
        width = math.max(width, self.children[i]:width())
      end

      return width
    end

    error("UNIMPLEMENTED")
  end

  Renderer._render_column_in_row = function(self, component, current_col)
    current_col = current_col or 0
    local column_start_col = current_col
    local column_width = component:width()
    local column_lines = {}
    local column_highlights = {}
    local column_extmarks = {}

    local saved_line = vim.deepcopy(self.line)
    local saved_highlights = vim.deepcopy(self.highlight)
    local saved_extmarks = vim.deepcopy(self.extmark)
    local saved_flag = vim.deepcopy(self.flag)

    self.line = {}
    self.highlight = {}
    self.extmark = {}
    self.flag.in_row = false
    self.flag.column_offset = column_start_col

    for _, child in ipairs(component.children) do
      self:_render_child(child)
    end

    column_lines = vim.deepcopy(self.line)
    column_highlights = vim.deepcopy(self.highlight)
    column_extmarks = vim.deepcopy(self.extmark)

    self.line = saved_line
    self.highlight = saved_highlights
    self.extmark = saved_extmarks
    self.flag = saved_flag

    local lines_needed = self.flag.row_base_line + #column_lines
    while #self.line < lines_needed do
      table.insert(self.line, "")
    end

    for i, line_content in ipairs(column_lines) do
      local target_line_idx = self.flag.row_base_line + i
      local current_line = self.line[target_line_idx] or ""

      if line_content and line_content ~= "" then
        local padding_needed = column_start_col - display_width(current_line)
        if padding_needed > 0 then
          current_line = current_line .. string.rep(" ", padding_needed)
        end

        self.line[target_line_idx] = current_line .. line_content
      end
    end

    for _, hl in ipairs(column_highlights) do
      table.insert(self.highlight, {
        line = self.flag.row_base_line + hl.line,
        col_start = column_start_col + hl.col_start,
        col_end = column_start_col + hl.col_end,
        highlight_group = hl.highlight_group,
      })
    end

    for _, extmark in ipairs(column_extmarks) do
      table.insert(self.extmark, {
        line = self.flag.row_base_line + extmark.line,
        col = column_start_col + (extmark.col or 0),
        virt_text = extmark.virt_text,
        virt_text_pos = extmark.virt_text_pos,
        hl_mode = extmark.hl_mode,
      })
    end

    return "", column_start_col + column_width
  end
end

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

local function show_line_numbers(win)
  if win and vim.api.nvim_win_is_valid(win) then
    vim.wo[win].number = true
    vim.wo[win].relativenumber = false
  end
end

local function open_fyler()
  vim.cmd("Fyler kind=float")
  show_line_numbers(vim.api.nvim_get_current_win())
end

local function is_image_path(path)
  local ok, image = pcall(require, "snacks.image")
  return ok and image.supports_file(path) and image.config.enabled ~= false
end

local function prepare_preview_buffer(path)
  if is_image_path(path) then
    local buf = vim.api.nvim_create_buf(false, true)
    require("snacks.image").buf.attach(buf, { src = path })
    return buf, true
  end

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

  return buf, false
end

local function apply_preview_window_options(win, path)
  if not win or not vim.api.nvim_win_is_valid(win) then
    return
  end

  if is_image_path(path) then
    vim.wo[win].number = false
    vim.wo[win].relativenumber = false
  else
    show_line_numbers(win)
  end

  vim.wo[win].wrap = false
end

local function cleanup_preview_buffer()
  if preview_buf_is_scratch and preview_buf and vim.api.nvim_buf_is_valid(preview_buf) then
    vim.api.nvim_buf_delete(preview_buf, { force = true })
  end

  preview_buf = nil
  preview_buf_is_scratch = nil
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

  local previous_preview_buf = preview_buf
  local previous_preview_buf_is_scratch = preview_buf_is_scratch
  local buf, buf_is_scratch = prepare_preview_buffer(entry.path)
  vim.api.nvim_win_set_buf(preview_win, buf)
  preview_buf = buf
  preview_buf_is_scratch = buf_is_scratch

  if previous_preview_buf_is_scratch and previous_preview_buf and vim.api.nvim_buf_is_valid(previous_preview_buf) then
    vim.api.nvim_buf_delete(previous_preview_buf, { force = true })
  end

  apply_preview_window_options(preview_win, entry.path)
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
  cleanup_preview_buffer()

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
  show_line_numbers(fyler_win)
  fyler_win_config = vim.api.nvim_win_get_config(fyler_win)
  if explorer.win.origin_win and vim.api.nvim_win_is_valid(explorer.win.origin_win) then
    fyler_origin_win = explorer.win.origin_win
  else
    fyler_origin_win = nil
  end

  local margin = 2
  local total_width = fit_width(PREVIEW_TOTAL_MAX_WIDTH)
  local total_height = fyler_win_config.height
  local max_fyler_width = math.max(1, total_width - margin - PREVIEW_MIN_WIDTH)
  local fyler_width = math.min(
    math.max(FLOAT_MIN_WIDTH, fyler_content_width(fyler_win, explorer.win.namespace) + 2),
    FLOAT_MAX_WIDTH,
    max_fyler_width
  )
  local preview_width = total_width - fyler_width - margin
  local row = fyler_win_config.row
  local col = center_col(total_width)

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

  local buf, buf_is_scratch = prepare_preview_buffer(entry.path)

  preview_win = vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    row = row,
    col = col + fyler_width + margin,
    width = preview_width,
    height = total_height,
    style = "minimal",
    border = "rounded",
    zindex = 40,
  })

  apply_preview_window_options(preview_win, entry.path)
  set_preview_keymaps(buf)

  preview_buf = buf
  preview_buf_is_scratch = buf_is_scratch
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
    { "<Space>t", open_fyler, desc = "Open Fyler" },
  },
  config = function(_, opts)
    require("fyler").setup(opts)
    patch_fyler_display_width()

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
        columns_order = { "git", "diagnostic", "size", "link" },
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
        win = {
          kinds = {
            float = {
              width = fit_width(FLOAT_MAX_WIDTH),
              height = "70%",
              top = "10%",
              left = center_col(fit_width(FLOAT_MAX_WIDTH)),
            },
          },
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
