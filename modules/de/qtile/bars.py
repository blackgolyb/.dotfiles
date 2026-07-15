from libqtile import bar, widget
from services import utils
from settings import bar_gaps, bar_orientation, group_gaps, outer_gaps
from themes import color_theme
from widgets import (
    base_groupbox,
    default_widgets,
    kb_layout_widget,
)

background_color = color_theme["bar_background_color"]
border_color = color_theme["bar_border_color"]

bar_defaults = {
    "size": 20,  # Высота панели
    "border_width": [2, 16, 2, 10],
    "border_color": [border_color, border_color, border_color, border_color],
    "margin": bar_gaps,  # Гапсы бара
    "background": background_color,  # Цвет фона панели
    "opacity": 1,  # Прозрачность бара
}

main_bar = bar.Bar(
    default_widgets,
    **bar_defaults,
)

second_bar = bar.Bar(
    [
        widget.Spacer(length=10),
        kb_layout_widget,
        # widget.Spacer(length=15),
        widget.Spacer(),
        base_groupbox,
        widget.Spacer(),
        # widget.Spacer(length=15),
        # battery_pack_widget,
        # widget.Spacer(length=15),
        widget.Clock(format="%H:%M", padding=0),
        # widget.Spacer(length=20),
        widget.Spacer(length=20),
    ],
    **bar_defaults,
    # size=30,
)

# main_bar = None
# second_bar = None


def init_bars(bar, bar_orientation="top"):
    bars = utils.configure_bars(outer_gaps, group_gaps, bar)
    bars = utils.rotate_matrix_by_bar_orientation(bars, bar_orientation)
    bars = utils.make_2d_matrix_flat(bars)
    return bars


main_bars = init_bars(main_bar, bar_orientation)
second_bars = init_bars(second_bar)
