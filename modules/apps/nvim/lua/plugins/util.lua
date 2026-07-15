local M = {}
local build_hooks = {}
local build_autocmd_created = false

function M.gh(repo)
    return "https://github.com/" .. repo
end

function M.notify_build_error(title, result)
    if result.code == 0 then
        return
    end

    vim.schedule(function()
        vim.notify(result.stderr, vim.log.levels.ERROR, { title = title })
    end)
end

local function ensure_build_autocmd()
    if build_autocmd_created then
        return
    end

    build_autocmd_created = true
    vim.api.nvim_create_autocmd("PackChanged", {
        group = vim.api.nvim_create_augroup("NativePackBuilds", { clear = true }),
        callback = function(args)
            local data = args.data
            if not data or (data.kind ~= "install" and data.kind ~= "update") then
                return
            end

            local name = data.spec and data.spec.name or vim.fn.fnamemodify(data.path or "", ":t")
            local callback = build_hooks[name]
            if callback then
                callback(data)
            end
        end,
    })
end

function M.build(name, callback)
    build_hooks[name] = callback
    ensure_build_autocmd()
end

return M
