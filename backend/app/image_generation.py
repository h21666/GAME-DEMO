import base64
import binascii
from pathlib import Path

import httpx

from app.config import Settings, get_settings


class ImageGenerationError(RuntimeError):
    pass


class ImageGenerationClient:
    def __init__(self, settings: Settings | None = None) -> None:
        self.settings = settings or get_settings()

    async def generate(
        self,
        *,
        prompt: str,
        reference_image: bytes | None = None,
        reference_filename: str = "reference.png",
        reference_content_type: str = "image/png",
    ) -> bytes:
        if not self.settings.openai_api_key:
            raise ImageGenerationError("OPENAI_API_KEY is not configured.")

        if reference_image:
            return await self._edit_image(
                prompt=prompt,
                image=reference_image,
                filename=reference_filename,
                content_type=reference_content_type,
            )

        return await self._generate_image(prompt)

    async def _generate_image(self, prompt: str) -> bytes:
        url = f"{self.settings.openai_base_url.rstrip('/')}/images/generations"
        data = {
            "model": self.settings.openai_image_model,
            "prompt": prompt,
            "size": self.settings.image_size,
            "quality": self.settings.image_quality,
            "background": self.settings.image_background,
        }

        async with httpx.AsyncClient(timeout=120.0) as client:
            response = await client.post(
                url,
                headers={"Authorization": f"Bearer {self.settings.openai_api_key}"},
                json=data,
            )

        return self._extract_image(response)

    async def _edit_image(
        self,
        *,
        prompt: str,
        image: bytes,
        filename: str,
        content_type: str,
    ) -> bytes:
        url = f"{self.settings.openai_base_url.rstrip('/')}/images/edits"
        data = {
            "model": self.settings.openai_image_model,
            "prompt": prompt,
            "size": self.settings.image_size,
            "quality": self.settings.image_quality,
            "background": self.settings.image_background,
        }
        files = {
            "image": (filename, image, content_type),
        }

        async with httpx.AsyncClient(timeout=120.0) as client:
            response = await client.post(
                url,
                headers={"Authorization": f"Bearer {self.settings.openai_api_key}"},
                data=data,
                files=files,
            )

        return self._extract_image(response)

    @staticmethod
    def _extract_image(response: httpx.Response) -> bytes:
        if response.is_error:
            detail = response.text[:1000]
            raise ImageGenerationError(
                f"Image API returned HTTP {response.status_code}: {detail}"
            )

        try:
            payload = response.json()
            item = payload["data"][0]
        except (ValueError, KeyError, IndexError, TypeError) as exc:
            raise ImageGenerationError("Image API returned an unexpected response.") from exc

        if item.get("b64_json"):
            try:
                return base64.b64decode(item["b64_json"])
            except (ValueError, binascii.Error) as exc:
                raise ImageGenerationError("Image API returned invalid base64 image data.") from exc

        image_url = item.get("url")
        if image_url:
            raise ImageGenerationError(
                "Image API returned a URL instead of base64 data; URL download is not enabled."
            )

        raise ImageGenerationError("Image API response did not contain an image.")


def build_identity_prompt(
    *,
    name: str,
    gender: str,
    age: int,
    art_style: str,
    visual_description: str,
) -> str:
    return "\n".join(
        [
            "Create a consistent fictional adult AI companion character.",
            f"Character name: {name}.",
            f"Gender presentation: {gender}.",
            f"Age: {age}.",
            f"Art style: {art_style}.",
            f"Visual description: {visual_description}.",
            "Keep the same facial identity, age, hairstyle, hair color, eye color, body proportions, and art style.",
            "Use a clean character-focused composition with no text, watermark, or logo.",
        ]
    )


def media_root(settings: Settings | None = None) -> Path:
    active_settings = settings or get_settings()
    path = Path(active_settings.media_dir)
    path.mkdir(parents=True, exist_ok=True)
    return path


def save_media(
    *,
    relative_path: str,
    content: bytes,
    settings: Settings | None = None,
) -> str:
    root = media_root(settings)
    target = root / relative_path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(content)
    return relative_path.replace("\\", "/")


def public_media_url(relative_path: str | None, settings: Settings | None = None) -> str | None:
    if not relative_path:
        return None
    active_settings = settings or get_settings()
    return f"{active_settings.public_base_url.rstrip('/')}/media/{relative_path.lstrip('/')}"
