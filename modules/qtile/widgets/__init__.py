from libqtile import widget
from libqtile.widget.battery import BatteryState
from libqtile.lazy import lazy
from libqtile.log_utils import logger
from qtile_extras import widget as qe_widget

from settings import *
from .base import WidgetGroup, WidgetBox, WidgetBoxTest
from .battery import Batteries, BatteriesIcon
from .volume import Volume
from .brightness import Brightness
from .multi_monitor import MultiMonitor
from .color_picker import ColorPicker, ColorPickerDropper, ColorPickerPalette
from .keyboard_layout import KeyboardLayout
from .yt_music import YTMusicWidget
from .yt_music.api import api as yt_music_api
from .bluetooth import Bluetooth
from themes import color_theme


rofi_wifi_menu = (
    f"bash {home_path}/.config/rofi-network-manager/rofi-network-manager.sh"
)
rofi_bluetooth_menu = f"bash {home_path}/.config/rofi-bluetooth/rofi-bluetooth"



# ВИДЖЕТЫ НА ПАНЕЛИ И ИХ ПАРАМЕТРЫ ------------------------------------------------
widget_defaults = dict(
    font=font,
    fontsize=fontsize,
    padding=8,
)


decor = {
    "decorations": [
        qe_widget.decorations.BorderDecoration(
            colour=color_theme["bar_foreground_color"],
            border_width=1,
        )
    ],
}


volume_widget = Volume(
    mouse_callbacks={"Button3": lazy.spawn("pavucontrol")},
    padding=0,
)

brightness_widget = Brightness(
    fmt="󰖨 {}",
    padding=0,
)

multi_monitor_widget = MultiMonitor(
    padding=0,
)

color_picker_widget = ColorPicker()

yt_music_widget = YTMusicWidget(yt_music_api)

base_groupbox = widget.GroupBox(
    borderwidth=1,  # Толщина рамки
    highlight_method="line",
    block_highlight_text_color="#ffffff",
    this_current_screen_border="#ffffff",  # C3C3C3  Цвет фона активного воркспейса
    inactive="#777777",
    active="#ffffff",
    other_screen_border="#3333ff",
    highlight_color=["#2E3440", "#2E3440"],
    rounded=True,
    margin_x=0,
    margin_y=2,
    markup=True,
    hide_unused=True,
)

battery_pack_widget = WidgetGroup(
    widgets=[
       # BatteriesIcon(
       #     theme_path=str(resources_path / "battery_icons"),
       #     batteries=[0],
       #     padding=3,
       #     update_interval=5,
       #     scale=1,
       # ),
        Batteries(
            batteries=[0, ],
            padding=3,
            format="{percent:2.0%}",
            update_interval=1,
            notify_below=10,
            hide_threshold=True,
        ),
    ]
)

clock_widget = WidgetBox(
    text_closed="",
    text_open="",
    padding=0,
    widgets=[
        # Дата
        widget.Clock(format="[%d %B %Y | %A]", padding=0),
        widget.Spacer(length=5),
    ],
)

kb_layout_widget = widget.KeyboardLayout(
    configured_keyboards=keyboard_layouts, update_interval=1, padding=0
)

bluetooth = Bluetooth(
    icon="",
    mouse_callbacks={"Button1": lazy.spawn(rofi_bluetooth_menu)},
)

main_menu = WidgetBox(
    text_open="",
    text_closed="",
    padding=3,
    widgets=[
        widget.TextBox(text="|"),
        widget.Spacer(length=5),
        # Запуск bpython
        widget.TextBox(
            text=" ",
            mouse_callbacks={"Button1": lazy.spawn(f"{terminal} -e bpython")},
        ),
        widget.Spacer(length=5),
        # Открытие конфига qtile в редакторе кода
        widget.TextBox(
            text=" ",
            mouse_callbacks={"Button1": lazy.spawn(f"{text_editor} {config_path}")},
        ),
        widget.Spacer(length=5),
        qe_widget.TextBox(
            text="SEMPAI",
            margin=6,
            padding=3,
            mouse_callbacks={
                "Button1": lazy.spawn(f"{webbrowser} https://anifap.top/")
            },
            **decor,
        ),
        widget.Image(
            filename=str(resources_path / "menu_images" / "hent.jpg"),
            mouse_callbacks={
                "Button1": lazy.spawn(f"{webbrowser} https://anifap.top/")
            },
        ),
        widget.Spacer(length=5),
        widget.TextBox(text="|"),
    ],
)


default_widgets = [
    # Menu
    widget.Spacer(length=20),
    widget.Image(
        filename=str(resources_path / "menu_images" / "logo.png"),
        mouse_callbacks={"Button1": main_menu.cmd_toggle},
        margin=4,
    ),
    main_menu,
    widget.Spacer(length=20),
    # Иконки воркспейсов
    base_groupbox,
    # Виджет выполнения команд
    widget.Prompt(),
    # Виджет пробела который заполняет всё доступное место
    widget.Spacer(),
    # widget.WindowName(),
    # widget.Spacer(),
    # Трэй, не работает в вялом, нужно будет юзать widget.StatusNotifier
    widget.Systray(),
    widget.Spacer(length=15),
    WidgetBox(
        text_closed="  ",
        text_open="  ",
        padding=0,
        widgets=[
            widget.TextBox(text="|"),
            # WIFI
            widget.Wlan(
                fmt=" {}",
                format="{essid}",
                padding=0,
                mouse_callbacks={"Button1": lazy.spawn(rofi_wifi_menu)},
                interface="wlp3s0",
            ),
            widget.Spacer(length=15),
            # Яркость
            brightness_widget,
            widget.Spacer(length=15),
            # Обновлений пакетов
            widget.CheckUpdates(
                distro="Arch",
                display_format=" {updates}",
                no_update_string=" 0",
                padding=0,
                mouse_callbacks={
                    "Button1": lazy.spawn(f"{terminal} -e sudo pacman -Sy")
                },
            ),
            widget.Spacer(length=6),
            # Bluetooth
            bluetooth,
            widget.Spacer(length=8),
            multi_monitor_widget,
            widget.Spacer(length=15),
            # Color picker
            # Нужно установить xcolor
            color_picker_widget,
            widget.Spacer(length=8),
            widget.TextBox(text="|"),
            widget.Spacer(length=8),
        ],
    ),
    widget.Spacer(length=8),
    # Виджет для управления YouTube Music
    # yt_music_widget,
    # widget.Spacer(length=8),
    # Виджет громкости пульсы
    # Нужно установить pavucontrol
    volume_widget,
    widget.Spacer(length=15),
    # Keyboard layout
    kb_layout_widget,
    widget.Spacer(length=15),
    battery_pack_widget,
    widget.Spacer(length=12),
    # Время и дата
    clock_widget,
    widget.Clock(format="%H:%M", padding=0, mouse_callbacks={"Button1": clock_widget.cmd_toggle}),
    widget.Spacer(length=20),
    # Кнопка выключения
    widget.TextBox(
        text="",
        mouse_callbacks={"Button1": lazy.spawn("poweroff")},
    ),
    widget.Spacer(length=10),
]
