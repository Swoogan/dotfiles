local path = require('core.path')
local Lockfile = require("core.lockfile")

local M = setmetatable({}, {
  __index = function(_, key)
    return require("packer")[key]
  end,
})

M.spec = {
  { "wbthomason/packer.nvim" }, -- Package manager

  { "Swoogan/nightfox.nvim" }, -- theme

  { "neovim/nvim-lspconfig" }, -- Easy configuration of LSP
  { "nvim-treesitter/nvim-treesitter", run = ":TSUpdate" }, -- incremental language parser
  { "nvim-treesitter/nvim-treesitter-textobjects" }, -- Additional textobjects for treesitter
  -- { "nvim-treesitter/playground" },

  { "Hoffs/omnisharp-extended-lsp.nvim" },
  -- { "theHamsta/nvim-dap-virtual-text" },
  -- { "mfussenegger/nvim-dap" },

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

  -- vim.api.nvim_create_augroup("Packer", { clear = true })
  -- vim.api.nvim_create_autocmd({ "BufWritePost" }, {
  --   pattern = "init.lua",
  --   callback = "PackerCompile",
  -- })

  -- Set plugins to the value defined in lockfile
  vim.api.nvim_create_user_command("PackInstall", function()
    Lockfile.should_apply = true
    require("packer").sync()
  end, {})

  vim.api.nvim_create_user_command("PackUpgrade", function()
    Lockfile.should_apply = false
    require("packer").sync()
    require("plugins").set_on_packer_complete(function()
      Lockfile.should_apply = true
      Lockfile:update(M.spec)
    end)
  end, {})

  vim.api.nvim_create_user_command("LockUpdate", function()
    require("plugins").lockfile_update()
  end, {})
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
  if Lockfile.should_apply then
    Lockfile:load()
    for _, spec in ipairs(specs) do
      packer.use(Lockfile:apply(spec))
    end
  else
    for _, spec in ipairs(specs) do
      packer.use(spec)
    end
  end
end

function M.lockfile_update()
  Lockfile:update(M.spec)
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
