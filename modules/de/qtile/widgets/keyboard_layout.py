import subprocess

from libqtile.widget import base
from libqtile.lazy import lazy
from libqtile import hook
from libqtile.log_utils import logger

import settings


class KeyboardLayout(base.InLoopPollText):
    defaults = [
        (
            "update_interval",
            1,
            "Update interval in seconds, if none, the "
            "widget updates whenever it's done.",
        ),
        (
            "configured_keyboards",
            ["us"],
            "Path to brightness control script",
        ),
    ]

    def __init__(self, **config):
        base.InLoopPollText.__init__(self, default_text=" ", **config)
        self.add_defaults(KeyboardLayout.defaults)
        self.add_callbacks(
            {
                "Button1": lazy.function(self.next_layout),
            }
        )

        self.keyboard_layout = self.configured_keyboards[0]

    def init_setxkbmap_setup(self):
        @hook.subscribe.startup_once
        def setxkbmap_setup():
            setxkbmap_setup = 'setxkbmap -layout "us,ru" -option "grp:alt_shift_toggle"'
            ...

    def _configure(self, qtile, bar):
        # self.init_setxkbmap_setup()
        super()._configure(qtile, bar)

    def get_next_layout(self):
        if self.keyboard_layout in self.configured_keyboards:
            current_keyboard_layout_id = self.configured_keyboards.index(
                self.keyboard_layout
            )
        else:
            current_keyboard_layout_id = 0

        keyboards_list_len = len(self.configured_keyboards)
        next_keyboard_layout_id = (current_keyboard_layout_id + 1) % keyboards_list_len
        return self.configured_keyboards[next_keyboard_layout_id]

    def get_current_layout(self):
        logger.error(self.keyboard_layout)
        return self.keyboard_layout

    def set_layout(self, layout):
        subprocess.call([f"setxkbmap {layout}"], shell=True)

    def next_layout(self, qtile):
        self.keyboard_layout = self.get_next_layout()
        self.set_layout(self.keyboard_layout)

    def poll(self):
        return self.get_current_layout()
