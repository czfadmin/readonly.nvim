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
                restricted_directories = {"/custom", "/etc"}
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
        end)

        it("should set buffer readonly for language-specific directories", function()
            readonly.setup({
                language_directories = {
                    python = {"custom_venv", "venv"}
                }
            })
            -- 模拟一个 Python buffer，使用完整路径
            local test_buf = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_buf_set_name(test_buf, "/project/custom_venv/test.py")
            vim.bo[test_buf].filetype = "python"

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
            vim.api.nvim_buf_set_name(test_buf, "/project/frontend/src/node_modules/package/index.js")
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

        it("should handle multiple language directories for same file type", function()
            readonly.setup({
                language_directories = {
                    python = {'venv', 'env', '.virtualenv', '__pycache__'}
                }
            })

            -- 测试多个语言相关目录
            local paths = {'/project/venv/lib/python3.8/site-packages/test.py', '/project/env/lib/test.py',
                           '/project/.virtualenv/bin/test.py', '/project/src/__pycache__/module.py'}

            for _, path in ipairs(paths) do
                local test_buf = vim.api.nvim_create_buf(false, true)
                vim.api.nvim_buf_set_name(test_buf, path)
                vim.bo[test_buf].filetype = 'python'
                vim.api.nvim_set_current_buf(test_buf)

                local result = readonly.check_readonly()
                assert.truthy(result)
                assert.truthy(vim.bo.readonly)

                vim.api.nvim_buf_delete(test_buf, {
                    force = true
                })
            end
        end)

        it("should handle table-type exclude directories", function()
            readonly.setup({
                restricted_directories = {'/var'},
                exclude_directories = {{'/var/www/html', '/var/www/public'}, '/var/local'}
            })

            -- 测试表类型的排除目录
            local allowed_paths = {'/var/www/html/index.php', '/var/www/public/assets/style.css',
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

        it("should handle relative paths correctly", function()
            readonly.setup({
                restricted_directories = {'node_modules', 'build'},
                language_directories = {
                    js = {'dist'}
                }
            })

            -- 测试相对路径
            local test_buf = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_buf_set_name(test_buf, 'project/node_modules/package/index.js')
            vim.api.nvim_set_current_buf(test_buf)

            local result = readonly.check_readonly()
            assert.truthy(result)
            assert.truthy(vim.bo.readonly)

            vim.api.nvim_buf_delete(test_buf, {
                force = true
            })
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

        it("should handle complex language-specific directory patterns", function()
            readonly.setup({
                language_directories = {
                    python = {"venv", ".venv", "env", ".env", "virtualenv", "__pycache__", ".pytest_cache",
                              ".mypy_cache"},
                    javascript = {"node_modules", "dist", "build", ".next", "coverage"}
                }
            })

            local test_cases = { -- Python 相关测试
            {
                path = "project/venv/lib/python3.8/site-packages/test.py",
                filetype = "python",
                expected = true
            }, {
                path = "project/.venv/bin/python",
                filetype = "python",
                expected = true
            }, {
                path = "project/src/__pycache__/module.cpython-38.pyc",
                filetype = "python",
                expected = true
            }, {
                path = "project/tests/.pytest_cache/test_file.py",
                filetype = "python",
                expected = true
            }, -- JavaScript 相关测试
            {
                path = "project/node_modules/@types/react/index.d.ts",
                filetype = "javascript",
                expected = true
            }, {
                path = "project/.next/server/pages/index.js",
                filetype = "javascript",
                expected = true
            }, {
                path = "project/coverage/lcov-report/index.html",
                filetype = "javascript",
                expected = true
            }}

            for _, test in ipairs(test_cases) do
                local test_buf = vim.api.nvim_create_buf(false, true)
                vim.api.nvim_buf_set_name(test_buf, test.path)
                vim.bo[test_buf].filetype = test.filetype
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
                restricted_directories = {"/path with spaces", "/path-with-dashes", "/path.with.dots",
                                          "/path_with_underscores", "/path(with)parentheses"},
                exclude_directories = {"/path with spaces/allowed", "/path-with-dashes/allowed"}
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
                exclude_directories = {"/var/www/html/vendor/allowed", "node_modules/allowed"},
                language_directories = {
                    php = {"vendor/composer"}
                }
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
    end)

    describe("setup()", function()
        it("should merge user config with defaults", function()
            local user_config = {
                restricted_directories = {'/custom', '/etc'},
                language_directories = {
                    python = {'custom_venv'},
                    js = {'node_modules'}
                }
            }

            readonly.setup(user_config)

            -- 验证配置合并结果
            assert.truthy(vim.tbl_contains(readonly.config.restricted_directories, '/custom'))
            assert.truthy(vim.tbl_contains(readonly.config.restricted_directories, '/etc'))
            assert.truthy(readonly.config.language_directories.python)
            assert.truthy(vim.tbl_contains(readonly.config.language_directories.python, 'custom_venv'))
            assert.truthy(readonly.config.language_directories.js)
            assert.truthy(vim.tbl_contains(readonly.config.language_directories.js, 'node_modules'))
        end)

        it("should use empty config when no options provided", function()
            readonly.setup()

            -- 验证使用空配置
            assert.same({}, readonly.config.restricted_directories)
            assert.same({}, readonly.config.exclude_directories)
            assert.same({}, readonly.config.language_directories)
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
            assert.truthy(vim.tbl_contains(readonly.config.language_directories.custom_lang, 'custom_dir'))
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
                exclude_directories = {'/etc/allowed', {'/var/www', '/var/log'}, '/usr/local'}
            }

            readonly.setup(user_config)

            -- 验证复杂的排除目录配置
            assert.truthy(vim.tbl_contains(readonly.config.exclude_directories, '/etc/allowed'))
            assert.truthy(vim.tbl_contains(readonly.config.exclude_directories, user_config.exclude_directories[2]))
            assert.truthy(vim.tbl_contains(readonly.config.exclude_directories, '/usr/local'))
        end)
    end)
end)
