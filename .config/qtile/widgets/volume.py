import subprocess

from libqtile.widget import base

import settings


class Volume(base.InLoopPollText):
    defaults = [
        (
            "update_interval",
            5,
            "Update interval in seconds, if none, the " "widget updates whenever it's done.",
        ),
        (
            "script_path",
            str(settings.scripts_path / 'volume_control'),
            "Path to volume control script"
        ),
        
    ]
    
    def __init__(self, **config):
        base.InLoopPollText.__init__(self, default_text=" ", **config)
        self.add_defaults(Volume.defaults)
    
    def change_volume(self, change_type):
        subprocess.call([f'bash {self.script_path} {change_type}'], shell=True)
        
    def get_volume(self):
        result = subprocess.run(
            ['bash', self.script_path, 'get'],
            capture_output=True,
            text=True,
        )
        return result.stdout.replace("\n", "")
    
    def up(self, qtile):
        self.change_volume('up')
        self.update(self.poll())
    
    def down(self, qtile):
        self.change_volume('down')
        self.update(self.poll())
    
    def mute(self):
        self.change_volume('mute')
        self.update(self.poll())
    
    def poll(self):
        return self.get_volume()