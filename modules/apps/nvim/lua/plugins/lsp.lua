local ui = require("core.ui")

return {
    {
        "neovim/nvim-lspconfig",
        dependencies = { "saghen/blink.cmp" },
        config = function()
            local capabilities = require('blink.cmp').get_lsp_capabilities()

            local servers = {
                "nixd", "lua_ls", "ts_ls", "html", "cssls", "jsonls",
                "eslint", "tailwindcss", "emmet_ls", "pyright", "ruff",
                "clangd", "rust_analyzer", "elixirls", "bashls",
                "dockerls", "taplo", "yamlls", "typos_lsp", "marksman",
                "wgsl_analyzer"
            }

            for _, server_name in ipairs(servers) do
                vim.lsp.config(server_name, {
                    capabilities = capabilities,
                })
            end

            -- LSP scpecific settings
            vim.lsp.config('lua_ls', {
                capabilities = capabilities,
                settings = {
                    Lua = {
                        diagnostics = { globals = { "vim" } },
                    },
                },
            })

            vim.lsp.config('ruff', {
                capabilities = capabilities,
                init_options = {
                    settings = {
                        lineLength = 100,
                        lint = {
                            extendSelect = { "I" }
                        }
                    }
                }
            })

            vim.lsp.config('pyright', {
                capabilities = capabilities,
                settings = {
                    python = {
                        analysis = {
                            typeCheckingMode = "off",
                        },
                        pythonPath = ".venv/bin/python"
                    }
                },
            })

            for _, server_name in ipairs(servers) do
                vim.lsp.enable(server_name)
            end

            -- Keymaps
            vim.api.nvim_create_autocmd('LspAttach', {
                callback = function(event)
                    local opts = { buffer = event.buf }

                    local function show_diagnostics()
                        vim.diagnostic.open_float(nil, {
                            scope = "cursor",
                            focus = false,
                            border = ui.surface_border,
                        })
                    end

                    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
                    vim.keymap.set('n', 'K',  vim.lsp.buf.hover, opts)
                    vim.keymap.set('n', 'ge', show_diagnostics, opts)
                    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
                    vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
                    vim.keymap.set('n', 'cd', vim.lsp.buf.rename, opts)
                    vim.keymap.set('n', 'g.', vim.lsp.buf.code_action, opts)
                end,
            })
        end,
    },
}
