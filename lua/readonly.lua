-- main module file
local module = require("plugin_name.module")

---@class Config
---@field opt string Your config option
local config = {
  opt = "Hello!",
}

---@class MyModule
local M = {}

---@type Config
M.config = config

---@param args Config?
-- you can define your setup function here. Usually configurations can be merged, accepting outside params and
-- you can also put some validation here for those.
M.setup = function(args)
  M.config = vim.tbl_deep_extend("force", M.config, args or {})
end
function M.setup(opts)
  -- 合并用户配置
  M.options = vim.tbl_deep_extend("force", M.options, opts or {})

  local group = vim.api.nvim_create_augroup("ReadOnlyBuffers", {
    clear = true
  })
  vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = set_read_only
  })
end

M.hello = function()
  return module.my_first_function(M.config.opt)
end

return M
