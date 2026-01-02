from typing import Any

from libqtile import bar, images
from libqtile.log_utils import logger
from libqtile.command.base import expose_command
from libqtile.images import Img
from libqtile.utils import send_notification
from libqtile.widget import base
from libqtile.widget.battery import BatteryState, BatteryStatus, load_battery, default_icon_path


def marge_statuses(statuses: list[BatteryStatus]) -> BatteryStatus:
    n = len(statuses)
    states = [s.state for s in statuses]
    percent = sum((s.percent for s in statuses)) / n
    res_id = 0

    if (states.count(BatteryState.FULL) == n):
        res_id = 0

    if (states.count(BatteryState.EMPTY) == n):
        res_id = 0

    if (states.count(BatteryState.CHARGING) > 0):
        i = states.index(BatteryState.CHARGING)
        res_id = i

    return BatteryStatus(
        state=statuses[res_id].state,
        percent=percent,
        power=statuses[res_id].power,
        time=statuses[res_id].time,
        charge_start_threshold=statuses[res_id].charge_start_threshold,
        charge_end_threshold=statuses[res_id].charge_end_threshold,
    )


class Batteries(base.BackgroundPoll):
    defaults = [
        ("charge_char", "^", "Character to indicate the battery is charging"),
        ("discharge_char", "V", "Character to indicate the battery is discharging"),
        ("full_char", "=", "Character to indicate the battery is full"),
        ("empty_char", "x", "Character to indicate the battery is empty"),
        ("not_charging_char", "*", "Character to indicate the batter is not charging"),
        ("unknown_char", "?", "Character to indicate the battery status is unknown"),
        ("format", "{char} {percent:2.0%} {hour:d}:{min:02d} {watt:.2f} W", "Display format"),
        ("hide_threshold", None, "Hide the text when there is enough energy 0 <= x < 1"),
        (
            "full_short_text",
            "Full",
            "Short text to indicate battery is full; see `show_short_text`",
        ),
        (
            "empty_short_text",
            "Empty",
            "Short text to indicate battery is empty; see `show_short_text`",
        ),
        (
            "show_short_text",
            True,
            "Show only characters rather than formatted text when battery is full or empty",
        ),
        ("low_percentage", 0.10, "Indicates when to use the low_foreground color 0 < x < 1"),
        ("low_foreground", "FF0000", "Font color on low battery"),
        ("low_background", None, "Background color on low battery"),
        ("update_interval", 60, "Seconds between status updates"),
        ("batteries", [0, ], "Which battery should be monitored (battery number or name)"),
        ("notify_below", None, "Send a notification below this battery level."),
        ("notification_timeout", 10, "Time in seconds to display notification. 0 for no expiry."),
    ]

    def __init__(self, **config) -> None:
        base.BackgroundPoll.__init__(self, "", **config)
        self.add_defaults(self.defaults)

        self._batteries = self._load_batteries(**config)
        self._has_notified = False
        self.timeout = int(self.notification_timeout * 1000)

    def _configure(self, qtile, bar):
        if not self.low_background:
            self.low_background = self.background
        self.normal_background = self.background

        base.BackgroundPoll._configure(self, qtile, bar)

    @expose_command()
    def charge_to_full(self):
        for bat in self._batteries:
            bat.force_charge = True

    @expose_command()
    def charge_dynamically(self):
        for bat in self._batteries:
            bat.force_charge = False

    @staticmethod
    def _load_batteries(**config):
        """Function used to load the Battery object

        Battery behavior can be changed by overloading this function in a base
        class.
        """
        res = []
        for bat in config.get("batteries", (0, )):
            res.append(load_battery(**config, battery=bat))
        return res

    def update_status(self) -> BatteryStatus:
        statuses = []
        for bat in self._batteries:
            statuses.append(bat.update_status())

        return marge_statuses(statuses)


    def poll(self) -> str:
        """Determine the text to display

        Function returning a string with battery information to display on the
        status bar. Should only use the public interface in _Battery to get
        necessary information for constructing the string.
        """
        try:
            status = self.update_status()
        except RuntimeError as e:
            return f"Error: {e}"

        if self.notify_below:
            percent = int(status.percent * 100)
            if percent < self.notify_below:
                if not self._has_notified:
                    send_notification(
                        "Warning",
                        f"Battery at {status.percent:2.0%}",
                        urgent=True,
                        timeout=self.timeout,
                    )
                    self._has_notified = True
            elif self._has_notified:
                self._has_notified = False

        return self.build_string(status)

    def build_string(self, status: BatteryStatus) -> str:
        """Determine the string to return for the given battery state

        Parameters
        ----------
        status:
            The current status of the battery

        Returns
        -------
        str
            The string to display for the current status.
        """
        if self.hide_threshold is not None and status.percent > self.hide_threshold:
            return ""

        if self.layout is not None:
            if status.state == BatteryState.DISCHARGING and status.percent < self.low_percentage:
                self.layout.colour = self.low_foreground
                self.background = self.low_background
            else:
                self.layout.colour = self.foreground
                self.background = self.normal_background

        if status.state == BatteryState.CHARGING:
            char = self.charge_char
        elif status.state == BatteryState.DISCHARGING:
            char = self.discharge_char
        elif status.state == BatteryState.FULL:
            if self.show_short_text:
                return self.full_short_text
            char = self.full_char
        elif status.state == BatteryState.EMPTY or (
            status.state == BatteryState.UNKNOWN and status.percent == 0
        ):
            if self.show_short_text:
                return self.empty_short_text
            char = self.empty_char
        elif status.state == BatteryState.NOT_CHARGING:
            char = self.not_charging_char
        else:
            char = self.unknown_char

        hour = status.time // 3600
        minute = (status.time // 60) % 60

        return self.format.format(
            char=char, percent=status.percent, watt=status.power, hour=hour, min=minute
        )


class BatteriesIcon(base._Widget):
    """Battery life indicator widget."""

    orientations = base.ORIENTATION_HORIZONTAL
    defaults: list[tuple[str, Any, str]] = [
        ("batteries", [0, ], "Which battery should be monitored (battery number or name)"),
        ("update_interval", 60, "Seconds between status updates"),
        ("theme_path", default_icon_path(), "Path of the icons"),
        ("scale", 1, "Scale factor relative to the bar height.  " "Defaults to 1"),
        ("padding", 0, "Additional padding either side of the icon"),
    ]

    icon_names = (
        "battery-missing",
        "battery-caution",
        "battery-low",
        "battery-good",
        "battery-full",
        "battery-caution-charging",
        "battery-low-charging",
        "battery-good-charging",
        "battery-full-charging",
        "battery-full-charged",
    )

    def __init__(self, **config) -> None:
        base._Widget.__init__(self, length=bar.CALCULATED, **config)
        self.add_defaults(self.defaults)
        self.scale: float = 1.0 / self.scale

        self.image_padding = 0
        self.images: dict[str, Img] = {}
        self.current_icon = "battery-missing"

        self._batteries = self._load_batteries(**config)

    @staticmethod
    def _load_batteries(**config):
        """Function used to load the Battery object

        Battery behavior can be changed by overloading this function in a base
        class.
        """
        res = []
        for bat in config.get("batteries", [0, ]):
            res.append(load_battery(**config, battery=bat))
        return res

    def update_bat_status(self) -> BatteryStatus:
        statuses = []
        for bat in self._batteries:
            statuses.append(bat.update_status())

        return marge_statuses(statuses)

    def timer_setup(self) -> None:
        self.update()
        self.timeout_add(self.update_interval, self.timer_setup)

    def _configure(self, qtile, bar) -> None:
        base._Widget._configure(self, qtile, bar)
        self.setup_images()

    def setup_images(self) -> None:
        d_imgs = images.Loader(self.theme_path)(*self.icon_names)

        new_height = self.bar.height * self.scale
        for key, img in d_imgs.items():
            img.resize(height=new_height)
            self.images[key] = img

    def calculate_length(self):
        return 0
        icon = self.images.get(self.current_icon, None)
        if icon is None:
            return 0

        return icon.width + 2 * self.padding

    def update(self) -> None:
        status = self.update_bat_status()
        icon = self._get_icon_key(status)
        if icon != self.current_icon:
            self.current_icon = icon
            self.draw()

    def draw(self) -> None:
        return 0
        image = self.images.get(self.current_icon, None)
        if image is None:
            return

        self.drawer.clear(self.background or self.bar.background)
        self.drawer.ctx.save()
        self.drawer.ctx.translate(self.padding, (self.bar.height - image.height) // 2)
        self.drawer.ctx.set_source(image.pattern)
        self.drawer.ctx.paint()
        self.drawer.ctx.restore()
        self.drawer.draw(offsetx=self.offset, offsety=self.offsety, width=self.length)

    @staticmethod
    def _get_icon_key(status: BatteryStatus) -> str:
        key = "battery"

        percent = status.percent
        if percent < 0.2:
            key += "-caution"
        elif percent < 0.4:
            key += "-low"
        elif percent < 0.8:
            key += "-good"
        else:
            key += "-full"

        state = status.state
        if state == BatteryState.CHARGING:
            key += "-charging"
        elif state == BatteryState.FULL:
            key += "-charged"
        return key
