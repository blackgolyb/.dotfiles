import psutil
import typing

from libqtile import bar
from libqtile.lazy import lazy


def lazy_method(method):
    def wrap(ref, *args, **kwargs):
        ref_method = getattr(ref, method.__name__)
        return lazy.function(ref_method(*args, **kwargs))
    
    return wrap


def is_process_run(process_name):
    for proc in psutil.process_iter():
        if proc.name() == process_name:
            return True

    return False


def rot90(matrix):
    return [list(reversed(col)) for col in zip(*matrix)]


def rotate_matrix_by_bar_orientation(
    matrix: list[list[typing.Any]],
    bar_orientation: typing.Literal['top', 'right', 'bottom', 'left'],
) -> list[list[typing.Any]]:
    
    repeats = 0
    if bar_orientation == 'top':
        repeats = 0
    elif bar_orientation == 'right':
        repeats = 1
    elif bar_orientation == 'bottom':
        repeats = 2
    elif bar_orientation == 'left':
        repeats = 3
        
    for _ in range(repeats):
        matrix = utils.rot90(matrix)
    
    return matrix


def make_2d_matrix_flat(matrix: list[list[typing.Any]]) -> list[typing.Any]:
    '''
    take matrix like:
    matrix = [
        [N, E],
        [W, S]
    ]
    and return list like:
    returned_list = [
        [N, E, S, W]
    ]
    '''
    return [matrix[0][0], matrix[0][1], matrix[1][1], matrix[1][0]]


def configure_layout_margins(
    outer_gaps: int,
    group_gaps: int,
) -> list[list[int]]:
    
    # layout_margins = [
    #     [N, E],
    #     [W, S],
    # ] 
    layout_margins = [
        [outer_gaps, 0],
        [group_gaps, group_gaps - outer_gaps]
    ]
    
    return layout_margins


def configure_bars(
    outer_gaps: int,
    group_gaps: int,
    main_bar: bar.Bar | bar.Gap,
) -> list[list[bar.Bar | bar.Gap]]:
    
    # bar = [
    #     [N, E],
    #     [W, S],
    # ] 
    bars = [
        [main_bar, bar.Gap(outer_gaps)],
        [bar.Gap(outer_gaps - group_gaps), bar.Gap(2 * outer_gaps - group_gaps)]
    ]
    
    return bars