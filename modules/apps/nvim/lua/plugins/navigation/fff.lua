-- Plugin: fff.nvim
-- URL: https://github.com/dmtrKovalenko/fff.nvim
-- Description: Fast fuzzy file finder with a native Rust backend.

local util = require("plugins.util")

local opts = {
    debug = {
        enabled = true,
        show_scores = false,
    },
    prompt = "  ",
    title = "Files",
    preview = {
        enabled = false,
    },
    layout = {
        border = "single",
        title_pos = "center",
        prompt_position = "top",
        height = 0.6,
        width = 0.4,
    },
    hl = {
        border = "FFFBorder",
        normal = "FFFNormal",
        prompt = "FFFPrompt",
        title = "FFFTitle",
        cursor = "FFFCursor",
    },
}

local function ensure_binary()
    local ok, download = pcall(require, "fff.download")
    if not ok then
        vim.notify("Failed to load fff downloader", vim.log.levels.ERROR)
        return false
    end

    local binary_path = download.get_binary_path()
    local stat = vim.uv.fs_stat(binary_path)
    if stat and stat.type == "file" then
        return true
    end

    local build_ok, err = pcall(download.download_or_build_binary)
    if not build_ok then
        vim.notify("Failed to build fff.nvim binary: " .. err, vim.log.levels.ERROR)
        return false
    end

    return true
end

-- pre
vim.g.fff = vim.tbl_deep_extend("force", vim.g.fff or {}, {
    lazy_sync = true,
})

-- build
util.build("fff.nvim", function()
    ensure_binary()
end)

-- install
vim.pack.add({ util.gh("dmtrKovalenko/fff.nvim") })

-- build
ensure_binary()
vim.api.nvim_create_user_command("FFFBuild", function()
    ensure_binary()
end, { desc = "Download or build fff.nvim native binary" })

-- setup
local fff_layout = require("fff.layout")

if not fff_layout._title_pos_patched then
    local compute = fff_layout.compute

    fff_layout.compute = function(config, ...)
        local result = compute(config, ...)
        local title_pos = config.layout and config.layout.title_pos

        if title_pos and result.win_configs then
            for _, win in ipairs({ result.win_configs.list, result.win_configs.input }) do
                if win and win.title then
                    win.title_pos = title_pos
                end
            end
        end

        return result
    end

    fff_layout._title_pos_patched = true
end

require("fff").setup(opts)

-- keymaps
vim.keymap.set("n", "<leader>f", function()
    require("fff").find_files()
end, { desc = "Fuzzy Find Files" })

vim.keymap.set("i", "<C-x><C-f>", function()
    require("fff").find_files({
        on_submit = function(item, ctx)
            local path = ctx.relative_path
            vim.api.nvim_feedkeys("a" .. path, "n", false)
        end,
    })
end, { desc = "Insert file path via fff" })
