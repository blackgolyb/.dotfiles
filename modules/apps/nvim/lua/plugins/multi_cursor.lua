return {
    {
        'mg979/vim-visual-multi',
        branch = 'master',
        init = function()
            vim.g.VM_maps = {
                -- Find
                ['Find Under']         = 'gl',
                ['Find Prev']          = 'gL',
                ['Select All']         = 'ga',

                -- Skip
                ['Skip Region']        = 'g>',
                ['Remove Region']      = 'g<',

                -- Vertical expand cursors
                ['Add Cursor Down']    = 'gj',
                ['Add Cursor Up']      = 'gk',

		['Switch Mode']        = 'v',    
		['Exit']               = '<Esc>',
            }
        end,
        config = function()
            -- Додаткові налаштування для покращення досвіду
            -- vim.g.VM_highlight_parent = 1 -- Підсвічувати "головний" курсор
            -- vim.g.VM_theme = 'ocean'      -- Можна змінити тему для кращої видимості
        end
    },
}
