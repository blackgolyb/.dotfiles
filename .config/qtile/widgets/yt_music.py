import time
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
from libqtile.widget import base
from libqtile.log_utils import logger
from pathlib import Path

from utils import is_process_run



yt_music_song_title_file = '/tmp/yt_music_song_name.txt'

class YTMusicTitleFileModifiedHandler(FileSystemEventHandler):
    def __init__(self, widget):
        self.widget = widget

    def on_modified(self, event):
        # logger.warning('on_modified')
        if not event.is_directory and event.src_path == self.widget.song_title_file:
            # time.sleep(0.5)
            self.widget.update_title()
            logger.warning(f'modified: {self.widget.song_title}')
            if self.widget.song_title != '':
                self.widget.cmd_force_update()
            

class YTMusicWidget(base.ThreadPoolText):
    defaults = [
        (
            "update_interval",
            5,
            "Update interval in seconds, if none, the " "widget updates whenever it's done.",
        ),
        (
            "app_close_msg",
            "YT music close)",
            "",
        ),
        (
            "song_title_file",
            yt_music_song_title_file,
            "",
        ),
    ]
    
    def __init__(self, **config):
        base.ThreadPoolText.__init__(self, text=" ", **config)
        self.add_defaults(YTMusicWidget.defaults)

        self.observer = Observer()
        self.observer.schedule(
            YTMusicTitleFileModifiedHandler(self),
            path=self.song_title_file
        )
        
    def _configure(self, qtile, bar):
        super()._configure(qtile, bar)
        self.song_title = ''
        
        if not Path(self.song_title_file).exists():
            with open(self.song_title_file, 'w') as f:
                f.write(' ')
                
        self.start()

    @property
    def _is_youtube_music_run(self):
        return is_process_run('youtube-music')
        
    def update_title(self):
        with open(self.song_title_file, 'r') as f:
            self.song_title = f.read()

    def poll(self):
        if is_run := self._is_youtube_music_run:# or True:
            self.text = self.song_title
            result = self.text
        else:
            result = self.app_close_msg
        
        return result
        
    def start(self):
        self.observer.start()
        # self.update_title()

    def stop(self):
        self.observer.stop()
        self.observer.join()
