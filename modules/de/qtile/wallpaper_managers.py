from screens import default_screens as screens
from services.wallpaper_manager import WallpaperManager
from settings import resources_path

wallpaper_priority = [
    ("8.jpg", 7),
    ("10.png", 7),
    ("5.png", 7),
    ("14.jpg", 7),
    ("15.png", 7),
]

wallpaper_managers = [
    WallpaperManager(
        screen=screens[0],
        wallpaper=resources_path / "wallpapers",
        wallpaper_priority=wallpaper_priority,
        wallpaper_mode="fill",
        activate_hooks=True,
    ),
    WallpaperManager(
        screen=screens[1],
        wallpaper=resources_path / "wallpapers",
        wallpaper_priority=wallpaper_priority,
        wallpaper_mode="fill",
        activate_hooks=True,
    ),
]
