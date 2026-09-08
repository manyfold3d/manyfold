# Image-embed client slot — must not be used on archive recall path (INIT-021 D-3).
from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from .config import SparkConfig

PROVENANCE = "INIT-021/SPEC-006"


class ImageEmbedGuardError(RuntimeError):
    """Vision encoder misconfiguration or illegal use on match path."""


@dataclass
class ImageEmbedClient:
    """Vision-slot embedder — separate from text-embed; not used in SPEC-006."""

    cfg: SparkConfig
    constructed: bool = True

    def __post_init__(self) -> None:
        self.constructed = True

    def embed_image_bytes(self, image_bytes: bytes) -> list[float]:
        raise ImageEmbedGuardError(
            "image-embed is not configured for archive recall (INIT-021/SPEC-006 ac-13)"
        )

    def health(self) -> dict[str, Any]:
        raise ImageEmbedGuardError("image-embed health unavailable on archive recall path")
