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
      -- Todo move the file_ignore_patterns to local config
      require('telescope.builtin').lsp_references({ path_display = { "tail" }, file_ignore_patterns = { "%.gen.h", "%.gen.cpp" } })
    end, bufopts)
    vim.keymap.set('n', 'gt', require('telescope.builtin').lsp_type_definitions, bufopts)

    vim.keymap.set('n', '<leader>lh', function()
      vim.lsp.buf.hover({ border = 'rounded' })
    end, bufopts)
    vim.keymap.set('n', '<leader>ls', function()
      vim.lsp.buf.signature_help({ border = 'rounded' })
    end, bufopts)
    vim.keymap.set('n', '<leader>lf', opts.code_format, bufopts)
    if client:supports_method('textDocument/rename') then
      vim.keymap.set('n', '<leader>lr', vim.lsp.buf.rename, bufopts)
    end
    vim.keymap.set('n', '<leader>li', require('telescope.builtin').lsp_implementations, bufopts)
    if client:supports_method('textDocument/codeAction') then
      vim.keymap.set({ 'n', 'v' }, '<leader>lc', vim.lsp.buf.code_action, bufopts)
    end

    vim.keymap.set('n', '<leader>sy', function()
      require('telescope.builtin').lsp_document_symbols({ ignore_symbols = { 'variable', 'method', 'constant' } })
    end, bufopts)
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
  local servers = { 'ty' }
  for _, lsp in ipairs(servers) do
    if vim.fn.executable(lsp) == 1 then
      vim.lsp.config(lsp, {
        capabilities = capabilities,
        on_attach = on_attach,
      })
      vim.lsp.enable(lsp)
    end
  end

  -- Clangd
  local function run_clang_format()
    local clang_format = 'clang-format'
    if vim.fn.executable(vim.env.CLANG_FORMAT or "") == 1 then
      clang_format = vim.env.CLANG_FORMAT
    end

    local bufnr = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local original_text = table.concat(lines, '\n')

    local assume_file = "--assume-filename=" .. vim.fn.expand("%:p")
    local cmd = vim.system({ clang_format, assume_file }, { stdin = true }, function(obj)
      -- replace the buffer content with the command results
      if obj.code == 0 then
        vim.schedule(function()
          local formatted_text = obj.stdout
          if formatted_text and formatted_text ~= original_text then
            local text_edit = {
              range = {
                start = { line = 0, character = 0 },
                ['end'] = {
                  line = #lines - 1,
                  character = -1
                }
              },
              newText = formatted_text
            }

            vim.lsp.util.apply_text_edits({ text_edit }, bufnr, 'utf-8')
          end
        end)
      end
    end)
    cmd:write(original_text)
    cmd:write(nil)
  end

  local function switch_source_header(bufnr, client)
    local method_name = 'textDocument/switchSourceHeader'
    ---@diagnostic disable-next-line:param-type-mismatch
    if not client or not client:supports_method(method_name) then
      return vim.notify(('method %s is not supported by any servers active on the current buffer'):format(
        method_name))
    end
    local params = vim.lsp.util.make_text_document_params(bufnr)
    ---@diagnostic disable-next-line:param-type-mismatch
    client:request(method_name, params, function(err, result)
      if err then
        error(tostring(err))
      end
      if not result then
        vim.notify('corresponding file cannot be determined')
        return
      end
      vim.cmd.edit(vim.uri_to_fname(result))
    end, bufnr)
  end

  if vim.fn.executable('clangd') == 1 then
    vim.lsp.config('clangd', {
      capabilities = capabilities,
      on_attach = function(client, bufnr)
        local bufopts = { noremap = true, silent = true, buffer = bufnr }
        vim.api.nvim_buf_create_user_command(bufnr, 'LspClangdSwitchSourceHeader', function()
          switch_source_header(bufnr, client)
        end, { desc = 'Switch between source/header' })

        vim.keymap.set('n', 'gh', function() vim.cmd("LspClangdSwitchSourceHeader") end, bufopts)
        vim.keymap.set('n', '<leader>bb', require("cpp").build_editor, bufopts)

        -- Todo: only set any of this up for work config
        opts.code_format = function()
          local pos = vim.api.nvim_win_get_cursor(0)
          run_clang_format()
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
    })
    vim.lsp.enable('clangd')
  end

  -- Python
  if false and vim.fn.executable('pyright') == 1 then
    local cap = capabilities
    cap.textDocument.publishDiagnostics = { tagSupport = { valueSet = { 2 } } }
    vim.lsp.config('pyright', {
      capabilities = cap,
      on_attach = function(client, bufnr)
        on_attach(client, bufnr)
      end,
      root_dir = function(_, on_dir)
        on_dir(vim.fn.getcwd())
      end,
      settings = {
        python = {
          analysis = {
            typeCheckingMode = "off",
          }
        }
      }
    })
    vim.lsp.enable('pyright')
  end

  if vim.fn.executable('ruff') == 1 then
    vim.lsp.config('ruff', {
      capabilities = {
        general = {
          -- positionEncodings = { "utf-8", "utf-16", "utf-32" }  <--- this is the default
          -- This is a fix because pyright always uses "utf-16" and ruff defaults to "utf-8"
          -- which causes a warning from the LSP api
          positionEncodings = { "utf-16" }
        },
      }
    })
    vim.lsp.enable('ruff')
  end

  -- Rust
  local rust_analyzer = 'rust-analyzer'
  if vim.fn.executable(vim.env.RUST_ANALYZER or "") == 1 then
    rust_analyzer = vim.env.RUST_ANALYZER
  end

  if vim.fn.executable(rust_analyzer) == 1 then
    vim.lsp.config('rust_analyzer', {
      capabilities = capabilities,
      on_attach = on_attach,
      cmd = { rust_analyzer },
    })
    vim.lsp.enable('rust_analyzer')
  end

  -- PowerShell
  local bundle_path = vim.env.DEV_HOME .. '/.ls/PowerShellEditorServices'
  if vim.fn.isdirectory(bundle_path) == 1 then
    -- Setup PowerShell Editor Extensions
    vim.lsp.config('powershell_es', {
      capabilities = capabilities,
      on_attach = function(client, bufnr)
        on_attach(client, bufnr)
        -- for some reason powershell_es says it doesn't support code actions, when it does
        local bufopts = { noremap = true, silent = true, buffer = bufnr }
        vim.keymap.set({ 'n', 'v' }, '<leader>lc', vim.lsp.buf.code_action, bufopts)
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
    vim.lsp.enable('powershell_es')
  end

  -- Lua
  local lua_language_server = vim.env.DEV_HOME .. '/.ls/lua-language-server/bin/lua-language-server'
  if vim.fn.executable(lua_language_server) == 1 then
    vim.lsp.config('lua_ls', {
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
    vim.lsp.enable('lua_ls')
  end

  -- Zig
  local zls = vim.env.DEV_HOME .. '/.ls/zigtools-zls/bin/zls'
  if vim.fn.executable(zls) == 1 then
    vim.lsp.config('zls', {
      cmd = { zls },
      capabilities = capabilities,
      on_attach = on_attach,
    })
    vim.lsp.enable('zls')
  end

  -- Typescript
  if vim.fn.executable('typescript-language-server') == 1 then
    vim.lsp.config('ts_ls', {
      capabilities = capabilities,
      on_attach = on_attach,
    })
    vim.lsp.enable('ts_ls')
  end

  -- C#
  local omnisharp = vim.env.DEV_HOME .. '/.ls/omnisharp/OmniSharp.exe'
  if vim.fn.executable(omnisharp) == 1 then
    vim.lsp.config('omnisharp', {
      handlers = {
        ["textDocument/definition"] = require('omnisharp_extended').handler,
      },
      capabilities = capabilities,
      on_attach = on_attach,
      cmd = { omnisharp, "--languageserver", "--hostPID", tostring(pid),
        "formattingOptions:EnableEditorConfigSupport=true" }
    })
    vim.lsp.enable('omnisharp')
  end
end

return M
