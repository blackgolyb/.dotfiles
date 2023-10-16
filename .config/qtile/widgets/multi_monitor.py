import subprocess
import re

from libqtile.widget import base
from libqtile.lazy import lazy
from libqtile.log_utils import logger
from libqtile import qtile
from screeninfo import get_monitors

import settings


class MultiMonitor(base.InLoopPollText):
    defaults = [
        (
            "update_interval",
            5,
            "Update interval in seconds, if none, the "
            "widget updates whenever it's done.",
        ),
        (
            "script_path",
            str(settings.scripts_path / "multi_monitor"),
            "Path to brightness control script",
        ),
        (
            "extern_monitor",
            "HDMI-2",
            "Path to brightness control script",
        ),
        (
            "extern_monitor_default_option",
            "extend_right",
            "Path to brightness control script",
        ),
    ]

    def __init__(self, **config):
        base.InLoopPollText.__init__(self, default_text=" ", **config)
        self.add_defaults(MultiMonitor.defaults)
        self.add_callbacks(
            {
                "Button1": lazy.function(self.open_rofi_menu),
            }
        )

        self._connected_monitors = []

    def call_script(self, argument):
        subprocess.call([f"bash {self.script_path} {argument}"], shell=True)
        qtile.cmd_reload_config()

    def open_rofi_menu(self, qtile):
        self.call_script("menu")

    def get_monitors(self):
        # raw_result = subprocess.run(
        #     ["xrandr", "--query"],
        #     capture_output=True,
        #     text=True,
        # )

        # result = re.findall(r"(\w+-\w) connected", raw_result.stdout)
        result = list(map(lambda monitor: monitor.name, get_monitors()))
        logger.error(result)

        return result

    def update_monitors(self):
        connected_monitors = self.get_monitors()

        if (self.extern_monitor in connected_monitors) and (
            self.extern_monitor not in self._connected_monitors
        ):
            # extern monitor connected
            self.call_script(self.extern_monitor_default_option)

        elif (self.extern_monitor not in connected_monitors) and (
            self.extern_monitor in self._connected_monitors
        ):
            # extern monitor disconnected
            self.call_script("disconnect")

        self._connected_monitors = connected_monitors

    def poll(self):
        # self.update_monitors()

        return "󰍹"
