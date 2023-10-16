import typing

import libqtile
from libqtile.config import Group, Key
from libqtile.lazy import lazy

from settings import *


class ScreenGroup(Group):
    def __init__(self, *args, **kwargs):
        if "screen" in kwargs:
            self.screen = kwargs["screen"]
            del kwargs["screen"]
        else:
            self.screen = None

        super().__init__(*args, **kwargs)


class GroupCreator:
    is_description = False
    is_subscript_or_superscript = True
    fmt = "{label} {description}"
    error_text = (
        "Subscript for key:[{key}] not found. Try to set the subscript yourself."
    )

    def format_description(self, label: str, description: str) -> str:
        return self.fmt.format(label=label, description=description)

    def __call__(
        self,
        key: str,
        label: str,
        screen: int | None = None,
        is_description: bool | None = None,
        description: str = "",
        **kwargs,
    ) -> ScreenGroup:
        if is_description is not None:
            add_description = is_description
        else:
            add_description = self.is_description

        if add_description:
            if not description:
                description = key

            if self.is_subscript_or_superscript is None:
                description = description
            elif self.is_subscript_or_superscript:
                description = f"<sub> {description}</sub>"
            else:
                description = f"<sup>{description}</sup>"

            label = self.format_description(label, description)

        return ScreenGroup(key, label=label, screen=screen, **kwargs)


def go_to_group(group: ScreenGroup):
    def f(qtile: libqtile.core.manager.Qtile):
        qtile.cmd_to_screen(group.screen)
        qtile.groups_map[group.name].cmd_toscreen()
        # qtile.groups[group.name].toscreen()
        # group.toscreen()

    return f


def move_to_group(group: ScreenGroup):
    def f(qtile: libqtile.core.manager.Qtile):
        qtile.current_window.togroup(group.name)
        qtile.cmd_to_screen(group.screen)
        qtile.groups_map[group.name].cmd_toscreen()

    return f


def extend_keys(keys: list[Key], groups: list[Group]) -> typing.NoReturn:
    for group in groups:
        keys.extend(
            [
                # mod + номер вокспейса = переход на этот воркспейс
                Key(
                    [mod],
                    group.name,
                    # lazy.group[group.name].toscreen(),
                    lazy.function(go_to_group(group)),
                    desc="Switch to group {}".format(group.name),
                ),
                # mod + shift + номер воркспейса = перенос окна на этот воркспейс
                Key(
                    [mod, "shift"],
                    group.name,
                    # lazy.window.togroup(group.name, switch_group=True),
                    lazy.function(move_to_group(group)),
                    desc="Switch to & move focused window to group {}".format(
                        group.name
                    ),
                ),
            ]
        )


# keys = []
# for i in "1234567890":
#     keys.append(Key([mod], i, lazy.function(go_to_group(i)))),
#     keys.append(Key([mod, "shift"], i, lazy.window.togroup(i)))

# screens = [
#     Screen(top=bar.Bar(widget.GroupBox(visible_groups=["1", "2", "3"]))),
#     Screen(top=bar.Bar(widget.GroupBox(visible_groups=["4", "5", "6", "7"]))),
#     Screen(top=bar.Bar(widget.GroupBox(visible_groups=["8", "9", "0"]))),
# ]
