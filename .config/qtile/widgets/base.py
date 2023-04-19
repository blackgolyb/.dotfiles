from libqtile import widget, bar
from libqtile.widget import base
from libqtile.log_utils import logger
from libqtile.widget import Systray

# from libqtile.command.base import expose_command


class WidgetGroup(base._Widget):
    def __init__(self, widgets, **config):
        base._Widget.__init__(self, bar.CALCULATED, **config)

        self.widgets = widgets

    def _configure(self, qtile, bar):
        base._Widget._configure(self, qtile, bar)

        self._configure_inner_widgets()

    def _configure_inner_widgets(self):
        index = self.bar.widgets.index(self)

        for idx, w in enumerate(self.widgets):
            if w.configured:
                w = w.create_mirror()
                self.widgets[idx] = w

        for w in self.widgets[::-1]:
            self.bar.widgets.insert(index, w)

        for idx, w in enumerate(self.widgets):
            self.qtile.register_widget(w)
            w._configure(self.qtile, self.bar)
            w.offsety = self.bar.border_width[0]

            w.offsetx = self.bar.width
            self.qtile.call_soon(w.draw)

            # w.drawer.enable()
            # w.configured = True

    def show(self):
        index = self.bar.widgets.index(self) + 1

        for widget in self.widgets[::-1]:
            self.bar.widgets.insert(index, widget)
            widget.drawer.enable()

            if isinstance(widget, WidgetBox):
                widget.show()
            elif isinstance(widget, WidgetGroup):
                widget.show()

    def hide(self):
        for widget in self.widgets:
            self.bar.widgets.remove(widget)
            widget.drawer.disable()

            if isinstance(widget, WidgetBox):
                widget.hide()
            elif isinstance(widget, WidgetGroup):
                widget.hide()

    def draw(self):
        ...

    def calculate_length(self):
        return 0


class WidgetBox(base._Widget):
    """A widget to declutter your bar.

    WidgetBox is a widget that hides widgets by default but shows them when
    the box is opened.

    Widgets that are hidden will still update etc. as if they were on the main
    bar.

    Button clicks are passed to widgets when they are visible so callbacks will
    work.

    Widgets in the box also remain accessible via command interfaces.

    Widgets can only be added to the box via the configuration file. The widget
    is configured by adding widgets to the "widgets" parameter as follows::

        widget.WidgetBox(widgets=[
            widget.TextBox(text="This widget is in the box"),
            widget.Memory()
            ]
        ),
    """

    orientations = base.ORIENTATION_HORIZONTAL
    defaults = [
        ("font", "sans", "Text font"),
        ("fontsize", None, "Font pixel size. Calculated if None."),
        ("fontshadow", None, "font shadow color, default is None(no shadow)"),
        ("foreground", "#ffffff", "Foreground colour."),
        (
            "close_button_location",
            "left",
            "Location of close button when box open ('left' or 'right')",
        ),
        ("text_closed", "[<]", "Text when box is closed"),
        ("text_open", "[>]", "Text when box is open"),
        ("widgets", list(), "A list of widgets to include in the box"),
    ]  # type: list[tuple[str, Any, str]]

    def __init__(self, _widgets: list[base._Widget] | None = None, **config):
        base._Widget.__init__(self, bar.CALCULATED, **config)
        self.add_defaults(WidgetBox.defaults)
        self.box_is_open = False
        self.add_callbacks({"Button1": self.cmd_toggle})

        if _widgets:
            logger.warning(
                "The use of a positional argument in WidgetBox is deprecated. "
                "Please update your config to use widgets=[...]."
            )
            self.widgets = _widgets

        self.close_button_location: str
        if self.close_button_location not in ["left", "right"]:
            val = self.close_button_location
            logger.warning("Invalid value for 'close_button_location': %s", val)
            self.close_button_location = "left"

    def _configure(self, qtile, bar):
        base._Widget._configure(self, qtile, bar)

        self.layout = self.drawer.textlayout(
            self.text_open if self.box_is_open else self.text_closed,
            self.foreground,
            self.font,
            self.fontsize,
            self.fontshadow,
            markup=False,
        )

        if self.configured:
            return

        self._configure_inner_widgets()

    def _configure_inner_widgets(self):
        index = self.bar.widgets.index(self)

        for idx, w in enumerate(self.widgets):
            if w.configured:
                w = w.create_mirror()
                self.widgets[idx] = w

            self.bar.widgets.insert(index, w)
            self.qtile.register_widget(w)
            w._configure(self.qtile, self.bar)
            w.offsety = self.bar.border_width[0]

            # In case the widget is mirrored, we need to draw it once so the
            # mirror can copy the surface but draw it off screen
            w.offsetx = self.bar.width
            self.qtile.call_soon(w.draw)

            # Setting the configured flag for widgets was moved to Bar._configure so we need to
            # set it here.
            w.configured = True

        self.box_is_open = False
        self.toggle_widgets()

    def show(self):
        ...

    def hide(self):
        if self.box_is_open:
            self.cmd_toggle()

    def toggle_widgets(self):
        for widget in self.widgets:
            try:
                self.bar.widgets.remove(widget)
                # Override drawer.drawer with a no-op
                widget.drawer.disable()

                # Systray widget needs some additional steps to hide as the icons
                # are separate _Window instances.
                # Systray unhides icons when it draws so we only need to hide them.
                if isinstance(widget, Systray):
                    for icon in widget.tray_icons:
                        icon.hide()

                elif isinstance(widget, WidgetBox):
                    widget.hide()

                elif isinstance(widget, WidgetGroup):
                    widget.hide()

            except ValueError:
                continue

        index = self.bar.widgets.index(self)

        if self.close_button_location == "left":
            index += 1

        if self.box_is_open:
            # Need to reverse list as widgets get added in front of eachother.
            for widget in self.widgets[::-1]:
                # enable drawing again
                widget.drawer.enable()
                self.bar.widgets.insert(index, widget)

                if isinstance(widget, WidgetBox):
                    widget.show()
                elif isinstance(widget, WidgetGroup):
                    widget.show()

    def calculate_length(self):
        return self.layout.width

    def set_box_label(self):
        self.layout.text = self.text_open if self.box_is_open else self.text_closed

    def draw(self):
        self.drawer.clear(self.background or self.bar.background)

        self.layout.draw(0, int(self.bar.height / 2.0 - self.layout.height / 2.0) + 1)

        self.drawer.draw(offsetx=self.offsetx, offsety=self.offsety, width=self.width)

    # @expose_command
    def cmd_toggle(self):
        """Toggle box state"""
        self.box_is_open = not self.box_is_open
        self.toggle_widgets()
        self.set_box_label()
        self.bar.draw()


class Animation:
    update_time: float = 0.1
    max_iters_count: int = 100

    def __init__(
        self,
        time: float,
        anim_type: str,
    ):
        self._time = time
        self._anim_type = anim_type

    def animate(self, anim_func, **kwargs):
        anim_start_time = 0
        anim_iters = self._time / self.update_time
        iter_delta = self.max_iters_count / anim_iters

        for i in range(anim_iters):
            anim_func(iteration=int(iter_delta * i), **kwargs)
            time.sleep(update_time)

    def __call__(self, anim_func, **kwargs):
        self.animate(anim_func, **kwargs)


class BaseWidgetTabGroup(WidgetGroup):
    defaults = [
        ("switch_tab_animation", Animation(1, "line")),
    ]

    def __init__(self, _widgets: list[base._Widget] | None = None, **config):
        base._Widget.__init__(self, bar.CALCULATED, **config)
        self.add_defaults(WidgetBox.defaults)

    def __init__(self, tabs: list[list], **config):
        self.tabs = tabs

        WidgetGroup.__init__(self, widgets=tabs[0], **config)

    def _configure(self, qtile, bar):
        base._Widget._configure(self, qtile, bar)

        for widgets in self.tabs:
            self.widgets = widgets
            self._configure_inner_widgets()

            self.hide()

        self.widgets = self.tabs[0]
        self.show()

    def switch_tab_frame(self, iteration: int, from_tab, to_tab):
        ...

    def switch_tab(self, tab_id):
        from_tab = self.widgets
        to_tab = self.tabs[tab_id]

        # self.widgets = to_tab
        # self.show()

        # self.switch_tab_animation(
        #     self.switch_tab_frame,
        #     from_tab=self.widgets,
        #     to_tab=self.tabs[tab_id],
        # )

        # self.widgets = from_tab
        # self.hide()

        # self.widgets = to_tab

        self.hide()
        self.widgets = to_tab
        self.show()

        self.bar.draw()


class HoveringWidgetTabGroup(BaseWidgetTabGroup):
    def __init__(self, hover_out_widgets, hover_in_widgets, **config):
        tabs = [
            hover_out_widgets,
            hover_in_widgets,
        ]

        self.init_hovering(hover_out_widgets)
        self.init_hovering(hover_in_widgets)

        BaseWidgetTabGroup.__init__(self, tabs=tabs, **config)

    def init_hovering(self, tab):
        for widget in tab:
            if isinstance(widget, WidgetBox):
                self.init_hovering(widget.widgets)
            elif isinstance(widget, WidgetGroup):
                self.init_hovering(widget.widgets)
            else:
                f_in = self.widget_hover_in_decorator(widget.mouse_enter)
                widget.mouse_enter = f_in
                f_out = self.widget_hover_out_decorator(widget.mouse_leave)
                widget.mouse_leave = f_out

    def widget_hover_in_decorator(self, mouse_enter):
        def mouse_enter_wrap(x, y):
            self.switch_tab(1)

        return mouse_enter_wrap

    def widget_hover_out_decorator(self, mouse_leave):
        def mouse_leave_wrap(x, y):
            self.switch_tab(0)

        return mouse_leave_wrap
