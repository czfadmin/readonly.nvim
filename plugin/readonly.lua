if vim.g.loaded_readonly then
  return
end
vim.g.loaded_readonly = true

require("readonly")
