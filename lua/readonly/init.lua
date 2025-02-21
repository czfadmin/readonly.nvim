local M = {}

-- 默认配置
M.options = {
  restricted_directories = {"/etc", -- 默认不可编辑的目录
  "/usr", -- 另一个常见的不可编辑目录
  "/var", -- 另一个常见的不可编辑目录
  "/tmp" -- 临时文件目录
  },
  exclude_directories = {
    -- 用户可以在此处添加可编辑的目录
  },
  language_directories = {
    js = {"node_modules", "dist"}, -- Node.js 相关目录
    python = {"__pycache__", "venv"}, -- Python 相关目录
    ruby = {"vendor", "log"}, -- Ruby 相关目录
    php = {"vendor"}, -- PHP 相关目录
    go = {"bin", "pkg"}, -- Go 相关目录
    java = {"target", "out"}, -- Java 相关目录
    c = {"build", "bin"}, -- C/C++ 相关目录
    rust = {"target"}, -- Rust 相关目录
    elixir = {"_build", "deps"}, -- Elixir 相关目录
    haskell = {".stack-work"}, -- Haskell 相关目录
    scala = {"target"} -- Scala 相关目录
    -- 可以在此处添加其他语言的目录
  }
}

-- 设置只读模式
local function set_read_only()
  local current_buf = vim.api.nvim_get_current_buf()
  local buf_name = vim.api.nvim_buf_get_name(current_buf)

  -- 检查通用不可编辑目录
  for _, dir in ipairs(M.options.restricted_directories) do
    if buf_name:match("^" .. dir) then
      vim.bo.readonly = true -- 设置为只读
      vim.bo.modifiable = false -- 禁止修改
      print("This buffer is read-only because it is in a restricted directory: " .. dir)
      return
    end
  end

  -- 检查特定语言的目录
  local filetype = vim.bo.filetype
  if M.options.language_directories[filetype] then
    for _, dir in ipairs(M.options.language_directories[filetype]) do
      if buf_name:match("^" .. dir) then
        vim.bo.readonly = true -- 设置为只读
        vim.bo.modifiable = false -- 禁止修改
        print("This buffer is read-only because it is in a restricted directory for " .. filetype .. ": " .. dir)
        return
      end
    end
  end

  -- 检查可编辑目录（排除目录）
  for _, dir in ipairs(M.options.exclude_directories) do
    if type(dir) == "string" and buf_name:match("^" .. dir) then
      vim.bo.readonly = false -- 允许编辑
      vim.bo.modifiable = true -- 允许修改
      return
    elseif type(dir) == "table" then
      for _, subdir in ipairs(dir) do
        if buf_name:match("^" .. subdir) then
          vim.bo.readonly = false -- 允许编辑
          vim.bo.modifiable = true -- 允许修改
          return
        end
      end
    end
  end
end

-- 设置自动命令
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

return M

