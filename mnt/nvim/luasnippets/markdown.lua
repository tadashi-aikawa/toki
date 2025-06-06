---@diagnostic disable: undefined-global

local function today()
  return sn(nil, { i(1, os.date("%Y%m%d")) })
end


-- stylua: ignore
return {
  s("_mtg", {
    t("- [ ] "),
    i(1, "10"), t(":"), i(2, "00"),
    t(" [[MTG_"), d(3, today), t("_"), i(4, "MTG名"), t("]]"),
  }),
  s("_activity", {
    t("- [ ] "),
    t("[["), d(1, today), t("_"), i(2, "作業名"), t("]]"),
  }),
  s("_fm", {
    t({
      "---",
      "created: "
    }),
    f(function()
      return os.date("%Y-%m-%d")
    end, {}),
    t({
      "",
      "refer: ",
      "---",
      ""
    }),
  }),
  s("_fmp", {
    t({
      "---",
      "created: "
    }),
    f(function()
      return os.date("%Y-%m-%d")
    end, {}),
    t({
      "",
      "author:",
      "  - tadashi-aikawa",
      "refer: ",
      "---",
      ""
    }),
  }),
}
