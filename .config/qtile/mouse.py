from libqtile.config import Click, Drag
from libqtile.lazy import lazy


from services.floating_window_utils import set_position_floating_with_sticking
from settings import mod


default_mouse = [
    Drag(
        [mod],
        "Button1",
        lazy.function(set_position_floating_with_sticking),
        # lazy.window.set_position_floating,
        start=lazy.window.get_position(),
    ),
    Drag(
        [mod], "Button3", lazy.window.set_size_floating(), start=lazy.window.get_size()
    ),
    Click([mod], "Button2", lazy.window.cmd_bring_to_front()),
    Click([mod, "control"], "Button1", lazy.window.toggle_floating()),
]
