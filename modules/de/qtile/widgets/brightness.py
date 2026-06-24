import subprocess

from libqtile.widget import base
from libqtile.lazy import lazy

import settings


class Brightness(base.InLoopPollText):
    defaults = [
        (
            "update_interval",
            5,
            "Update interval in seconds, if none, the "
            "widget updates whenever it's done.",
        ),
        (
            "script_path",
            str(settings.scripts_path / "brightness_control"),
            "Path to brightness control script",
        ),
    ]

    def __init__(self, **config):
        base.InLoopPollText.__init__(self, default_text=" ", **config)
        self.add_defaults(Brightness.defaults)
        self.add_callbacks(
            {
                # 'Button1': lazy.function(self.mute),
                "Button4": lazy.function(self.up),
                "Button5": lazy.function(self.down),
            }
        )

    def change_brightness(self, change_type):
        subprocess.call([f"bash {self.script_path} {change_type}"], shell=True)

    def get_brightness(self):
        result = subprocess.run(
            ["bash", self.script_path, "get"],
            capture_output=True,
            text=True,
        )
        return result.stdout.replace("\n", "")

    def up(self, qtile):
        self.change_brightness("up")
        self.update(self.poll())

    def down(self, qtile):
        self.change_brightness("down")
        self.update(self.poll())

    def poll(self):
        return self.get_brightness()
