-- Based on:
-- https://github.com/stevearc/overseer.nvim/blob/master/lua/overseer/component/on_result_diagnostics_quickfix.lua
--
-- This local variant intentionally avoids eventignore=all when opening quickfix/loclist,
-- so plugins that depend on window/filetype events (e.g. nvim-bqf preview bootstrap) can initialize.

local task_list = require("overseer.task_list")

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
    context = {
      desc = "Optional quickfix context key for grouping results",
      type = "string",
      optional = true,
    },
    merge_by_task = {
      desc = "If true, merge child task diagnostics into one list (keyed by task name)",
      type = "boolean",
      default = false,
    },
    show_task_name = {
      desc = "If true, prepend task name to quickfix text in merge mode",
      type = "boolean",
      default = false,
    },
  },
  constructor = function(params)
    local function to_tagged_items(items, task_name, show_task_name)
      local ret = {}
      local prefix = string.format("[%s] ", task_name)
      for _, item in ipairs(items) do
        local copied = vim.deepcopy(item)
        local user_data = copied.user_data
        if type(user_data) ~= "table" then
          user_data = {}
        end
        user_data.overseer_task_name = task_name
        copied.user_data = user_data
        if show_task_name and type(copied.text) == "string" then
          copied.text = prefix .. copied.text
        end
        table.insert(ret, copied)
      end
      return ret
    end

    local function split_items_by_task(items, task_name)
      local keep = {}
      local had_task_items = false

      for _, item in ipairs(items) do
        local user_data = item.user_data
        if type(user_data) == "table" and user_data.overseer_task_name == task_name then
          had_task_items = true
        else
          table.insert(keep, item)
        end
      end

      return keep, had_task_items
    end

    local function find_task_by_id(id)
      local tasks = task_list.list_tasks({
        include_ephemeral = true,
        filter = function(candidate)
          return candidate.id == id
        end,
      })
      return tasks[1]
    end

    return {
      on_result = function(self, task, result)
        local diagnostics = result.diagnostics or {}
        local merge_by_task = params.merge_by_task and task.parent_id ~= nil
        local parent_task = nil
        if merge_by_task then
          parent_task = find_task_by_id(task.parent_id)
        end

        local base_context = params.context
          or (parent_task and parent_task.name)
          or task.name
        local context_key = base_context
        if merge_by_task then
          context_key = string.format("%s::parent=%d", base_context, task.parent_id)
        end
        local conf
        local prev
        if params.use_loclist then
          prev = vim.fn.getloclist(0, { context = 1, items = 1 })
          conf = {
            open_cmd = "lopen",
            close_cmd = "lclose",
          }
        else
          prev = vim.fn.getqflist({ context = 1, items = 1 })
          conf = {
            open_cmd = "botright copen",
            close_cmd = "cclose",
          }
        end

        local prev_context = prev.context
        local replace = prev_context == context_key
        local items = diagnostics
        local is_empty = vim.tbl_isempty(items)

        if merge_by_task then
          local existing_items = replace and (prev.items or {}) or {}
          local keep, had_task_items = split_items_by_task(existing_items, task.name)
          local merged = vim.list_extend(keep, to_tagged_items(diagnostics, task.name, params.show_task_name))
          local merged_is_empty = vim.tbl_isempty(merged)
          if not replace and merged_is_empty and not params.set_empty_results and not had_task_items then
            return
          end
          items = merged
          is_empty = merged_is_empty
        end

        local what = {
          title = base_context,
          context = context_key,
          items = items,
        }
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
