# Click, Drag, Group, Key, EzKey, Match, Screen
from libqtile.config import Key
from libqtile.lazy import lazy

from settings import scripts_path, mod, alt, bar_orientation, terminal, webbrowser, text_editor, file_explorer
from widgets import (
    volume_widget,
    brightness_widget,
    color_picker_widget,
    multi_monitor_widget,
)
from sticky_manager import sticky_manager
from groups import groups_keys

wp = (scripts_path / "video_wallpaper").resolve()

default_keys = [
    # Управление фокусом
    Key([mod], "left", lazy.layout.left(), desc="Move focus to left"),  # Фокус влево
    Key(
        [mod], "right", lazy.layout.right(), desc="Move focus to right"
    ),  # Фокус вправо
    Key([mod], "down", lazy.layout.down(), desc="Move focus down"),  # Фокус вниз
    Key([mod], "up", lazy.layout.up(), desc="Move focus up"),  # Фокус вверх
    # Перемещение окон
    Key(
        [mod, "shift"],
        "left",
        lazy.layout.shuffle_left(),
        desc="Move window to the left",
    ),  # Переместить окно влево
    Key(
        [mod, "shift"],
        "right",
        lazy.layout.shuffle_right(),
        desc="Move window to the right",
    ),  # Переместить окно вправо
    Key(
        [mod, "shift"], "down", lazy.layout.shuffle_down(), desc="Move window down"
    ),  # Переместить окно вниз
    Key(
        [mod, "shift"], "up", lazy.layout.shuffle_up(), desc="Move window up"
    ),  # Переместить окно вверх
    # Изменение размера окна
    Key(
        [mod, "control"],
        "left",
        lazy.layout.grow_left(),
        desc="Grow window to the left",
    ),  # Увеличить окно влево
    Key(
        [mod, "control"],
        "right",
        lazy.layout.grow_right(),
        desc="Grow window to the right",
    ),  # Увеличитпапкамиь окно вправо
    Key(
        [mod, "control"], "down", lazy.layout.grow_down(), desc="Grow window down"
    ),  # Увеличить окно вниз
    Key(
        [mod, "control"], "up", lazy.layout.grow_up(), desc="Grow window up"
    ),  # Увеличить окно вверх
    Key(
        [mod], "n", lazy.layout.normalize(), desc="Reset all window sizes"
    ),  # Вернуть все взад
    # Переключение между макетами
    Key([mod], "Tab", lazy.next_layout(), desc="Toggle between layouts"),
    # Переключение между макетами
    Key([mod, "shift"], "Tab", lazy.prev_layout(), desc="Toggle between layouts"),
    # Закрыть окно
    Key([mod], "q", lazy.window.kill(), desc="Kill focused window"),
    # Перезагрузить конфиг
    Key([mod, "control"], "r", lazy.reload_config(), desc="Reload the config"),
    # Выйти из Qtile
    Key([mod, "control"], "q", lazy.shutdown(), desc="Shutdown Qtile"),
    # Выполнить команды (типо встроенное dmenu)
    Key([mod], "d", lazy.spawncmd(), desc="Spawn a command using a prompt widget"),
    # Скрыть/раскрыть панель
    Key([mod, "control"], "space", lazy.hide_show_bar(bar_orientation)),
    # Запуск приложений
    Key([mod], "Return", lazy.spawn(terminal)),
    # Key([mod], "f", lazy.spawn("firefox --wayland")), # Это для вайланда
    Key([mod], "f", lazy.spawn(webbrowser)),  # Для иксов
    Key([mod], "c", lazy.spawn(text_editor)),
    Key([mod], "e", lazy.spawn(file_explorer)),
    Key([mod], "t", lazy.spawn("telegram-desktop")),
    Key([mod], "space", lazy.spawn("rofi -show drun")),
    Key(
        [mod], "v", lazy.spawn('rofi -modi "clipboard:greenclip print" -show clipboard')
    ),
    Key([mod], "l", lazy.spawn("betterlockscreen --lock")),
    # Раскладка клавиатуры
    Key(
        [alt],
        "Shift_L",
        lazy.widget["keyboardlayout"].next_keyboard(),
        desc="Next keyboard layout.",
    ),
    # Скриешоты
    # Нужно установить gnome-screenshot
    Key([], "Print", lazy.spawn("flameshot gui")),
    Key([mod], "w", lazy.spawn(f"{wp} start")),
    Key(
        [mod],
        "s",
        lazy.function(multi_monitor_widget.open_rofi_menu),
        desc="multi monitors",
    ),
    # Штука которая позволяет закрепить окно на всех рабочих поверхностях
    # Т.е. окно будет следовать за вами на всех робочих столах
    Key(
        [mod],
        "o",
        lazy.function(sticky_manager.toggle_sticky_window),
        desc="toggle stick window",
    ),
    # Color picker
    Key([mod], "p", lazy.function(color_picker_widget.dropper.pick_color)),
    # Контроль звука и яркости
    Key([], "XF86AudioLowerVolume", lazy.function(volume_widget.down)),
    Key([], "XF86AudioRaiseVolume", lazy.function(volume_widget.up)),
    Key([], "XF86AudioMute", lazy.function(volume_widget.mute)),
    Key([], "XF86AudioMicMute", lazy.spawn("amixer set Capture togglemute")),
    # Яркость нужно установить brightnessctl
    Key([], "XF86MonBrightnessDown", lazy.function(brightness_widget.down)),
    Key([], "XF86MonBrightnessUp", lazy.function(brightness_widget.up)),
    *groups_keys,
]
