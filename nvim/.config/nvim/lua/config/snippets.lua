local M = {

}

local luasnip = require('luasnip')
local cmp = require("cmp")

M.snippets = function ()
  local s = luasnip.snippet
  -- local sn = luasnip.snippet_node
  local t = luasnip.text_node
  local i = luasnip.insert_node
  -- local f = luasnip.function_node
  -- local c = luasnip.choice_node
  -- local d = luasnip.dynamic_node

  return {
    cs = {
      s("sum", {
        t({ "/// <summary>", "/// " }),
        i(0),
        t({ "", "/// </summary>" }),
      }),
      s("pra", {
        t("<parameter name=\""),
        i(1, "name"),
        t("\">"),
        i(0),
        t("</parameter>"),
      }),
      s({ trig = "try", name = "Try log", dscr = "Try catch, log the exception" }, {
        t({ "try", "{", "\t" }),
        i(0),
        t({ "", "}", "catch (" }),
        i(1, "Exception"),
        t(" e)"),
        t({ "", "{", "\t_logger.LogError(e, \"" }),
        i(2),
        t({ "\");", "}" }),
      }),
    }
  }

end

M.setup = function()
  local t = function(str)
    return vim.api.nvim_replace_termcodes(str, true, true, true)
  end

  local check_back_space = function()
    local col = vim.fn.col('.') - 1
    if col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') then
      return true
    else
      return false
    end
  end

  _G.tab_complete = function()
    if luasnip and luasnip.expand_or_jumpable() then
      return t("<Plug>luasnip-expand-or-jump")
    elseif check_back_space() then
      return t "<Tab>"
    else
      cmp.complete()
    end
    return ""
  end
  _G.s_tab_complete = function()
    if luasnip and luasnip.jumpable(-1) then
      return t("<Plug>luasnip-jump-prev")
    else
      return t "<S-Tab>"
    end
  end

  vim.api.nvim_set_keymap("i", "<Tab>", "v:lua.tab_complete()", { expr = true })
  vim.api.nvim_set_keymap("s", "<Tab>", "v:lua.tab_complete()", { expr = true })
  vim.api.nvim_set_keymap("i", "<S-Tab>", "v:lua.s_tab_complete()", { expr = true })
  vim.api.nvim_set_keymap("s", "<S-Tab>", "v:lua.s_tab_complete()", { expr = true })


  luasnip.snippets = M.snippets()

  require("luasnip/loaders/from_vscode").lazy_load()

end

return M
