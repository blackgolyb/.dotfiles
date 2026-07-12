local ui = require("core.ui")

return {
    {
        "kdheepak/lazygit.nvim",
        lazy = true,
        cmd = {
            "LazyGit",
            "LazyGitConfig",
            "LazyGitCurrentFile",
            "LazyGitFilter",
            "LazyGitFilterCurrentFile",
        },
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        init = function()
            if vim.v.servername == "" then
                vim.fn.serverstart()
            end

            vim.g.lazygit_use_neovim_remote = 1
            vim.g.lazygit_floating_window_border_chars = ui.surface_border
            vim.env.NVIM_LISTEN_ADDRESS = vim.v.servername
            vim.env.GIT_EDITOR = "nvr --remote-wait-silent +'set bufhidden=wipe'"
        end,
        keys = {
            { "<leader>g", "<cmd>LazyGit<cr>", desc = "LazyGit" },
        },
    },
}
