local M = {
}

M.spec = {
  { "EdenEast/nightfox.nvim" },    -- theme
  { "neovim/nvim-lspconfig" },     -- Easy configuration of LSP
  { "equalsraf/neovim-gui-shim" }, -- gui shim for nvim-qt
  { "neovim/nvim-lspconfig" },     -- lsp configurations
  {
    "nvim-treesitter/nvim-treesitter",
    branch = 'master',
    lazy = false,
    build = ":TSUpdate",
    dependencies = { "nvim-treesitter/nvim-treesitter-textobjects" }, -- Additional textobjects for treesitter
    -- Treesitter configuration
    config = function()
      require('nvim-treesitter.configs').setup {
        ensure_installed = {
          "c",
          "c_sharp",
          "css",
          "go",
          "html",
          "javascript",
          "json",
          "lua",
          "markdown",
          "markdown_inline",
          "python",
          "query",
          "regex",
          "rust",
          "tsx",
          "typescript",
          "vimdoc",
          "zig",
        },
        highlight = {
          enable = true, -- false will disable the whole extension
        },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = 'gnn',
            scope_incremental = 'grc',
            node_incremental = 'grn',
            node_decremental = 'grm',
          },
        },
        indent = {
          enable = true,
        },
        textobjects = {
          select = {
            enable = true,
            lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
            keymaps = {
              -- You can use the capture groups defined in textobjects.scm
              ['ac'] = '@class.outer',
              ['ic'] = '@class.inner',
              ['af'] = '@function.outer',
              ['if'] = '@function.inner',
              ["ia"] = "@parameter.inner",
              ["aa"] = "@parameter.outer",
              ['ab'] = '@block.outer',
              ['ib'] = '@block.inner',
            },
            selection_modes = {
              ['@block.outer'] = 'V',    -- linewise
              ['@function.outer'] = 'V', -- linewise
            },
          },
          move = {
            enable = true,
            set_jumps = true, -- whether to set jumps in the jumplist
            goto_next_start = {
              [']]'] = '@class.outer',
              [']m'] = '@function.outer',
              [']a'] = '@parameter.inner',
              [']b'] = '@block.outer',
            },
            goto_previous_start = {
              ['[['] = '@class.outer',
              ['[m'] = '@function.outer',
              ['[a'] = '@parameter.inner',
              ['[b'] = '@block.outer',
            },
            goto_next_end = {
              [']['] = '@class.outer',
              [']M'] = '@function.outer',
              [']A'] = '@parameter.outer',
            },
            goto_previous_end = {
              ['[]'] = '@class.outer',
              ['[M'] = '@function.outer',
              ['[A'] = '@parameter.outer',
            },
          },
        },
      }
    end
  }, -- incremental language parser
  { "Hoffs/omnisharp-extended-lsp.nvim", lazy = true },

  -- DAP
  {
    "mfussenegger/nvim-dap",
    dependencies = { "theHamsta/nvim-dap-virtual-text" },
    lazy = true,
    config = function()
      -- hotkeys
      local dap = require('dap')
      local opts = { noremap = true, silent = true }
      vim.keymap.set('n', '<leader>db', dap.toggle_breakpoint, opts)
      vim.keymap.set('n', '<leader>dc', dap.continue, opts)
      vim.keymap.set('n', '<leader>do', dap.step_over, opts)
      vim.keymap.set('n', '<leader>di', dap.step_into, opts)
      vim.keymap.set('n', '<leader>de', dap.close, opts)
      vim.keymap.set('n', '<leader>dro', dap.repl.open, opts)
      vim.keymap.set('n', '<leader>drc', dap.repl.close, opts)

      vim.fn.sign_define('DapBreakpoint', { text = '🛑', texthl = '', linehl = '', numhl = '' })
      vim.fn.sign_define('DapBreakpointRejected', { text = '⛔', texthl = '', linehl = '', numhl = '' })

      -- dap virtual text
      require('nvim-dap-virtual-text').setup {
        enabled_commands = true,            -- create commands DapVirtualTextEnable, DapVirtualTextDisable, DapVirtualTextToggle, (DapVirtualTextForceRefresh for refreshing when debug adapter did not notify its termination)
        highlight_changed_variables = true, -- highlight changed values with NvimDapVirtualTextChanged, else always NvimDapVirtualText
        highlight_new_as_changed = false,   -- highlight new variables in the same way as changed variables (if highlight_changed_variables)
        show_stop_reason = true,            -- show stop reason when stopped for exceptions
        commented = false,                  -- prefix virtual text with comment string
      }
      -- adds loading of .vscode/launch.json files
      -- require('dap.ext.vscode').load_launchjs()
    end,
  },
  {
    "mfussenegger/nvim-dap-python",
    ft = "python",
    dependencies = { "mfussenegger/nvim-dap" },
    lazy = true,
    config = function()
      require('dap-python').setup()
    end
  },
  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
    lazy = true,
    config = function()
      require("dapui").setup()
    end
  },

  {
    "hrsh7th/nvim-cmp", -- Autocomplete
    event = "InsertEnter",
    -- these dependencies will only be loaded when cmp loads
    -- dependencies are always lazy-loaded unless specified otherwise
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
    },
    config = function()
      local cmp = require('cmp')

      cmp.setup({
        snippet = {
          expand = function(args)
            require('luasnip').lsp_expand(args.body)
          end,
        },
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-y>'] = cmp.mapping.select_prev_item({ count = -4 }),
          ['<C-e>'] = cmp.mapping.select_next_item({ count = 4 }),
          ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
          ['<Tab>'] = cmp.mapping.confirm({ select = true, behavior = cmp.ConfirmBehavior.Replace }),
        }),
        -- Mostly just for debugging
        -- formatting = {
        --   format = function(entry, item)
        --     item.menu = entry.source.name
        --     return item
        --   end,
        -- },
        sources = cmp.config.sources(
          {
            { name = 'nvim_lsp' },
            { name = 'luasnip' },
            { name = 'path' },
          }, {
            { name = 'buffer' },
          }
        ),
        -- defaults
        -- sorting = {
        --   comparators = {
        --     cmp.offset,
        --     cmp.exact,
        --     cmp.score,
        --     cmp.recently_used,
        --     cmp.locality,
        --     cmp.kind,
        --     cmp.sort_text,
        --     cmp.length,
        --     cmp.order,
        --   },
        -- },
        -- performance = { debounce = 250 }
      })


      -- Set configuration for CPP.
      cmp.setup.filetype('cpp', {
        matching = {
          disallow_fuzzy_matching = true,
        },
        sources = cmp.config.sources(
          {
            {
              name = 'nvim_lsp',
              entry_filter = function(entry)
                return not vim.startswith(entry:get_word(), 'std::')
              end
            },
            { name = 'luasnip' },
            { name = 'path' },
          },
          {
            { name = 'buffer' },
          }
        )
      })

      -- Set configuration for Python.
      cmp.setup.filetype('python', {
        sources = cmp.config.sources(
          {
            {
              name = 'nvim_lsp',
              entry_filter = function(entry, _)
                local match = string.match(entry:get_word(), '__(%w+)__')
                return match == nil
              end
            },
            { name = 'luasnip' },
            { name = 'path' },
          },
          {
            { name = 'buffer' },
          }
        )
      })

      -- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
      cmp.setup.cmdline('/', {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = 'buffer' }
        }
      })
      cmp.setup.cmdline('?', {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = 'buffer' }
        }
      })

      -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
      cmp.setup.cmdline(':', {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = 'path' }
        }, {
          { name = 'cmdline' }
        })
      })
    end
  },
  {
    "nvim-telescope/telescope.nvim", -- Fuzzy finder
    keys = { "<leader>s" },
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local telescope = require("telescope")
      local builtin = require("telescope.builtin")
      local actions = require("telescope.actions")

      telescope.setup {
        defaults = {
          file_ignore_patterns = { "__pycache__" },
          path_display = { "truncate" },
          mappings = {
            n = {
              ['<a-d>'] = actions.delete_buffer
            },
            i = {
              ["<CR>"] = actions.select_default + actions.center
            }
          }
        },
        pickers = {
          find_files = {
            find_command = { "fd", "--type", "f", "--color", "never" }
          }
        }
      }

      -- Add shortcuts
      local opts = { noremap = true, silent = true }

      vim.keymap.set('n', '<leader><space>', builtin.buffers, opts)
      vim.keymap.set('n', '<leader>sf', function() builtin.find_files({ previewer = false }) end, opts)
      vim.keymap.set('n', '<leader>sh', builtin.help_tags, opts)
      vim.keymap.set('n', '<leader>sg', builtin.live_grep, opts)
      vim.keymap.set('n', '<leader>sb',
        function() builtin.live_grep({ prompt_title = "Find in Buffers", grep_open_files = true }) end, opts
      )
      vim.keymap.set('n', '<leader>ss', builtin.grep_string, opts)
      vim.keymap.set('n', '<leader>sd', builtin.diagnostics, opts)
      vim.keymap.set('n', '<leader>so', builtin.oldfiles, opts)
      vim.keymap.set('n', '<leader>sr', builtin.resume, opts)

      -- Deprecating as I never use these
      -- vim.keymap.set('n', '<leader>sb', builtin.current_buffer_fuzzy_find, opts)
      -- vim.keymap.set('n', '<leader>sc', builtin.command_history, opts)
      -- vim.keymap.set('n', '<leader>ss', builtin.search_history, opts)
      -- vim.keymap.set('n', '<leader>sm', builtin.marks, opts)
      -- vim.keymap.set('n', '<leader>sv',
      --   function() telescope.setup { defaults = { layout_strategy = 'vertical', }, } end,
      --   opts
      -- )
      -- vim.keymap.set('n', '<leader>sz',
      --   function() telescope.setup { defaults = { layout_strategy = 'horizontal', }, } end,
      --   opts
      -- )
    end
  },
  {
    'stevearc/conform.nvim',
    opts = {},
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          -- Conform will run the first available formatter
          javascript = { "prettierd", "prettier", stop_after_first = true },
        },
        format_on_save = {
          timeout_ms = 500,
          lsp_format = "fallback",
        },
      })
    end
  },
  {
    "nvim-tree/nvim-web-devicons", -- Pretty Icons
    lazy = true,
    config = function()
      require('nvim-web-devicons').setup {
        -- globally enable default icons (default to false)
        -- will get overriden by `get_icons` option
        default = true,
      }
    end
  },
  {
    "nvim-tree/nvim-tree.lua", -- Filesystem viewer
    cmd = { "NvimTreeToggle", "NvimTreeFindFile" },
    version = "*",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("nvim-tree").setup({})
    end,
  },

  -- Comment stuff out.  gcc to comment out a line, gcb to block comment.
  {
    "numToStr/Comment.nvim",
    keys = { "gc", { "gc", mode = "v" } },
    config = function()
      require("Comment").setup({})
    end,
  },

  {
    "machakann/vim-sandwich", -- add, delete, replace pairs (like {}, (), "")
    keys = { "s" },
    config = function()
      -- Add: Press sa{motion/textobject}{addition}. For example, a key sequence saiw( makes foo to (foo).
      -- Delete: Press sdb or sd{deletion}. For example, key sequences sdb or sd( makes (foo) to foo. sdb searches a set of surrounding automatically.
      -- Replace: Press srb{addition} or sr{deletion}{addition}. For example, key sequences srb" or sr(" makes (foo) to "foo".
      vim.cmd([[ let g:sandwich#recipes = deepcopy(g:sandwich#default_recipes) ]])
    end
  },
  { -- Fancier statusline
    "nvim-lualine/lualine.nvim",
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    event = "VeryLazy",
    config = function()
      require('lualine').setup {
        options = { theme = "nightfox" }
      }
    end
  },
  { -- Snippets plugin
    "L3MON4D3/LuaSnip",
    event = "InsertEnter",
    dependencies = {
      "saadparwaiz1/cmp_luasnip",    -- luasnip to nvim-cmp integration
      "rafamadriz/friendly-snippets" -- Premade snippets
    },
    config = function()
      require("luasnip").config.setup({ store_selection_keys = "<Tab>" })
      -- require("luasnip").filetype_extend("python", { "pydoc" })
      -- require("luasnip").filetype_extend("cs", { "csharpdoc" })
      -- require("luasnip").filetype_extend("typescript", { "javascript" })
      -- require("luasnip").filetype_extend("typescriptreact", { "typescript", "javascript" })
      -- Todo: switch to https://github.com/danymat/neogen
      require("luasnip").filetype_extend("rust", { "rustdoc" })
      require 'luasnip'.filetype_extend("cpp", { "cppdoc" })
      require('config.snippets').setup()
    end
  },
  { "AndrewRadev/tagalong.vim",          ft = "html" },
}

--- Bootstrap lazy.nvim
function M.init()
  local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
  if not vim.uv.fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
    if vim.v.shell_error ~= 0 then
      vim.api.nvim_echo({
        { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
        { out,                            "WarningMsg" },
        { "\nPress any key to exit..." },
      }, true, {})
      vim.fn.getchar()
      os.exit(1)
    end
  end
  vim.opt.rtp:prepend(lazypath)
end

--- Setup lazy.nvim
function M.load()
  local home = os.getenv("HOME")

  if require('utils').is_windows() then
    home = os.getenv("USERPROFILE")
  end

  local local_data = string.format("%s/.local/nvim", home)

  require("lazy").setup({
    spec = M.spec,
    performance = {
      rtp = {
        paths = {
          local_data,
        },
        -- disable some rtp plugins
        disabled_plugins = {
          "gzip",
          "man",
          "matchit",
          "matchparen",
          "netrwPlugin",
          "remote_plugins",
          "rplugin",
          "tarPlugin",
          "tohtml",
          "tutor",
          "zip",
          "zipPlugin",
        },
      },
    }
  })
end

return M
