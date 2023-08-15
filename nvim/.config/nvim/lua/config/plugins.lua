local M = {
}

M.setup = function()
  -- Setup nvim-cmp.
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
    sources = cmp.config.sources({
      { name = 'nvim_lsp' },
      { name = 'luasnip' },
    }, {
      { name = 'buffer' },
    }),
    completion = { keyword_length = 3 }
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

  --Set statusbar
  require('lualine').setup {
    options = {
      -- ... your lualine config
      theme = "nightfox"
    }
  }

  -- Setup telescope
  require('telescope').setup{
    defaults = { file_ignore_patterns = {"__pycache__"} }
  }

  -- Treesitter configuration
  -- Parsers must be installed manually via :TSInstall
  require('nvim-treesitter.configs').setup {
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
        },
      },
      move = {
        enable = true,
        set_jumps = true, -- whether to set jumps in the jumplist
        goto_next_start = {
          [']]'] = '@class.outer',
          [']m'] = '@function.outer',
          [']a'] = '@parameter.inner',
        },
        goto_previous_start = {
          ['[['] = '@class.outer',
          ['[m'] = '@function.outer',
          ['[a'] = '@parameter.inner',
        },
        goto_next_end = {
          [']}'] = '@class.outer',
          [']M'] = '@function.outer',
          [']A'] = '@parameter.outer',
        },
        goto_previous_end = {
          ['[{'] = '@class.outer',
          ['[M'] = '@function.outer',
          ['[A'] = '@parameter.outer',
        },
      },
    },
    playground = {
      enable = false,
      disable = {},
      updatetime = 25, -- Debounced time for highlighting nodes in the playground from source code
      persist_queries = false, -- Whether the query persists across vim sessions
      keybindings = {
        toggle_query_editor = 'o',
        toggle_hl_groups = 'i',
        toggle_injected_languages = 't',
        toggle_anonymous_nodes = 'a',
        toggle_language_display = 'I',
        focus_language = 'f',
        unfocus_language = 'F',
        update = 'R',
        goto_node = '<cr>',
        show_help = '?',
      },
    },
  }

  -- Pretty Icons
  require('nvim-web-devicons').setup {
    -- globally enable default icons (default to false)
    -- will get overriden by `get_icons` option
    default = true;
  }

  -- Add: Press sa{motion/textobject}{addition}. For example, a key sequence saiw( makes foo to (foo).
  -- Delete: Press sdb or sd{deletion}. For example, key sequences sdb or sd( makes (foo) to foo. sdb searches a set of surrounding automatically.
  -- Replace: Press srb{addition} or sr{deletion}{addition}. For example, key sequences srb" or sr(" makes (foo) to "foo".
  vim.api.nvim_exec([[ let g:sandwich#recipes = deepcopy(g:sandwich#default_recipes) ]], false)

  -- Prettier
  vim.g['prettier#autoformat'] = 1
  vim.g['prettier#autoformat_require_pragma'] = 0
end

return M
