from libqtile import widget, bar
from libqtile.widget import base
from libqtile.log_utils import logger
from libqtile.widget import Systray

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
            logger.warning(w)
            
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


class WidgetBox(widget.WidgetBox):
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


class BaseWidgetTabGroup(WidgetGroup):
    def __init__(self, tabs : list[list], **config):
        self.tabs = tabs

        WidgetGroup.__init__(self, widgets=tabs[0], **config)
        
    def _configure(self, qtile, bar):
        base._Widget._configure(self, qtile, bar)
        
        for widgets in self.tabs:
            self.widgets = widgets
            self._configure_inner_widgets()
            
            self.hide()
            
        for i, w in enumerate(self.bar.widgets):
            logger.warning(f'wtf: {i} {w}')
        
        # logger.warning(self.bar.widgets.index(self))
        # logger.warning(self)
        # self.configured = False
        self.widgets = self.tabs[0]
        self.show()
        # self.hide()
        # self.widgets = self.tabs[1]
        # self.show()
            
    def switch_tab(self, tab_id):
        # logger.warning(self.bar.widgets)
        self.hide()
        # logger.warning(self.bar.widgets)
        # logger.warning(self.widgets)
        self.widgets = self.tabs[tab_id]
        for i, w in enumerate(self.bar.widgets):
            logger.warning(f'wtf: {i} {w}')
        self.show()
        try:
            ...
        except Exception as e:
            logger.warning(e)
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
        # logger.warning("widget_hover_in_decorator")
        def mouse_enter_wrap(x, y):
            # logger.warning("mouse_enter_wrap")
            # logger.warning(widget)
            self.switch_tab(1)
            # mouse_enter(x, y)
            
        return mouse_enter_wrap
            
    def widget_hover_out_decorator(self, mouse_leave):
        # logger.warning("widget_hover_out_decorator")
        def mouse_leave_wrap(x, y):
            # logger.warning("mouse_leave_wrap")
            self.switch_tab(0)
            # mouse_leave(x, y)
            
        return mouse_leave_wrap
  