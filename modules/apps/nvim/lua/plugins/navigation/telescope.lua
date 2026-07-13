-- Fuzzy finder framework
local ui = require("core.ui")

return {
    'nvim-telescope/telescope.nvim',
    tag = 'v0.2.1',
    dependencies = {
        'nvim-lua/plenary.nvim',
        'nvim-telescope/telescope-ui-select.nvim',
        { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
    },
    config = function()
        local builtin = require('telescope.builtin')
        local actions = require('telescope.actions')
        local borderchars = {
            prompt = ui.surface_border,
            results = ui.surface_border,
            preview = ui.surface_border,
        }

        vim.keymap.set('n', 'g/', builtin.live_grep, { desc = "Global search (Live Grep)" })
        vim.keymap.set('n', 'g*', builtin.grep_string, { desc = "Search word under cursor" })

        vim.keymap.set("n", "<leader>D", builtin.diagnostics, {
          desc = "Workspace diagnostics",
        })

        vim.keymap.set("n", "<leader>d", function()
          builtin.diagnostics({ bufnr = 0 })
        end, {
          desc = "Buffer diagnostics",
        })

        vim.keymap.set("n", "<leader>b", function()
            builtin.buffers({
                sort_mru = true,
                select_current = true,
                show_all_buffers = true,
            })
        end, {
            desc = "Buffers",
        })

        vim.keymap.set('v', 'g/', function()
            local function get_visual_selection()
                vim.cmd('noau normal! "vy"')
                local text = vim.fn.getreg('v')
                vim.fn.setreg('v', {})
                return text
            end

            local selection = get_visual_selection()
            builtin.live_grep({ default_text = selection })
        end, { desc = "Search selection in project" })

        require('telescope').setup({
            defaults = {
                initial_mode = "insert",
                mappings = {
                    i = {
                        ["<esc>"] = actions.close,
                    },
                },
                sorting_strategy = "ascending",
                border = true,
                borderchars = borderchars,
                layout_config = {
                    prompt_position = "top",
                },
            },
            extensions = {
                ["ui-select"] = {
                    require("telescope.themes").get_dropdown({
                        border = true,
                        borderchars = borderchars,
                    }),
                },
            },
        })

        require('telescope').load_extension('fzf')
        require("telescope").load_extension("ui-select")
    end
}
