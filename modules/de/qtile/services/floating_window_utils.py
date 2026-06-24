def set_position_floating_with_sticking(qtile, x, y, clip_size=15):
    window = qtile.current_window
    screen = qtile.current_screen

    w, h = window.get_size()
    s_w, s_h = screen.width, screen.height

    if abs(x) <= clip_size:
        x = 0
    elif abs(x + w - s_w) <= clip_size:
        x = s_w - w

    if abs(y) <= clip_size:
        y = 0
    elif abs(y + h - s_h) <= clip_size:
        y = s_h - h

    window.set_position_floating(x=x, y=y)