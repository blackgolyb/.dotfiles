from typing import Iterable
import random
from pathlib import Path

from libqtile import hook
from libqtile.log_utils import logger

class WallpaperManager(object):
    def __init__(
        self,
        screen,
        wallpaper: Path | list[Path],
        wallpaper_mode: str | None = None,
        activate_hooks: bool = False,
    ):
        self.screen = screen
        self.wallpaper = wallpaper
        self.wallpaper_mode = wallpaper_mode 
        
        if activate_hooks:
            self.init_hooks()
        
    @property
    def wallpaper(self):
        if isinstance(self._wallpaper, (list, tuple)):
            w = str(random.choice(self._wallpaper))
            logger.error(f"{w=}")
            return w
        
        return str(self._wallpaper)
    
    @wallpaper.setter
    def wallpaper(self, wallpaper: Path | list[Path]):
        # logger.error(f"{wallpaper=}")
        if isinstance(wallpaper, (list, tuple)):
            self._wallpaper = wallpaper
            return
            
        logger.error(f"{wallpaper=}")
        if wallpaper.is_dir():
            all_files = filter(lambda path: path.is_file(), wallpaper.iterdir())
            self._wallpaper = list(all_files)
            logger.error(f"{self._wallpaper=}")
            return
        
        self._wallpaper = wallpaper
            
    def setup_wallpaper(self):
        self.screen.paint(self.wallpaper, self.wallpaper_mode)
        
    def init_hooks(self):
        @hook.subscribe.startup
        def _setup_bg():
            self.setup_wallpaper()