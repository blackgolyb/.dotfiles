local function fix_python3_host()
    -- Neovim (as of 0.12.5) pre-initializes g:loaded_python3_provider to 0
    -- without defining provider#python3#Require. The legacy autoload then
    -- `finish`es early on its guard, so the "python3" host used by remote
    -- plugins (e.g. molten) can never bootstrap and :UpdateRemotePlugins
    -- fails with "E117: Unknown function: provider#python3#Require".
    --
    -- Workaround: clear the guard and source the autoload now, which defines
    -- the provider functions and records successful detection.
    if vim.fn.exists("g:loaded_python3_provider") == 1 and vim.g.loaded_python3_provider == 0 then
        vim.g.loaded_python3_provider = nil
        vim.cmd.runtime("autoload/provider/python3.vim")
        if vim.fn.exists("*provider#python3#Require") ~= 1 then
            vim.notify("python3 provider bootstrap failed", vim.log.levels.WARN)
        end
    end
end

fix_python3_host()
