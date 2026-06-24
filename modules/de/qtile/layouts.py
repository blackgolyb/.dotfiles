from libqtile import layout
from libqtile.config import Match

from services import utils
from settings import outer_gaps, group_gaps, bar_orientation

layout_margins = utils.configure_layout_margins(outer_gaps, group_gaps)
layout_margins = utils.rotate_matrix_by_bar_orientation(layout_margins, bar_orientation)
layout_margins = utils.make_2d_matrix_flat(layout_margins)

# Как в bspwm
bsp_layout = layout.Bsp(
    border_focus="#C3C3C3",
    border_normal="#2E3440",
    border_width=1,
    margin=layout_margins,
    grow_amount=2,
)

# Как в dwm
dwm_layout = layout.Tile(
    border_focus="#C3C3C3",
    border_normal="#2E3440",
    border_width=1,
    add_after_last=True,
    border_on_single=False,
    margin=layout_margins,
)

# Фуллскрин
max_layout = layout.Max(margin=layout_margins)
max_center_layout = layout.Max(margin=[100, 200, 100, 200])

default_layouts = [
    bsp_layout,
    max_layout,
    # max_center_layout,
]

default_floating_layout = layout.Floating(
    border_width=0,
    float_rules=[
        # Run the utility of `xprop` to see the wm class and name of an X client.
        *layout.Floating.default_float_rules,
        Match(wm_class="confirmreset"),  # gitk
        Match(wm_class="makebranch"),  # gitk
        Match(wm_class="maketag"),  # gitk
        Match(wm_class="ssh-askpass"),  # ssh-askpass
        Match(wm_class="imv"),
        Match(wm_class="mpv"),
        Match(wm_class="viewnior"),
        Match(title="branchdialog"),  # gitk
        Match(title="pinentry"),  # GPG key password entry
        Match(title="Picture-in-Picture"),
        Match(title="Kolo-Face"),
    ],
)
