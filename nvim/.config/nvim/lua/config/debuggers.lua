local M = {
}

M.setup = function()
  -- dap virtual text
  require('nvim-dap-virtual-text').setup {
    enabled_commands = true, -- create commands DapVirtualTextEnable, DapVirtualTextDisable, DapVirtualTextToggle, (DapVirtualTextForceRefresh for refreshing when debug adapter did not notify its termination)
    highlight_changed_variables = true, -- highlight changed values with NvimDapVirtualTextChanged, else always NvimDapVirtualText
    highlight_new_as_changed = false, -- highlight new variables in the same way as changed variables (if highlight_changed_variables)
    show_stop_reason = true, -- show stop reason when stopped for exceptions
    commented = false, -- prefix virtual text with comment string
  }
  require('dap-python').setup()
  require("dapui").setup()
  require("nvim-dap-virtual-text").setup()
  -- adds loading of .vscode/launch.json files
  -- require('dap.ext.vscode').load_launchjs()

  vim.fn.sign_define('DapBreakpoint', { text = '🛑', texthl = '', linehl = '', numhl = '' })
  vim.fn.sign_define('DapBreakpointRejected', { text = '⛔', texthl = '', linehl = '', numhl = '' })

  -- local dap = require('dap')
  -- dap.adapters.coreclr = {
  --   type = 'executable',
  --   command = vim.env.DEV_HOME .. '/.tools/netcoredbg/netcoredbg',
  --   args = { '--interpreter=vscode' }
  -- }
  --
  -- dap.configurations.cs = {
  --   {
  --     type = "coreclr",
  --     name = "launch - netcoredbg",
  --     request = "launch",
  --     program = function()
  --       return vim.fn.input('Path to dll', vim.fn.getcwd() .. '/bin/Debug/net5.0', 'file')
  --     end,
  --   },
  -- }

end

return M
