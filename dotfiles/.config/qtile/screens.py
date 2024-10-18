from libqtile.config import Screen

from settings import *
from bars import main_bars, second_bars


default_screens = [
    Screen(
        top=main_bars[0],
        right=main_bars[1],
        bottom=main_bars[2],
        left=main_bars[3],
    ),
    Screen(
        top=second_bars[0],
        right=second_bars[1],
        bottom=second_bars[2],
        left=second_bars[3],
    ),
]
