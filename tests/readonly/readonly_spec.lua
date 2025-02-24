local readonly = require("readonly")

describe("readonly", function()
  -- 在每个测试用例前重置配置
  before_each(function()
    ---@type Config
    readonly.config = {
      restricted_directories = {},
      exclude_directories = {},
      language_directories = {}
    }
  end)

  describe("check_readonly()", function()
    it("should set buffer readonly for restricted directories", function()
      readonly.setup({
        restricted_directories = {"/custom", "/etc",
                                  "/lua-language-server/libexec"}
      })
      -- 模拟一个buffer，使用完整路径
      local test_buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_name(test_buf, "/custom/test.txt")

      -- 切换到测试buffer
      vim.api.nvim_set_current_buf(test_buf)

      -- 执行检查
      local result = readonly.check_readonly()

      -- 验证结果
      assert.truthy(result)
      assert.truthy(vim.bo.readonly)
      assert.falsy(vim.bo.modifiable)

      -- 清理
      vim.api.nvim_buf_delete(test_buf, {
        force = true
      })
      -- 2. 模拟一个buffer，使用完整路径
      test_buf = vim.api.nvim_create_buf(false, true)

      vim.api.nvim_buf_set_name(test_buf,
        "/home/xxxx/.local/share/nvim/mason/packages/lua-language-server/libexec/meta/Lua/init.lua")

      -- 切换到测试buffer
      vim.api.nvim_set_current_buf(test_buf)

      -- 执行检查
      local result = readonly.check_readonly()

      -- 验证结果
      assert.truthy(result)
      assert.truthy(vim.bo.readonly)
      assert.falsy(vim.bo.modifiable)
      -- 清理
      vim.api.nvim_buf_delete(test_buf, {
        force = true
      })
    end)

    it("should allow editing for excluded directories", function()
      readonly.setup({
        restricted_directories = {"/etc"},
        exclude_directories = {"/etc/allowed"}
      })
      -- 模拟一个buffer，使用完整路径
      local test_buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_name(test_buf, "/etc/allowed/test.txt")

      -- 切换到测试buffer
      vim.api.nvim_set_current_buf(test_buf)

      -- 执行检查
      local result = readonly.check_readonly()

      -- 验证结果
      assert.falsy(result)
      assert.falsy(vim.bo.readonly)
      assert.truthy(vim.bo.modifiable)

      -- 清理
      vim.api.nvim_buf_delete(test_buf, {
        force = true
      })
    end)

    it("should handle files in nested directories correctly", function()
      readonly.setup({
        restricted_directories = {"/project/frontend/src/node_modules/package"},
        language_directories = {
          js = {"node_modules"}
        }
      })
      -- 模拟一个 JavaScript buffer，使用嵌套路径
      local test_buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_name(test_buf,
        "/project/frontend/src/node_modules/package/index.js")
      vim.bo[test_buf].filetype = "js"

      -- 切换到测试buffer
      vim.api.nvim_set_current_buf(test_buf)

      -- 执行检查
      local result = readonly.check_readonly()

      -- 验证结果
      assert.truthy(result)
      assert.truthy(vim.bo.readonly)
      assert.falsy(vim.bo.modifiable)

      -- 清理
      vim.api.nvim_buf_delete(test_buf, {
        force = true
      })
    end)

    it("should handle files without directory path", function()
      readonly.setup({
        restricted_directories = {"/etc"}
      })
      -- 模拟一个没有目录路径的文件
      local test_buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_name(test_buf, "test.txt")

      -- 切换到测试buffer
      vim.api.nvim_set_current_buf(test_buf)

      -- 执行检查
      local result = readonly.check_readonly()

      -- 验证结果
      assert.falsy(result)
      assert.falsy(vim.bo.readonly)
      assert.truthy(vim.bo.modifiable)

      -- 清理
      vim.api.nvim_buf_delete(test_buf, {
        force = true
      })
    end)

    it("should handle nested restricted directories", function()
      readonly.setup({
        restricted_directories = {'/var/www/html'},
        exclude_directories = {'/var/www/html/public'}
      })

      -- 测试嵌套的受限目录
      local test_buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_name(test_buf, '/var/www/html/private/config.php')
      vim.api.nvim_set_current_buf(test_buf)

      local result = readonly.check_readonly()
      assert.truthy(result)
      assert.truthy(vim.bo.readonly)

      -- 测试嵌套的排除目录
      local test_buf2 = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_name(test_buf2, '/var/www/html/public/index.php')
      vim.api.nvim_set_current_buf(test_buf2)

      local result2 = readonly.check_readonly()
      assert.falsy(result2)
      assert.falsy(vim.bo.readonly)

      vim.api.nvim_buf_delete(test_buf, {
        force = true
      })
      vim.api.nvim_buf_delete(test_buf2, {
        force = true
      })
    end)

    it("should handle table-type exclude directories", function()
      readonly.setup({
        restricted_directories = {'/var'},
        exclude_directories = {{'/var/www/html', '/var/www/public'},
                               '/var/local'}
      })

      -- 测试表类型的排除目录
      local allowed_paths = {'/var/www/html/index.php',
                             '/var/www/public/assets/style.css',
                             '/var/local/bin/script.sh'}

      for _, path in ipairs(allowed_paths) do
        local test_buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_name(test_buf, path)
        vim.api.nvim_set_current_buf(test_buf)

        local result = readonly.check_readonly()
        assert.falsy(result)
        assert.falsy(vim.bo.readonly)

        vim.api.nvim_buf_delete(test_buf, {
          force = true
        })
      end
    end)

    it("should handle files with special characters in path", function()
      readonly.setup({
        restricted_directories = {'/path/with spaces', '/path/with-dash'},
        language_directories = {
          python = {'venv with spaces'}
        }
      })

      -- 测试带特殊字符的路径
      local test_paths = {{
        path = '/path/with spaces/config.txt',
        expected = true
      }, {
        path = '/path/with-dash/config.txt',
        expected = true
      }, {
        path = '/project/venv with spaces/lib/test.py',
        expected = true,
        filetype = 'python'
      }}

      for _, test in ipairs(test_paths) do
        local test_buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_name(test_buf, test.path)
        if test.filetype then
          vim.bo[test_buf].filetype = test.filetype
        end
        vim.api.nvim_set_current_buf(test_buf)

        local result = readonly.check_readonly()
        assert.equals(test.expected, result)
        assert.equals(test.expected, vim.bo.readonly)

        vim.api.nvim_buf_delete(test_buf, {
          force = true
        })
      end
    end)

    it("should handle absolute and relative paths together", function()
      readonly.setup({
        restricted_directories = {"/etc", "node_modules"},
        exclude_directories = {"/etc/allowed", "node_modules/allowed"}
      })

      -- 测试绝对路径
      local test_cases = {{
        path = "/etc/config/test.conf",
        expected = true
      }, {
        path = "/etc/allowed/test.conf",
        expected = false
      }, -- 测试相对路径
      {
        path = "project/node_modules/package.json",
        expected = true
      }, {
        path = "project/node_modules/allowed/package.json",
        expected = false
      }}

      for _, test in ipairs(test_cases) do
        local test_buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_name(test_buf, test.path)
        vim.api.nvim_set_current_buf(test_buf)

        local result = readonly.check_readonly()
        assert.equals(test.expected, result)
        assert.equals(test.expected, vim.bo.readonly)

        vim.api.nvim_buf_delete(test_buf, {
          force = true
        })
      end
    end)

    it("should handle paths with special characters and spaces", function()
      readonly.setup({
        restricted_directories = {"/path with spaces", "/path-with-dashes",
                                  "/path.with.dots", "/path_with_underscores",
                                  "/path(with)parentheses"},
        exclude_directories = {"/path with spaces/allowed",
                               "/path-with-dashes/allowed"}
      })

      local test_cases = {{
        path = "/path with spaces/config.txt",
        expected = true
      }, {
        path = "/path with spaces/allowed/config.txt",
        expected = false
      }, {
        path = "/path-with-dashes/test.txt",
        expected = true
      }, {
        path = "/path.with.dots/test.txt",
        expected = true
      }, {
        path = "/path_with_underscores/test.txt",
        expected = true
      }, {
        path = "/path(with)parentheses/test.txt",
        expected = true
      }}

      for _, test in ipairs(test_cases) do
        local test_buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_name(test_buf, test.path)
        vim.api.nvim_set_current_buf(test_buf)

        local result = readonly.check_readonly()
        assert.equals(test.expected, result)
        assert.equals(test.expected, vim.bo.readonly)

        vim.api.nvim_buf_delete(test_buf, {
          force = true
        })
      end
    end)

    it("should handle deeply nested directory structures", function()
      readonly.setup({
        restricted_directories = {"/var/www/html/vendor", "node_modules"},
        exclude_directories = {"/var/www/html/vendor/allowed",
                               "node_modules/allowed"}
      })

      local test_cases = {{
        path = "/var/www/html/vendor/package/src/file.php",
        expected = true
      }, {
        path = "/var/www/html/vendor/allowed/file.php",
        expected = false
      }, {
        path = "/project/frontend/node_modules/react/dist/react.js",
        expected = true
      }, {
        path = "/project/frontend/node_modules/allowed/package/index.js",
        expected = false
      }, {
        path = "/project/vendor/composer/autoload.php",
        filetype = "php",
        expected = true
      }}

      for _, test in ipairs(test_cases) do
        local test_buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_name(test_buf, test.path)
        if test.filetype then
          vim.bo[test_buf].filetype = test.filetype
        end
        vim.api.nvim_set_current_buf(test_buf)

        local result = readonly.check_readonly()
        assert.equals(test.expected, result)
        assert.equals(test.expected, vim.bo.readonly)

        vim.api.nvim_buf_delete(test_buf, {
          force = true
        })
      end
    end)

    it("should handle edge cases with empty or invalid paths", function()
      readonly.setup({
        restricted_directories = {"/etc"},
        exclude_directories = {"/etc/allowed"}
      })

      local test_cases = {{
        path = "", -- 空路径
        expected = false
      }, {
        path = "   ", -- 只包含空格的路径
        expected = false
      }, {
        path = "///", -- 多个斜杠
        expected = false
      }, {
        path = "./relative/path", -- 相对路径
        expected = false
      }, {
        path = "../parent/path", -- 父目录路径
        expected = false
      }}

      for _, test in ipairs(test_cases) do
        local test_buf = vim.api.nvim_create_buf(false, true)
        if test.path ~= "" then
          vim.api.nvim_buf_set_name(test_buf, test.path)
        end
        vim.api.nvim_set_current_buf(test_buf)

        local result = readonly.check_readonly()
        assert.equals(test.expected, result)
        assert.equals(test.expected, vim.bo.readonly)

        vim.api.nvim_buf_delete(test_buf, {
          force = true
        })
      end
    end)

    it("should handle partial path matching in restricted directories",
      function()
        readonly.setup({
          restricted_directories = {"/lua-language-server/libexec",
                                    "/node_modules", "/.git"}
        })

        local test_cases = {{
          path = "/home/user/.local/share/nvim/mason/packages/lua-language-server/libexec/meta/Lua/init.lua",
          expected = true,
          desc = "should match partial path in mason packages"
        }, {
          path = "/project/frontend/node_modules/react/index.js",
          expected = true,
          desc = "should match node_modules in any location"
        }, {
          path = "/home/user/project/.git/config",
          expected = true,
          desc = "should match .git directory"
        }, {
          path = "/home/user/git/project/file.txt",
          expected = false,
          desc = "should not match 'git' in regular path"
        }}

        for _, test in ipairs(test_cases) do
          local test_buf = vim.api.nvim_create_buf(false, true)
          vim.api.nvim_buf_set_name(test_buf, test.path)
          vim.api.nvim_set_current_buf(test_buf)

          local result = readonly.check_readonly()
          assert.equals(test.expected, result, test.desc)
          assert.equals(test.expected, vim.bo.readonly)

          vim.api.nvim_buf_delete(test_buf, {
            force = true
          })
        end
      end)

    it("should handle complex path patterns with mixed slashes", function()
      readonly.setup({
        restricted_directories = {"/var/www"},
        exclude_directories = {"/var/www/html/public"}
      })

      local test_cases = {{
        path = "/var/www\\html\\private\\config.php",
        expected = true,
        desc = "should handle backslashes"
      }, {
        path = "/var/www//html/private//config.php",
        expected = true,
        desc = "should handle multiple slashes"
      }, {
        path = "/var/www/html/public/index.php",
        expected = false,
        desc = "should handle excluded directory"
      }, {
        path = "./var/www/html/config.php",
        expected = true,
        desc = "should handle relative paths"
      }}

      for _, test in ipairs(test_cases) do
        local test_buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_name(test_buf, test.path)
        vim.api.nvim_set_current_buf(test_buf)

        local result = readonly.check_readonly()
        assert.equals(test.expected, result, test.desc)
        assert.equals(test.expected, vim.bo.readonly)

        vim.api.nvim_buf_delete(test_buf, {
          force = true
        })
      end
    end)

    it("should handle complex language-specific patterns", function()
      readonly.setup({
        language_directories = {
          python = {"site-packages", "__pycache__", ".pytest_cache", "venv/lib"},
          javascript = {"node_modules", ".next/server", "dist/client"}
        }
      })

      local test_cases = {{
        path = "/usr/local/lib/python3.8/site-packages/package/module.py",
        filetype = "python",
        expected = true,
        desc = "should match site-packages anywhere in path"
      }, {
        path = "/project/src/__pycache__/module.cpython-39.pyc",
        filetype = "python",
        expected = true,
        desc = "should match __pycache__ directory"
      }, {
        path = "/project/venv/lib/python3.9/importlib.py",
        filetype = "python",
        expected = true,
        desc = "should match venv/lib pattern"
      }, {
        path = "/project/.next/server/pages/api/data.js",
        filetype = "javascript",
        expected = true,
        desc = "should match Next.js server directory"
      }}

      for _, test in ipairs(test_cases) do
        local test_buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_name(test_buf, test.path)
        vim.bo[test_buf].filetype = test.filetype
        vim.api.nvim_set_current_buf(test_buf)

        local result = readonly.check_readonly()
        assert.equals(test.expected, result, test.desc)
        assert.equals(test.expected, vim.bo.readonly)

        vim.api.nvim_buf_delete(test_buf, {
          force = true
        })
      end
    end)

    it("should handle paths with special characters and spaces correctly",
      function()
        readonly.setup({
          restricted_directories = {"/Program Files",
                                    "/Users/name/Library/Application Support",
                                    "/path with (parentheses)",
                                    "/path.with.dots", "/path-with-dashes"},
          exclude_directories = {"/Program Files/Allowed Space",
                                 "/path.with.dots/allowed"}
        })

        local test_cases = {{
          path = "/Program Files/Microsoft/Word/document.doc",
          expected = true,
          desc = "should match path with spaces"
        }, {
          path = "/Program Files/Allowed Space/file.txt",
          expected = false,
          desc = "should handle excluded directory with spaces"
        }, {
          path = "/Users/name/Library/Application Support/Code/file.txt",
          expected = true,
          desc = "should match complex path with spaces"
        }, {
          path = "/path with (parentheses)/config.ini",
          expected = true,
          desc = "should match path with special characters"
        }, {
          path = "/path.with.dots/config.txt",
          expected = true,
          desc = "should match path with dots"
        }, {
          path = "/path.with.dots/allowed/file.txt",
          expected = false,
          desc = "should handle excluded directory with dots"
        }}

        for _, test in ipairs(test_cases) do
          local test_buf = vim.api.nvim_create_buf(false, true)
          vim.api.nvim_buf_set_name(test_buf, test.path)
          vim.api.nvim_set_current_buf(test_buf)

          local result = readonly.check_readonly()
          assert.equals(test.expected, result, test.desc)
          assert.equals(test.expected, vim.bo.readonly)

          vim.api.nvim_buf_delete(test_buf, {
            force = true
          })
        end
      end)
  end)

  describe("setup()", function()
    it("should use empty config when no options provided", function()
      -- 调用不带参数的 setup
      readonly.setup()

      -- 验证使用空配置
      assert.same({}, readonly.config.restricted_directories)
      assert.same({}, readonly.config.exclude_directories)
      assert.same({}, readonly.config.language_directories)

      -- 验证自动命令组是否创建
      local augroup = vim.api.nvim_get_autocmds({
        group = 'ReadOnlyBuffers'
      })
      assert.truthy(#augroup > 0)
      assert.equals('BufEnter', augroup[1].event)
    end)

    it("should use provided config when options are passed", function()
      -- 提供完整的配置
      local user_config = {
        restricted_directories = {"/etc", "/usr"},
        exclude_directories = {"/etc/allowed"},
        language_directories = {
          python = {"venv", "__pycache__"},
          js = {"node_modules"}
        }
      }

      -- 设置用户配置
      readonly.setup(user_config)

      -- 验证配置是否完全匹配用户提供的值
      assert.same(user_config.restricted_directories,
        readonly.config.restricted_directories)
      assert.same(user_config.exclude_directories,
        readonly.config.exclude_directories)
      assert.same(user_config.language_directories,
        readonly.config.language_directories)
    end)

    it("should preserve user-specific configurations", function()
      local user_config = {
        custom_setting = 'test',
        language_directories = {
          custom_lang = {'custom_dir'}
        }
      }

      readonly.setup(user_config)

      -- 验证保留了用户特定的配置
      assert.equals('test', readonly.config.custom_setting)
      assert.truthy(readonly.config.language_directories.custom_lang)
      assert.truthy(vim.tbl_contains(readonly.config.language_directories
                                       .custom_lang, 'custom_dir'))

      -- 验证其他配置为空
      assert.same({}, readonly.config.restricted_directories)
      assert.same({}, readonly.config.exclude_directories)
      assert.equals(1, vim.tbl_count(readonly.config.language_directories))
    end)

    it("should create autocommands", function()
      readonly.setup()

      -- 验证自动命令组是否创建
      local augroup = vim.api.nvim_get_autocmds({
        group = 'ReadOnlyBuffers'
      })

      assert.truthy(#augroup > 0)
      assert.equals('BufEnter', augroup[1].event)
    end)

    it("should handle complex exclude_directories configuration", function()
      local user_config = {
        exclude_directories = {'/etc/allowed', {'/var/www', '/var/log'},
                               '/usr/local'}
      }

      readonly.setup(user_config)

      -- 验证复杂的排除目录配置
      assert.truthy(vim.tbl_contains(readonly.config.exclude_directories,
        '/etc/allowed'))
      assert.truthy(vim.tbl_contains(readonly.config.exclude_directories,
        user_config.exclude_directories[2]))
      assert.truthy(vim.tbl_contains(readonly.config.exclude_directories,
        '/usr/local'))
    end)
  end)

  describe("path handling", function()
    it("should handle normalized paths correctly", function()
      readonly.setup({
        restricted_directories = {"/test/path"},
        exclude_directories = {"/test/path/allowed"}
      })

      local test_cases = {{
        path = "/test/path/./file.txt",
        expected = true,
        desc = "should handle current directory marker"
      }, {
        path = "/test/path/../path/file.txt",
        expected = true,
        desc = "should handle parent directory marker"
      }, {
        path = "/test//path///file.txt",
        expected = true,
        desc = "should handle multiple slashes"
      }, {
        path = "/test/path/allowed/../restricted/file.txt",
        expected = false,
        desc = "should handle complex path navigation"
      }}

      for _, test in ipairs(test_cases) do
        local test_buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_name(test_buf, test.path)
        vim.api.nvim_set_current_buf(test_buf)

        local result = readonly.check_readonly()
        assert.equals(test.expected, result, test.desc)
        assert.equals(test.expected, vim.bo.readonly)

        vim.api.nvim_buf_delete(test_buf, {
          force = true
        })
      end
    end)

    it("should handle special file paths", function()
      readonly.setup({
        restricted_directories = {"/var/log"},
        exclude_directories = {"/var/log/app"}
      })

      local test_cases = {{
        path = "",
        expected = false,
        desc = "should handle empty path"
      }, {
        path = "noroot.txt",
        expected = false,
        desc = "should handle files without root"
      }, {
        path = "./relative/path.txt",
        expected = false,
        desc = "should handle relative paths"
      }, {
        path = "/var/log/~backup/file.txt",
        expected = true,
        desc = "should handle paths with tilde"
      }}

      for _, test in ipairs(test_cases) do
        local test_buf = vim.api.nvim_create_buf(false, true)
        if test.path ~= "" then
          vim.api.nvim_buf_set_name(test_buf, test.path)
        end
        vim.api.nvim_set_current_buf(test_buf)

        local result = readonly.check_readonly()
        assert.equals(test.expected, result, test.desc)
        assert.equals(test.expected, vim.bo.readonly)

        vim.api.nvim_buf_delete(test_buf, {
          force = true
        })
      end
    end)
  end)

  describe("exclude directory handling", function()
    it("should handle complex exclude patterns", function()
      readonly.setup({
        restricted_directories = {"/app", "/data"},
        exclude_directories = {"/app/public", {"/data/cache", "/data/temp"},
                               "/app/config/local"}
      })

      local test_cases = {{
        path = "/app/src/main.js",
        expected = true,
        desc = "should be readonly in restricted dir"
      }, {
        path = "/app/public/index.html",
        expected = false,
        desc = "should not be readonly in excluded dir"
      }, {
        path = "/data/cache/temp.dat",
        expected = false,
        desc = "should handle array exclude pattern"
      }, {
        path = "/app/config/local/settings.json",
        expected = false,
        desc = "should handle nested exclude pattern"
      }}

      for _, test in ipairs(test_cases) do
        local test_buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_name(test_buf, test.path)
        vim.api.nvim_set_current_buf(test_buf)

        local result = readonly.check_readonly()
        assert.equals(test.expected, result, test.desc)
        assert.equals(test.expected, vim.bo.readonly)

        vim.api.nvim_buf_delete(test_buf, {
          force = true
        })
      end
    end)
  end)

  describe("pattern matching", function()
    it("should handle fuzzy path matching", function()
      readonly.setup({
        restricted_directories = {"node_modules$", -- 以 node_modules 结尾
        "^/var/log", -- 以 /var/log 开头
        "build", -- 包含 build
        "%.git$", -- 以 .git 结尾（转义点号）
        "dist/.+/build" -- dist 和 build 之间必须有内容
        },
        exclude_directories = {"^/var/log/app", -- 以 /var/log/app 开头
        "allowed/.+" -- allowed 后必须有内容
        }
      })

      local test_cases = { -- 结尾匹配测试
      {
        path = "/project/node_modules",
        expected = true,
        desc = "should match exact node_modules at end"
      }, {
        path = "/project/sub/node_modules",
        expected = true,
        desc = "should match nested node_modules at end"
      }, {
        path = "/project/node_modules_extra",
        expected = false,
        desc = "should not match when node_modules is not at end"
      }, -- 开头匹配测试
      {
        path = "/var/log/system.log",
        expected = true,
        desc = "should match path starting with /var/log"
      }, {
        path = "/var/log/app/debug.log",
        expected = false,
        desc = "should not match excluded /var/log/app path"
      }, -- 包含匹配测试
      {
        path = "/project/build/output",
        expected = true,
        desc = "should match path containing build"
      }, {
        path = "/project/building/output",
        expected = false,
        desc = "should not match when build is part of another word"
      }, -- 特殊字符匹配测试
      {
        path = "/project/.git",
        expected = true,
        desc = "should match .git at end with escaped dot"
      }, {
        path = "/project/.github",
        expected = false,
        desc = "should not match .git when not at end"
      }, -- 复杂模式匹配测试
      {
        path = "/project/dist/v1/build",
        expected = true,
        desc = "should match dist/.+/build pattern"
      }, {
        path = "/project/dist/build",
        expected = false,
        desc = "should not match dist/build without content between"
      }, -- 排除目录匹配测试
      {
        path = "/project/allowed/edit",
        expected = false,
        desc = "should match excluded allowed/.+ pattern"
      }, {
        path = "/project/allowed",
        expected = true,
        desc = "should not match excluded allowed without content after"
      }}

      for _, test in ipairs(test_cases) do
        local test_buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_name(test_buf, test.path)
        vim.api.nvim_set_current_buf(test_buf)

        local result = readonly.check_readonly()
        assert.equals(test.expected, result, test.desc)
        assert.equals(test.expected, vim.bo.readonly)

        vim.api.nvim_buf_delete(test_buf, {
          force = true
        })
      end
    end)

    it("should handle complex pattern combinations", function()
      readonly.setup({
        restricted_directories = {"^/opt/[^/]+/lib", -- /opt/ 后跟任意非斜杠字符，再跟 /lib
                                  "%.min%.[^/]+$", -- 以 .min. 加任意非斜杠字符结尾
                                  "^/.+_backup/.+$", -- 以 _backup 目录包含的任意文件
                                  "%f[%w]test%f[%W]" -- 单词边界的 test
        }
      })

      local test_cases = {{
        path = "/opt/python3/lib/python3.8",
        expected = true,
        desc = "should match /opt/*/lib pattern"
      }, {
        path = "/opt/lib/python3.8",
        expected = false,
        desc = "should not match when lib is directly after opt"
      }, {
        path = "/js/script.min.js",
        expected = true,
        desc = "should match .min.* extension"
      }, {
        path = "/js/script.min/file.js",
        expected = false,
        desc = "should not match when .min. is in middle"
      }, {
        path = "/sys_backup/file.txt",
        expected = true,
        desc = "should match _backup directory"
      }, {
        path = "/path/test/file",
        expected = true,
        desc = "should match word-bounded test"
      }, {
        path = "/path/testing/file",
        expected = false,
        desc = "should not match test when part of another word"
      }}

      for _, test in ipairs(test_cases) do
        local test_buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_name(test_buf, test.path)
        vim.api.nvim_set_current_buf(test_buf)

        local result = readonly.check_readonly()
        assert.equals(test.expected, result, test.desc)
        assert.equals(test.expected, vim.bo.readonly)

        vim.api.nvim_buf_delete(test_buf, {
          force = true
        })
      end
    end)
  end)
end)
