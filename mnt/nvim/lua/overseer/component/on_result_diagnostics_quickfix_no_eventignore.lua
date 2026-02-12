-- Based on:
-- https://github.com/stevearc/overseer.nvim/blob/master/lua/overseer/component/on_result_diagnostics_quickfix.lua
--
-- This local variant intentionally avoids eventignore=all when opening quickfix/loclist,
-- so plugins that depend on window/filetype events (e.g. nvim-bqf preview bootstrap) can initialize.

-- Looks for a result value of 'diagnostics' that is a list of quickfix items
---@type overseer.ComponentFileDefinition
return {
  desc = "If task result contains diagnostics, add them to the quickfix (without eventignore)",
  params = {
    use_loclist = {
      desc = "If true, use the loclist instead of quickfix",
      type = "boolean",
      default = false,
    },
    close = {
      desc = "If true, close the quickfix when there are no diagnostics",
      type = "boolean",
      default = false,
    },
    open = {
      desc = "If true, open the quickfix when there are diagnostics",
      type = "boolean",
      default = false,
    },
    set_empty_results = {
      desc = "If true, overwrite the current quickfix even if there are no diagnostics",
      type = "boolean",
      default = false,
    },
  },
  constructor = function(params)
    return {
      on_result = function(self, task, result)
        local diagnostics = result.diagnostics or {}
        local is_empty = vim.tbl_isempty(diagnostics)
        local conf
        local prev_context
        if params.use_loclist then
          prev_context = vim.fn.getloclist(0, { context = 1 }).context
          conf = {
            open_cmd = "lopen",
            close_cmd = "lclose",
          }
        else
          prev_context = vim.fn.getqflist({ context = 1 }).context
          conf = {
            open_cmd = "botright copen",
            close_cmd = "cclose",
          }
        end
        local what = {
          title = task.name,
          context = task.name,
          items = diagnostics,
        }
        local replace = prev_context == task.name
        local action = replace and "r" or " "
        if not replace and is_empty and not params.set_empty_results then
          return
        end

        if params.use_loclist then
          vim.fn.setloclist(0, {}, action, what)
        else
          vim.fn.setqflist({}, action, what)
        end

        if is_empty then
          if params.close then
            vim.cmd(conf.close_cmd)
          end
        elseif params.open then
          local winid = vim.api.nvim_get_current_win()
          -- DIFF from upstream: open without util.eventignore_call(...)
          -- to keep FileType/WinEnter-related plugin hooks working.
          vim.cmd(conf.open_cmd)
          vim.api.nvim_set_current_win(winid)
        end
      end,
    }
  end,
}
