import psutil

def is_process_run(process_name):
    for proc in psutil.process_iter():
        if proc.name() == process_name:
            return True

    return False
