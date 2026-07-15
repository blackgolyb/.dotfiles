-- Plugins:
-- - nvim-treesitter: https://github.com/nvim-treesitter/nvim-treesitter
--   Provides Treesitter parser installation, highlighting, folding, and indentation.
-- - nvim-treesitter-textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
--   Provides Treesitter textobject queries for other plugins.

local util = require("plugins.util")

local ensure_installed = {
    "bash",
    "c",
    "css",
    "diff",
    "git_config",
    "git_rebase",
    "gitattributes",
    "gitcommit",
    "gitignore",
    "html",
    "ini",
    "javascript",
    "jsdoc",
    "json",
    "jsonc",
    "lua",
    "luadoc",
    "luap",
    "make",
    "markdown",
    "markdown_inline",
    "nix",
    "printf",
    "python",
    "qmljs",
    "query",
    "regex",
    "rust",
    "ssh_config",
    "tmux",
    "toml",
    "tsx",
    "typescript",
    "udev",
    "vim",
    "vimdoc",
    "wgsl",
    "xml",
    "yaml",
}

-- build
util.build("nvim-treesitter", function()
    vim.schedule(function()
        pcall(vim.cmd.TSUpdate)
    end)
end)

-- install
vim.pack.add({
    util.gh("nvim-treesitter/nvim-treesitter"),
    util.gh("nvim-treesitter/nvim-treesitter-textobjects"),
})

-- setup
local treesitter = require("nvim-treesitter")
treesitter.setup()
vim.treesitter.language.register("json", "jsonc")
treesitter.install(ensure_installed)

vim.api.nvim_create_autocmd("FileType", {
    pattern = ensure_installed,
    callback = function()
        pcall(vim.treesitter.start)
        vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
        vim.wo.foldmethod = "expr"
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end,
})
