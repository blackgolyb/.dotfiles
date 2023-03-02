# ИМПОРТ БИБЛИОТЕК ----------------------------------------------------------------
import os
import subprocess

from pathlib import Path

import typing

import libqtile
from libqtile import hook, qtile

from libqtile import bar, layout, widget
from libqtile.config import Click, Drag, Group, Key, EzKey, Match, Screen
from libqtile.lazy import lazy
from libqtile.utils import guess_terminal

import utils
from sticky_window_manager import StickyWindowManager
from groups import GroupCreator, extend_keys
import hooks
from layouts import default_layouts
from widgets import (
    main_bar_widgets, widget_defaults,
    volume_widget, brightness_widget, color_picker
)
from keys import *
from settings import *
# from utils import is_process_run
# from widgets.yt_music import YTMusicWidget

import locale
locale.setlocale(locale.LC_TIME, 'ru_RU.UTF-8')









import time
import json
import requests
import threading
import psutil
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
from libqtile.widget import base
from libqtile.log_utils import logger
from pathlib import Path

from libqtile.widget import Systray





# class FileClosedHandler(FileSystemEventHandler):
#     def __init__(self, handled_file):
#         self.handled_file = handled_file
#         self.callbacks = Callbacks()

#     def on_closed(self, event):
#         if not event.is_directory and event.src_path == self.handled_file:
#             self.callbacks.send()
        

# DEFAULT_OBSERVER_TIMEOUT = 1

# class ProcessObserver(threading.Thread):
#     def __init__(self, process_name, timeout=DEFAULT_OBSERVER_TIMEOUT, soft_waiting=False):
#         threading.Thread.__init__(self)
        
#         self.process_name = process_name
#         self._timeout = timeout
#         self._stop_event = threading.Event()
        
#         self.start_callbacks = Callbacks()
#         self.stop_callbacks = Callbacks()
#         self.update_callbacks = Callbacks()
        
#         self.previous_status = self.current_process_status
        
#         if soft_waiting:
#             self.wait = self.soft_wait
#         else:
#             self.wait = self.basic_wait
            
#     def soft_wait(self):
#         for _ in range(int(self._timeout)):
#             if self._stop_event.is_set():
#                 return
            
#             time.sleep(1)
            
#         time.sleep(self._timeout - int(self._timeout))
        
#     def basic_wait(self):
#         time.sleep(self._timeout)
        
#     def check_is_process_run(self) -> bool:
#         for proc in psutil.process_iter():
#             if proc.name() == self.process_name:
#                 return True

#         return False
    
#     @property
#     def current_process_status(self) -> bool:
#         current_status = self.check_is_process_run()
#         self.previous_status = current_status
        
#         return current_status
    
#     def _is_process_start_or_stop(self) -> bool | None:
#         previous_status = self.previous_status
#         current_status = self.current_process_status
        
#         if previous_status == current_status:
#             return None
        
#         return current_status
    
#     def run(self):
#         while not self._stop_event.is_set():
#             self.wait()
            
#             current_status = self._is_process_start_or_stop()
#             if current_status is None:
#                 continue
            
#             if current_status:
#                 self.start_callbacks.send()
#             else:
#                 self.stop_callbacks.send()
                
#             self.update_callbacks.send(current_status)
            
#     def stop(self):
#         self._stop_event.set()


# class YTMusicAPI:
#     song_info_file = '/tmp/yt_music_song_info.json'
#     yt_music_api_version = 1
#     yt_music_api_port = 8128
#     yt_music_api_url = 'http://localhost:{port}/api/v{version}'
    
#     def __init__(self):       
#         self.yt_music_api_url = self.yt_music_api_url.format(
#             port=self.yt_music_api_port,
#             version=self.yt_music_api_version,
#         )
        
#         self.yt_music_api_controls_url = f'{self.yt_music_api_url}/control'
#         self.yt_music_api_info_url = f'{self.yt_music_api_url}/song_info'
        
#         self.info_callbacks = Callbacks()
        
#         if not Path(self.song_info_file).exists():
#             with open(self.song_info_file, 'w') as f:
#                 f.write('{}')
        
#         handler = FileClosedHandler(self.song_info_file)
#         handler.callbacks.add(self.send_info_callbacks)
        
#         self.info_observer = Observer()
#         self.info_observer.schedule(
#             handler,
#             path=self.song_info_file,
#         )
        
#         self.process_observer = ProcessObserver(
#             'youtube-music',
#             timeout=10,
#             soft_waiting=True
#         )
        
#     @property
#     def song_info_from_file(self):
#         with open(self.song_info_file, 'r') as current_info_from_file:
#             parsed_data = json.load(current_info_from_file)
#             logger.warning(parsed_data)
#             return parsed_data
        
#     def send_info_callbacks(self):
#         self.info_callbacks.send(self.song_info_from_file)
        
#     def force_send_info_callback(self, callback):
#         callback(self.song_info_from_file)
        
#     def toggle_pause_play(self):
#         r = requests.post(f'{self.yt_music_api_controls_url}/playPause')
        
#     def previous_song(self):
#         r = requests.post(f'{self.yt_music_api_controls_url}/previous')
        
#     def next_song(self):
#         r = requests.post(f'{self.yt_music_api_controls_url}/next')
        
#     def start_up(self):
#         try:
#             logger.warning('start')
#             if not self.info_observer.is_alive():
#                 self.info_observer.start()
#             if not self.process_observer.is_alive():
#                 self.process_observer.start()
#             logger.warning('start_up')
#         except Exception as e:
#             logger.warning(e)
        
#     def kill(self):
#         try:
#             logger.warning('stop')
#             self.info_observer.stop()
#             self.info_observer.join()
#             self.process_observer.stop()
#             self.process_observer.join()
#             logger.warning('kill')
#         except Exception as e:
#             logger.warning(e)

# yt_music_api = YTMusicAPI()


# class YTMusicAPIInitMixin():
#     yt_music_api: YTMusicAPI
    
#     def init_yt_music_api_hooks(self, api):
#         @hook.subscribe.shutdown
#         def on_shutdown_kill_api():
#             api.kill()
            
#     def _configure(self, qtile, bar):
#         logger.warning('YTMusicAPIInitMixin._configure')
#         self.yt_music_api.start_up()
#         self.init_yt_music_api_hooks(self.yt_music_api)
#         super()._configure(qtile, bar)
      

# class YTMusicTitleWidget(YTMusicAPIInitMixin, base.InLoopPollText):
#     defaults = [
#         (
#             "update_interval",
#             1,
#             "Update interval in seconds, if none, the " "widget updates whenever it's done.",
#         ),
#         (
#             "fmt",
#             '{}',
#             "Update interval in seconds, if none, the " "widget updates whenever it's done.",
#         ),
#         (
#             "max_chars",
#             12, 
#             "Maximum number of characters to display in widget."
#         ),
#         (
#             "app_close_msg",
#             "close",
#             "",
#         ),
#         (
#             "song_info_file",
#             "/tmp/yt_music_song_info.json",
#             "",
#         ),
#         (
#             "animate_format",
#             '{}  '
#             "",
#         ),
#     ]
    
#     def __init__(self, **config):
#         base.InLoopPollText.__init__(self, default_text=" ", **config)
#         self.add_defaults(YTMusicTitleWidget.defaults)
        
#         # Fix max_chars default bug
#         for i in range(len(YTMusicTitleWidget.defaults)):
#             if YTMusicTitleWidget.defaults[i][0] == 'max_chars':
#                 self.max_chars = YTMusicTitleWidget.defaults[i][1]
#                 break

#         self._is_youtube_music_run = False
#         self.yt_music_api = yt_music_api
        
#     def _configure(self, qtile, bar):           
#         super()._configure(qtile, bar)
#         logger.warning('super()._configure(qtile, bar)')
        
#         self._is_youtube_music_run = self.yt_music_api.process_observer.check_is_process_run()
#         self.update_song()
            
#         self.yt_music_api.info_callbacks.add(self.update_song)
#         self.yt_music_api.process_observer.start_callbacks.add(self.on_start_yt_music)
#         self.yt_music_api.process_observer.stop_callbacks.add(self.on_stop_yt_music)
        
#     def on_start_yt_music(self):
#         self._is_youtube_music_run = True
        
#     def on_stop_yt_music(self):
#         self._is_youtube_music_run = False
        
#     def update_title(self, song_info):
#         self.song_title = song_info['title']
            
#     def update_song(self, song_info=None):
#         if song_info is None:
#             song_info = {'title': self.app_close_msg}
#         self.update_title(song_info)
#         self.animator = self.animate()
            
#     def animate(self):
#         if len(self.song_title) <= self.max_chars:
#             # Будем раздавать название песни без анимации
#             while True:
#                 yield self.song_title
        
#         # В ином случае будем раздавать уже с анимацией прокрутки
#         target_text = self.animate_format.format(self.song_title)
#         self._amin_id = 0
        
#         while True:
#             start_char = self._amin_id
#             end_char = self._amin_id + self.max_chars
            
#             # Часть которая попадает до конца названия 
#             first_part = target_text[start_char: min(end_char, len(target_text))]
#             # Часть которая попадает после конца названия
#             second_part = ''
#             if end_char >= len(target_text):
#                 second_part = target_text[: max(0, end_char % len(target_text))]
                
#             current_animated_text = first_part + second_part
            
#             yield current_animated_text
#             self._amin_id = (self._amin_id + 1) % len(target_text)

#     def poll(self):
#         if self._is_youtube_music_run:
#             result = next(self.animator)
#         else:
#             result = self.app_close_msg
        
#         return result
        

# class YTMusicPausePlayWidget(YTMusicAPIInitMixin, base._TextBox):
#     def __init__(self, **config):
#         base._TextBox.__init__(self, **config)
        
#         self.add_callbacks({
#             'Button1': lazy.function(self.toggle_pause_play_qtile)
#         })
        
#         self.yt_music_api = yt_music_api
        
#     def _configure(self, qtile, bar):           
#         super()._configure(qtile, bar)
        
#         self.update_state()
            
#         self.yt_music_api.info_callbacks.add(self.update_state)
        
#     def update_state(self, song_info=None):
#         if song_info is None:
#             song_info = {'isPaused': False}
#         self.is_paused = song_info['isPaused']
#         self.update_label()
        
#     def update_label(self):
#         if self.is_paused:
#             current_status = ''
#         else:
#             current_status = ''
            
#         self.update(current_status)
        
#     def toggle_pause_play(self):
#         self.yt_music_api.toggle_pause_play()
        
#     def toggle_pause_play_qtile(self, qtile):
#         self.toggle_pause_play()
        

# class YTMusicNextSongWidget(base._TextBox):
#     def __init__(self, **config):
#         base._TextBox.__init__(self, **config)

#         self.add_callbacks({
#             'Button1': lazy.function(self.next_song_qtile)
#         })
        
#         self.text = '󰒭'
        
#         self.yt_music_api = yt_music_api
        
#     def next_song(self):
#         self.yt_music_api.next_song()
        
#     def next_song_qtile(self, qtile):
#         self.next_song()
             

# class YTMusicPreviousSongWidget(base._TextBox):
#     def __init__(self, **config):
#         base._TextBox.__init__(self, **config)

#         self.add_callbacks({
#             'Button1': lazy.function(self.previous_song_qtile)
#         })
        
#         self.text = '󰒮'
        
#         self.yt_music_api = yt_music_api
        
#     def previous_song(self):
#         self.yt_music_api.previous_song()
        
#     def previous_song_qtile(self, qtile):
#         self.previous_song()
        
        
# class YTMusicControlWidget(WidgetGroup):
#     def __init__(self, **config):
#         self.play_pause_widget = YTMusicPausePlayWidget()
#         self.previous_widget = YTMusicPreviousSongWidget()
#         self.next_widget = YTMusicNextSongWidget()
        
#         widgets = [
#             self.previous_widget,
#             self.play_pause_widget,
#             self.next_widget,
#         ]
        
#         WidgetGroup.__init__(self, widgets=widgets, **config)


# class YTMusicWidget(YTMusicAPIInitMixin, WidgetBox):
#     defaults = [
#         ("foreground", "#ffffff", "Foreground color."),
#     ]
    
#     def __init__(self, **config):
#         self.title_widget = YTMusicTitleWidget()
#         self.control_widget = YTMusicControlWidget()
        
#         widgets = [
#             HoveringWidgetTabGroup(
#                 [self.title_widget,],
#                 [self.control_widget,],
#             ),
#         ]
        
#         widget.WidgetBox.__init__(self, widgets=widgets, **config)
#         self.add_defaults(YTMusicWidget.defaults)
        
#         self.yt_music_api = yt_music_api
        
#         self.yt_music_on_icon = '󰝚 '
#         self.yt_music_off_icon = '󰝛 '
        
#     def _configure(self, qtile, bar):           
#         super()._configure(qtile, bar)
        
#         self.update_yt_music_status(
#             self.yt_music_api.process_observer.check_is_process_run()
#         )
        
#         self.yt_music_api.process_observer.update_callbacks.add(
#             self.update_yt_music_status
#         )
        
#     def update_yt_music_status(self, yt_music_status):
#         if yt_music_status:
#             current_icon = self.yt_music_on_icon         
#             self._can_toggling = True
#         else:
#             current_icon = self.yt_music_off_icon
            
#             # close widget if youtube music closed
#             if self.box_is_open:
#                 self.cmd_toggle()
                
#             self._can_toggling = False
            
#         self.text_open = current_icon
#         self.text_closed = current_icon
            
#         self.set_box_label()
#         self.bar.draw()
        
#     def cmd_toggle(self):
#         if self._can_toggling:
#             super().cmd_toggle()

            
        
























sticky_manager = StickyWindowManager(
    activate_hooks=True,
    sticky_rules=[
        Match(title="Picture-in-Picture"),
    ],
    groups_rules=[
        {
            'match': Match(title="Picture-in-Picture"),
            'groups': '__all__',
            # 'groups': ('0', '1', '2'),
            # 'exclude_groups': ('0', '1', '2'),
        },
    ],
)


# КЛАВИША МОДИФИКАТОР -------------------------------------------------------------


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
        desc="Grow window to the right"),  # Увеличитпапкамиь окно вправо
    Key([mod, "control"], "down", lazy.layout.grow_down(),
        desc="Grow window down"),  # Увеличить окно вниз
    Key([mod, "control"], "up", lazy.layout.grow_up(),
        desc="Grow window up"),  # Увеличить окно вверх
    Key([mod], "n", lazy.layout.normalize(),
        desc="Reset all window sizes"),  # Вернуть все взад


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
    
    # Скрыть/раскрыть панель
    Key([mod, "control"], "space", lazy.hide_show_bar(bar_orientation)),


    # Запуск приложений
    Key([mod], "Return", lazy.spawn(terminal)),
    # Key([mod], "f", lazy.spawn("firefox --wayland")), # Это для вайланда
    Key([mod], "f", lazy.spawn(webbrowser)),  # Для иксов
    Key([mod], "e", lazy.spawn(file_explorer)),
    Key([mod], "t", lazy.spawn("telegram-desktop")),
    Key([mod], "space", lazy.spawn("rofi -show drun")),


    # Раскладка клавиатуры
    Key([alt], "Shift_L", lazy.widget["keyboardlayout"].next_keyboard(),
        desc="Next keyboard layout."),


    # Штука которая позволяет закрепить окно на всех рабочих поверхностях
    # Т.е. окно будет следовать за вами на всех робочих столах
    Key([mod], "o", lazy.function(
        sticky_manager.toggle_sticky_window), desc="toggle stick window"),


    # Скриешоты
    # Нужно установить gnome-screenshot
    Key([], "Print", lazy.spawn('flameshot gui')),
    
    
    # Color picker
    Key([mod], "p", lazy.function(color_picker.dropper.pick_color)),


    # Контроль звука и яркости
    Key([], "XF86AudioLowerVolume", lazy.function(volume_widget.down)),
    Key([], "XF86AudioRaiseVolume", lazy.function(volume_widget.up)),
    Key([], "XF86AudioMute", lazy.function(volume_widget.mute)),
    Key([], "XF86AudioMicMute", lazy.spawn("amixer set Capture togglemute")),


    # Яркость нужно установить light
    # sudo chmod +s /usr/bin/light для работы утилиты light
    Key([], "XF86MonBrightnessDown", lazy.function(brightness_widget.down)),
    Key([], "XF86MonBrightnessUp", lazy.function(brightness_widget.up)),
]


# ПЕРЕКЛЮЧЕНИЕ ВОРКСПЕЙСОВ И ПЕРЕМЕЩЕНИЕ ОКОН ПО НИМ ------------------------------
create_group = GroupCreator()
create_group.is_description = True
create_group.is_subscript_or_superscript = False

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

extend_keys(keys, groups)

    

# МАКЕТЫ (в скобках прописываются параметры, толщина бордера, цвета...) -----------

layouts = default_layouts

# ОБЩИЕ ПАРАМЕТРЫ ВИДЖЕТОВ НА ПАНЕЛИ ----------------------------------------------



bar_defaults = {
    "size": 20,  # Высота панели
    "border_width": [2, 16, 2, 10],
    "border_color": ["#2E3440", "#2E3440", "#2E3440", "#2E3440"],
    "margin": bar_gaps,  # Гапсы бара
    "background": "#2E3440",  # Цвет фона панели
    "opacity": 1,  # Прозрачность бара
}

extension_defaults = widget_defaults.copy()

main_bar = bar.Bar(  # Расположение бара
    main_bar_widgets,
    **bar_defaults,
)

bars = utils.configure_bars(outer_gaps, group_gaps, main_bar)
bars = utils.rotate_matrix_by_bar_orientation(bars, bar_orientation)
bars = utils.make_2d_matrix_flat(bars)

top_bar, right_bar, bottom_bar, left_bar = bars

screens = [
    Screen(
        wallpaper=str(resources_path / 'wallpapers/1.jpg'),
        wallpaper_mode='stretch',
        right=right_bar,
        left=left_bar,
        bottom=bottom_bar,
        top=top_bar,
    ),
    Screen(
        wallpaper=str(resources_path / 'wallpapers/2.jpg'),
        wallpaper_mode='stretch',
        top=bar.Bar(
            [
                widget.Spacer(length=10),
                widget.Spacer(),
                # base_groupbox,
                widget.Spacer(),
                widget.Spacer(length=20),
            ],
            **bar_defaults,
        ),
    ),
]


# МЫШЬ ----------------------------------------------------------------------------
mouse = [
    Drag([mod], "Button1", lazy.window.set_position_floating(),
         start=lazy.window.get_position()),
    Drag([mod], "Button3", lazy.window.set_size_floating(),
         start=lazy.window.get_size()),
    Click([mod], "Button2", lazy.window.bring_to_front()),
]


hooks.init_hooks(main_bar, is_bar_rounded)
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
        Match(title="Picture-in-Picture"),
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
