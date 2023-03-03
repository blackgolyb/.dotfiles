import subprocess

from libqtile.widget import base
from libqtile.lazy import lazy
from libqtile.log_utils import logger
import pyperclip

import settings
from .base import WidgetGroup
from services.callbacks import Callbacks
from services.utils import copy_to_clipboard


class ColorPickerDropper(base._TextBox):
    defaults = [
        (
            "script_path",
            str(settings.scripts_path / 'pick_color'),
            "Path to pick_color script",
        ),
        (
            "dropper_icon",
            " ",
        )
    ]
    
    def __init__(self, **config):
        base._TextBox.__init__(self, **config)
        self.add_defaults(ColorPickerDropper.defaults)
        self.add_callbacks({
            'Button1': self._pick_color,
        })
        
        self.text = self.dropper_icon
        
        self.pick_color_callbacks = Callbacks()
        
    def _pick_color(self):
        logger.warning("start pick")
        logger.warning(f"{self.script_path=}")
        try:
            result = subprocess.run(
                ["bash", self.script_path],
                capture_output=True,
                text=True,
            )
        except Exception as e:
            logger.warning(f'{e=}')
        logger.warning("end pick")
        result = result.stdout.replace("\n", "")
        logger.warning(result)
        copy_to_clipboard(result)
        self.pick_color_callbacks.send(result)
        
    def pick_color(self, qtile):
        self._pick_color()


class ColorPickerPalette(base._TextBox):
    defaults = [
        (
            "empty_icon",
            '',
        ),
        (
            "fill_icon",
            '',
        ),
    ]
    
    def __init__(self, picker_widget: ColorPickerDropper, **config):
        base._TextBox.__init__(self, **config)
        self.add_defaults(ColorPickerPalette.defaults)
        self.add_callbacks({
            'Button1': self.copy_color,
            'Button3': self.open_palette,
        })
        
        self.text = self.empty_icon
        
        self._picked_color = ''
        
        self.picker_widget = picker_widget
        self.picker_widget.pick_color_callbacks.add(self.update_color)
    
    def copy_color(self):
        copy_to_clipboard(self._picked_color)
        
    def open_palette(self):
        ...
        
    def update_color(self, color):
        self._picked_color = color
        self.foreground = self._picked_color
        self.update(self.fill_icon)
        self.bar.draw()
        
        
class ColorPicker(WidgetGroup):
    def __init__(self, dropper_config=None, palette_config=None, **config):
        default_dropper_config = {
            'padding': 0,
        }
        default_palette_config = {
            'padding': 4,
        }
        
        dropper_config = dropper_config or dict()
        dropper_config.update(default_dropper_config)
        
        palette_config = palette_config or dict()
        palette_config.update(default_palette_config)
        
        self.dropper = ColorPickerDropper(**dropper_config)
        self.palette = ColorPickerPalette(self.dropper, **palette_config)
        
        widgets = [
            self.dropper,
            self.palette,
        ]
        
        WidgetGroup.__init__(self, widgets=widgets, **config)
        
        
if __name__ == "__main__":
    d = ColorPickerDropper()
    d.pick_color(None)