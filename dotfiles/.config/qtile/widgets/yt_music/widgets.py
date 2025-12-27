from libqtile import hook, widget
from libqtile.lazy import lazy
from libqtile.log_utils import logger
from libqtile.widget import Systray, base

from widgets.base import HoveringWidgetTabGroup, WidgetBox, WidgetGroup

# from pathlib import Path
from .api import YTMusicAPI


class YTMusicAPIInitMixin:
    yt_music_api: YTMusicAPI

    def init_yt_music_api_hooks(self, api):
        @hook.subscribe.shutdown
        def on_shutdown_kill_api():
            api.stop()

        # @hook.subscribe.startup
        # def on_reconfigured_kill_api():
        #     api.kill()

    def _configure(self, qtile, bar):
        self.yt_music_api.start()
        self.init_yt_music_api_hooks(self.yt_music_api)
        super()._configure(qtile, bar)


def animate_line(title: str, title_fmt: str, max_chars: int):
    if len(title) <= max_chars:
        # Будем раздавать название песни без анимации
        while True:
            yield title

    # В ином случае будем раздавать уже с анимацией прокрутки
    target_text = title_fmt.format(title)
    anim_id = 0

    while True:
        start_char = anim_id
        end_char = anim_id + max_chars

        # Часть которая попадает до конца названия
        first_part = target_text[start_char : min(end_char, len(target_text))]
        # Часть которая попадает после конца названия
        second_part = ""
        if end_char >= len(target_text):
            second_part = target_text[: max(0, end_char % len(target_text))]

        current_animated_text = first_part + second_part

        yield current_animated_text
        anim_id = (anim_id + 1) % len(target_text)


class YTMusicTitleWidget(YTMusicAPIInitMixin, base.InLoopPollText):
    defaults = [
        (
            "update_interval",
            1,
            "Update interval in seconds, if none, the widget updates whenever it's done.",
        ),
        (
            "fmt",
            "{}",
            "Update interval in seconds, if none, the widget updates whenever it's done.",
        ),
        ("max_chars", 12, "Maximum number of characters to display in widget."),
        (
            "app_close_msg",
            "close",
            "",
        ),
        (
            "animate_format",
            "{}  ",
            "",
        ),
    ]

    def __init__(self, api: YTMusicAPI | None = None, animate=None, **config):
        base.InLoopPollText.__init__(self, default_text=" ", **config)
        self.add_defaults(YTMusicTitleWidget.defaults)

        # Fix max_chars default bug
        for i in range(len(YTMusicTitleWidget.defaults)):
            if YTMusicTitleWidget.defaults[i][0] == "max_chars":
                self.max_chars = YTMusicTitleWidget.defaults[i][1]
                break

        self.yt_music_api = api or YTMusicAPI()
        self.animate = animate or animate_line
        self.song_title = ""

    def _configure(self, qtile, bar):
        super()._configure(qtile, bar)

        self.yt_music_api.info_callbacks.add(self.update_song)
        self.update_song()

    def update_song(self, song_info=None):
        if song_info is None:
            title = self.app_close_msg
        else:
            title = song_info.title

        if self.song_title == title:
            return

        self.song_title = title
        self.animator = self.animate(self.song_title, self.animate_format, self.max_chars)

    def poll(self):
        if self.yt_music_api.is_alive():
            result = next(self.animator)
        else:
            result = self.app_close_msg

        return result


class YTMusicPausePlayWidget(YTMusicAPIInitMixin, base._TextBox):
    def __init__(self, api: YTMusicAPI | None = None, **config):
        base._TextBox.__init__(self, **config)

        self.add_callbacks({"Button1": lazy.function(self.toggle_pause_play_qtile)})

        self.yt_music_api = api or YTMusicAPI()
        self.is_paused = True

    def _configure(self, qtile, bar):
        super()._configure(qtile, bar)

        self.yt_music_api.info_callbacks.add(self.update_state)
        self.update_state()

    def update_state(self, song_info=None):
        if song_info is None:
            is_paused = False
        else:
            is_paused = song_info.is_paused

        if self.is_paused == is_paused:
            return

        self.is_paused = is_paused
        self.update_label()

    def update_label(self):
        if self.is_paused:
            current_status = ""
        else:
            current_status = ""

        self.update(current_status)

    def toggle_pause_play(self):
        self.yt_music_api.toggle_pause_play()

    def toggle_pause_play_qtile(self, qtile):
        self.toggle_pause_play()


class YTMusicNextSongWidget(base._TextBox):
    def __init__(self, api: YTMusicAPI | None = None, **config):
        base._TextBox.__init__(self, **config)

        self.add_callbacks({"Button1": lazy.function(self.next_song)})

        self.text = "󰒭"
        self.yt_music_api = api or YTMusicAPI()

    def next_song(self, qtile=None):
        self.yt_music_api.next_song()


class YTMusicPreviousSongWidget(base._TextBox):
    def __init__(self, api: YTMusicAPI | None = None, **config):
        base._TextBox.__init__(self, **config)

        self.add_callbacks({"Button1": lazy.function(self.previous_song)})

        self.text = "󰒮"
        self.yt_music_api = api or YTMusicAPI()

    def previous_song(self, qtile=None):
        self.yt_music_api.previous_song()


class YTMusicControlWidget(WidgetGroup):
    def __init__(self, api: YTMusicAPI | None = None, **config):
        api = api or YTMusicAPI()
        self.play_pause_widget = YTMusicPausePlayWidget(api)
        self.previous_widget = YTMusicPreviousSongWidget(api)
        self.next_widget = YTMusicNextSongWidget(api)

        widgets = [
            self.previous_widget,
            self.play_pause_widget,
            self.next_widget,
        ]

        WidgetGroup.__init__(self, widgets=widgets, **config)


class YTMusicWidget(YTMusicAPIInitMixin, WidgetBox):
    defaults = [
        ("foreground", "#ffffff", "Foreground color."),
    ]

    def __init__(self, api: YTMusicAPI | None = None, **config):
        api = api or YTMusicAPI()
        self.title_widget = YTMusicTitleWidget(api)
        self.control_widget = YTMusicControlWidget(api)

        widgets = [
            HoveringWidgetTabGroup(
                [
                    self.title_widget,
                ],
                [
                    self.control_widget,
                ],
            ),
        ]

        WidgetBox.__init__(self, widgets=widgets, **config)
        self.add_defaults(YTMusicWidget.defaults)

        self.yt_music_api = api
        self.yt_music_status = None

    def _configure(self, qtile, bar):
        super()._configure(qtile, bar)

        self.update_yt_music_status(self.yt_music_api.is_alive())
        self.yt_music_api.is_alive_callbacks.add(self.update_yt_music_status)

    def update_yt_music_status(self, yt_music_status):
        if self.yt_music_status == yt_music_status:
            return

        self.yt_music_status = yt_music_status

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


class YTMusicIndicator(base.InLoopPollText):
    defaults = [
        (
            "update_interval",
            5,
            "Update interval in seconds, if none, the widget updates whenever it's done.",
        ),
        ("yt_music_on_icon", "󰝚", ""),
        ("yt_music_off_icon", "󰝛", ""),
    ]

    def __init__(self, api: YTMusicAPI | None = None, **config):
        base.InLoopPollText.__init__(self, default_text="", **config)
        self.add_defaults(YTMusicIndicator.defaults)
        self.yt_music_api = api or YTMusicAPI()
        self.yt_music_status = None

    def update_status(self):
        self.yt_music_status = self.yt_music_api.is_alive(force=True)

    def _configure(self, qtile, bar):
        super()._configure(qtile, bar)
        self.update_status()

    def poll(self) -> str:
        self.update_status()
        return self.yt_music_on_icon if self.yt_music_status else self.yt_music_off_icon
