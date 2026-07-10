local ensure_installed = {
    'bash',
    'c',
    'diff',
    'html',
    'javascript',
    'jsdoc',
    'json',
    'lua',
    'luadoc',
    'luap',
    'markdown',
    'markdown_inline',
    'nix',
    'printf',
    'python',
    'query',
    'regex',
    'rust',
    'toml',
    'tsx',
    'typescript',
    'vim',
    'vimdoc',
    'wgsl',
    'xml',
    'yaml',
}

return {
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    build = ':TSUpdate',
    config = function()
        local treesitter = require('nvim-treesitter')
        treesitter.setup()
        vim.treesitter.language.register('json', 'jsonc')
        treesitter.install(ensure_installed)

        vim.api.nvim_create_autocmd('FileType', {
            pattern = ensure_installed,
            callback = function()
                pcall(vim.treesitter.start)
                vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
                vim.wo.foldmethod = 'expr'
                vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
            end,
        })
    end,
}
