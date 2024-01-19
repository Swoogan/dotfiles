local M = {
}

M.spec = {
  { "EdenEast/nightfox.nvim" }, -- theme
  { "neovim/nvim-lspconfig" },  -- Easy configuration of LSP
  {
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPost", "BufNewFile" },
    build = ":TSUpdate",
    dependencies = { "nvim-treesitter/nvim-treesitter-textobjects" }, -- Additional textobjects for treesitter
    opts = {
      ensure_installed = {
        "c",
        "c_sharp",
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
        "typescript",
        "vimdoc",
        "zig",
      },
      auto_install = false,
    },
    -- Treesitter configuration
    config = function()
      require('nvim-treesitter.configs').setup {
        highlight = {
          enable = true, -- false will disable the whole extension
        },
        incremental_selection = {
          enable = false,
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
  },                                                                                                  -- incremental language parser
  { "jose-elias-alvarez/null-ls.nvim",   dependencies = { "nvim-lua/plenary.nvim" }, ft = "python" }, -- Easy configuration of LSP
  { "Hoffs/omnisharp-extended-lsp.nvim", lazy = true },

  -- DAP (set lazy to true on dap-ui to not load anything, aka disable dap until I have a workflow established)
  { "rcarriga/nvim-dap-ui",              dependencies = { "mfussenegger/nvim-dap" }, lazy = true },
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
    end,
  },
  { "mfussenegger/nvim-dap-python", ft = "python", dependencies = { "mfussenegger/nvim-dap" } },

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
        mapping = cmp.mapping.preset.insert({
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-e>'] = cmp.mapping.abort(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
        }),
        sources = cmp.config.sources(
          {
            { name = 'nvim_lsp' },
            { name = 'luasnip' },
          }, {
            { name = 'buffer' },
          }
        ),
        -- Todo: switch to debounce time instead?
        completion = { keyword_length = 2 }
      })

      -- Set configuration for Python.
      cmp.setup.filetype('python', {
        sources = cmp.config.sources(
          {
            {
              name = 'nvim_lsp',
              entry_filter = function(entry, ctx)
                local match = string.match(entry:get_word(), '__(%w+)__')
                return match == nil
              end
            },
            { name = 'luasnip' },
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

      telescope.setup {
        defaults = {
          file_ignore_patterns = { "__pycache__" },
          -- path_display = { shorten = { len = 1, exclude = { -1, -2 } } }
          path_display = { "truncate" }
        },
      }

      -- Add shortcuts
      local opts = { noremap = true, silent = true }

      vim.keymap.set('n', '<leader><space>', builtin.buffers, opts)
      vim.keymap.set('n', '<leader>sf', function() builtin.find_files({ previewer = false }) end,
        opts)
      vim.keymap.set('n', '<leader>sb', builtin.current_buffer_fuzzy_find, opts)
      vim.keymap.set('n', '<leader>sh', builtin.help_tags, opts)
      vim.keymap.set('n', '<leader>sg', builtin.live_grep, opts)
      vim.keymap.set('n', '<leader>sd', builtin.grep_string, opts)
      vim.keymap.set('n', '<leader>sc', builtin.command_history, opts)
      vim.keymap.set('n', '<leader>ss', builtin.search_history, opts)
      -- vim.keymap.set('n', '<leader>so', builtin.oldfiles, opts)
      vim.keymap.set('n', '<leader>sm', builtin.marks, opts)
      vim.keymap.set('n', '<leader>sr', builtin.resume, opts)
      vim.keymap.set('n', '<leader>sv',
        function() telescope.setup { defaults = { layout_strategy = 'vertical', }, } end,
        opts
      )
      vim.keymap.set('n', '<leader>sz',
        function() telescope.setup { defaults = { layout_strategy = 'horizontal', }, } end,
        opts
      )
    end
  },

  {
    "prettier/vim-prettier",
    ft = { "javascript", "typescript" },
    config = function()
      vim.g['prettier#autoformat'] = 1
      vim.g['prettier#autoformat_require_pragma'] = 0
    end
  },                               -- Autoformatting
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
      vim.api.nvim_exec([[ let g:sandwich#recipes = deepcopy(g:sandwich#default_recipes) ]], false)
    end
  },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    event = "VeryLazy",
    config = function()
      require('lualine').setup {
        options = { theme = "nightfox" }
      }
    end
  }, -- Fancier statusline
  {
    "L3MON4D3/LuaSnip",
    event = "InsertEnter",
    dependencies = {
      "saadparwaiz1/cmp_luasnip",    -- luasnip to nvim-cmp integration
      "rafamadriz/friendly-snippets" -- Premade snippets
    },
    config = function()
      require('config.snippets').setup()
    end
  }, -- Snippets plugin,
  { "AndrewRadev/tagalong.vim",     ft = "html" },
}

function M.init()
  -- Install lazy.nvim if necessary

  local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
  if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
      "git",
      "clone",
      "--filter=blob:none",
      "https://github.com/folke/lazy.nvim.git",
      "--branch=stable", -- latest stable release
      lazypath,
    })
  end
  vim.opt.rtp:prepend(lazypath)
end

---Loads packer spec defined above and applies the lockfile if it should apply
function M.load()
  require("lazy").setup({
    spec = M.spec,
    performance = {
      rtp = {
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
