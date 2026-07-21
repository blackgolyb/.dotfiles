-- Plugin: nvim-jdtls
-- URL: https://github.com/mfussenegger/nvim-jdtls
-- Description: Adds richer Java support on top of eclipse.jdt.ls.

local util = require("plugins.util")

vim.pack.add({ util.gh("mfussenegger/nvim-jdtls") })

local root_markers = {
    "gradlew",
    "mvnw",
    "pom.xml",
    "build.gradle",
    "build.gradle.kts",
    "settings.gradle",
    "settings.gradle.kts",
    ".git",
}

local function get_root_dir()
    return require("lspconfig.util").root_pattern(unpack(root_markers))(vim.fn.expand("%:p"))
end

local function get_workspace_dir(root_dir)
    local project_name = vim.fs.basename(vim.fs.normalize(root_dir))
    local suffix = string.sub(vim.fn.sha256(root_dir), 1, 8)

    return table.concat({
        vim.fn.stdpath("data"),
        "jdtls-workspaces",
        project_name .. "-" .. suffix,
    }, "/")
end

local function java_keymaps(bufnr)
    local jdtls = require("jdtls")
    local opts = { buffer = bufnr }

    vim.keymap.set(
        "n",
        "<localleader>oi",
        jdtls.organize_imports,
        vim.tbl_extend("force", opts, {
            desc = "Organize Java imports",
        })
    )
    vim.keymap.set(
        "n",
        "<localleader>ev",
        jdtls.extract_variable,
        vim.tbl_extend("force", opts, {
            desc = "Extract Java variable",
        })
    )
    vim.keymap.set(
        "x",
        "<localleader>ev",
        [[<Esc><Cmd>lua require('jdtls').extract_variable(true)<CR>]],
        vim.tbl_extend("force", opts, {
            desc = "Extract Java variable",
        })
    )
    vim.keymap.set(
        "n",
        "<localleader>ec",
        jdtls.extract_constant,
        vim.tbl_extend("force", opts, {
            desc = "Extract Java constant",
        })
    )
    vim.keymap.set(
        "x",
        "<localleader>ec",
        [[<Esc><Cmd>lua require('jdtls').extract_constant(true)<CR>]],
        vim.tbl_extend("force", opts, {
            desc = "Extract Java constant",
        })
    )
    vim.keymap.set(
        "x",
        "<localleader>em",
        [[<Esc><Cmd>lua require('jdtls').extract_method(true)<CR>]],
        vim.tbl_extend("force", opts, {
            desc = "Extract Java method",
        })
    )
end

vim.api.nvim_create_autocmd("FileType", {
    pattern = "java",
    callback = function()
        local root_dir = get_root_dir()

        if not root_dir then
            vim.notify("jdtls root not found", vim.log.levels.WARN)
            return
        end

        local capabilities = require("blink.cmp").get_lsp_capabilities()

        require("jdtls").start_or_attach({
            cmd = {
                "jdtls",
                "-data",
                get_workspace_dir(root_dir),
            },
            root_dir = root_dir,
            capabilities = capabilities,
            on_attach = function(_, bufnr)
                java_keymaps(bufnr)
            end,
        })
    end,
})
