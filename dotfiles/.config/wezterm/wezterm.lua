local wezterm = require 'wezterm'

local config = wezterm.config_builder()

-- config.color_scheme = 'custom'
config.color_scheme = 'Breeze (Gogh)'
config.window_background_opacity = 0.85
config.window_padding = {
    left = 25,
    right = 25,
    top = 25,
    bottom = 25,
}
config.enable_tab_bar = false

config.font = wezterm.font 'FiraCode Nerd Font Mono'
config.font_size = 15.0
config.bold_brightens_ansi_colors = false

return config
