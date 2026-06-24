import subprocess

from libqtile.widget import base
import settings


class Bluetooth(base.InLoopPollText):
    defaults = [
        (
            "update_interval",
            30,
            "Update interval in seconds, if none, the "
            "widget updates whenever it's done.",
        ),
        (
            "format",
            "{icon} {status}%",
            "format of data displaing",
        ),
        (
            "script_path",
            str(settings.scripts_path / "bluetooth_headphones_battery.sh"),
            "Path to volume control script",
        ),
    ]

    def __init__(self, **config):
        base.InLoopPollText.__init__(self, default_text=" ", **config)
        self.add_defaults(Bluetooth.defaults)

    @property
    def status(self) -> int | None:
        result = subprocess.run(
            ["bash", self.script_path],
            capture_output=True,
            text=True,
        )
        try:
            return int(result.stdout.replace("\n", ""))
        except:
            return None

    def format_volume(self, status: str) -> str:
        return self.format.format(icon=self.icon, status=status)

    def poll(self) -> str:
        return self.format_volume(str(self.status or "~"))
