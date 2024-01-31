from pathlib import Path

from libqtile.utils import guess_terminal

# from themes import default_theme, themes


DEBUG = False


# Paths
home_path = Path.home()
config_path = home_path / ".config/qtile/"
resources_path = config_path / "resources/"
scripts_path = config_path / "scripts/"
themes_path = config_path / "themes/"


# Theme
theme = "asd"
font = "JetBrainsMono Nerd Font Mono"
fontsize = 18
# font="Hack Nerd Font Mono"

# Keys variables
mod = "mod4"
alt = "mod1"


# Programs
text_editor = "code"
terminal = guess_terminal()  # 'alacritty'
# webbrowser = "firefox"
webbrowser = "floorp"
file_explorer = "thunar"


group_gaps = 10
outer_gaps = 10
# Сейчас хорошо работают: 'top' | 'bottom'
# Для 'left' и 'right' можно использовать только подходящие виджеты
bar_orientation = "top"  # one of: 'left' | 'right' | 'top' | 'bottom'
bar_gaps = [0, 0, 0, 0]
is_bar_rounded = False

# keyboard_layouts = ['us', 'ru', 'ua']
keyboard_layouts = ["us", "ua"]
# keyboard_layouts = ["us", "ru"]
