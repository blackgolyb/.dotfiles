-- Language server protocol configuration
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

            local function rename_with_quickfix()
                local source_bufnr = vim.api.nvim_get_current_buf()

                local clients = vim.lsp.get_clients({
                    bufnr = source_bufnr,
                    method = "textDocument/rename",
                })

                if #clients == 0 then
                    vim.notify(
                        "No LSP client supports rename",
                        vim.log.levels.WARN
                    )
                    return
                end

                local client = clients[1]
                local old_name = vim.fn.expand("<cword>")

                vim.ui.input({
                    prompt = "Rename to: ",
                    default = old_name,
                }, function(new_name)
                        if not new_name or new_name == "" or new_name == old_name then
                            return
                        end

                        local params = vim.lsp.util.make_position_params(
                            vim.api.nvim_get_current_win(),
                            client.offset_encoding
                        )

                        params.newName = new_name

                        client:request("textDocument/rename", params, function(err, edit)
                            if err then
                                vim.notify(err.message, vim.log.levels.ERROR)
                                return
                            end

                            if not edit then
                                vim.notify("LSP returned no rename edits")
                                return
                            end

                            local locations = {}
                            local seen = {}

                            local function collect(uri, edits)
                                local filename = vim.uri_to_fname(uri)
                                local bufnr = vim.uri_to_bufnr(uri)

                                vim.fn.bufload(bufnr)

                                for _, text_edit in ipairs(edits or {}) do
                                    local start = text_edit.range.start
                                    local key = table.concat({
                                        filename,
                                        start.line,
                                        start.character,
                                    }, ":")

                                    if not seen[key] then
                                        seen[key] = true

                                        locations[#locations + 1] = {
                                            uri = uri,
                                            bufnr = bufnr,
                                            filename = filename,
                                            line = start.line,
                                            character = start.character,
                                        }
                                    end
                                end
                            end

                            for uri, edits in pairs(edit.changes or {}) do
                                collect(uri, edits)
                            end

                            for _, change in ipairs(edit.documentChanges or {}) do
                                if change.textDocument then
                                    collect(
                                        change.textDocument.uri,
                                        change.edits
                                    )
                                end
                            end

                            vim.lsp.util.apply_workspace_edit(
                                edit,
                                client.offset_encoding
                            )

                            local items = {}

                            for _, location in ipairs(locations) do
                                local line_text =
                                vim.api.nvim_buf_get_lines(
                                    location.bufnr,
                                    location.line,
                                    location.line + 1,
                                    false
                                )[1] or ""

                                items[#items + 1] = {
                                    bufnr = location.bufnr,
                                    filename = location.filename,
                                    lnum = location.line + 1,
                                    col = location.character + 1,
                                    text = vim.trim(line_text),
                                }
                            end

                            table.sort(items, function(a, b)
                                if a.filename ~= b.filename then
                                    return a.filename < b.filename
                                end

                                if a.lnum ~= b.lnum then
                                    return a.lnum < b.lnum
                                end

                                return a.col < b.col
                            end)

                            vim.fn.setqflist({}, " ", {
                                title = ("Rename: %s → %s"):format(
                                    old_name,
                                    new_name
                                ),
                                items = items,
                            })

                            if #items > 0 then
                                vim.cmd("copen")
                            end
                        end, source_bufnr)
                    end)
            end

            -- Keymaps
            vim.api.nvim_create_autocmd('LspAttach', {
                callback = function(event)
                    local opts = { buffer = event.buf }

                    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
                    vim.keymap.set('n', 'K',  vim.lsp.buf.hover, opts)
                    vim.keymap.set("n", "ge", function()
                        vim.diagnostic.open_float({
                            buffer = event.buf,
                            scope = "cursor",
                            focusable = true,
                            source = "if_many",
                        })
                    end, { desc = "Cursor diagnostics" })
                    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
                    vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
                    vim.keymap.set('n', 'cd', rename_with_quickfix, opts)
                    vim.keymap.set('n', 'g.', vim.lsp.buf.code_action, opts)
                end,
            })
        end,
    },
}
