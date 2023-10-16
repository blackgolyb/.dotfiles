from libqtile.config import Key, Match

from services.groups_utils import GroupCreator, extend_keys


create_group = GroupCreator()
create_group.is_description = True
create_group.is_subscript_or_superscript = False

default_groups = [
    create_group("1", "󰈹", screen=0, matches=[Match(wm_class="firefox")]),
    create_group("2", "", screen=0),
    create_group("3", "", screen=0),
    create_group("4", "", screen=0),
    create_group("5", "", screen=0),
    create_group("6", "", screen=1),
    create_group("7", "", screen=1),
    create_group("8", "", screen=1),
    create_group("9", "󰋋", screen=1),
    create_group("0", "", screen=1),
    create_group("w", ""),
]

groups_keys: list[Key] = []
extend_keys(groups_keys, default_groups)
