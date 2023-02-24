# ИМПОРТ БИБЛИОТЕК ----------------------------------------------------------------
import os
import subprocess

from pathlib import Path

from libqtile import hook, qtile

from libqtile import bar, layout, widget
from libqtile.config import Click, Drag, Group, Key, EzKey, Match, Screen
from libqtile.lazy import lazy
from libqtile.utils import guess_terminal

from qtile_extras import widget as qe_widget

from utils import is_process_run
# from widgets.yt_music import YTMusicWidget

import locale
locale.setlocale(locale.LC_TIME, 'ru_RU.UTF-8')


home_path = Path.home()
config_path = home_path / '.config/qtile/'
wallpapers_folder = config_path / 'wallpapers/'
battery_icons_folder = config_path / 'battery_icons/'

text_editor = 'code'
webbrowser = 'firefox'
file_explorer = 'thunar'

group_gaps = 7
around_gaps = 7
bar_gaps = [0, 0, 0, 0]
rounded_bar = False

# keyboard_layouts = ['us', 'ru', 'ua']
keyboard_layouts = ['us', 'ru']






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




yt_music_song_info_file = '/tmp/yt_music_song_info.json'

class Callbacks:
    def __init__(self):
        self._callbacks = []
        
    def add(self, callback):
        if callback not in self._callbacks:
            self._callbacks.append(callback)
            
    def remove(self, callback):
        if callback in self._callbacks:
            self._callbacks.remove(callback)
            
    def clear(self):
        self._callbacks = []
        
    def send(self, *args, **kwargs):
        for callback in self._callbacks:
            callback(*args, **kwargs)


class FileClosedHandler(FileSystemEventHandler):
    def __init__(self, handled_file):
        self.handled_file = handled_file
        self.callbacks = Callbacks()

    def on_closed(self, event):
        if not event.is_directory and event.src_path == self.handled_file:
            self.callbacks.send()
        

DEFAULT_OBSERVER_TIMEOUT = 1

class ProcessObserver(threading.Thread):
    def __init__(self, process_name, timeout=DEFAULT_OBSERVER_TIMEOUT):
        threading.Thread.__init__(self)
        
        self.process_name = process_name
        self._timeout = timeout
        self.running = True
        
        self.start_callbacks = Callbacks()
        self.stop_callbacks = Callbacks()
        self.update_callbacks = Callbacks()
        
        self.previous_status = self.current_process_status
        
    def check_is_process_run(self) -> bool:
        for proc in psutil.process_iter():
            if proc.name() == self.process_name:
                return True

        return False
    
    @property
    def current_process_status(self) -> bool:
        current_status = self.check_is_process_run()
        self.previous_status = current_status
        
        return current_status
    
    def _is_process_start_or_stop(self) -> bool | None:
        previous_status = self.previous_status
        current_status = self.current_process_status
        
        if previous_status == current_status:
            return None
        
        return current_status
    
    def run(self):
        while self.running:
            time.sleep(self._timeout)
            
            current_status = self._is_process_start_or_stop()
            if current_status is None:
                continue
            
            if current_status:
                self.start_callbacks.send()
            else:
                self.stop_callbacks.send()
                
            self.update_callbacks.send(current_status)


class YTMusicAPI:
    song_info_file = '/tmp/yt_music_song_info.json'
    yt_music_api_version = 1
    yt_music_api_port = 8128
    yt_music_api_url = 'http://localhost:{port}/api/v{version}'
    
    def __init__(self):       
        self.yt_music_api_url = self.yt_music_api_url.format(
            port=self.yt_music_api_port,
            version=self.yt_music_api_version,
        )
        
        self.yt_music_api_controls_url = f'{self.yt_music_api_url}/control'
        self.yt_music_api_info_url = f'{self.yt_music_api_url}/song_info'
        
        self.info_callbacks = Callbacks()
        
        if not Path(self.song_info_file).exists():
            with open(self.song_info_file, 'w') as f:
                f.write('{}')
        
        handler = FileClosedHandler(self.song_info_file)
        handler.callbacks.add(self.send_info_callbacks)
        
        self.info_observer = Observer()
        self.info_observer.schedule(
            handler,
            path=self.song_info_file,
        )
        
        self.process_observer = ProcessObserver('youtube-music', timeout=10)
        
    @property
    def song_info_from_file(self):
        with open(self.song_info_file, 'r') as current_info_from_file:
            parsed_data = json.load(current_info_from_file)
            logger.warning(parsed_data)
            return parsed_data
        
    def send_info_callbacks(self):
        self.info_callbacks.send(self.song_info_from_file)
        
    def force_send_info_callback(self, callback):
        callback(self.song_info_from_file)
        
    def toggle_pause_play(self):
        r = requests.post(f'{self.yt_music_api_controls_url}/playPause')
        
    def previous_song(self):
        r = requests.post(f'{self.yt_music_api_controls_url}/previous')
        
    def next_song(self):
        r = requests.post(f'{self.yt_music_api_controls_url}/next')
        
    def start_up(self):
        try:
            logger.warning('start')
            self.info_observer.start()
            self.process_observer.start()
            logger.warning('start_up')
        except Exception as e:
            logger.warning(e)
        
    def kill(self):
        try:
            logger.warning('stop')
            self.info_observer.stop()
            self.info_observer.join()
            self.process_observer.stop()
            self.process_observer.join()
            logger.warning('kill')
        except Exception as e:
            logger.warning(e)

yt_music_api = YTMusicAPI()


class YTMusicAPIInitMixin():
    def init_yt_music_api_hooks(self, api):
        
        @hook.subscribe.shutdown
        def on_shutdown_kill_api():
            api.kill()


class YTMusicTitleWidget(base.InLoopPollText, YTMusicAPIInitMixin):
    defaults = [
        (
            "update_interval",
            1,
            "Update interval in seconds, if none, the " "widget updates whenever it's done.",
        ),
        (
            "fmt",
            '{}',
            "Update interval in seconds, if none, the " "widget updates whenever it's done.",
        ),
        (
            "max_chars",
            12, 
            "Maximum number of characters to display in widget."
        ),
        (
            "app_close_msg",
            "close",
            "",
        ),
        (
            "song_info_file",
            yt_music_song_info_file,
            "",
        ),
        (
            "animate_format",
            '{}  '
            "",
        ),
    ]
    
    def __init__(self, **config):
        base.InLoopPollText.__init__(self, default_text=" ", **config)
        self.add_defaults(YTMusicTitleWidget.defaults)
        
        # Fix max_chars default bug
        for i in range(len(YTMusicTitleWidget.defaults)):
            if YTMusicTitleWidget.defaults[i][0] == 'max_chars':
                self.max_chars = YTMusicTitleWidget.defaults[i][1]
                break

        self._is_youtube_music_run = False
        self.yt_music_api = yt_music_api
        
    def _configure(self, qtile, bar):           
        base.InLoopPollText._configure(self, qtile, bar)
        
        self.yt_music_api.start_up()
        self.init_yt_music_api_hooks(self.yt_music_api)
        
        self._is_youtube_music_run = self.yt_music_api.process_observer.check_is_process_run()
        self.update_song()
            
        self.yt_music_api.info_callbacks.add(self.update_song)
        self.yt_music_api.process_observer.start_callbacks.add(self.on_start_yt_music)
        self.yt_music_api.process_observer.stop_callbacks.add(self.on_stop_yt_music)
        
    def on_start_yt_music(self):
        self._is_youtube_music_run = True
        
    def on_stop_yt_music(self):
        self._is_youtube_music_run = False
        
    def update_title(self, song_info):
        self.song_title = song_info['title']
            
    def update_song(self, song_info=None):
        if song_info is None:
            song_info = {'title': self.app_close_msg}
        self.update_title(song_info)
        self.animator = self.animate()
            
    def animate(self):
        if len(self.song_title) <= self.max_chars:
            # Будем раздавать название песни без анимации
            while True:
                yield self.song_title
        
        # В ином случае будем раздавать уже с анимацией прокрутки
        target_text = self.animate_format.format(self.song_title)
        self._amin_id = 0
        
        while True:
            start_char = self._amin_id
            end_char = self._amin_id + self.max_chars
            
            # Часть которая попадает до конца названия 
            first_part = target_text[start_char: min(end_char, len(target_text))]
            # Часть которая попадает после конца названия
            second_part = ''
            if end_char >= len(target_text):
                second_part = target_text[: max(0, end_char % len(target_text))]
                
            current_animated_text = first_part + second_part
            
            yield current_animated_text
            self._amin_id = (self._amin_id + 1) % len(target_text)

    def poll(self):
        if self._is_youtube_music_run:
            result = next(self.animator)
        else:
            result = self.app_close_msg
        
        return result
    


class YTMusicControlWidget(widget.WidgetBox):
    # TODO: make this widget
    defaults = [
        ("foreground", "#ffffff", "Foreground color."),
        ("text_closed", "as", "Text when box is closed"),
        ("text_open", "", "Text when box is open"),
    ]
    
    def __init__(self, **config):
        self.play_pause_widget = widget.TextBox(text='')
        self.previous_widget = widget.TextBox(text='󰒮')
        self.next_widget = widget.TextBox(text='󰒭')
        
        widgets = [
            self.previous_widget,
            self.play_pause_widget,
            self.next_widget,
        ]
        
        widget.WidgetBox.__init__(self, widgets, **config)
        self.add_defaults(YTMusicControlWidget.defaults)
        # self.box_is_open = True
        
    def _configure(self, qtile, bar):
        widget.WidgetBox._configure(self, qtile, bar)
        
        # if not self.box_is_open:
        #     self.box_is_open = not self.box_is_open
        #     self.toggle_widgets()
        #     # widget.WidgetBox.cmd_toggle(self)
        
    # def cmd_toggle(self):
    #     # disable widget toggling
    #     ...
        

class YTMusicPausePlayWidget(base._TextBox, YTMusicAPIInitMixin):
    def __init__(self, **config):
        base._TextBox.__init__(self, **config)
        
        self.add_callbacks({
            'Button1': lazy.function(self.toggle_pause_play_qtile)
        })
        
        self.yt_music_api = yt_music_api
        
    def _configure(self, qtile, bar):           
        base._TextBox._configure(self, qtile, bar)
        
        self.yt_music_api.start_up()
        self.init_yt_music_api_hooks(self.yt_music_api)
        
        self.update_state()
            
        self.yt_music_api.info_callbacks.add(self.update_state)
        
    def update_state(self, song_info=None):
        if song_info is None:
            song_info = {'isPaused': False}
        self.is_paused = song_info['isPaused']
        self.update_label()
        
    def update_label(self):
        if self.is_paused:
            current_status = ''
        else:
            current_status = ''
            
        self.update(current_status)
        
    def toggle_pause_play(self):
        self.yt_music_api.toggle_pause_play()
        
    def toggle_pause_play_qtile(self, qtile):
        self.toggle_pause_play()
        


class YTMusicNextSongWidget(base._TextBox):
    def __init__(self, **config):
        base._TextBox.__init__(self, **config)

        self.add_callbacks({
            'Button1': lazy.function(self.next_song_qtile)
        })
        
        self.text = '󰒭'
        
        self.yt_music_api = yt_music_api
        
    def next_song(self):
        self.yt_music_api.next_song()
        
    def next_song_qtile(self, qtile):
        self.next_song()
        
        

class YTMusicPreviousSongWidget(base._TextBox):
    def __init__(self, **config):
        base._TextBox.__init__(self, **config)

        self.add_callbacks({
            'Button1': lazy.function(self.previous_song_qtile)
        })
        
        self.text = '󰒮'
        
        self.yt_music_api = yt_music_api
        
    def previous_song(self):
        self.yt_music_api.previous_song()
        
    def previous_song_qtile(self, qtile):
        self.previous_song()
        


class YTMusicWidget(widget.WidgetBox):
    defaults = [
        ("foreground", "#ffffff", "Foreground color."),
    ]
    
    def __init__(self, **config):
        self.title_widget = YTMusicTitleWidget()
        self.play_pause_widget = YTMusicPausePlayWidget()
        self.previous_widget = YTMusicPreviousSongWidget()
        self.next_widget = YTMusicNextSongWidget()
        
        widgets = [
            self.title_widget,
            self.previous_widget,
            self.play_pause_widget,
            self.next_widget,
            widget.TextBox(text='|')
        ]
        
        widget.WidgetBox.__init__(self, widgets, **config)
        self.add_defaults(YTMusicWidget.defaults)
        
        self.yt_music_api = yt_music_api
        
        self.yt_music_on_icon = '󰝚 '
        self.yt_music_off_icon = '󰝛 '
        
    def _configure(self, qtile, bar):           
        widget.WidgetBox._configure(self, qtile, bar)
        
        self.yt_music_api.start_up()
        
        self.update_yt_music_status(
            self.yt_music_api.process_observer.check_is_process_run()
        )
        
        self.yt_music_api.process_observer.update_callbacks.add(
            self.update_yt_music_status
        )
        
    def update_yt_music_status(self, yt_music_status):
        if yt_music_status:
            current_icon = self.yt_music_on_icon         
            self._can_toggling = True
        else:
            current_icon = self.yt_music_off_icon
            
            # close widget if youtube music closed
            if self.box_is_open:
                self.cmd_toggle()
                
            self._can_toggling = False
            
        self.text_open = current_icon
        self.text_closed = current_icon
            
        self.set_box_label()
        self.bar.draw()
        
    def cmd_toggle(self):
        if self._can_toggling:
            super().cmd_toggle()
            
            
        
























class ChangeVolume:
    script_path = str(config_path / 'change_volume')
    
    def change_volume(self, change_type):
        subprocess.call([f'bash {self.script_path} {change_type}'], shell=True)
        
    def up(self, qtile):
        self.change_volume('up')
        
    def down(self, qtile):
        self.change_volume('down')
        
    def mute(self, qtile):
        self.change_volume('mute')
        
        
change_volume = ChangeVolume()



class ChangeBrightness:
    script_path = str(config_path / 'change_brightness')
    
    def change_brightness(self, change_type):
        subprocess.call([f'bash {self.script_path} {change_type}'], shell=True)
        
    # @lazy.function
    def up(self, qtile):
        self.change_brightness('up')
        
    # @lazy.function
    def down(self, qtile):
        self.change_brightness('down')
        
        
change_brightness = ChangeBrightness()
# change_brightness.change_brightness('up')

pick_color_script = str(config_path / 'pick_color')
logger.warning(f'pick_color_script: {pick_color_script}')

@lazy.function
def pick_color_qtile(qtile):
    logger.warning('mouse clicked')

    try:
        # bash
        subprocess.call([f'bash {pick_color_script}'], shell=True)
        logger.warning('subprocess called')
    except Exception as e:
        logger.warning(f'meh {e}')


# АВТОЗАПУСК ----------------------------------------------------------------------
@hook.subscribe.startup_once
def autostart():
    subprocess.call([str(config_path / 'autostart.sh')])


@hook.subscribe.startup
def _startup():
    global mybar, rounded_bar
    mybar.window.window.set_property("QTILE_BAR", 1, "CARDINAL", 32)

    addition_process = ''
    if is_process_run('picom'):
        sleep_time = 0.5
        addition_process = f'pkill picom; sleep {sleep_time}; '

    picom_command = 'picom -b --xrender-sync-fence --glx-no-rebind-pixmap --use-damage --glx-no-stencil --use-ewmh-active-win'
    if rounded_bar:
        subprocess.run(addition_process + picom_command, shell=True)
    else:
        subprocess.run(
            addition_process + picom_command + ' --rounded-corners-exclude "QTILE_INTERNAL:32c = 1"',
            shell=True
        )


# СДЕЛАТЬ ДИАЛОГОВЫЕ ОКНА ПЛАВАЮЩИМИ ----------------------------------------------
@hook.subscribe.client_new
def floating_dialogs(window):
    dialog = window.window.get_wm_type() == 'dialog'
    transient = window.window.get_wm_transient_for()
    if dialog or transient:
        window.floating = True


class StickyManagement:
    """Класс который реализует возможность закреплять окна на рабочих поверхностях"""

    def __init__(self, activate_hooks=False, sticky_rules=None, groups_rules=None):
        self.window_list = list()
        
        if sticky_rules is None:
            sticky_rules = []
        self.sticky_rules = sticky_rules
        
        
        if groups_rules is None:
            groups_rules = []
            
        for idx, rule in enumerate(groups_rules):
            if 'match' not in rule:
                raise ValueError(f"{groups_rules=}\nelement: {rule}\element index: {idx}\ngroups_rules element must contains 'match' to understand the query.")
            if 'groups' not in rule and 'exclude_groups' not in rule:
                raise ValueError(f"{groups_rules=}\nelement: {rule}\element index: {idx}\ngroups_rules element must contains 'groups' or 'exclude_groups'.")
        self.groups_rules = groups_rules
        
        if activate_hooks:
            self.init_hooks()

    def _pin_window(self, window):
        self.window_list.append(window)

    def _unpin_window(self, window):
        self.window_list.remove(window)

    def toggle_sticky_window(self, qtile):
        current_window = qtile.current_window

        if current_window in self.window_list:
            self._unpin_window(current_window)
        else:
            self._pin_window(current_window)

    def pin_window(self, qtile):
        current_window = qtile.current_window

        if current_window not in self.window_list:
            self._pin_window(current_window)

    def unpin_window(self, qtile):
        current_window = qtile.current_window

        if current_window in self.window_list:
            self._unpin_window(current_window)
            
    def check_translate_available(self, window, group_name):
        for rule in self.groups_rules:
            if window.match(rule['match']):
                if 'exclude_groups' in rule:
                    if group_name not in rule['exclude_groups']:
                        return True
                    
                if group_name in rule['groups'] or rule['groups'] == '__all__':
                        return True
                    
                return False
                    
        return True

    def init_hooks(self):
        window_list = self.window_list

        @hook.subscribe.setgroup
        def _move_sticky_window_to_current_group():
            for window in window_list:
                if self.check_translate_available(window, qtile.current_group.name):
                    window.togroup(qtile.current_group.name)
                    window.cmd_bring_to_front()

        @hook.subscribe.client_managed
        def _display_pined_window_above_other(window_):
            for window in window_list:
                window.cmd_bring_to_front()
                
        @hook.subscribe.client_killed
        def _unpin_window_when_its_kill(window_):
            if window_ in window_list:
                self._unpin_window(window_)
                
        @hook.subscribe.client_new
        def _check_match_when_new_window_opened(new_window):
            for match in self.sticky_rules:
                if new_window.match(match) and new_window not in window_list:
                    self._pin_window(new_window)
                    break
                
            for window in window_list:
                window.cmd_bring_to_front()


sticky_management = StickyManagement(
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
    Key([mod, "control"], "space", lazy.hide_show_bar("top")),


    # Запуск приложений
    Key([mod], "Return", lazy.spawn("alacritty")),
    # Key([mod], "f", lazy.spawn("firefox --wayland")), # Это для вайланда
    Key([mod], "f", lazy.spawn(webbrowser)),  # Для иксов
    Key([mod], "e", lazy.spawn(file_explorer)),
    Key([mod], "t", lazy.spawn("telegram-desktop")),
    Key([mod], "p", pick_color_qtile),
    Key([mod], "space", lazy.spawn("rofi -show drun")),


    # Раскладка клавиатуры
    # Key([mod], "space", lazy.widget["keyboardlayout"].next_keyboard(), desc="Next keyboard layout."),
    Key(['mod1'], "Shift_L", lazy.widget["keyboardlayout"].next_keyboard(),
        desc="Next keyboard layout."),


    # Штука которая позволяет закрепить окно на всех рабочих поверхностях
    # Т.е. окно будет следовать за вами на всех робочих столах
    Key([mod], "o", lazy.function(
        sticky_management.toggle_sticky_window), desc="toggle stick window"),


    # Скриешоты
    # Нужно установить gnome-screenshot
    Key([], "Print", lazy.spawn('flameshot gui')),


    # Контроль звука и яркости
    Key([], "XF86AudioLowerVolume", lazy.function(change_volume.down)),
    Key([], "XF86AudioRaiseVolume", lazy.function(change_volume.up)),
    Key([], "XF86AudioMute", lazy.function(change_volume.mute)),
    Key([], "XF86AudioMicMute", lazy.spawn("amixer set Capture togglemute")),


    # Яркость нужно установить light
    # sudo chmod +s /usr/bin/light для работы утилиты light
    Key([], "XF86MonBrightnessDown", lazy.function(change_brightness.down)),
    Key([], "XF86MonBrightnessUp", lazy.function(change_brightness.up)),

]


# ПЕРЕКЛЮЧЕНИЕ ВОРКСПЕЙСОВ И ПЕРЕМЕЩЕНИЕ ОКОН ПО НИМ ------------------------------
class GroupCreator:
    is_description = False
    is_subscript_or_superscript = True
    fmt = '{label} {description}'
    error_text = 'Subscript for key:[{key}] not found. Try to set the subscript yourself.'

    def format_description(self, label, description):
        return self.fmt.format(label=label, description=description)

    def __call__(self, key, label, is_description=None, description='', **kwargs):
        if is_description is not None:
            add_description = is_description
        else:
            add_description = self.is_description

        if add_description:
            if not description:
                description = key
                
            if self.is_subscript_or_superscript is None:
                description = description
            elif self.is_subscript_or_superscript:
                description = f'<sub> {description}</sub>'
            else:
                description = f'<sup>{description}</sup>'
                    
                # description = self.error_text.format(key=key)
                

            label = self.format_description(label, description)

        return Group(key, label=label, **kwargs)


create_group = GroupCreator()
create_group.is_description = True
create_group.is_subscript_or_superscript = False
# create_group.fmt = '{label} {description}'

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
    layout.Bsp(
        border_focus="#C3C3C3",
        border_normal="#2E3440",
        border_width=1,
        # lower_right=False,
        # ratio=-1.6,
        # fair=False,
        margin=[around_gaps, 0, group_gaps - around_gaps, group_gaps]
    ),  # Как в bspwm

    # layout.MonadTall(
    #     border_focus="#C3C3C3",
    #     border_normal="#2E3440",
    #     border_width=1,
    #     margin=[0, 0, group_gaps, group_gaps]
    # ),  # Как в bspwm

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


rofi_wifi_menu = f'bash {home_path}/.config/rofi-network-manager/rofi-network-manager.sh'
rofi_bluetooth_menu = f'bash {home_path}/.config/rofi-bluetooth/rofi-bluetooth'


class MyBattery(widget.Battery):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        def get_prep__get_param(func):
            def _get_param(name):
                try:
                    return func(name)
                except:
                    return None
            return _get_param

        self._battery._get_param = get_prep__get_param(
            self._battery._get_param)


# /usr/share/icons/breeze-dark/status
# ВИДЖЕТЫ НА ПАНЕЛИ И ИХ ПАРАМЕТРЫ ------------------------------------------------
decor = {
    "decorations": [
        qe_widget.decorations.BorderDecoration(
            colour="#ffffff",
            border_width=1,
        )
    ],
    # "padding": 18,
}

bar_widgets = [
    # Menu
    widget.WidgetBox(
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
                    "alacritty -e bpython")},
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
                **decor
            ),
            widget.Image(
                filename=str(config_path / 'menu_images/1.jpg'),
                mouse_callbacks={'Button1': lazy.spawn(
                    "alacritty -e bpython")},
            ),

            widget.Spacer(length=5),
            widget.TextBox(text="|"),
        ]
    ),

    widget.Spacer(length=20),

    # widget.CurrentLayout(), # Текущий макет
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
    # widget.WindowName(max_chars=30),  # Имя окна
    widget.Chord(
        chords_colors={
            "launch": ("#ff0000", "#ffffff"),
        },
        name_transform=lambda name: name.upper(),
    ),
    widget.Spacer(),

    widget.Systray(),  # Трэй, не работает в вялом, нужно будет юзать widget.StatusNotifier
    widget.Spacer(length=15),


    widget.WidgetBox(
        text_closed='  ',
        text_open='  ',
        padding=0,
        widgets=[
            widget.TextBox(text="|"),

            # WIFI
            widget.TextBox(
                text="",
                mouse_callbacks={'Button1': lazy.spawn(rofi_wifi_menu)},
            ),
            widget.Wlan(
                format='{essid}',
                padding=0,
                mouse_callbacks={'Button1': lazy.spawn(rofi_wifi_menu)},
            ),
            widget.Spacer(length=8),


            # Яркость
            widget.TextBox(text="󰖨"),
            blw := widget.Backlight(padding=0),
            widget.Spacer(length=15),

            # Обновлений пакетов
            widget.CheckUpdates(
                distro='Arch',
                display_format=' {updates}',
                no_update_string=' 0',
                padding=0
            ),
            widget.Spacer(length=6),

            # Bluetooth
            widget.TextBox(
                text="",
                mouse_callbacks={'Button1': lazy.spawn(rofi_bluetooth_menu)},
            ),
            
            # Color picker
            # Нужно установить xcolor
            widget.TextBox(
                text="",
                mouse_callbacks={'Button1': pick_color_qtile},
                # padding=7
            ),
            # widget.Spacer(length=8),

            widget.TextBox(text="|"),
            widget.Spacer(length=8),
        ]
    ),
    # widget.Spacer(length=0),
    widget.Spacer(length=8),
    
    # YTMusicWidget(),
    widget.Spacer(length=8),


    # Нужно установить pavucontrol
    widget.TextBox(
        text="",
        mouse_callbacks={'Button1': lazy.spawn("pavucontrol")},
        padding=7
    ),
    # Виджет громкости пульсы
    widget.PulseVolume(limit_max_volume=True, padding=0),
    widget.Spacer(length=15),  # Виджет пробела
 
    # Keyboard layout
    widget.KeyboardLayout(
        configured_keyboards=keyboard_layouts,
        update_interval=1,
        padding=0
    ),
    widget.Spacer(length=15),

    # Battery
    battery_widget := widget.BatteryIcon(
        theme_path=str(battery_icons_folder),
        padding=0,
        update_interval=5,
        scale=1,
    ),
    MyBattery(
        padding=5,
        format="{percent:2.0%}",
        update_interval=5,
        hide_threshold=True,
    ),
    widget.Spacer(length=10),

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

    widget.Clock(format="%H:%M.%S",
                 padding=0),  # Время и дата
    widget.Spacer(length=20),  # Виджет пробела

    # Quit
    widget.QuickExit(default_text='', padding=6),  # Кнопка выключения
]


screens = [
    Screen(
        wallpaper=str(wallpapers_folder / '1.jpg'),
        wallpaper_mode='stretch',
        right=bar.Gap(around_gaps),
        left=bar.Gap(around_gaps - group_gaps),
        bottom=bar.Gap(2 * around_gaps - group_gaps),
        top=(mybar := bar.Bar(  # Расположение бара
            bar_widgets,
            20,  # Высота панели
            border_width=[2, 16, 2, 10],  # Толщина рамок панели
            border_color=["2E3440", "2E3440", "2E3440", "2E3440"],
            margin=bar_gaps,  # Гапсы бара
            background="#2E3440",  # Цвет фона панели
            opacity=1,  # Прозрачность бара
        )),
    ),
    Screen(
        wallpaper=str(wallpapers_folder / '2.jpg'),
        wallpaper_mode='stretch',
        top=bar.Bar(
            [
                widget.Spacer(length=10),
                # base_groupbox,
                # widget.Spacer(length=20),
            ],
            30,
            border_width=[2, 2, 2, 2],  # Толщина рамок панели
            # 777777  C3C3C3   Цвет рамок панели
            border_color=["2E3440", "2E3440", "ffffff", "2E3440"],
            # border_color=["2E3440", "2E3440", "2E3440", "2E3440"],  # Цвет рамок панели
            margin=[10, 725, 0, 725],  # Гапсы бара
            background="#2E3440"  # Цвет фона панели
            # opacity=0,5 # Прозрачность бара
        ),
    ),
]

# base_groupbox.margin_x = 10


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
    self.drawer.ctx.translate(
        0, (self.bar.height - image.height) // 2 + self.y_padding)
    self.drawer.ctx.set_source(image.pattern)
    self.drawer.ctx.paint()
    self.drawer.ctx.restore()
    self.drawer.draw(offsetx=self.offset,
                     offsety=self.offsety, width=self.length)

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
        # Match(title="Picture-in-Picture"),
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
