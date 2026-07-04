return {
    {
        'rmagatti/alternate-toggler',
        opts = {
            alternates = {
                { 'true', 'false' },
                { 'True', 'False' },
                { 'TRUE', 'FALSE' },
                { 'Yes', 'No' },
                { 'YES', 'NO' },
                { '1', '0' },
                { '<', '>' },
                { '>=', '<=' },
                { '+', '-' },
                { '===', '!==' },
                { '==', '!=' },
                { '&&', '||' },
                { 'and', 'or' },
                { 'public', 'private', 'protected' },
            },
        },
    },
    {
        'Wansmer/treesj',
        dependencies = {
            'nvim-treesitter/nvim-treesitter',
            'rmagatti/alternate-toggler',
        },
        keys = {
            {
                '<leader>m',
                function()
                    local changedtick = vim.b.changedtick
                    vim.cmd.ToggleAlternate()

                    if vim.b.changedtick ~= changedtick then
                        return
                    end

                    require('treesj').toggle()
                end,
                desc = 'Toggle alternate or split/join',
            },
        },
        opts = {
            use_default_keymaps = false,
            max_join_length = 120,
        },
    },
}
