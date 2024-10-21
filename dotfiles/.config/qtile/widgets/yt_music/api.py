import re
import json
import threading
import time
import typing
import requests
import datetime
from pathlib import Path
from dataclasses import dataclass

from libqtile.log_utils import logger
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

from services.callbacks import Callbacks

CAMEL_CASE_TO_SNAKE_CASE_PATTERN = re.compile(r'(?<!^)(?=[A-Z])')
def camel_case_to_snake_case(name: str) -> str:
    return CAMEL_CASE_TO_SNAKE_CASE_PATTERN.sub('_', name).lower()


@dataclass
class SongInfo:
    title: str
    artist: str
    views: int
    upload_date: datetime.datetime
    image_src: str
    is_paused: bool
    song_duration: int
    elapsed_seconds: int
    url: str
    video_id: str
    playlist_id: str
    media_type: str
    album: str | None = None

    def __post_init__(self):
        if isinstance(self.upload_date, str):
            self.upload_date = datetime.datetime.fromisoformat(self.upload_date)

    @classmethod
    def from_dict(cls, data: dict):
        data = {camel_case_to_snake_case(k): v for k, v in data.items()}
        return cls(**data)


class LoopThread(threading.Thread):
    def __init__(self, target, timeout):
        threading.Thread.__init__(self)

        self._target = target
        self._timeout = timeout
        self._stop_event = threading.Event()

    def wait(self):
        # for _ in range(int(self._timeout)):
        #     if self._stop_event.is_set():
        #         return

        #     time.sleep(1)

        # time.sleep(self._timeout - int(self._timeout))
        time.sleep(self._timeout)

    def run(self):
        while not self._stop_event.is_set():
            self._target()
            self.wait()

    def stop(self):
        self._stop_event.set()

class YTMusicAPI:
    song_info_file = "/tmp/yt_music_song_info.json"
    check_timeout = 10
    api_version = 1
    api_port = 26538
    api_host = "localhost"
    api = {
        "base": "http://{host}:{port}",
        "api": "http://{host}:{port}/api/v{api_version}",
        "auth": "{base}/auth/{id}",
        "song_info": "{api}/song-info",
        "toggle_play_pause": "{api}/toggle-play",
        "previous": "{api}/previous",
        "next": "{api}/next",
    }

    def __init__(self):
        self.info_callbacks = Callbacks()
        self.is_alive_callbacks = Callbacks()
        self.token = None
        self.song_info = None
        self.update_process = LoopThread(self._update, self.check_timeout)

    def _format_url(self, url: str, **params) -> str:
        defaults = {
            "base": self.api["base"].format(host=self.api_host, port=self.api_port),
            "api": self.api["api"].format(host=self.api_host, port=self.api_port, api_version=self.api_version),
            "host": self.api_host,
            "port": self.api_port,
            "api_version": self.api_version,
        }
        return url.format(**defaults, **params)

    def _api_call(self, method: str, api: str, request_params=None, **params):
        if request_params is None:
            request_params = {}

        url = self._format_url(self.api[api], **params)
        try:
            return requests.request(method, url, **request_params)
        except:
            return None

    def _update(self):
        if not self.update_song_info():
            self.song_info = None

        self.send_info_callbacks()
        self.is_alive_callbacks.send(self.is_alive())

    def send_info_callbacks(self):
        self.info_callbacks.send(self.song_info)
        # print(self.song_info)

    def auth(self) -> bool:
        r = self._api_call("post", "auth", id="qtile")

        if r is None or r.status_code != 200:
            return False

        self.token = r.json()["accessToken"]
        return True

    def update_song_info(self) -> bool:
        r = self._api_call("get", "song_info")

        if r is None or r.status_code != 200:
            return False

        self.song_info = SongInfo.from_dict(r.json())
        return True

    def is_alive(self, force=False) -> bool:
        # return self._api_call("get", "base") is not None
        if force:
            return self._api_call("get", "base") is not None
        else:
            return self.song_info is not None

    def toggle_pause_play(self):
        r = self._api_call("post", "toggle_play_pause")
        if r is not None and self.song_info is not None:
            self.song_info.is_paused = not self.song_info.is_paused
            self.send_info_callbacks()

    def previous_song(self):
        self._api_call("post", "previous")

    def next_song(self):
        self._api_call("post", "next")

    def start(self):
        try:
            # logger.warning('start')
            if not self.update_process.is_alive():
                self.update_process.start()
            # logger.warning('start_up')
        except Exception as e:
            logger.warning(e)

    def stop(self):
        try:
            if self.update_process.is_alive():
                self.update_process.stop()
                self.update_process.join()
        except Exception as e:
            logger.warning(e)


api = YTMusicAPI()
