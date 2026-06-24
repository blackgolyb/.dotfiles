_G.sidebar_on_open("neotree", function()
    vim.cmd("Neotree")
end)

_G.sidebar_on_close("neotree", function()
    require("neo-tree.command").execute({ action = "close" })
end)

return {
    {
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v3.x",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "MunifTanjim/nui.nvim",
            "nvim-tree/nvim-web-devicons",
        },
        keys = {
            { "<leader>e", function() _G.sidebar("neotree") end, desc = "Toggle Filetree", silent = true },
        },
        lazy = false,
        opts = {
            window = {
                position = "right",
                width = 30,
                mappings = {
                    ["<esc>"] = function() _G.sidebar("none") end,
                    ["h"] = "close_node",
                    ["n"] = "add",
                    ["N"] = "add_directory",
                    ["a"] = "none",
                    ["A"] = "none",
                    ["l"] = function(state)
                        local node = state.tree:get_node()
                        if node.type == "directory" then
                            if not node:is_expanded() then
                                require("neo-tree.sources.filesystem.commands").open(state)
                            else
                                -- Якщо папка вже відкрита, йдемо до першого дитини (вниз)
                                require("neo-tree.ui.renderer").focus_node(state, node:get_child_ids()[1])
                            end
                        end
                    end,
                }
            },
            close_if_last_window = true,
            filesystem = {
                hijack_netrw_behavior = "disabled",
                follow_current_file = {
                    enabled = true,
                },
                filtered_items = {
                    hide_dotfiles = false,
                    hide_gitignored = false,
                },
            },
            event_handlers = {
                {
                    event = "file_added",
                    handler = function(file_path)
                        local timer = vim.loop.new_timer()
                        timer:start(50, 0, vim.schedule_wrap(function()
                            vim.cmd("edit " .. vim.fn.fnameescape(file_path))
                            _G.sidebar("none")

                            timer:stop()
                            timer:close()
                        end))
                    end
                },
                {
                    event = "file_opened",
                    handler = function(file_path)
                        require("neo-tree.command").execute({ action = "close" })
                    end
                },
            },
            renderers = {
                file = {
                    { "indent" },
                    { "icon" },
                    { "name", use_git_status_colors = true },
                },
                directory = {
                    { "indent" },
                    { "icon" },
                    { "name", use_git_status_colors = true },
                },
            },
        }
    }
}

