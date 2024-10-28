from libqtile import widget
from libqtile.widget.battery import BatteryState


class Battery(widget.Battery):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        self.state: BatteryState = None
        self.state_change_events = []

        def get_prep__get_param(func):
            def _get_param(name):
                try:
                    result = func(name)
                    return result
                except:
                    return None

            return _get_param

        self._battery_update_status = self._battery.update_status
        self._battery._get_param = get_prep__get_param(self._battery._get_param)
        self._battery.update_status = self.update_status

    def track_status_changed(self, status):
        if self.state is None or status.state == self.state.state:
            return

        for event, callback in self.state_change_events:
            if isinstance(event, tuple) and event == (self.state.state, status.state):
                callback()
            if isinstance(event, BatteryState) and event == status.state:
                callback()

    def add_event(self, event, callback):
        self.state_change_events.append((event, callback))

    def update_status(self):
        state = self._battery_update_status()
        self.track_status_changed(state)
        self.state = state
        return state
