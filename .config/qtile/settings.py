from pathlib import Path


home_path = Path.home()
config_path = home_path / '.config/qtile/'
resources_path = home_path / '.config/qtile/'
scripts_path = home_path / '.config/qtile/'

text_editor = 'code'
terminal = 'alacritty'
webbrowser = 'firefox'
file_explorer = 'thunar'

group_gaps = 7
outer_gaps = 7
# Сейчас хорошо работают: 'top' | 'bottom'
# Для 'left' и 'right' можно использовать только подходящие виджеты
bar_orientation = 'top' # one of: 'left' | 'right' | 'top' | 'bottom'
bar_gaps = [0, 0, 0, 0]
is_bar_rounded = False

# keyboard_layouts = ['us', 'ru', 'ua']
keyboard_layouts = ['us', 'ru']