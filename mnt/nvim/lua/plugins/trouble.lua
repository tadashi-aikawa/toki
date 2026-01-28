local function is_trouble_open()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "trouble" then
      return true
    end
  end
  return false
end

local function get_trouble_view()
  local view = require("trouble.api")._find_last()
  if not view or not view.win or not view.win.win then
    return nil
  end
  if not vim.api.nvim_win_is_valid(view.win.win) then
    return nil
  end
  if not vim.api.nvim_buf_is_valid(view.win.buf) then
    return nil
  end
  return view
end

local function has_trouble_item_in_direction(view, direction)
  local cursor = vim.api.nvim_win_get_cursor(view.win.win)[1]
  local max = vim.api.nvim_buf_line_count(view.win.buf)
  local start_row, end_row, step
  if direction == "next" then
    start_row, end_row, step = cursor + 1, max, 1
  else
    start_row, end_row, step = cursor - 1, 1, -1
  end
  for row = start_row, end_row, step do
    local info = view.renderer:at(row)
    if info.item and info.first_line then
      return true
    end
  end
  return false
end

return {
  "folke/trouble.nvim",
  cmd = "Trouble",
  keys = {
    {
      "<C-j>h",
      "<cmd>Trouble lsp_references<cr>",
    },
    {
      "<C-j>w",
      "<cmd>Trouble we<cr>",
    },
    {
      ",j",
      function()
        if is_trouble_open() then
          local view = get_trouble_view()
          if view then
            if has_trouble_item_in_direction(view, "next") then
              require("trouble").next()
            else
              require("trouble").first()
            end
          else
            vim.cmd("cnext")
          end
        else
          vim.cmd("cnext")
        end
      end,
    },
    {
      ",k",
      function()
        if is_trouble_open() then
          local view = get_trouble_view()
          if view then
            if has_trouble_item_in_direction(view, "prev") then
              require("trouble").prev()
            else
              require("trouble").last()
            end
          else
            vim.cmd("cprev")
          end
        else
          vim.cmd("cprev")
        end
      end,
    },
  },
  opts = {
    focus = true,
    auto_refresh = false,
    keys = {
      ["<cr>"] = "jump_close",
      o = "jump",
      l = "fold_open",
      h = "fold_close",
      ["<C-CR>"] = "jump_vsplit",
      ["<esc>"] = "inspect",
      -- XXX: sはバインドしたくないが、fallbackの方法が分からず...
      s = function()
        require("flash").jump()
      end,
    },
    lsp_references = {
      params = {
        -- 呼び出し履歴(lsp_references)では宣言を表示しない
        include_declaration = false,
      },
    },
    modes = {
      lsp_base = {
        params = {
          -- 現在の項目が消えてしまうので...
          include_current = true,
        },
      },
      we = {
        mode = "diagnostics",
        filter = {
          ["any"] = {
            { severity = vim.diagnostic.severity.WARN },
            { severity = vim.diagnostic.severity.ERROR },
          },
        },
      },
    },
    signs = {
      error = "",
      warning = "",
      hint = "󱩎",
      information = "",
      other = "",
    },
  },
}
