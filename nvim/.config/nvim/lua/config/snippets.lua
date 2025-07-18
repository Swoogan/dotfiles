local ls = require('luasnip')
local extras = require("luasnip.extras")

local function snippets()
  -- local s = ls.snippet
  -- local sn = luasnip.snippet_node
  -- local t = ls.text_node
  -- local i = ls.insert_node
  -- local f = ls.function_node
  -- local c = luasnip.choice_node
  -- local d = luasnip.dynamic_node
  -- local rep = extras.rep

  -- ls.add_snippets("cs", {
  --   s("sum", {
  --     t({ "/// <summary>", "/// " }),
  --     i(1),
  --     t({ "", "/// </summary>" }),
  --   }),
  --   s("pra", {
  --     t("<parameter name=\""),
  --     i(2, "name"),
  --     t("\">"),
  --     i(1),
  --     t("</parameter>"),
  --   }),
  --   s({ trig = "try", name = "Try log", dscr = "Try catch, log the exception" }, {
  --     t({ "try", "{", "\t" }),
  --     i(1),
  --     t({ "", "}", "catch (" }),
  --     i(2, "Exception"),
  --     t(" e)"),
  --     t({ "", "{", "\t_logger.LogError(e, \"" }),
  --     i(3),
  --     t({ "\");", "}" }),
  --   }),
  -- })
end

local M = {
}

M.setup = function()
  snippets()
  require('local_config').luasnips()

  vim.keymap.set({ "i", "s" }, "<Tab>", function()
      if require("luasnip").expand_or_jumpable() then
        return "<Plug>luasnip-expand-or-jump"
      else
        return "<Tab>"
      end
    end,
    { expr = true, silent = true })

  vim.keymap.set({ "i", "s" }, "<S-Tab>", function() ls.jump(-1) end, { silent = true })

  vim.keymap.set({ "i", "v" }, "<C-k>", function()
    if ls.expandable() then
      ls.expand()
    end
  end, { silent = true })

  require("luasnip/loaders/from_vscode").lazy_load()
end

return M
