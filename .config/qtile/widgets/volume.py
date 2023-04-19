import subprocess

from libqtile.widget import base
from libqtile.lazy import lazy

import settings
from services.utils import str2bool


class Volume(base.InLoopPollText):
    defaults = [
        (
            "update_interval",
            5,
            "Update interval in seconds, if none, the "
            "widget updates whenever it's done.",
        ),
        (
            "format",
            "{icon} {volume}",
        ),
        (
            "limit_max_volume",
            False,
        ),
        (
            "max_volume",
            100,
        ),
        (
            "volume_icons",
            ["󰕾", "󰖀", "󰕿", "󰝟"],
        ),
        (
            "script_path",
            str(settings.scripts_path / "volume_control"),
            "Path to volume control script",
        ),
    ]

    def __init__(self, **config):
        base.InLoopPollText.__init__(self, default_text=" ", **config)
        self.add_defaults(Volume.defaults)
        self.add_callbacks(
            {
                "Button1": lazy.function(self.mute),
                "Button4": lazy.function(self.up),
                "Button5": lazy.function(self.down),
            }
        )

    def change_volume(self, change_type):
        subprocess.call([f"bash {self.script_path} {change_type}"], shell=True)

    @property
    def volume(self) -> int:
        result = subprocess.run(
            ["bash", self.script_path, "get"],
            capture_output=True,
            text=True,
        )
        return int(result.stdout.replace("\n", ""))

    @property
    def is_muted(self) -> bool:
        result = subprocess.run(
            ["bash", self.script_path, "is_muted"],
            capture_output=True,
            text=True,
        )
        return str2bool(result.stdout.replace("\n", ""))

    def up(self, qtile):
        if self.limit_max_volume:
            if int(self.volume) >= self.max_volume:
                return

        self.change_volume("up")
        self.update(self.poll())

    def down(self, qtile):
        self.change_volume("down")
        self.update(self.poll())

    def mute(self, qtile):
        self.change_volume("mute")
        self.update(self.poll())

    def get_icon_by_volume(self, volume: int, is_muted: bool = False) -> str:
        if is_muted:
            return self.volume_icons[-1]

        icon = None
        n = len(self.volume_icons[:-1])
        for i in range(n):
            if self.max_volume / n * (n - i) >= volume:
                icon = self.volume_icons[i]

        if volume > self.max_volume:
            icon = self.volume_icons[0]
        elif volume == 0:
            icon = self.volume_icons[-1]

        return icon

    def format_volume(self, volume: int, is_muted: bool) -> str:
        current_icon = self.get_icon_by_volume(volume, is_muted)

        return self.format.format(icon=current_icon, volume=volume)

    def poll(self) -> str:
        # is_muted = self.is_muted
        # volume = self.volume

        return self.format_volume(self.volume, self.is_muted)
