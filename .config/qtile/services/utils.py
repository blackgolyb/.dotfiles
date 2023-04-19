import psutil
import typing
import subprocess

from libqtile import bar
from libqtile.lazy import lazy


def lazy_method(method):
    def wrap(ref, *args, **kwargs):
        ref_method = getattr(ref, method.__name__)
        return lazy.function(ref_method(*args, **kwargs))

    return wrap


def str2bool(val):
    """Convert a string representation of truth to true (1) or false (0).
    True values are 'y', 'yes', 't', 'true', 'on', and '1'; false values
    are 'n', 'no', 'f', 'false', 'off', and '0'.  Raises ValueError if
    'val' is anything else.
    """
    val = val.lower()
    if val in ("y", "yes", "t", "true", "on", "1"):
        return 1
    elif val in ("n", "no", "f", "false", "off", "0"):
        return 0
    else:
        raise ValueError(f"invalid truth value {val}")


def copy_to_clipboard(input_data):
    p = subprocess.Popen(
        ["xclip", "-selection", "clipboard", "-f"], stdin=subprocess.PIPE
    )
    p.communicate(input=(input_data.encode()))


def is_process_run(process_name):
    for proc in psutil.process_iter():
        if proc.name() == process_name:
            return True

    return False


def rot90(matrix):
    return [list(reversed(col)) for col in zip(*matrix)]


def rotate_matrix_by_bar_orientation(
    matrix: list[list[typing.Any]],
    bar_orientation: typing.Literal["top", "right", "bottom", "left"],
) -> list[list[typing.Any]]:
    repeats = 0
    if bar_orientation == "top":
        repeats = 0
    elif bar_orientation == "right":
        repeats = 1
    elif bar_orientation == "bottom":
        repeats = 2
    elif bar_orientation == "left":
        repeats = 3

    for _ in range(repeats):
        matrix = utils.rot90(matrix)

    return matrix


def make_2d_matrix_flat(matrix: list[list[typing.Any]]) -> list[typing.Any]:
    """
    take matrix like:
    matrix = [
        [N, E],
        [W, S]
    ]
    and return list like:
    returned_list = [
        [N, E, S, W]
    ]
    """
    return [matrix[0][0], matrix[0][1], matrix[1][1], matrix[1][0]]


def configure_layout_margins(
    outer_gaps: int,
    group_gaps: int,
) -> list[list[int]]:
    # layout_margins = [
    #     [N, E],
    #     [W, S],
    # ]
    layout_margins = [[outer_gaps, 0], [group_gaps, group_gaps - outer_gaps]]

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
        [bar.Gap(outer_gaps - group_gaps), bar.Gap(2 * outer_gaps - group_gaps)],
    ]

    return bars
