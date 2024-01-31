#!/bin/python

import subprocess
import time
import json


def workspaces_status_checker(wm: str, show_empty: bool = False):
    row_workspaces = subprocess.getoutput("wmctrl -d | awk '{print $1, $2, $9}'").split("\n")
    row_workspaces = list(map(str.split, row_workspaces))
    workspaces = dict()
    prev_active = None

    for workspace in row_workspaces:
        idx = workspace[0]
        is_active = workspace[1] == "*"
        prev_active = idx if is_active else prev_active
        
        if wm == "qtile":
            label = eval(subprocess.getoutput(f"qtile cmd-obj -o group {workspace[2]} -f eval -a self.label"))[1]
        else:
            label = workspace[2]
        
        workspaces[idx] = {
            "idx": idx,
            "label": label,
            "is_active": is_active,
        }
    
    
    while True:
        output = subprocess.getoutput(
            "{(wmctrl -l | awk '{print $2}' | sort | uniq) && (wmctrl -d | grep '*' | awk '{print $1}');}"
        ).split("\n")
        
        active_workspaces = output[:-1]
        active_workspace = output[-1]
        
        workspaces[prev_active]["is_active"] = False
        workspaces[active_workspace]["is_active"] = True
        prev_active = active_workspace
        
        yield list(filter(lambda x: show_empty or (x["idx"] in active_workspaces) or x["is_active"], workspaces.values()))

get_workspaces = workspaces_status_checker(wm="qtile")
while True:
    print(json.dumps(next(get_workspaces)), flush=True)
    time.sleep(0.5)

