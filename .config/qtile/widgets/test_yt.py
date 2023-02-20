import time
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
from libqtile.widget import base
from libqtile.log_utils import logger
from pathlib import Path



yt_music_song_title_file = '/tmp/yt_music_song_name.txt'

class YTMusicTitleFileModifiedHandler(FileSystemEventHandler):
    def on_modified(self, event):
        print('on_modified')
        if not event.is_directory and event.src_path == yt_music_song_title_file:
            time.sleep(0.5)
            song_title = update_title()
            print(f'modified {song_title}')


def update_title():
    with open(yt_music_song_title_file, 'r') as f:
        song_title = f.read()
        
    return song_title


# observer = Observer()
# observer.schedule(
#     YTMusicTitleFileModifiedHandler(),
#     path=yt_music_song_title_file
# )
# observer.start()

# try:
#     while True:
#         time.sleep(0.1)
# except KeyboardInterrupt:
#     observer.stop()
# observer.join()


song_title = 'Sooooooome text))))'
max_chars = 5
animate_format = '{}|/|'

def animate():
    target_text = animate_format.format(song_title)
    _amin_id = 0
    while True:
        start_char = _amin_id
        end_char = _amin_id + max_chars
        first_part = target_text[start_char: min(end_char, len(target_text))]
        second_part = ''
        if end_char >= len(target_text):
            second_part = target_text[: max(0, end_char % len(target_text))]
        print(start_char, end_char, len(target_text))
        # print(f'{first_part=}')
        # print(f'{second_part=}')
        current_animated_text = first_part + second_part
        yield current_animated_text
        _amin_id = (_amin_id + 1) % len(target_text)
        

animator = animate()
try:
    while True:
        time.sleep(0.1)
        print(next(animator))
except KeyboardInterrupt:
    quit()