local path = require('core.path')

local M = setmetatable({}, {
    __index = function(_, key)
    return require("packer")[key]
  end,
})

M.spec = {
  { "wbthomason/packer.nvim" }, -- Package manager

  { "EdenEast/nightfox.nvim" }, -- theme

  { "neovim/nvim-lspconfig" }, -- Easy configuration of LSP
  { "nvim-treesitter/nvim-treesitter", run = ":TSUpdate" }, -- incremental language parser
  { "nvim-treesitter/nvim-treesitter-textobjects" }, -- Additional textobjects for treesitter
  -- { "nvim-treesitter/playground" },

  { "jose-elias-alvarez/null-ls.nvim", requires = { "nvim-lua/plenary.nvim" } }, -- Easy configuration of LSP
  { "Hoffs/omnisharp-extended-lsp.nvim" },

  { "mfussenegger/nvim-dap" },
  { "mfussenegger/nvim-dap-python" },
  { "theHamsta/nvim-dap-virtual-text" },
  { "rcarriga/nvim-dap-ui", requires = {"mfussenegger/nvim-dap"} },

  { "hrsh7th/cmp-nvim-lsp" },
  { "hrsh7th/cmp-buffer" },
  { "hrsh7th/cmp-path" },
  { "hrsh7th/cmp-cmdline" },
  { "hrsh7th/nvim-cmp" }, -- Autocomplete

  { "nvim-telescope/telescope.nvim", requires = { "nvim-lua/plenary.nvim" } }, -- Fuzzy finder
  -- { "prettier/vim-prettier" }, -- Run prettier formatting for javascript/typescript
  {
    "kyazdani42/nvim-tree.lua",
    requires = { "kyazdani42/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup({})
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
  -- Install packer
  local install_path = vim.fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"

  if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
    vim.fn.execute("!git clone https://github.com/wbthomason/packer.nvim " .. install_path)
  end
end

---Loads packer spec defined above and applies the lockfile if it should apply
function M.load()
  local packer = require("packer")
  packer.init({
    -- This path needs to be known to the lockfile as this is where it will search installed plugins
    package_root = path.packroot,
  })
  packer.reset()

  local specs = vim.deepcopy(M.spec)
  for _, spec in ipairs(specs) do
    packer.use(spec)
  end
end

function M.set_on_packer_complete(fn, pattern)
  local id = vim.api.nvim_create_augroup("PackOnComplete", { clear = true })
  vim.api.nvim_create_autocmd("User", {
    group = id,
    pattern = pattern or "PackerComplete",
    callback = function()
      M.on_packer_complete(fn)
    end,
  })
end

function M.on_packer_complete(fn)
  vim.api.nvim_del_augroup_by_name("PackOnComplete")
  fn()
end

return M
