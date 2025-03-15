from libqtile.config import Key, Match

from services.groups_utils import GroupCreator, extend_keys


create_group = GroupCreator()
create_group.is_description = True
create_group.is_subscript_or_superscript = False

default_groups = [
    create_group(
        "f",
        "󰈹",
        screen=0,
        matches=[
            Match(wm_class="firefox"),
            Match(wm_class="floorp"),
            Match(wm_class="zen-beta"),
        ],
    ),
    create_group("d", "", screen=0),
    create_group("s", "", screen=0),
    create_group("a", "󱞁", screen=0, matches=[Match(wm_class="Logseq")]),
    create_group("v", "", screen=1),
    create_group("c", "", screen=1),
    create_group(
        "x",
        "󰋋",
        screen=1,
        matches=[
            Match(wm_class="discord"),
            Match(wm_class="YouTube Music"),
        ],
    ),
    create_group("z", "", screen=1, matches=[Match(wm_class="telegram-desktop")]),
]

groups_keys: list[Key] = []
extend_keys(groups_keys, default_groups)
