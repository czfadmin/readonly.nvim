# Readonly.nvim

The file you open is in read-only mode, so it won't be accidentally modified, similar to the file read-only function in VSCODE

## HOW TO USE IT?

- lazyvim

```lua
return {
  "czfadmin/readonly.nvim",
  event = "BufReadPre",
  enabled = true,
  opts = {
    restricted_directories = {
      "/etc",
      "/usr",
      "/var",
      "/tmp",
      "/opt",
      "*/node_modules/.*"
    },
    exclude_directories = {},

  },
  config = function(_, opts)
    require("readonly").setup(opts)
  end,
}
```
