import json
import requests

from pathlib import Path
from libqtile.log_utils import logger
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

from services.callbacks import Callbacks
from services.process_observer import ProcessObserver


class FileClosedHandler(FileSystemEventHandler):
    def __init__(self, handled_file):
        self.handled_file = handled_file
        self.callbacks = Callbacks()

    def on_closed(self, event):
        if not event.is_directory and event.src_path == self.handled_file:
            self.callbacks.send()


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
        
        self.process_observer = ProcessObserver(
            'youtube-music',
            timeout=10,
            soft_waiting=True
        )
        
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
            # logger.warning('start')
            if not self.info_observer.is_alive():
                self.info_observer.start()
            if not self.process_observer.is_alive():
                self.process_observer.start()
            # logger.warning('start_up')
        except Exception as e:
            logger.warning(e)
        
    def kill(self):
        try:
            # logger.warning('stop')
            self.info_observer.stop()
            self.info_observer.join()
            self.process_observer.stop()
            self.process_observer.join()
            # logger.warning('kill')
        except Exception as e:
            logger.warning(e)

yt_music_api = YTMusicAPI()