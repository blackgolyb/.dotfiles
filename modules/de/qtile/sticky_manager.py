from libqtile.config import Match

from services.sticky_window_manager import StickyWindowManager

sticky_manager = StickyWindowManager(
    activate_hooks=True,
    sticky_rules=[
        Match(role="PictureInPicture"),
        Match(title="Kolo-Face"),
    ],
    groups_rules=[
        {
            # "match": Match(title="Picture-in-Picture"),
            "match": Match(role="PictureInPicture"),
            "groups": "__all__",
            # 'groups': ('0', '1', '2'),
            # 'exclude_groups': ('0', '1', '2'),
        },
        {
            "match": Match(role="Kolo-Face"),
            "groups": "__all__",
        },
    ],
)
