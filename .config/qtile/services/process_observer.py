import time
import threading
import psutil

from .callbacks import Callbacks


DEFAULT_OBSERVER_TIMEOUT = 1

class ProcessObserver(threading.Thread):
    def __init__(self, process_name, timeout=DEFAULT_OBSERVER_TIMEOUT, soft_waiting=False):
        threading.Thread.__init__(self)
        
        self.process_name = process_name
        self._timeout = timeout
        self._stop_event = threading.Event()
        
        self.start_callbacks = Callbacks()
        self.stop_callbacks = Callbacks()
        self.update_callbacks = Callbacks()
        
        self.previous_status = self.current_process_status
        
        if soft_waiting:
            self.wait = self.soft_wait
        else:
            self.wait = self.basic_wait
            
    def soft_wait(self):
        for _ in range(int(self._timeout)):
            if self._stop_event.is_set():
                return
            
            time.sleep(1)
            
        time.sleep(self._timeout - int(self._timeout))
        
    def basic_wait(self):
        time.sleep(self._timeout)
        
    def check_is_process_run(self) -> bool:
        for proc in psutil.process_iter():
            if proc.name() == self.process_name:
                return True

        return False
    
    @property
    def current_process_status(self) -> bool:
        current_status = self.check_is_process_run()
        self.previous_status = current_status
        
        return current_status
    
    def _is_process_start_or_stop(self) -> bool | None:
        previous_status = self.previous_status
        current_status = self.current_process_status
        
        if previous_status == current_status:
            return None
        
        return current_status
    
    def run(self):
        while not self._stop_event.is_set():
            self.wait()
            
            current_status = self._is_process_start_or_stop()
            if current_status is None:
                continue
            
            if current_status:
                self.start_callbacks.send()
            else:
                self.stop_callbacks.send()
                
            self.update_callbacks.send(current_status)
            
    def stop(self):
        self._stop_event.set()
