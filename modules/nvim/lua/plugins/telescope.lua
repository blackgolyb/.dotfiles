return {
    'nvim-telescope/telescope.nvim',
    tag = '0.2.1',
    dependencies = {
        'nvim-lua/plenary.nvim',
        { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
    },
    config = function()
        local builtin = require('telescope.builtin')
        local actions = require('telescope.actions')

        vim.keymap.set('n', 'g/', builtin.live_grep, { desc = "Global search (Live Grep)" })
        vim.keymap.set('n', 'g*', builtin.grep_string, { desc = "Search word under cursor" })

        require('telescope').setup({
            defaults = {
                initial_mode = "insert",
                mappings = {
                    i = {
                        ["<esc>"] = actions.close,
                    },
                },
            }
        })

        require('telescope').load_extension('fzf')
    end
}
