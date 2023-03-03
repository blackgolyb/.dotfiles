from libqtile.config import Key, Match

from services.groups_utils import GroupCreator, extend_keys


create_group = GroupCreator()
create_group.is_description = True
create_group.is_subscript_or_superscript = False

default_groups = [
    create_group("1", "󰈹", matches=[Match(wm_class="firefox")]),
    create_group("2", ""),
    create_group("3", ""),
    create_group("4", ""),
    create_group("5", ""),
    create_group("6", ""),
    create_group("7", ""),
    create_group("8", ""),
    create_group("9", "󰋋"),
    create_group("0", ""),
    create_group("w", ""),
]

groups_keys: list[Key] = []
extend_keys(groups_keys, default_groups)