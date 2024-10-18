import random
from pathlib import Path

from libqtile import hook
from libqtile.log_utils import logger


class WallpaperManager(object):
    def __init__(
        self,
        screen,
        wallpaper: Path | list[Path],
        wallpaper_priority: list[str] | None = None,
        wallpaper_mode: str | None = None,
        activate_hooks: bool = False,
    ):
        self.screen = screen
        self.wallpaper = wallpaper
        self.wallpaper_mode = wallpaper_mode
        self.wallpaper_priority = wallpaper_priority or []

        if activate_hooks:
            self.init_hooks()

    @property
    def wallpaper(self):
        if isinstance(self._wallpaper, (list, tuple)):
            wallpapers = self._wallpaper.copy()
            names = [w.name for w in wallpapers]

            for name, priority in self.wallpaper_priority:
                if name in names:
                    w = wallpapers[names.index(name)]
                    wallpapers.extend([w] * (priority - 1))

            w = str(random.choice(wallpapers))
            return w

        return str(self._wallpaper)

    @wallpaper.setter
    def wallpaper(self, wallpaper: Path | list[Path]):
        if isinstance(wallpaper, (list, tuple)):
            self._wallpaper = wallpaper
            return

        if wallpaper.is_dir():
            all_files = filter(lambda path: path.is_file(), wallpaper.iterdir())
            self._wallpaper = list(all_files)
            return

        self._wallpaper = wallpaper

    def setup_wallpaper(self):
        self.screen.paint(self.wallpaper, self.wallpaper_mode)

    def init_hooks(self):
        @hook.subscribe.startup
        def _setup_bg():
            self.setup_wallpaper()
