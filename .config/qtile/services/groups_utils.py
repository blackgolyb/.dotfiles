import typing

from libqtile.config import Group, Key
from libqtile.lazy import lazy

from settings import *


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
        is_description: bool | None = None,
        description: str = "",
        **kwargs,
    ) -> Group:
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

        return Group(key, label=label, **kwargs)


def extend_keys(keys: list[Key], groups: list[Group]) -> typing.NoReturn:
    for group in groups:
        keys.extend(
            [
                # mod + номер вокспейса = переход на этот воркспейс
                Key(
                    [mod],
                    group.name,
                    lazy.group[group.name].toscreen(),
                    desc="Switch to group {}".format(group.name),
                ),
                # mod + shift + номер воркспейса = перенос окна на этот воркспейс
                Key(
                    [mod, "shift"],
                    group.name,
                    lazy.window.togroup(group.name, switch_group=True),
                    desc="Switch to & move focused window to group {}".format(
                        group.name
                    ),
                ),
            ]
        )
