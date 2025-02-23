if vim.g.loaded_readonly then
    return
end
vim.g.loaded_readonly = true

-- 加载插件（它会自动初始化）
require("readonly").setup()
