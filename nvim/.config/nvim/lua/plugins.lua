local M = {
}

M.spec = {
  { "EdenEast/nightfox.nvim" }, -- theme

  { "neovim/nvim-lspconfig" }, -- Easy configuration of LSP
  {"nvim-treesitter/nvim-treesitter", build = ":TSUpdate"}, -- incremental language parser
  { "nvim-treesitter/nvim-treesitter-textobjects" }, -- Additional textobjects for treesitter
  -- { "nvim-treesitter/playground" },

  { "jose-elias-alvarez/null-ls.nvim", dependencies = { "nvim-lua/plenary.nvim" } }, -- Easy configuration of LSP
  { "Hoffs/omnisharp-extended-lsp.nvim" },

  { "mfussenegger/nvim-dap" },
  { "mfussenegger/nvim-dap-python" },
  { "theHamsta/nvim-dap-virtual-text" },
  { "rcarriga/nvim-dap-ui", dependencies = {"mfussenegger/nvim-dap"} },

  { "hrsh7th/cmp-nvim-lsp" },
  { "hrsh7th/cmp-buffer" },
  { "hrsh7th/cmp-path" },
  { "hrsh7th/cmp-cmdline" },
  { "hrsh7th/nvim-cmp" }, -- Autocomplete

  { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } }, -- Fuzzy finder
  -- { "prettier/vim-prettier" }, -- Run prettier formatting for javascript/typescript
  {
    "nvim-tree/nvim-tree.lua",
    version = "*",
    lazy = false,
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("nvim-tree").setup {}
    end,
  }, -- Filesystem viewer
  { "editorconfig/editorconfig-vim" },

  -- Comment stuff out.  gcc to comment out a line, gcb to block comment.
  {
    "numToStr/Comment.nvim",
    config = function()
      require("Comment").setup({})
    end,
  },

  { "machakann/vim-sandwich" }, -- add, delete, replace pairs (like {}, (), "")
  { "nvim-lualine/lualine.nvim" }, -- Fancier statusline

  --  'tpope/vim-unimpaired'
  -- { "tpope/vim-dispatch" }, -- Async task runner
  { "L3MON4D3/LuaSnip" }, -- Snippets plugin
  { "saadparwaiz1/cmp_luasnip" }, -- luasnip to nvim-cmp integration
  { "rafamadriz/friendly-snippets" }, -- Premade snippets
  -- { "AndrewRadev/tagalong.vim" },
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
  require("lazy").setup(M.spec)
end

return M
