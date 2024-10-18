from .theme_parser import parse_theme_file
from pathlib import Path

from settings import *


default_theme = parse_theme_file(themes_path / "base_themes/default_thme.json")

themes = {
    "default": themes_path / "base_themes/default_thme.json",
}


def get_color_theme(name):
    if theme in themes:
        return themes.themes[theme]
    
    return default_theme

color_theme = get_color_theme(theme)

# {
#     "bar": {
#         "background_color": "#2E3440",
#         "border_color": "#2E3440",
#         "foreground_color": "#ffffff"
#     },
#     "screen": {
#         "wallpaper": "",
#         "wallpapers": ""
#     },
#     "apps": {
#         "glava": ""
#     }
# }