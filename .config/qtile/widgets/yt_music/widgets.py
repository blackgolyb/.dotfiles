from libqtile.widget import base, Systray
from libqtile.lazy import lazy
from libqtile.log_utils import logger
from libqtile import widget
from libqtile import hook
# from pathlib import Path

from .api import YTMusicAPI, yt_music_api
from widgets.base import WidgetBox, WidgetGroup, HoveringWidgetTabGroup


class YTMusicAPIInitMixin():
    yt_music_api: YTMusicAPI
    
    def init_yt_music_api_hooks(self, api):
        @hook.subscribe.shutdown
        def on_shutdown_kill_api():
            api.kill()
            
        # @hook.subscribe.startup
        # def on_reconfigured_kill_api():
        #     api.kill()
            
    def _configure(self, qtile, bar):
        self.yt_music_api.start_up()
        self.init_yt_music_api_hooks(self.yt_music_api)
        super()._configure(qtile, bar)
      

class YTMusicTitleWidget(YTMusicAPIInitMixin, base.InLoopPollText):
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
            "/tmp/yt_music_song_info.json",
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
        super()._configure(qtile, bar)
        
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
        

class YTMusicPausePlayWidget(YTMusicAPIInitMixin, base._TextBox):
    def __init__(self, **config):
        base._TextBox.__init__(self, **config)
        
        self.add_callbacks({
            'Button1': lazy.function(self.toggle_pause_play_qtile)
        })
        
        self.yt_music_api = yt_music_api
        
    def _configure(self, qtile, bar):           
        super()._configure(qtile, bar)
        
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
        
        
class YTMusicControlWidget(WidgetGroup):
    def __init__(self, **config):
        self.play_pause_widget = YTMusicPausePlayWidget()
        self.previous_widget = YTMusicPreviousSongWidget()
        self.next_widget = YTMusicNextSongWidget()
        
        widgets = [
            self.previous_widget,
            self.play_pause_widget,
            self.next_widget,
        ]
        
        WidgetGroup.__init__(self, widgets=widgets, **config)


class YTMusicWidget(YTMusicAPIInitMixin, WidgetBox):
    defaults = [
        ("foreground", "#ffffff", "Foreground color."),
        ("yt_music_on_icon", "󰝚 ", ),
        ("yt_music_off_icon", "󰝛 ", ),
    ]
    
    def __init__(self, **config):
        self.title_widget = YTMusicTitleWidget()
        self.control_widget = YTMusicControlWidget()
        
        widgets = [
            HoveringWidgetTabGroup(
                [self.title_widget,],
                [self.control_widget,],
            ),
        ]
        
        WidgetBox.__init__(self, widgets=widgets, **config)
        self.add_defaults(YTMusicWidget.defaults)
        
        self.yt_music_api = yt_music_api
        
    def _configure(self, qtile, bar):           
        super()._configure(qtile, bar)
        
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
            WidgetBox.cmd_toggle(self)
