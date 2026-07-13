return {
    name = "local-buffer-manager",
    dir = vim.fn.stdpath("config"),
    dependencies = {
        "nvim-tree/nvim-web-devicons",
    },
    cmd = {
        "Buffers",
        "BuffersFloat",
        "BuffersCloseUnmodified",
    },
    keys = {
        {
            "<leader>B",
            function()
                require("core.buffers").toggle_float()
            end,
            desc = "Editable buffers",
        },
    },
    config = function()
        require("core.buffers").setup({
            order = "lastused",
            close_modified = "confirm",
        })

        vim.api.nvim_create_user_command("Buffers", function()
            require("core.buffers").open()
        end, { desc = "Open editable buffer manager" })

        vim.api.nvim_create_user_command("BuffersFloat", function()
            require("core.buffers").open_float()
        end, { desc = "Open editable buffer manager in a float" })

        vim.api.nvim_create_user_command("BuffersCloseUnmodified", function()
            require("core.buffers").close_unmodified_except_current()
        end, { desc = "Close unmodified buffers except current" })
    end,
}
