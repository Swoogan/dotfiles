local M = {
}

M.setup = function()
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

  local on_attach = function(_, bufnr)
    --Enable completion triggered by <c-x><c-o>
    vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

    -- Mappings.
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    local bufopts = { noremap = true, silent = true, buffer = bufnr }
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)

    -- vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, bufopts)
    -- vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, bufopts)
    -- vim.keymap.set('n', '<space>wl', function()
    --   print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    -- end, bufopts)

    -- TODO: unify these keypresses
    vim.keymap.set('n', '<leader>lh', vim.lsp.buf.hover, bufopts)
    vim.keymap.set('n', '<leader>ls', vim.lsp.buf.signature_help, bufopts)
    vim.keymap.set('n', '<leader>lt', vim.lsp.buf.type_definition, bufopts)
    vim.keymap.set('n', '<leader>lr', vim.lsp.buf.rename, bufopts)
    vim.keymap.set('n', '<leader>lc', code_action_func, bufopts)
    vim.keymap.set('n', '<leader>lf', function() vim.lsp.buf.format({ async = true }) end, bufopts)
    vim.keymap.set('n', '<leader>ld', require('telescope.builtin').lsp_document_symbols, bufopts)
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
    nvim_lsp['pyright'].setup {
      capabilities = capabilities,
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
    nvim_lsp['jedi_language_server'].setup {
      capabilities = capabilities,
      on_attach = function(client, buffer)
        client.server_capabilities.completionProvider = false
        on_attach(client, buffer)
      end,
    }
  else
    nvim_lsp['jedi_language_server'].setup {
      capabilities = capabilities,
      on_attach = on_attach,
    }
  end

  local rust_analyzer = 'rust-analyzer'
  if vim.fn.executable('rust-analyzer-x86_64-pc-windows-msvc') == 1 then
    rust_analyzer = 'rust-analyzer-x86_64-pc-windows-msvc'
  end

  nvim_lsp['rust_analyzer'].setup {
    capabilities = capabilities,
    on_attach = on_attach,
    cmd = { rust_analyzer },
  }

  -- Setup PowerShell Editor Extensions
  local bundle_path = vim.env.DEV_HOME .. '/.ls/PowerShellEditorServices'

  nvim_lsp['powershell_es'].setup {
    capabilities = capabilities,
    on_attach = on_attach,
    bundle_path = bundle_path,
  }

  nvim_lsp['sumneko_lua'].setup {
    settings = {
      Lua = {
        runtime = {
          -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
          version = 'LuaJIT',
        },
        diagnostics = {
          -- Get the language server to recognize the `vim` global
          globals = { 'vim' },
        },
        workspace = {
          -- Make the server aware of Neovim runtime files
          library = vim.api.nvim_get_runtime_file("", true),
        },
        -- Do not send telemetry data containing a randomized but unique identifier
        telemetry = {
          enable = false,
        },
      },
    },
    cmd = { vim.env.DEV_HOME .. '/.ls/lua-language-server/bin/lua-language-server' },
    capabilities = capabilities,
    on_attach = on_attach,
  }

  nvim_lsp['zls'].setup {
    cmd = { vim.env.DEV_HOME .. '/.ls/zigtools-zls/bin/zls' },
    capabilities = capabilities,
    on_attach = on_attach,
  }

  -- Setup OmniSharp
  local omnisharp = vim.env.DEV_HOME .. '/.ls/omnisharp/OmniSharp.exe'

  nvim_lsp['omnisharp'].setup {
    handlers = {
      ["textDocument/definition"] = require('omnisharp_extended').handler,
    },
    capabilities = capabilities,
    on_attach = on_attach,
    cmd = { omnisharp, "--languageserver", "--hostPID", tostring(pid),
      "formattingOptions:EnableEditorConfigSupport=true" }
  }

  -- Setup null-ls
  local null_ls = require("null-ls")

  null_ls.setup({
    sources = {
      null_ls.builtins.formatting.black,
      null_ls.builtins.diagnostics.flake8,
      -- null_ls.builtins.diagnostics.pylint,
    },
  })

end

return M
