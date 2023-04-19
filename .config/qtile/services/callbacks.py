class Callbacks:
    def __init__(self):
        self.clear()

    def add(self, callback):
        if callback not in self._callbacks:
            self._callbacks.append(callback)

    def remove(self, callback):
        if callback in self._callbacks:
            self._callbacks.remove(callback)

    def clear(self):
        self._callbacks: list = []

    def send(self, *args, **kwargs):
        for callback in self._callbacks:
            callback(*args, **kwargs)
