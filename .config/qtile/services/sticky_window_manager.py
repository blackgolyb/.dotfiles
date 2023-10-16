import typing

import libqtile
from libqtile import hook, qtile
from libqtile.log_utils import logger
from libqtile.config import Match


class StickyWindowManager:
    """Класс который реализует возможность закреплять окна на рабочих поверхностях"""

    def __init__(
        self,
        activate_hooks: bool = False,
        sticky_rules: list[Match] | None = None,
        groups_rules: list[dict[str, str | Match]] | None = None,
    ) -> typing.NoReturn:
        self.window_list: list[libqtile.backend.base.Window] = list()

        self.sticky_rules = sticky_rules or []

        self.groups_rules = groups_rules or []

        for idx, rule in enumerate(self.groups_rules):
            if "match" not in rule:
                raise ValueError(
                    f"{self.groups_rules=}\nelement: {rule}\element index: {idx}\ngroups_rules element must contains 'match' to understand the query."
                )
            if "groups" not in rule and "exclude_groups" not in rule:
                raise ValueError(
                    f"{self.groups_rules=}\nelement: {rule}\element index: {idx}\ngroups_rules element must contains 'groups' or 'exclude_groups'."
                )

        if activate_hooks:
            self.init_hooks()

    def _pin_window(self, window: libqtile.backend.base.Window) -> typing.NoReturn:
        self.window_list.append(window)

    def _unpin_window(self, window: libqtile.backend.base.Window) -> typing.NoReturn:
        self.window_list.remove(window)

    def toggle_sticky_window(
        self, qtile: libqtile.core.manager.Qtile
    ) -> typing.NoReturn:
        """Реализует интерфейс для закрепления/открепления окна
        с рабочих поверхностей из qtile.
        Вызывать можно с помощью lazy.function(instance.toggle_sticky_window) в
        Key или в mouse_callbacks и т.п."""

        current_window = qtile.current_window
        if current_window is None:
            return

        if current_window in self.window_list:
            self._unpin_window(current_window)
        else:
            self._pin_window(current_window)

    def pin_window(self, qtile: libqtile.core.manager.Qtile) -> typing.NoReturn:
        """Реализует интерфейс для закрепления окна
        на рабочих поверхностях из qtile.
        Вызывать можно с помощью lazy.function(instance.pin_window) в
        Key или в mouse_callbacks и т.п."""

        current_window = qtile.current_window

        if current_window not in self.window_list:
            self._pin_window(current_window)

    def unpin_window(self, qtile: libqtile.core.manager.Qtile) -> typing.NoReturn:
        """Реализует интерфейс для открепления окна
        с рабочих поверхностей из qtile.
        Вызывать можно с помощью lazy.function(instance.unpin_window) в
        Key или в mouse_callbacks и т.п."""

        current_window = qtile.current_window

        if current_window in self.window_list:
            self._unpin_window(current_window)

    def _check_translate_available(
        self, window: libqtile.backend.base.Window, group_name: str
    ) -> bool:
        for rule in self.groups_rules:
            if window.match(rule["match"]):
                if "exclude_groups" in rule:
                    if group_name not in rule["exclude_groups"]:
                        return True

                if group_name in rule["groups"] or rule["groups"] == "__all__":
                    return True

                return False

        return True

    def init_hooks(self) -> typing.NoReturn:
        @hook.subscribe.setgroup
        def _move_sticky_window_to_current_group() -> typing.NoReturn:
            current_group_name = qtile.current_group.name
            for window in self.window_list:
                if self._check_translate_available(window, current_group_name):
                    window.togroup(qtile.current_group.name)
                    window.cmd_bring_to_front()

        @hook.subscribe.client_managed
        def _display_pined_window_above_other(
            managed_window: libqtile.backend.base.Window,
        ) -> typing.NoReturn:
            for window in self.window_list:
                window.cmd_bring_to_front()

        @hook.subscribe.client_killed
        def _unpin_window_when_its_kill(
            killed_window: libqtile.backend.base.Window,
        ) -> typing.NoReturn:
            if killed_window in self.window_list:
                self._unpin_window(killed_window)

        @hook.subscribe.client_new
        def _check_match_when_new_window_opened(
            new_window: libqtile.backend.base.Window,
        ) -> typing.NoReturn:
            for match in self.sticky_rules:
                is_window_managed = new_window in self.window_list
                if new_window.match(match) and not is_window_managed:
                    self._pin_window(new_window)
                    break

            for window in self.window_list:
                window.cmd_bring_to_front()
