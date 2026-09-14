from typing import Optional

from providers.base import MusicProvider
from providers.youtube import YouTubeProvider

_PROVIDERS = [YouTubeProvider()]


def get_provider(url: str) -> Optional[MusicProvider]:
    for provider in _PROVIDERS:
        if provider.matches(url):
            return provider
    return None
