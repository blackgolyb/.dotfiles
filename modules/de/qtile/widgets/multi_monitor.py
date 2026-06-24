import re
import subprocess
from pathlib import Path

import settings
from libqtile import hook, qtile
from libqtile.lazy import lazy
from libqtile.log_utils import logger
from libqtile.widget import base


class MultiMonitor(base.InLoopPollText):
    defaults = [
        (
            "update_interval",
            5,
            "Update interval in seconds, if none, the widget updates whenever it's done.",
        ),
        (
            "script_path",
            settings.scripts_path / "multi_monitor",
            "Path to brightness control script",
        ),
        (
            "displays_folder",
            Path("/sys/class/drm/"),
            "Path to folder with monitor devices",
        ),
        (
            "extern_monitor",
            "HDMI-2",
            "Path to brightness control script",
        ),
        (
            "extern_monitor_default_option",
            "only_extend HDMI-2",
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

        self.__init_extern_monitor()
        self.init_setup()

    def __init_extern_monitor(self):
        self.extern_monitor_folder = None
        for item in self.displays_folder.iterdir():
            formatted_name = re.findall(r"card\d+-([\w\-]+)", item.name)
            if not formatted_name:
                continue

            formatted_name = formatted_name[0]
            for part_of_name in self.extern_monitor.split("-"):
                if part_of_name not in formatted_name:
                    break
            else:
                self.extern_monitor_folder = item
                break

        self.prev_is_connected = self.is_monitor_connected()

    def init_setup(self):
        @hook.subscribe.startup_once
        def setup():
            self.prev_is_connected = self.is_monitor_connected()
            if self.prev_is_connected:
                self.call_script(self.extern_monitor_default_option, reload=False)

    def call_script(self, argument, reload=True):
        subprocess.call([f"bash {self.script_path} {argument}"], shell=True)
        if reload:
            qtile.reload_config()

    def open_rofi_menu(self, qtile):
        self.call_script("menu")

    def is_monitor_connected(self):
        if self.extern_monitor_folder is None:
            return False

        status_file: Path = self.extern_monitor_folder / "status"
        status = status_file.read_text().strip()

        return status == "connected"

    def update_monitors(self):
        is_connected = self.is_monitor_connected()
        prev = self.prev_is_connected
        self.prev_is_connected = is_connected

        if prev and not is_connected:
            self.call_script("disconnect")
        elif not prev and is_connected:
            self.call_script(self.extern_monitor_default_option)

    def poll(self):
        self.update_monitors()
        return "󰍹"
