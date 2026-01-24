return {
  "blackgolyb/monodark.nvim",
  version = false,
  priority = 1000,
  config = function()
    require('monodark').setup {
        transparent_background = true,
    }
    require('monodark').load()
  end,
}
