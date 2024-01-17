local M = {
}

M.setup = function()
  -- turn off all code diagnostics when diffing
  if vim.opt.diff:get() then
    return
  end

  -- vim.lsp.set_log_level("debug")

  -- Setup Language sever protocol
  local nvim_lsp = require('lspconfig')
  local pid = vim.fn.getpid()

  vim.diagnostic.config({
    virtual_text = {
      source = "if_many",
      prefix = '󰂖',
      -- prefix = '',
      -- prefix = '',
      -- prefix = '',
      -- prefix = '',
      -- prefix = '󰵛',
      -- prefix = '󰂚',
      -- prefix = '󰵙',
      -- prefix = '',
      -- prefix = '',
      -- prefix = '',
    },
    severity_sort = true,
    float = {
      source = "always", -- Or "if_many"
    },
  })

  local code_action_func = function()
    vim.lsp.buf.code_action({
      filter = function(client) return client.name ~= "pyright" end
    })
  end

  vim.api.nvim_create_autocmd('LspAttach', {
    pattern = "*.py",
    callback = function(_)
      vim.diagnostic.config({
        virtual_text = {
          source = false,
          -- prefix = '',
          prefix = '',
          format = function(diagnostic)
            return string.format("%s (%s) %s", diagnostic.source, diagnostic.code, diagnostic.message)
          end
        },
        severity_sort = true,
        float = {
          source = "always", -- Or "if_many"
        },
      })
    end,
  })

  local on_list = function(def_list)
    if #def_list > 1 then
      -- double call to lsp :(
      require('telescope.builtin').lsp_definitions()
    else
      local windows = vim.api.nvim_list_wins()
      local item = def_list['items'][1]

      if #windows == 1 then
        local window = windows[1]
        local buf = vim.api.nvim_win_get_buf(window)
        local file = vim.api.nvim_buf_get_name(buf)

        if string.lower(item['filename']) == string.lower(file) then
          -- local lnum, col = unpack(vim.api.nvim_win_get_cursor(0))
          -- vim.api.nvim_buf_set_mark(0, "p", lnum, col, {})
          -- vim.api.nvim_buf_set_mark(0, "`", lnum, col, {})
          vim.cmd("normal m`")
          vim.api.nvim_win_set_cursor(window, { item['lnum'], item['col'] - 1 })
        else
          vim.cmd.vsplit()
          vim.cmd.edit(item['filename'])
          local new_win = vim.api.nvim_get_current_win()
          vim.api.nvim_win_set_var(new_win, "references", true)
          vim.api.nvim_win_set_cursor(new_win, { item['lnum'], item['col'] - 1 })
          vim.api.nvim_set_hl(55, "Normal", { bg = "#222730" })
          vim.api.nvim_win_set_hl_ns(0, 55)
        end
      else
        local cur_win = vim.api.nvim_get_current_win()
        local cur_buf = vim.api.nvim_win_get_buf(cur_win)
        local cur_file = vim.api.nvim_buf_get_name(cur_buf)
        if string.lower(item['filename']) == string.lower(cur_file) then
          vim.cmd("normal m`")
          vim.api.nvim_win_set_cursor(cur_win, { item['lnum'], item['col'] - 1 })
          return
        end
        local done = false
        for _, window in pairs(windows) do
          local buf = vim.api.nvim_win_get_buf(window)
          local file = vim.api.nvim_buf_get_name(buf)
          if item['filename'] == file then
            vim.cmd("normal m`")
            vim.api.nvim_win_set_cursor(window, { item['lnum'], item['col'] - 1 })
            done = true
            break
          end
          local ok, refs = pcall(vim.api.nvim_win_get_var, window, "references")
          if ok and refs then
            vim.api.nvim_set_current_win(window)
            vim.cmd.edit(item['filename'])
            vim.api.nvim_win_set_cursor(window, { item['lnum'], item['col'] - 1 })
            done = true
            break
          end
        end
        if not done then
          vim.cmd.vsplit()
          vim.cmd.edit(item['filename'])
          local new_win = vim.api.nvim_get_current_win()
          vim.api.nvim_win_set_var(new_win, "references", true)
          vim.api.nvim_win_set_cursor(new_win, { item['lnum'], item['col'] - 1 })
          vim.api.nvim_set_hl(55, "Normal", { bg = "#222730" })
          vim.api.nvim_win_set_hl_ns(0, 55)
        end
      end
    end
  end

  local on_attach = function(_, bufnr)
    --Enable completion triggered by <c-x><c-o>
    vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

    -- Mappings.
    local bufopts = { noremap = true, silent = true, buffer = bufnr }
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
    vim.keymap.set('n', 'gd', function() vim.lsp.buf.definition({ on_list = on_list }) end, bufopts)
    vim.keymap.set('n', 'gi', require('telescope.builtin').lsp_incoming_calls, bufopts)
    vim.keymap.set('n', 'go', require('telescope.builtin').lsp_outgoing_calls, bufopts)
    -- vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
    vim.keymap.set('n', 'gr',
      function() require('telescope.builtin').lsp_references({ path_display = { "tail" } }) end
      , bufopts)
    -- vim.keymap.set('n', '<leader>lt', vim.lsp.buf.type_definition, bufopts)
    vim.keymap.set('n', 'gt', require('telescope.builtin').lsp_type_definitions, bufopts)

    vim.keymap.set('n', '<leader>lh', vim.lsp.buf.hover, bufopts)
    vim.keymap.set('n', '<leader>ls', vim.lsp.buf.signature_help, bufopts)
    vim.keymap.set('n', '<leader>lf', function() vim.lsp.buf.format({ async = true }) end, bufopts)
    vim.keymap.set('n', '<leader>lr', vim.lsp.buf.rename, bufopts)
    vim.keymap.set('n', '<leader>lc', code_action_func, bufopts)
    -- vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
    vim.keymap.set('n', '<leader>li', require('telescope.builtin').lsp_implementations, bufopts)
  end

  local capabilities = require('cmp_nvim_lsp').default_capabilities()

  capabilities.textDocument.completion.completionItem.snippetSupport = true
  capabilities.textDocument.completion.completionItem.resolveSupport = {
    properties = {
      'documentation',
      'detail',
      'additionalTextEdits',
    }
  }

  -- Use a loop to conveniently call 'setup' on multiple servers and
  -- map buffer local keybindings when the language server attaches
  local servers = { "tsserver", "clangd" }
  for _, lsp in ipairs(servers) do
    nvim_lsp[lsp].setup {
      capabilities = capabilities,
      on_attach = on_attach,
    }
  end

  if vim.fn.executable('pyright') == 1 then
    local cap = capabilities
    cap.textDocument.publishDiagnostics = { tagSupport = { valueSet = { 2 } } }
    nvim_lsp['pyright'].setup {
      capabilities = cap,
      on_attach = function(client, buffer)
        client.server_capabilities.codeActionProvider = false
        client.server_capabilities.renameProvider = false
        client.handlers["textDocument/publishDiagnostics"] = function(...) end
        on_attach(client, buffer)
      end,
      settings = {
        python = {
          analysis = {
            typeCheckingMode = "off",
          }
        }
      }
    }
  end

  -- Rust
  local rust_analyzer = 'rust-analyzer'
  if vim.fn.executable('rust-analyzer-x86_64-pc-windows-msvc') == 1 then
    rust_analyzer = 'rust-analyzer-x86_64-pc-windows-msvc'
  end

  -- vim.api.nvim_create_autocmd('LspAttach', {
  --   pattern = "*.rs",
  --   callback = function(_)
  if vim.fn.executable(rust_analyzer) == 1 then
    nvim_lsp['rust_analyzer'].setup {
      capabilities = capabilities,
      on_attach = on_attach,
      cmd = { rust_analyzer },
    }
  end
  --   end
  -- })

  -- PowerShell
  local bundle_path = vim.env.DEV_HOME .. '/.ls/PowerShellEditorServices'
  if vim.fn.isdirectory(bundle_path) == 1 then
    -- Setup PowerShell Editor Extensions
    nvim_lsp['powershell_es'].setup {
      capabilities = capabilities,
      on_attach = on_attach,
      bundle_path = bundle_path,
    }
  end

  -- Lua
  local lua_language_server = vim.env.DEV_HOME .. '/.ls/lua-language-server/bin/lua-language-server'
  if vim.fn.executable(lua_language_server) == 1 then
    nvim_lsp['lua_ls'].setup {
      on_init = function(client)
        local path = client.workspace_folders[1].name
        if not vim.loop.fs_stat(path .. '/.luarc.json') and not vim.loop.fs_stat(path .. '/.luarc.jsonc') then
          client.config.settings = vim.tbl_deep_extend('force', client.config.settings, {
            Lua = {
              runtime = {
                version = 'LuaJIT'
              },
              -- Make the server aware of Neovim runtime files
              workspace = {
                checkThirdParty = false,
                library = { vim.env.VIMRUNTIME }
              }
            }
          })

          client.notify("workspace/didChangeConfiguration", { settings = client.config.settings })
        end
        return true
      end,
      cmd = { lua_language_server },
      capabilities = capabilities,
      on_attach = on_attach,
    }
  end

  -- Zig
  local zls = vim.env.DEV_HOME .. '/.ls/zigtools-zls/bin/zls'
  if vim.fn.executable(zls) == 1 then
    nvim_lsp['zls'].setup {
      cmd = { zls },
      capabilities = capabilities,
      on_attach = on_attach,
    }
  end

  -- C#
  local omnisharp = vim.env.DEV_HOME .. '/.ls/omnisharp/OmniSharp.exe'
  if vim.fn.executable(omnisharp) == 1 then
    nvim_lsp['omnisharp'].setup {
      handlers = {
        ["textDocument/definition"] = require('omnisharp_extended').handler,
      },
      capabilities = capabilities,
      on_attach = on_attach,
      cmd = { omnisharp, "--languageserver", "--hostPID", tostring(pid),
        "formattingOptions:EnableEditorConfigSupport=true" }
    }
  end

  -- Setup null-ls
  vim.api.nvim_create_autocmd('LspAttach', {
    pattern = "*.py",
    callback = function(_)
      local null_ls = require("null-ls")
      local null_ls_sources = {}
      if vim.fn.executable('black') == 1 then
        table.insert(null_ls_sources, null_ls.builtins.formatting.black)
      end

      if vim.fn.executable('flake8') == 1 then
        table.insert(null_ls_sources, null_ls.builtins.diagnostics.flake8)
      end

      if vim.fn.executable('ruff') == 1 then
        table.insert(null_ls_sources, null_ls.builtins.diagnostics.ruff)
      end

      null_ls.setup({
        sources = null_ls_sources,
      })
    end
  })
end

return M
