#!/bin/python

import subprocess
import sys
from pathlib import Path

eww = sys.argv[1].split()
eww = list(map(lambda x: x.strip("'"), eww))
eww = list(map(lambda x: x.strip('"'), eww))
eww[2] = str(Path(eww[2]).expanduser())
# print(eww, file=open("loh.log", "w"))

result = subprocess.run(
    ['/usr/bin/xcolor', '-S', '6', '-P', '255', '&'],
    capture_output = True,
    text = True,
).stdout.strip()
# result = "#ff00ff"
# print(*eww, 'update', f'picked_color={result}')
subprocess.run(
    [*eww, 'update', f'picked_color={result}'],
)