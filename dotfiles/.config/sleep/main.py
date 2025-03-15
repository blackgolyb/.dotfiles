import os
import time
from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import Callable


START_TIME = "23:50"
END_TIME   = "07:00"
WARN_TIME  = 5 * 60
EXIT_TIME  = 10 * 60


@dataclass
class RunOrSchedule():
    start_time: str
    end_time: str
    task: Callable[[], None]

    @property
    def current_time(self):
        return datetime.now().time()
        # return datetime.strptime("8:00", "%H:%M").time()

    def check_interval(self, current) -> bool:
        start = datetime.strptime(START_TIME, "%H:%M").time()
        end = datetime.strptime(END_TIME, "%H:%M").time()
        if start > end:
            return not (start >= current >= end)
        return end >= current >= start

    def calculate_seconds_to_start(self, current: str) -> int:
        start = datetime.strptime(START_TIME, "%H:%M").time()
        today = datetime.today()
        datetime_start = datetime.combine(today, start)
        datetime_current = datetime.combine(today, current)
        if datetime_start < datetime_current:
            datetime_start += timedelta(days=1)
        return (datetime_start - datetime_current).total_seconds()

    def schedule(self):
        sleep_seconds = self.calculate_seconds_to_start(self.current_time)
        time.sleep(sleep_seconds)
        main_task()

    def run(self):
        if self.check_interval(self.current_time):
            self.task()
        else:
            self.schedule()


def send_notification(message):
    os.system(f'notify-send "{message}"')


def shutdown_pc():
    os.system("shutdown -h now")


def main_task():
    exit_time = EXIT_TIME - WARN_TIME
    send_notification(f"Закінчуйте роботу, комп'ютер буде вимкнено через {WARN_TIME} секунд")
    time.sleep(WARN_TIME)
    send_notification(f"Комп'ютер вимикається через {exit_time} секунд")
    time.sleep(exit_time)
    shutdown_pc()


def main():
    worker = RunOrSchedule(START_TIME, END_TIME, main_task)
    worker.run()


if __name__ == "__main__":
    main()
