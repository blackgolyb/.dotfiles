from typing import Optional

from providers.youtube import YouTubeProvider

_PROVIDERS = [YouTubeProvider()]


def get_provider(url: str) -> Optional[YouTubeProvider]:
    for provider in _PROVIDERS:
        if provider.matches(url):
            return provider
    return None
