# ИМПОРТ БИБЛИОТЕК ----------------------------------------------------------------
import os
import subprocess

from pathlib import Path

from libqtile import hook

from libqtile import bar, layout, widget
from libqtile.config import Click, Drag, Group, Key, EzKey, Match, Screen
from libqtile.lazy import lazy
from libqtile.utils import guess_terminal


home_path = os.path.expanduser('~')
config_path = home_path + '/.config/qtile/'


# АВТОЗАПУСК ----------------------------------------------------------------------
@hook.subscribe.startup_once
def autostart():
    subprocess.call([config_path + 'autostart.sh'])

# @hook.subscribe.startup_complete
def reconfig():
    # print(battery_widget.image_padding)
    battery_widget.image_padding = 5
    battery_widget.setup_images()
    subprocess.spawn('alacritty')


# СДЕЛАТЬ ДИАЛОГОВЫЕ ОКНА ПЛАВАЮЩИМИ ----------------------------------------------
@hook.subscribe.client_new
def floating_dialogs(window):
    dialog = window.window.get_wm_type() == 'dialog'
    transient = window.window.get_wm_transient_for()
    if dialog or transient:
        window.floating = True

    

# КЛАВИША МОДИФИКАТОР -------------------------------------------------------------
mod = "mod4"


# ХОТКЕИ --------------------------------------------------------------------------
keys = [
    # Управление фокусом
    Key([mod], "left", lazy.layout.left(),
        desc="Move focus to left"),  # Фокус влево
    Key([mod], "right", lazy.layout.right(),
        desc="Move focus to right"),  # Фокус вправо
    Key([mod], "down", lazy.layout.down(),
        desc="Move focus down"),  # Фокус вниз
    Key([mod], "up", lazy.layout.up(), desc="Move focus up"),  # Фокус вверх
    Key([mod], "space", lazy.layout.next(),
        desc="Move window focus to other window"),  # Переключить фокус

    # Перемещение окон
    Key([mod, "shift"], "left", lazy.layout.shuffle_left(),
        desc="Move window to the left"),  # Переместить окно влево
    Key([mod, "shift"], "right", lazy.layout.shuffle_right(),
        desc="Move window to the right"),  # Переместить окно вправо
    Key([mod, "shift"], "down", lazy.layout.shuffle_down(),
        desc="Move window down"),  # Переместить окно вниз
    Key([mod, "shift"], "up", lazy.layout.shuffle_up(),
        desc="Move window up"),  # Переместить окно вверх

    # Изменение размера окна
    Key([mod, "control"], "left", lazy.layout.grow_left(),
        desc="Grow window to the left"),  # Увеличить окно влево
    Key([mod, "control"], "right", lazy.layout.grow_right(),
        desc="Grow window to the right"),  # Увеличить окно вправо
    Key([mod, "control"], "down", lazy.layout.grow_down(),
        desc="Grow window down"),  # Увеличить окно вниз
    Key([mod, "control"], "up", lazy.layout.grow_up(),
        desc="Grow window up"),  # Увеличить окно вверх
    Key([mod], "n", lazy.layout.normalize(),
        desc="Reset all window sizes"),  # Вернуть все взад

    Key([mod, "control"], "space", lazy.hide_show_bar("top")),

    # Запуск приложений
    Key([mod], "Return", lazy.spawn("alacritty")),
    # Key([mod], "f", lazy.spawn("firefox --wayland")), # Это для вайланда
    Key([mod], "f", lazy.spawn("firefox")),  # Для иксов
    Key([mod], "e", lazy.spawn("dolphin")),
    Key([mod], "t", lazy.spawn("telegram-desktop")),
    Key([mod], "space", lazy.spawn("rofi -show drun")),
    # Key([mod], "n", lazy.spawn("thunar")),
    # Key([mod], "i", lazy.spawn("inkscape")),
    # Key([mod], "b", lazy.spawn("blender")),
    # Key([mod], "l", lazy.spawn("lutris")),

    # Переключение между макетами
    Key([mod], "Tab", lazy.next_layout(), desc="Toggle between layouts"),
    # Закрыть окно
    Key([mod], "q", lazy.window.kill(), desc="Kill focused window"),
    # Перезагрузить конфиг
    Key([mod, "control"], "r", lazy.reload_config(), desc="Reload the config"),
    # Выйти из Qtile
    Key([mod, "control"], "q", lazy.shutdown(), desc="Shutdown Qtile"),
    # Выполнить команды (типо встроенное dmenu)
    Key([mod], "d", lazy.spawncmd(), desc="Spawn a command using a prompt widget"),

    # Раскладка клавиатуры
    #Key([mod], "space", lazy.widget["keyboardlayout"].next_keyboard(), desc="Next keyboard layout."),
    Key(["mod1"], "Shift_L", lazy.widget["keyboardlayout"].next_keyboard(), desc="Next keyboard layout."),

    # Яхз что за это, типо все окна на месте одного окна отображаются.
    # Toggle between split and unsplit sides of stack.
    # Split = all windows displayed
    # Unsplit = 1 window displayed, like Max layout, but still with
    # multiple stack panes
    # Key(
    #    [mod, "shift"],
    #    "Return",
    #    lazy.layout.toggle_split(),
    #    desc="Toggle between split and unsplit sides of stack",
    # ),

    # Скриешоты
    # НУжно установить gnome-screenshot
    Key([mod], "Print", lazy.spawn('gnome-screenshot -i')),

    
    # Контроль звука и яркости
    Key([], "XF86AudioLowerVolume", lazy.spawn("amixer set Master 5%- unmute")),
    Key([], "XF86AudioRaiseVolume", lazy.spawn("amixer set Master 5%+ unmute")),
    Key([], "XF86AudioMute", lazy.spawn("amixer set Master togglemute")),
    Key([], "XF86AudioMicMute", lazy.spawn("amixer set Capture togglemute")),


    # Яркость нужно установить light
    # sudo chmod +s /usr/bin/light для работы утилиты light
    Key([], "XF86MonBrightnessDown", lazy.spawn("light -U 5")),
    Key([], "XF86MonBrightnessUp", lazy.spawn("light -A 5")),
    
]


# ПЕРЕКЛЮЧЕНИЕ ВОРКСПЕЙСОВ И ПЕРЕМЕЩЕНИЕ ОКОН ПО НИМ ------------------------------
get_superscript_by_normal = {
    '0': '⁰',
    '1': '¹',
    '2': '²',
    '3': '³',
    '4': '⁴',
    '5': '⁵',
    '6': '⁶',
    '7': '⁷',
    '8': '⁸',
    '9': '⁹',
    'w': 'ʷ',
}

class GroupCreator:
    is_subscript = False
    format = '{label} {subscript}'
    error_text = 'Subscript for key:[{key}] not found. Try to set the subscript yourself.'

    def format_subscript(self, label, subscript):
        return self.format.format(label=label, subscript=subscript)

    def __call__(self, key, label, is_subscript=None, subscript='', **kwargs):
        if is_subscript is not None:
            add_subscript = is_subscript
        else:
            add_subscript = self.is_subscript

        if add_subscript:
            if not subscript:
                if key in get_superscript_by_normal:
                    subscript = get_superscript_by_normal[key]
                else:
                    subscript = self.error_text.format(key=key)

            label = self.format_subscript(label, subscript)

        return Group(key, label=label, **kwargs)


create_group = GroupCreator()
create_group.is_subscript = True
# create_group.format = '{subscript} {label}'

groups = [
    create_group("1", "󰈹", matches=[Match(wm_class=["firefox"])]),
    create_group("2", ""),
    create_group("3", ""),
    create_group("4", ""),
    create_group("5", ""),
    create_group("6", ""),
    create_group("7", ""),
    create_group("8", ""),
    create_group("9", "󰋋"),
    create_group("0", ""),
    create_group("w", ""),
]

for i in groups:
    keys.extend(
        [
            # mod + номер вокспейса = переход на этот воркспейс
            Key(
                [mod],
                i.name,
                lazy.group[i.name].toscreen(),
                desc="Switch to group {}".format(i.name),
            ),
            # mod + shift + номер воркспейса = перенос окна на этот воркспейс
            Key(
                [mod, "shift"],
                i.name,
                lazy.window.togroup(i.name, switch_group=True),
                desc="Switch to & move focused window to group {}".format(
                    i.name),
            ),
        ]
    )


# МАКЕТЫ (в скобках прописываются параметры, толщина бордера, цвета...) -----------
layouts = [
    # layout.Columns(),
    # layout.Max(), # Фуллскрин
    # layout.Stack(num_stacks=2), #Какая то фигня
    layout.Bsp(border_focus="#C3C3C3", border_normal="#2E3440",
               border_width=1,
               margin=5),  # Как в bspwm
    # layout.Matrix(), # В 2 колонки
    # layout.MonadTall(), # Как в dwm
    # layout.MonadWide(), # Как в dwm только по горизонтали
    # layout.RatioTile(), # Окна мазайкой 3х3, 4х4 ...
    # layout.Tile(), # Как в dwm
    # layout.TreeTab(), # Вертикальный монокль с заголовками
    # layout.VerticalTile(), # Окна открываются вертикально
    # layout.Zoomy(), # Как в dwm ток мастер окно большое
]


# ОБЩИЕ ПАРАМЕТРЫ ВИДЖЕТОВ НА ПАНЕЛИ ----------------------------------------------
widget_defaults = dict(
    font="JetBrainsMono Nerd Font",
    fontsize=12,
    padding=8,
)
extension_defaults = widget_defaults.copy()



class MyBatteryIcon(widget.BatteryIcon):
    offsety = -2
    # offsetx = -0

# /usr/share/icons/breeze-dark/status
# ВИДЖЕТЫ НА ПАНЕЛИ И ИХ ПАРАМЕТРЫ ------------------------------------------------
bar_widgets = [
    # widget.CurrentLayout(), # Текущий макет
    # Иконки воркспейсов
    base_groupbox:=widget.GroupBox(
        borderwidth=1,  # Толщина рамки
        highlight_method='line',  # ('border', 'block', 'text', 'line') # Метод выделения активного воркспейса
        block_highlight_text_color='#ffffff',  # '#DDDFE5',  # Цвет текста активного воркспейса
        this_current_screen_border='#ffffff',  #C3C3C3  Цвет фона активного воркспейса
        inactive='#777777',
        active='#ffffff',
        other_screen_border='#3333ff',
        highlight_color=['2E3440', '2E3440'],
        rounded=True,
        markup=False,
        margin_x=0,
        margin_y=2,
        # margin=3,
        pading=0,
    ),

    # Виджет выполнения команд
    widget.Prompt(),
    # widget.WindowName(max_chars=30),  # Имя окна
    widget.Chord(
        chords_colors={
            "launch": ("#ff0000", "#ffffff"),
        },
        name_transform=lambda name: name.upper(),
    ),
    widget.Spacer(),

    widget.Systray(), # Трэй, не работает в вялом, нужно будет юзать widget.StatusNotifier
    widget.Spacer(length=15),


    widget.WidgetBox(
        text_closed = '  ',
        text_open = '  ',
        padding=0,
        widgets=[
            widget.TextBox(text="|"),

            # WIFI
            widget.TextBox(text=""),
            widget.Wlan(format='{essid}', padding=0),
            widget.Spacer(length=8),


            # Яркость
            widget.TextBox(text="󰖨"),
            blw:=widget.Backlight(padding=0),
            widget.Spacer(length=15),

            # Обновлений пакетов
            widget.CheckUpdates(
                distro='Arch',
                display_format=' {updates}',
                no_update_string=' 0',
                padding=0
            ),

            widget.Spacer(length=6),
            widget.TextBox(text="|"),
            widget.Spacer(length=8),
        ]
    ),
    # widget.Spacer(length=0),


    # Нужно установить pavucontrol
    widget.TextBox(
        text="",
        mouse_callbacks={'Button1': lazy.spawn("pavucontrol")},
        padding=7
    ),
    widget.PulseVolume(limit_max_volume=True, padding=0),  # Виджет громкости пульсы
    widget.Spacer(length=15),  # Виджет пробела

    # Keyboard layout
    widget.KeyboardLayout(configured_keyboards=['us', 'ru', 'ua'],
                            update_interval=1,
                            padding=0),
    widget.Spacer(length=15),

    # Battery
    battery_widget:=widget.BatteryIcon(
        theme_path=config_path + 'battery_icons',
        padding=0,
        update_interval=5,
        scale=1,
    ),
    widget.Battery(
        padding=5,
        format="{percent:2.0%}",
        update_interval=5,
    ),
    widget.Spacer(length=10),

    # Clock
    widget.WidgetBox(
        text_closed = ' ',
        text_open = ' ',
        padding=0,
        widgets=[
            # дата
            widget.Clock(format="%d-%m-%y %h", padding=0),
            widget.Spacer(length=5),
        ]
    ),
    widget.Spacer(length=5),

    widget.Clock(format="%H:%M",
                    padding=0),  # Время и дата
    widget.Spacer(length=20),  # Виджет пробела

    # Quit
    widget.QuickExit(default_text='', padding=6),  # Кнопка выключения
]




screens = [
    Screen(
        wallpaper='~/Pictures/wallpapers/2.jpg',
        wallpaper_mode='stretch',
        right=bar.Gap(5),
        left=bar.Gap(5),
        bottom=bar.Gap(5),
        top=bar.Bar(  # Расположение бара
            bar_widgets,
            20,  # Высота панели
            border_width=[2, 16, 2, 10],  # Толщина рамок панели
            border_color=["2E3440", "2E3440", "2E3440", "2E3440"],  # 777777  C3C3C3   Цвет рамок панели
            # border_color=["2E3440", "2E3440", "2E3440", "2E3440"],  # Цвет рамок панели
            margin=[5, 10, 10, 10],  # Гапсы бара
            background="#2E3440"  # Цвет фона панели
            # opacity=0,5 # Прозрачность бара
        ),
        # top=bar.Bar(  # Расположение бара
        #     bar_widgets,
        #     20,  # Высота панели
        #     border_width=[0, 16, 0, 10],  # Толщина рамок панели
        #     border_color=["2E3440", "2E3440", "c3c3c3", "2E3440"],  # 777777  C3C3C3   Цвет рамок панели
        #     # border_color=["2E3440", "2E3440", "2E3440", "2E3440"],  # Цвет рамок панели
        #     margin=[0, 0, 5, 0],  # Гапсы бара
        #     background="#2E3440"  # Цвет фона панели
        #     # opacity=0,5 # Прозрачность бара
        # ),
    ),
    Screen(
        wallpaper='~/Pictures/wallpapers/1.jpg',
        wallpaper_mode='stretch',
        top=bar.Bar(
            [
                widget.Spacer(length=10),
                base_groupbox,
                # widget.Spacer(length=20),
            ],
            30,
            border_width=[2, 2, 2, 2],  # Толщина рамок панели
            border_color=["2E3440", "2E3440", "ffffff", "2E3440"],  # 777777  C3C3C3   Цвет рамок панели
            # border_color=["2E3440", "2E3440", "2E3440", "2E3440"],  # Цвет рамок панели
            margin=[10, 725, 0, 725],  # Гапсы бара
            background="#2E3440"  # Цвет фона панели
            # opacity=0,5 # Прозрачность бара
        ),
    ),
]


def battery_widget_configure(battery_widget, setup_images, image_padding=0):
    def wrap():
        battery_widget.image_padding = image_padding
        setup_images()

    return wrap


def battery_widget_draw(self) -> None:
    # self.y_padding
    self.drawer.clear(self.background or self.bar.background)
    image = self.images[self.current_icon]
    self.drawer.ctx.save()
    self.drawer.ctx.translate(0, (self.bar.height - image.height) // 2 + self.y_padding)
    self.drawer.ctx.set_source(image.pattern)
    self.drawer.ctx.paint()
    self.drawer.ctx.restore()
    self.drawer.draw(offsetx=self.offset, offsety=self.offsety, width=self.length)

# res = battery_widget.setup_images
# battery_widget.setup_images = battery_widget_configure(battery_widget, res)

# print(battery_widget)
# battery_widget.y_padding = 5
# battery_widget.draw = lambda: battery_widget_draw(battery_widget)

# Переделываем виджет яркости под утилиту light
def get_brightness():
    result = subprocess.run(['light', '-G'], capture_output=True, text=True)
    brightness = result.stdout.replace("\n", "")
    return float(brightness)/100

blw._get_info = get_brightness


# МЫШЬ ----------------------------------------------------------------------------
mouse = [
    Drag([mod], "Button1", lazy.window.set_position_floating(),
         start=lazy.window.get_position()),
    Drag([mod], "Button3", lazy.window.set_size_floating(),
         start=lazy.window.get_size()),
    Click([mod], "Button2", lazy.window.bring_to_front()),
]


# НАСТРОЙКА ВМ --------------------------------------------------------------------

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
    ]
)

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
