return {
    {
        'nvim-lualine/lualine.nvim',
        lazy = false,
        priority = 900,
        dependencies = { 'nvim-tree/nvim-web-devicons' },
        config = function()
            local function lsp_clients()
                local clients = vim.lsp.get_clients({ bufnr = 0 })
                if #clients == 0 then
                    return ''
                end

                local names = {}
                for _, client in ipairs(clients) do
                    table.insert(names, client.name)
                end

                return table.concat(names, ",")
            end

            local function filename_widget()
                local name = vim.fn.expand('%:.')

                if name == '' then
                    name = '[No Name]'
                end

                if vim.bo.readonly then
                    name = name .. ' %#LualineModifiedCircle#%*'
                end

                if vim.bo.modified then
                    return name .. ' %#LualineModifiedCircle#●%*'
                end

                return name
            end

            local function get_hl(name)
                local ok, value = pcall(vim.api.nvim_get_hl, 0, { name = name })
                if ok then
                    return value
                end

                return {}
            end

            local function update_modified_highlight()
                local normal = get_hl('lualine_b_normal')

                if normal.bg then
                    vim.api.nvim_set_hl(0, 'LualineModifiedCircle', {
                        fg = '#61afef',
                        bg = normal.bg,
                        bold = true,
                    })
                end
            end

            local function hide_statusline()
                vim.opt.laststatus = 0
            end

            require('lualine').setup({
                options = {
                    theme = 'monodark',
                    globalstatus = true,
                    icons_enabled = true,
                    component_separators = '',
                    section_separators = '',
                    disabled_filetypes = {
                        statusline = { 'alpha', 'dashboard' },
                    },
                },
                sections = {
                    lualine_a = { 'mode' },
                    lualine_b = {
                        filename_widget,
                    },
                    lualine_c = {
                        'branch',
                        {
                            'diff',
                            symbols = { added = '+', modified = '~', removed = '-' },
                        },
                    },
                    lualine_x = {
                        {
                            'diagnostics',
                            sources = { 'nvim_diagnostic' },
                            sections = { 'error', 'warn' },
                            symbols = { error = 'E:', warn = 'W:' },
                        },
                        lsp_clients,
                    },
                    lualine_y = { 'filetype' },
                    lualine_z = { 'location' },
                },
                inactive_sections = {
                    lualine_a = {},
                    lualine_b = { filename_widget },
                    lualine_c = {},
                    lualine_x = {},
                    lualine_y = {},
                    lualine_z = {},
                },
                extensions = { 'lazy', 'neo-tree', 'quickfix' },
            })

            update_modified_highlight()
            hide_statusline()

            vim.api.nvim_create_autocmd('ColorScheme', {
                group = vim.api.nvim_create_augroup('LualineCustomHighlights', { clear = true }),
                callback = vim.schedule_wrap(update_modified_highlight),
            })

            vim.api.nvim_create_autocmd({ 'BufEnter', 'FocusGained', 'WinEnter' }, {
                group = vim.api.nvim_create_augroup('HideLualineStatusline', { clear = true }),
                callback = vim.schedule_wrap(hide_statusline),
            })
        end,
    },
}
