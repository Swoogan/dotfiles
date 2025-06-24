local M = {
}

M.setup = function(opts)
  opts = opts or {
    code_format = function() vim.lsp.buf.format({ async = true }) end
  }

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
      source = true, -- Or "if_many"
    },
  })

  vim.api.nvim_create_autocmd('LspAttach', {
    pattern = "*.py",
    callback = function(_)
      vim.diagnostic.config({
        virtual_text = {
          source = false,
          prefix = '',
          format = function(diagnostic)
            return string.format("%s (%s) %s", diagnostic.source, diagnostic.code, diagnostic.message)
          end
        },
        severity_sort = true,
        float = {
          source = true, -- Or "if_many"
        },
      })
    end,
  })

  local on_attach = function(client, bufnr)
    -- Mappings
    local bufopts = { noremap = true, silent = true, buffer = bufnr }
    if client:supports_method('textDocument/declaration') then
      vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
    end
    vim.keymap.set('n', 'gd', function()
      vim.lsp.buf.definition({ on_list = require('reference_win').on_list })
    end, bufopts)
    vim.keymap.set('n', 'gi', require('telescope.builtin').lsp_incoming_calls, bufopts)
    vim.keymap.set('n', 'go', require('telescope.builtin').lsp_outgoing_calls, bufopts)
    vim.keymap.set('n', 'gr', function()
      vim.cmd.normal("m'")
      require('telescope.builtin').lsp_references({ path_display = { "tail" } })
    end, bufopts)
    vim.keymap.set('n', 'gt', require('telescope.builtin').lsp_type_definitions, bufopts)

    vim.keymap.set('n', '<leader>lh', vim.lsp.buf.hover, bufopts)
    vim.keymap.set('n', '<leader>ls', vim.lsp.buf.signature_help, bufopts)
    vim.keymap.set('n', '<leader>lf', opts.code_format, bufopts)
    if client:supports_method('textDocument/rename') then
      vim.keymap.set('n', '<leader>lr', vim.lsp.buf.rename, bufopts)
    end
    vim.keymap.set('n', '<leader>li', require('telescope.builtin').lsp_implementations, bufopts)
    if client:supports_method('textDocument/codeAction') then
      vim.keymap.set({ 'n', 'v' }, '<leader>lc', vim.lsp.buf.code_action, bufopts)
    end
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

  local function run_clang_format(contents)
    local clang_format = 'clang-format'
    if vim.fn.executable(vim.env.CLANG_FORMAT or "") == 1 then
      clang_format = vim.env.CLANG_FORMAT
    end
    local assume_file = "--assume-filename=" .. vim.fn.expand("%:p")
    local cmd = vim.system({ clang_format, assume_file }, { stdin = true }, function(obj)
      -- replace the buffer content with the command results
      if obj.code == 0 then
        vim.schedule(function()
          local new_text = vim.split(obj.stdout, '\n')
          vim.api.nvim_buf_set_lines(0, 0, -1, false, new_text)
        end)
      end
    end)
    cmd:write(contents)
    cmd:write(nil)
  end

  -- Use a loop to conveniently call 'setup' on multiple servers and
  -- map buffer local keybindings when the language server attaches
  -- local servers = { "ts_ls", "clangd" }
  local servers = { "ts_ls" }
  for _, lsp in ipairs(servers) do
    nvim_lsp[lsp].setup {
      capabilities = capabilities,
      on_attach = on_attach,
    }
  end

  if vim.fn.executable('clangd') == 1 then
    nvim_lsp['clangd'].setup {
      capabilities = capabilities,
      on_attach = function(client, bufnr)
        local bufopts = { noremap = true, silent = true, buffer = bufnr }
        vim.keymap.set('n', 'gh', function() vim.cmd("ClangdSwitchSourceHeader") end, bufopts)
        vim.keymap.set('n', '<leader>bb', require("cpp").build_editor, bufopts)

        -- Todo: only set any of this up for work config
        opts.code_format = function()
          local pos = vim.api.nvim_win_get_cursor(0)

          -- Get the current buffer data
          local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
          local contents = table.concat(lines, '\n')
          run_clang_format(contents)

          vim.api.nvim_win_set_cursor(0, pos)
        end
        on_attach(client, bufnr)
      end,
      cmd = {
        "clangd",
        "--background-index",
        "--background-index-priority=low",
        "--clang-tidy",
      },
    }
  end

  -- Python
  if vim.fn.executable('pyright') == 1 then
    local cap = capabilities
    cap.textDocument.publishDiagnostics = { tagSupport = { valueSet = { 2 } } }
    nvim_lsp['pyright'].setup {
      capabilities = cap,
      on_attach = function(client, bufnr)
        -- client.handlers["textDocument/publishDiagnostics"] = function(...) end
        on_attach(client, bufnr)
      end,
      root_dir = function()
        -- This is a hack because pyright is dog slow otherwise
        return vim.fn.getcwd()
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

  if vim.fn.executable('ruff') == 1 then
    nvim_lsp['ruff'].setup({})
  end

  -- local pylyzer = vim.env.DEV_HOME .. '/.ls/pylyzer.exe'
  if false and vim.fn.executable('pylyzer') == 1 then
    nvim_lsp['pylyzer'].setup({
      capabilities = capabilities,
      on_attach = on_attach,
    })
  end

  if false and vim.fn.executable('pylsp') == 1 then
    nvim_lsp['pylsp'].setup({
      capabilities = capabilities,
      on_attach = on_attach,
      settings = {
        pylsp = {
          configurationSources = { "flake8" },
          plugins = {
            jedi_completion = { enabled = true },
            jedi_hover = { enabled = true },
            jedi_references = { enabled = true },
            jedi_signature_help = { enabled = true },
            jedi_symbols = { enabled = true, all_scopes = true },
            flake8 = {
              enabled = true,
              -- maxLineLength = 160
            },
            ruff = { enabled = true },
            black = { enabled = true },
            pycodestyle = { enabled = false },
            mypy = { enabled = false },
            isort = { enabled = false },
            yapf = { enabled = false },
            pylint = { enabled = false },
            pydocstyle = { enabled = false },
            mccabe = { enabled = false },
            preload = { enabled = false },
            rope_completion = { enabled = false }
          }
        }
      }
    })
  end

  if false and vim.fn.executable('jedi_language_server') == 1 then
    nvim_lsp['jedi_language_server'].setup({
      capabilities = capabilities,
      on_attach = function(client, buffer)
        client.server_capabilities.documentFormattingProvider = false
        client.server_capabilities.hoverProvider = false
        client.server_capabilities.renameProvider = false
        on_attach(client, buffer)
      end,
    })
  end

  -- Rust
  local rust_analyzer = 'rust-analyzer'
  if vim.fn.executable(vim.env.RUST_ANALYZER or "") == 1 then
    rust_analyzer = vim.env.RUST_ANALYZER
  end

  if vim.fn.executable(rust_analyzer) == 1 then
    nvim_lsp['rust_analyzer'].setup({
      capabilities = capabilities,
      on_attach = on_attach,
      cmd = { rust_analyzer },
    })
  end

  -- PowerShell
  local bundle_path = vim.env.DEV_HOME .. '/.ls/PowerShellEditorServices'
  if vim.fn.isdirectory(bundle_path) == 1 then
    -- Setup PowerShell Editor Extensions
    nvim_lsp['powershell_es'].setup({
      capabilities = capabilities,
      on_attach = function(client, bufnr)
        on_attach(client, bufnr)
        -- for some reason powershell_es says it doesn't support code actions, when it does
        local bufopts = { noremap = true, silent = true, buffer = bufnr }
        vim.keymap.set('n', '<leader>lc', vim.lsp.buf.code_action, bufopts)
      end,
      bundle_path = bundle_path,
      settings = {
        powershell = {
          codeFormatting = {
            -- preset = 'OTBS',
            preset = 'Stroustrup',
            addWhitespaceAroundPipe = true,
            -- autoCorrectAliases = true,
            avoidSemicolonsAsLineTerminators = true,
            useConstantStrings = true,
            pipelineIndentationStyle = 'IncreaseIndentationForFirstPipeline',
            trimWhitespaceAroundPipe = true,
            whitespaceBeforeOpenBrace = false,
            whitespaceBeforeOpenParen = false,
            whitespaceAroundOperator = true,
            whitespaceAfterSeparator = true,
            whitespaceBetweenParameters = true,
            whitespaceInsideBrace = false,
            ignoreOneLineBlock = true,
            alignPropertyValuePairs = true,
            useCorrectCasing = false,
          }
        }
      },
    })
  end

  -- Lua
  local lua_language_server = vim.env.DEV_HOME .. '/.ls/lua-language-server/bin/lua-language-server'
  if vim.fn.executable(lua_language_server) == 1 then
    nvim_lsp['lua_ls'].setup({
      on_init = function(client)
        if client.workspace_folders then
          local path = client.workspace_folders[1].name
          if
              path ~= vim.fn.stdpath('config')
              and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc'))
          then
            return
          end
        end
        client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
          runtime = {
            -- Tell the language server which version of Lua you're using (most
            -- likely LuaJIT in the case of Neovim)
            version = 'LuaJIT',
            -- Tell the language server how to find Lua modules same way as Neovim
            -- (see `:h lua-module-load`)
            path = {
              'lua/?.lua',
              'lua/?/init.lua',
            },
          },
          -- Make the server aware of Neovim runtime files
          workspace = {
            checkThirdParty = false,
            library = {
              vim.env.VIMRUNTIME
              -- Depending on the usage, you might want to add additional paths
              -- here.
              -- '${3rd}/luv/library'
              -- '${3rd}/busted/library'
            }
          }
        })
      end,
      settings = {
        Lua = {}
      },
      cmd = { lua_language_server },
      capabilities = capabilities,
      on_attach = on_attach,
    })
  end

  -- Zig
  local zls = vim.env.DEV_HOME .. '/.ls/zigtools-zls/bin/zls'
  if vim.fn.executable(zls) == 1 then
    nvim_lsp['zls'].setup({
      cmd = { zls },
      capabilities = capabilities,
      on_attach = on_attach,
    })
  end

  -- C#
  local omnisharp = vim.env.DEV_HOME .. '/.ls/omnisharp/OmniSharp.exe'
  if vim.fn.executable(omnisharp) == 1 then
    nvim_lsp['omnisharp'].setup({
      handlers = {
        ["textDocument/definition"] = require('omnisharp_extended').handler,
      },
      capabilities = capabilities,
      on_attach = on_attach,
      cmd = { omnisharp, "--languageserver", "--hostPID", tostring(pid),
        "formattingOptions:EnableEditorConfigSupport=true" }
    })
  end
end

return M
