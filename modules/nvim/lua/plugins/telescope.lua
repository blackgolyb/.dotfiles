return {
    'nvim-telescope/telescope.nvim', tag = '*',
    dependencies = {
        'nvim-lua/plenary.nvim',
        -- optional but recommended
        { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
    },
    config = function()
        local builtin = require('telescope.builtin')

        vim.keymap.set('n', 'g/', builtin.live_grep, { desc = "Global search (Live Grep)" })
        vim.keymap.set('n', 'g*', builtin.grep_string, { desc = "Search word under cursor" })

        require('telescope').setup({ })
    end
}
