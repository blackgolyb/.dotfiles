-- Push Neovim statusline into tmux status bar
return {
    'vimpostor/vim-tpipeline',
    lazy = false,
    priority = 800,
    dependencies = { 'nvim-lualine/lualine.nvim' },
    init = function()
        require('core.tmux_lualine').setup()

        function _G.tmux_lualine_statusline()
            return require('core.tmux_lualine').statusline()
        end

        vim.g.tpipeline_clearstl = 1
        vim.g.tpipeline_statusline = '%!v:lua.tmux_lualine_statusline()'
    end,
}
