-- main module file
---@class ReadOnly
local M = {}

local default_config = {
  restricted_directories = {
    "/etc",
    "/usr",
    "/var",
    "/tmp" -- 临时文件目录
  },
  exclude_directories = {}
}

local function escape_pattern(str)
  -- 转义特殊字符，包括空格和路径分隔符
  return str:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$%s/]", "%%%1")
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
  -- 处理相对路径
  path = path:gsub("^%./", "")
  -- 确保路径以斜杠开始（便于匹配）
  if not path:match("^/") then
    path = "/" .. path
  end
  return path
end

local function is_path_match(path, pattern)
  -- 标准化路径和模式
  path = normalize_path(path)
  pattern = normalize_path(pattern)

  -- 转义模式中的特殊字符
  -- pattern = escape_pattern(pattern)

  -- 构建匹配模式：
  -- 1. 完全匹配
  -- 2. 作为目录的一部分匹配（前后都有斜杠）
  -- 3. 作为开头匹配（后面有斜杠）
  -- 4. 作为结尾匹配（前面有斜杠）
  -- 5. 作为路径中的任意部分匹配（前后都有斜杠）
  local patterns = {
    "^" .. pattern .. "$",
    "/" .. pattern .. "/",
    "^" .. pattern .. "/",
    "/" .. pattern .. "$",
    pattern -- 允许匹配路径中的任意部分
  }

  -- 检查所有匹配模式
  for _, p in ipairs(patterns) do
    if string.match(path, p) then
      return true
    end
  end
  return false
end

local function check_is_excluded(file_path)
  -- 标准化文件路径
  file_path = normalize_path(file_path)

  -- 检查可编辑目录（排除目录）
  for _, dir in ipairs(M.config.exclude_directories) do
    -- 处理字符串类型的排除目录
    if type(dir) == "string" then
      if is_path_match(file_path, dir) then
        return true
      end
      -- 处理表类型的排除目录
    elseif type(dir) == "table" then
      for _, subdir in ipairs(dir) do
        if is_path_match(file_path, subdir) then
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
    if is_path_match(file_path, dir) then
      vim.bo.readonly = true
      vim.bo.modifiable = false
      print(
        "This buffer is read-only because it is in a restricted directory: " ..
          dir)
      return true
    end
  end
  return false
end

---@class Config
---@field restricted_directories table
---@field exclude_directories table
local config = {
  restricted_directories = {},
  exclude_directories = {}
}

---@type Config
M.config = config

---@param opts Config?
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  local group = vim.api.nvim_create_augroup(
                  "czfadfmin.readonly.ReadOnlyBuffers", {
      clear = true
    })

  vim.api.nvim_create_autocmd(
    "BufEnter", {
      group = group,
      callback = M.check_readonly
    })
end

return M
