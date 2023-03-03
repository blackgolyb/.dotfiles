from libqtile import bar, widget

from settings import *
from services import utils
from widgets import (
    default_widgets, base_groupbox
)


bar_defaults = {
    "size": 20,  # Высота панели
    "border_width": [2, 16, 2, 10],
    "border_color": ["#2E3440", "#2E3440", "#2E3440", "#2E3440"],
    "margin": bar_gaps,  # Гапсы бара
    "background": "#2E3440",  # Цвет фона панели
    "opacity": 1,  # Прозрачность бара
}

main_bar = bar.Bar(
    default_widgets,
    **bar_defaults,
)

second_bar = bar.Bar(
    [
        widget.Spacer(length=10),
        widget.Spacer(),
        base_groupbox,
        widget.Spacer(),
        widget.Spacer(length=20),
    ],
    **bar_defaults,
    # size=30,
)


def init_bars(bar, bar_orientation='top'):
    bars = utils.configure_bars(outer_gaps, group_gaps, bar)
    bars = utils.rotate_matrix_by_bar_orientation(bars, bar_orientation)
    bars = utils.make_2d_matrix_flat(bars)
    return bars


main_bars = init_bars(main_bar, bar_orientation)
second_bars = init_bars(second_bar)
