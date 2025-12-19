-- lua/custom/plugins/nvim-dap-process-attach.lua
local M = {}

local dap = require 'dap'
local pickers = require 'telescope.pickers'
local finders = require 'telescope.finders'
local conf = require('telescope.config').values
local actions = require 'telescope.actions'
local action_state = require 'telescope.actions.state'

-- Picker to select any running process and attach
M.attach_to_process = function()
  local lines = {}
  for line in io.popen('ps -ef'):lines() do
    table.insert(lines, line)
  end

  if #lines == 0 then
    vim.notify('No running processes found.', vim.log.levels.INFO)
    return
  end

  pickers
    .new({}, {
      prompt_title = 'Attach to a process',
      finder = finders.new_table { results = lines },
      sorter = conf.generic_sorter {},
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry().value

          -- Grab the PID from the second column
          local pid = tonumber(selection:match '^%S+%s+(%d+)')
          if not pid then
            vim.notify('Could not parse PID from selection.', vim.log.levels.ERROR)
            return
          end

          dap.run {
            type = 'coreclr',
            name = 'Attach to process',
            request = 'attach',
            processId = pid,
          }
        end)
        return true
      end,
    })
    :find()
end

return M
