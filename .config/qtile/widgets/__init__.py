import subprocess

from libqtile import widget
from libqtile.lazy import lazy
from libqtile.log_utils import logger
from qtile_extras import widget as qe_widget

from settings import *
from .base import WidgetGroup, WidgetBox
from .volume import Volume
from .brightness import Brightness
from .color_picker import ColorPicker, ColorPickerDropper, ColorPickerPalette


rofi_wifi_menu = f'bash {home_path}/.config/rofi-network-manager/rofi-network-manager.sh'
rofi_bluetooth_menu = f'bash {home_path}/.config/rofi-bluetooth/rofi-bluetooth'


class MyBattery(widget.Battery):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        def get_prep__get_param(func):
            def _get_param(name):
                try:
                    result = func(name)
                    return result
                except:
                    return None
            return _get_param

        self._battery._get_param = get_prep__get_param(
            self._battery._get_param)


# ВИДЖЕТЫ НА ПАНЕЛИ И ИХ ПАРАМЕТРЫ ------------------------------------------------
widget_defaults = dict(
    font="JetBrainsMono Nerd Font",
    fontsize=12,
    padding=8,
)


decor = {
    "decorations": [
        qe_widget.decorations.BorderDecoration(
            colour="#ffffff",
            border_width=1,
        )
    ],
}

volume_widget = Volume(
    # limit_max_volume=True,
    mouse_callbacks={'Button3': lazy.spawn("pavucontrol")},
    padding=0,
)

brightness_widget = Brightness(
    fmt='󰖨 {}',
    padding=0,
)

color_picker = ColorPicker()


main_bar_widgets = [
    # Menu
    WidgetBox(
        text_closed='  ',
        text_open='  ',
        padding=3,
        widgets=[
            widget.TextBox(text="|"),
            widget.Spacer(length=5),

            # Запуск bpython
            widget.TextBox(
                text=" ",
                mouse_callbacks={'Button1': lazy.spawn(
                    f"{terminal} -e bpython")},
            ),
            widget.Spacer(length=5),

            # Открытие конфига qtile в редакторе кода
            widget.TextBox(
                text=" ",
                mouse_callbacks={'Button1': lazy.spawn(
                    f"{text_editor} {config_path / 'config.py'}")},
            ),
            widget.Spacer(length=5),


            qe_widget.TextBox(
                text="SEMPAI",
                margin=6,
                padding=3,
                mouse_callbacks={'Button1': lazy.spawn(
                    f"{webbrowser} https://anifap.me/")},
                **decor,
            ),
            widget.Image(
                filename=str(resources_path / 'menu_images/1.jpg'),
                mouse_callbacks={'Button1': lazy.spawn(
                    "alacritty -e bpython")},
            ),

            widget.Spacer(length=5),
            widget.TextBox(text="|"),
        ]
    ),
    widget.Spacer(length=20),

    # Текущий макет
    # widget.CurrentLayout(),
    
    # Иконки воркспейсов
    base_groupbox := widget.GroupBox(
        borderwidth=1,  # Толщина рамки
        # ('border', 'block', 'text', 'line') # Метод выделения активного воркспейса
        highlight_method='line',
        # '#DDDFE5',  # Цвет текста активного воркспейса
        block_highlight_text_color='#ffffff',
        this_current_screen_border='#ffffff',  # C3C3C3  Цвет фона активного воркспейса
        inactive='#777777',
        active='#ffffff',
        other_screen_border='#3333ff',
        highlight_color=['2E3440', '2E3440'],
        rounded=True,
        margin_x=0,
        margin_y=2,
        # margin=3,
        hide_unused=True,
    ),

    # Виджет выполнения команд
    widget.Prompt(),
    
    
    # Виджет пробела который заполняет всё доступное место
    widget.Spacer(),


    # Трэй, не работает в вялом, нужно будет юзать widget.StatusNotifier
    widget.Systray(),
    widget.Spacer(length=15),

    WidgetBox(
        text_closed='  ',
        text_open='  ',
        padding=0,
        widgets=[
            widget.TextBox(text="|"),

            # WIFI
            widget.Wlan(
                fmt=' {}',
                format='{essid}',
                padding=0,
                mouse_callbacks={'Button1': lazy.spawn(rofi_wifi_menu)},
            ),
            widget.Spacer(length=15),

            # Яркость
            brightness_widget,
            widget.Spacer(length=15),

            # Обновлений пакетов
            widget.CheckUpdates(
                distro='Arch',
                display_format=' {updates}',
                no_update_string=' 0',
                padding=0,
                mouse_callbacks={'Button1': lazy.spawn(f"{terminal} -e sudo pacman -Sy")},
            ),
            widget.Spacer(length=6),

            # Bluetooth
            widget.TextBox(
                text="",
                mouse_callbacks={'Button1': lazy.spawn(rofi_bluetooth_menu)},
            ),
            widget.Spacer(length=8),
            
            # Color picker
            # Нужно установить xcolor
            color_picker,
            widget.Spacer(length=8),
            
            # Виджет для управления YouTube Music
            # YTMusicWidget(),

            widget.TextBox(text="|"),
            widget.Spacer(length=8),
        ]
    ),
    widget.Spacer(length=8),

    # WidgetBox(
    #     text_closed='  ',
    #     text_open='  ',
    #     padding=0,
    #     widgets=[
            widget.TextBox(
                text="",
                
                padding=7
            ),
            
            # Виджет громкости пульсы
            # Нужно установить pavucontrol
            volume_widget,
            widget.Spacer(length=15),
        
            # Keyboard layout
            widget.KeyboardLayout(
                configured_keyboards=keyboard_layouts,
                update_interval=1,
                padding=0
            ),
            widget.Spacer(length=15),

            # Battery
            battery_widget := widget.BatteryIcon(
                theme_path=str(resources_path / 'battery_icons'),
                padding=3,
                update_interval=5,
                scale=1,
            ),
            MyBattery(
                padding=3,
                format="{percent:2.0%}",
                update_interval=5,
                hide_threshold=True,
            ),
            widget.Spacer(length=12),

            # Clock
            widget.WidgetBox(
                text_closed=' ',
                text_open=' ',
                padding=0,
                widgets=[
                    # Дата
                    widget.Clock(format="[%d %B %Y | %A]", padding=0),
                    widget.Spacer(length=5),
                ]
            ),
            widget.Spacer(length=5),

            # Время и дата
            widget.Clock(format="%H:%M", padding=0),
            widget.Spacer(length=20),
    #     ],
    # ),

    # Кнопка выключения
    widget.QuickExit(default_text='', padding=6),  
]
