from libqtile import layout
from libqtile.config import Key, Match
from libqtile.lazy import lazy
from libqtile.widget.battery import BatteryState
from playsound import playsound

from settings import is_bar_rounded, resources_path, mod
from services.sticky_window_manager import StickyWindowManager
from services.wallpaper_manager import WallpaperManager
from layouts import default_layouts
from keys import default_keys
from groups import default_groups, groups_keys
from screens import default_screens
from bars import main_bar
from mouse import default_mouse
from widgets import widget_defaults, bat1, bat2
import hooks

import locale


locale.setlocale(locale.LC_TIME, "uk_UA.UTF-8")


# Настройка WM
sticky_manager = StickyWindowManager(
    activate_hooks=True,
    sticky_rules=[
        Match(role="PictureInPicture"),
        Match(title="Kolo-Face"),
    ],
    groups_rules=[
        {
            # "match": Match(title="Picture-in-Picture"),
            "match": Match(role="PictureInPicture"),
            "groups": "__all__",
            # 'groups': ('0', '1', '2'),
            # 'exclude_groups': ('0', '1', '2'),
        },
        {
            "match": Match(role="Kolo-Face"),
            "groups": "__all__",
        },
    ],
)

# Правила для плавающих окон
floating_layout = layout.Floating(
    border_width=0,
    float_rules=[
        # Run the utility of `xprop` to see the wm class and name of an X client.
        *layout.Floating.default_float_rules,
        Match(wm_class="confirmreset"),  # gitk
        Match(wm_class="makebranch"),  # gitk
        Match(wm_class="maketag"),  # gitk
        Match(wm_class="ssh-askpass"),  # ssh-askpass
        Match(wm_class="imv"),
        Match(wm_class="mpv"),
        Match(wm_class="viewnior"),
        Match(title="branchdialog"),  # gitk
        Match(title="pinentry"),  # GPG key password entry
        Match(title="Picture-in-Picture"),
        Match(title="Kolo-Face"),
    ],
)

# bat1.add_event(
#     BatteryState.CHARGING,
#     lambda: playsound(str(resources_path / "sounds" / "poweron.mp3")),
# )
# bat2.add_event(
#     BatteryState.CHARGING,
#     lambda: playsound(str(resources_path / "sounds" / "poweron.mp3")),
# )

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

# Настройки экранов
screens = default_screens

wallpaper_priority = [
    ("8.jpg", 7),
    ("10.png", 7),
    ("13.jpeg", 14),
]

wallpaper_managers = [
    WallpaperManager(
        screen=screens[0],
        wallpaper=resources_path / "wallpapers",
        wallpaper_priority=wallpaper_priority,
        wallpaper_mode="stretch",
        activate_hooks=True,
    ),
    WallpaperManager(
        screen=screens[1],
        wallpaper=resources_path / "wallpapers",
        wallpaper_priority=wallpaper_priority,
        wallpaper_mode="stretch",
        activate_hooks=True,
    ),
]

# Настройки мыши
mouse = default_mouse

# Хоткеи
keys = default_keys

# Расширения для хотеев
keys.append(
    # Штука которая позволяет закрепить окно на всех рабочих поверхностях
    # Т.е. окно будет следовать за вами на всех робочих столах
    Key(
        [mod],
        "o",
        lazy.function(sticky_manager.toggle_sticky_window),
        desc="toggle stick window",
    ),
)

keys.extend(groups_keys)


hooks.init_hooks(main_bar, is_bar_rounded)
extension_defaults = widget_defaults.copy()
