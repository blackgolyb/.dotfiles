_G.sidebar_manager = {
  current = "none"
}

_G.sidebar = function(name)
  local prev = _G.sidebar_manager.current

  if _G.sidebar_manager.current == name then
    _G.sidebar_manager.current = "none"
  else
    _G.sidebar_manager.current = name
  end

  if _G.sidebar_manager.current ~= "none" then
    vim.api.nvim_exec_autocmds("User", {
      pattern = "SidebarOpen",
      data = {
        name = _G.sidebar_manager.current,
      },
    })
  end

  if prev ~= "none" then
    vim.api.nvim_exec_autocmds("User", {
      pattern = "SidebarClose",
      data = { 
        name = prev,
      },
    })
  end
end


_G.sidebar_on_open = function(name, callback)
  vim.api.nvim_create_autocmd("User", {
    pattern = "SidebarOpen",
    callback = function(ev)
      if ev.data.name ~= name then
        return
      end
      callback()
    end,
  })
end

_G.sidebar_on_close = function(name, callback)
  vim.api.nvim_create_autocmd("User", {
    pattern = "SidebarClose",
    callback = function(ev)
      if ev.data.name ~= name then
        return
      end
      callback()
    end,
  })
end
