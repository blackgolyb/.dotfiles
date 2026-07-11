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
                ['Exit']               = '<C-c>',
            }
        end,
        config = function()
            local function in_vm()
                return vim.fn.exists('b:visual_multi') == 1
            end

            local function in_vm_extend_mode()
                local vm = vim.g.Vm
                return type(vm) == 'table' and vm.extend_mode == 1
            end

            local function feed(keys, mode)
                vim.api.nvim_feedkeys(
                    vim.api.nvim_replace_termcodes(keys, true, false, true),
                    mode,
                    false
                )
            end

            vim.keymap.set('x', 'gl', '<Plug>(VM-Find-Subword-Under)', { remap = true })
            vim.keymap.set('x', 'ga', '<Plug>(VM-Visual-All)', { remap = true })
            vim.keymap.set('x', 'gI', '<Plug>(VM-Visual-Cursors)', { remap = true })

            local group = vim.api.nvim_create_augroup('visual_multi_custom_esc', { clear = true })

            vim.api.nvim_create_autocmd('User', {
                group = group,
                pattern = 'visual_multi_start',
                callback = function()
                    vim.keymap.set('n', '<Esc>', function()
                        if not in_vm() then
                            pcall(vim.keymap.del, 'n', '<Esc>', { buffer = true })
                            feed('<Esc>', 'm')
                        elseif in_vm_extend_mode() then
                            vim.cmd('call b:VM_Selection.Global.change_mode(1)')
                        else
                            feed('<Plug>(VM-Exit)', 'm')
                        end
                    end, { buffer = true, nowait = true, silent = true })
                end,
            })

            vim.api.nvim_create_autocmd('User', {
                group = group,
                pattern = 'visual_multi_exit',
                callback = function(args)
                    pcall(vim.keymap.del, 'n', '<Esc>', { buffer = args.buf })
                end,
            })
        end
    },
}
