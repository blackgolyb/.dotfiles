from settings import is_bar_rounded
from layouts import default_layouts, default_floating_layout
from keys import default_keys
from groups import default_groups
from screens import default_screens
from bars import main_bar
from mouse import default_mouse
from widgets import widget_defaults
from wallpaper_managers import wallpaper_managers #noqa
import hooks

import locale


locale.setlocale(locale.LC_TIME, "uk_UA.UTF-8")


# Настройка WM

# Яхз
dgroups_key_binder = None

# На каком воркспейсе что открывается
dgroups_app_rules = []  # type: list

# Фокус следует за курсором
follow_mouse_focus = True

# Переносить окно на передний план при нажатии на него
bring_front_click = False

# Перемещать курсор в центр окна
cursor_warp = False

# Автофулскрин
auto_fullscreen = True

# Фокусировка на запущенном окне
focus_on_window_activation = "smart"

# Перестраивать эраны при реконфигурировании
reconfigure_screens = False

# Минимизировать приложения или нет, яхз что то для геймеров
auto_minimize = True

# Устройства вывода для вялого
wl_input_rules = None

# Яхз, трогать не надо со слов разрабов
wmname = "LG3D"


# Мои настройки WM
# Настройки групп
groups = default_groups

# Настройки расположения окно
layouts = default_layouts

# Правила для плавающих окон
floating_layout = default_floating_layout

# Настройки экранов
screens = default_screens

# Настройки мыши
mouse = default_mouse

# Хоткеи
keys = default_keys


hooks.init_hooks(main_bar, is_bar_rounded)
extension_defaults = widget_defaults.copy()
