-- main module file
---@class ReadOnly
local M = {}

local default_config = {
  restricted_directories = {
    "/etc", -- 默认不可编辑的目录
    "/usr", -- 另一个常见的不可编辑目录
    "/var", -- 另一个常见的不可编辑目录
    "/tmp", -- 临时文件目录
  },
  exclude_directories = {},
  language_directories = {
    js = { "node_modules", "dist" }, -- Node.js 相关目录
    python = { "__pycache__", "venv" }, -- Python 相关目录
    ruby = { "vendor", "log" }, -- Ruby 相关目录
    php = { "vendor" }, -- PHP 相关目录
    go = { "bin", "pkg" }, -- Go 相关目录
    java = { "target", "out" }, -- Java 相关目录
    c = { "build", "bin" }, -- C/C++ 相关目录
    rust = { "target" }, -- Rust 相关目录
    elixir = { "_build", "deps" }, -- Elixir 相关目录
    haskell = { ".stack-work" }, -- Haskell 相关目录
    scala = { "target" }, -- Scala 相关目录
  },
}

local function escape_pattern(str)
  -- 转义特殊字符，包括空格
  return str:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$%s]", "%%%1")
end

local function normalize_path(path)
  -- 标准化路径：处理路径中的空格和特殊字符
  if not path then
    return ""
  end
  -- 移除首尾空格
  path = path:gsub("^%s*(.-)%s*$", "%1")
  -- 确保使用标准的路径分隔符
  path = path:gsub("\\", "/")
  -- 处理多个连续的斜杠
  path = path:gsub("//+", "/")
  return path
end

local function check_is_excluded(file_path)
  -- 标准化文件路径
  file_path = normalize_path(file_path)

  -- 检查可编辑目录（排除目录）
  for _, dir in ipairs(M.config.exclude_directories) do
    -- 处理字符串类型的排除目录
    if type(dir) == "string" then
      local escaped_dir = escape_pattern(normalize_path(dir))
      -- 使用严格的路径匹配，确保匹配完整路径或子路径
      if
        string.match(file_path, "^" .. escaped_dir .. "/?")
        or string.match(file_path, "/" .. escaped_dir .. "/?")
      then
        vim.bo.readonly = false
        vim.bo.modifiable = true
        return true
      end
      -- 处理表类型的排除目录
    elseif type(dir) == "table" then
      for _, subdir in ipairs(dir) do
        local escaped_subdir = escape_pattern(normalize_path(subdir))
        -- 对表中的每个路径使用相同的匹配规则
        if
          string.match(file_path, "^" .. escaped_subdir .. "/?")
          or string.match(file_path, "/" .. escaped_subdir .. "/?")
        then
          vim.bo.readonly = false
          vim.bo.modifiable = true
          return true
        end
      end
    end
  end
  return false
end

function M.check_readonly()
  local current_buf = vim.api.nvim_get_current_buf()
  local buf_name = vim.api.nvim_buf_get_name(current_buf)

  -- 如果是新缓冲区或无名缓冲区，不设置只读
  if buf_name == "" then
    return false
  end

  -- 获取文件路径并标准化
  local file_path = normalize_path(buf_name)

  -- 首先检查是否在排除目录中
  if check_is_excluded(file_path) then
    return false
  end

  -- 检查通用不可编辑目录
  for _, dir in ipairs(M.config.restricted_directories) do
    local escaped_dir = escape_pattern(normalize_path(dir))
    if
      string.match(file_path, "^" .. escaped_dir .. "/?")
      or string.match(file_path, "/" .. escaped_dir .. "/?")
    then
      vim.bo.readonly = true
      vim.bo.modifiable = false
      print(
        "This buffer is read-only because it is in a restricted directory: "
          .. dir
      )
      return true
    end
  end

  -- 检查特定语言的目录
  local filetype = vim.bo.filetype
  if M.config.language_directories[filetype] then
    for _, dir in ipairs(M.config.language_directories[filetype]) do
      local escaped_dir = escape_pattern(normalize_path(dir))
      if string.match(file_path, escaped_dir) then
        if check_is_excluded(file_path) then
          return false
        end
        vim.bo.readonly = true
        vim.bo.modifiable = false
        print(
          "This buffer is read-only because it is in a restricted directory for "
            .. filetype
            .. ": "
            .. dir
        )
        return true
      end
    end
  end

  return false
end

---@class Config
---@field restricted_directories table
---@field exclude_directories table
---@field language_directories table
local config = {
  restricted_directories = {},
  exclude_directories = {},
  language_directories = {},
}

---@type Config
M.config = config

---@param opts Config?
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or default_config)

  local group = vim.api.nvim_create_augroup("ReadOnlyBuffers", {
    clear = true,
  })

  vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = M.check_readonly,
  })
end

return M
