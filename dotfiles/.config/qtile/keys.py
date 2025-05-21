# Click, Drag, Group, Key, EzKey, Match, Screen
from groups import groups_keys
from libqtile.config import Key
from libqtile.lazy import lazy
from settings import (
    alt,
    arrows,
    bar_orientation,
    file_explorer,
    mod,
    scripts_path,
    secondary_mod,
    terminal,
    text_editor,
    webbrowser,
)
from sticky_manager import sticky_manager
from widgets import (
    brightness_widget,
    color_picker_widget,
    multi_monitor_widget,
    volume_widget,
)

# Scripts:
wp = (scripts_path / "video_wallpaper").resolve()
device_manager_script = (scripts_path / "device_manager").resolve()

default_keys = [
    # Управление фокусом
    Key([mod], arrows["left"], lazy.layout.left(), desc="Move focus to left"),  # Фокус влево
    Key([mod], arrows["right"], lazy.layout.right(), desc="Move focus to right"),  # Фокус вправо
    Key([mod], arrows["down"], lazy.layout.down(), desc="Move focus down"),  # Фокус вниз
    Key([mod], arrows["up"], lazy.layout.up(), desc="Move focus up"),  # Фокус вверх
    # Перемещение окон
    Key(
        [mod, "shift"],
        arrows["left"],
        lazy.layout.shuffle_left(),
        desc="Move window to the left",
    ),  # Переместить окно влево
    Key(
        [mod, "shift"],
        arrows["right"],
        lazy.layout.shuffle_right(),
        desc="Move window to the right",
    ),  # Переместить окно вправо
    Key(
        [mod, "shift"], arrows["down"], lazy.layout.shuffle_down(), desc="Move window down"
    ),  # Переместить окно вниз
    Key(
        [mod, "shift"], arrows["up"], lazy.layout.shuffle_up(), desc="Move window up"
    ),  # Переместить окно вверх
    # Изменение размера окна
    Key(
        [mod, secondary_mod],
        arrows["left"],
        lazy.layout.grow_left(),
        desc="Grow window to the left",
    ),  # Увеличить окно влево
    Key(
        [mod, secondary_mod],
        arrows["right"],
        lazy.layout.grow_right(),
        desc="Grow window to the right",
    ),  # Увеличитпапкамиь окно вправо
    Key(
        [mod, secondary_mod], arrows["down"], lazy.layout.grow_down(), desc="Grow window down"
    ),  # Увеличить окно вниз
    Key(
        [mod, secondary_mod], arrows["up"], lazy.layout.grow_up(), desc="Grow window up"
    ),  # Увеличить окно вверх
    # Переключение между макетами
    Key([mod], "m", lazy.next_layout(), desc="Toggle between layouts"),
    # Закрыть окно
    Key([mod], "u", lazy.window.kill(), desc="Kill focused window"),
    # Перезагрузить конфиг
    Key([mod, secondary_mod], "r", lazy.reload_config(), desc="Reload the config"),
    # Скрыть/раскрыть панель
    Key([mod, secondary_mod], "space", lazy.hide_show_bar(bar_orientation)),
    # Запуск приложений
    Key([mod], "Return", lazy.spawn(terminal)),
    # Key([mod], "f", lazy.spawn("firefox --wayland")), # Это для вайланда
    Key([mod, secondary_mod], "f", lazy.spawn(webbrowser)),  # Для иксов
    Key([mod, secondary_mod], "c", lazy.spawn(text_editor)),
    Key([mod, secondary_mod], "e", lazy.spawn(file_explorer)),
    Key([mod, secondary_mod], "t", lazy.spawn("telegram-desktop")),
    Key([mod, secondary_mod], "w", lazy.spawn(f"{wp} start")),
    Key(
        [mod, secondary_mod],
        "s",
        lazy.function(multi_monitor_widget.open_rofi_menu),
        desc="multi monitors",
    ),
    # Touchpad
    Key([mod], "t", lazy.spawn(f"{device_manager_script} touchpad")),
    # Touchscreen
    Key([mod, "shift"], "t", lazy.spawn(f"{device_manager_script} touchscreen")),
    # Color picker
    Key([mod, secondary_mod], "p", lazy.function(color_picker_widget.dropper.pick_color)),
    # Штука которая позволяет закрепить окно на всех рабочих поверхностях
    # Т.е. окно будет следовать за вами на всех робочих столах
    Key(
        [mod, secondary_mod],
        "v",
        lazy.spawn('rofi -modi "clipboard:greenclip print" -show clipboard'),
    ),
    Key(
        [mod],
        "o",
        lazy.function(sticky_manager.toggle_sticky_window),
        desc="toggle stick window",
    ),
    Key([mod], "space", lazy.spawn("rofi -show drun")),
    Key([mod], "home", lazy.spawn("betterlockscreen --lock")),
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
