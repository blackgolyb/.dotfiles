return {
    {
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v3.x",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "MunifTanjim/nui.nvim",
            "nvim-tree/nvim-web-devicons",
        },
        lazy = false,
        opts = {
            window = {
                position = "right",
                width = 30,
                mappings = {
                    ["<esc>"] = "close_window",
                    ["h"] = "close_node",
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
                    event = "file_opened",
                    handler = function(file_path)
                        -- Закриваємо Neo-tree одразу після відкриття файлу
                        require("neo-tree.command").execute({ action = "close" })
                    end
                },
            }
        }
    }
}
