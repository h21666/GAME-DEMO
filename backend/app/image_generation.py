import base64
import binascii
import hashlib
import mimetypes
from io import BytesIO
from pathlib import Path

import httpx
from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageOps

from app.config import Settings, get_settings
from app.provider_store import get_provider_config
from app.prompt_defaults import DEFAULT_COMPANION_ROLEPLAY_PROMPT


class ImageGenerationError(RuntimeError):
    pass


class ImageGenerationClient:
    async def generate(
        self,
        *,
        prompt: str,
        reference_image: bytes | None = None,
        reference_filename: str = "reference.png",
        reference_content_type: str = "image/png",
    ) -> bytes:
        config = get_provider_config("image")

        if not config.get("api_key"):
            return self._generate_dev_image(prompt=prompt, reference_image=reference_image)

        if reference_image:
            return await self._edit_image(
                prompt=prompt,
                image=reference_image,
                filename=reference_filename,
                content_type=reference_content_type,
                config=config,
            )

        return await self._generate_image(prompt, config=config)

    async def _generate_image(self, prompt: str, config: dict) -> bytes:
        if _is_siliconflow_config(config):
            return await self._generate_siliconflow_image(prompt=prompt, config=config)

        url = f"{config['base_url'].rstrip('/')}{config['generation_path']}"
        data = {
            "model": config["model"],
            "prompt": prompt,
            "size": config["size"],
            "quality": config["quality"],
            "background": config["background"],
        }

        async with httpx.AsyncClient(timeout=120.0) as client:
            response = await client.post(
                url,
                headers={"Authorization": f"Bearer {config['api_key']}"},
                json=data,
            )

        return await self._extract_image(response)

    async def _edit_image(
        self,
        *,
        prompt: str,
        image: bytes,
        filename: str,
        content_type: str,
        config: dict,
    ) -> bytes:
        if _is_siliconflow_config(config):
            return await self._generate_siliconflow_image(
                prompt=prompt,
                config=config,
                reference_image=image,
                reference_content_type=content_type,
            )

        url = f"{config['base_url'].rstrip('/')}{config['edit_path']}"
        data = {
            "model": config["model"],
            "prompt": prompt,
            "size": config["size"],
            "quality": config["quality"],
            "background": config["background"],
        }
        if config.get("input_fidelity"):
            data["input_fidelity"] = config["input_fidelity"]
        files = {
            "image": (filename, image, content_type),
        }

        async with httpx.AsyncClient(timeout=120.0) as client:
            response = await client.post(
                url,
                headers={"Authorization": f"Bearer {config['api_key']}"},
                data=data,
                files=files,
            )

        return await self._extract_image(response)

    async def _generate_siliconflow_image(
        self,
        *,
        prompt: str,
        config: dict,
        reference_image: bytes | None = None,
        reference_content_type: str = "image/png",
    ) -> bytes:
        url = f"{config['base_url'].rstrip('/')}{config['generation_path']}"
        data = {
            "model": config["model"],
            "prompt": prompt,
            "num_inference_steps": 20,
        }
        if config.get("size") and "Image-Edit" not in config["model"]:
            data["image_size"] = config["size"]
        if config["model"].startswith("Qwen/Qwen-Image"):
            data["cfg"] = 4
        if config["model"].startswith("Kwai-Kolors/"):
            data["batch_size"] = 1
            data["guidance_scale"] = 7.5
        if reference_image:
            data["image"] = _build_data_url(reference_image, reference_content_type)

        async with httpx.AsyncClient(timeout=120.0) as client:
            response = await client.post(
                url,
                headers={
                    "Authorization": f"Bearer {config['api_key']}",
                    "Content-Type": "application/json",
                },
                json=data,
            )

        return await self._extract_image(response)

    async def _extract_image(self, response: httpx.Response) -> bytes:
        if response.is_error:
            detail = response.text[:1000]
            raise ImageGenerationError(
                f"Image API returned HTTP {response.status_code}: {detail}"
            )

        try:
            payload = response.json()
            items = payload.get("data") or payload.get("images")
            item = items[0]
        except (ValueError, KeyError, IndexError, TypeError) as exc:
            raise ImageGenerationError("Image API returned an unexpected response.") from exc

        if item.get("b64_json"):
            try:
                return base64.b64decode(item["b64_json"])
            except (ValueError, binascii.Error) as exc:
                raise ImageGenerationError("Image API returned invalid base64 image data.") from exc

        image_url = item.get("url")
        if image_url:
            return await self._download_image_url(image_url)

        raise ImageGenerationError("Image API response did not contain an image.")

    async def _download_image_url(self, image_url: str) -> bytes:
        if image_url.startswith("data:"):
            try:
                _, encoded = image_url.split(",", 1)
                return base64.b64decode(encoded)
            except (ValueError, binascii.Error) as exc:
                raise ImageGenerationError("Image API returned invalid data URL image.") from exc

        async with httpx.AsyncClient(timeout=120.0) as client:
            response = await client.get(image_url)
            if response.is_error:
                raise ImageGenerationError(
                    f"Image URL download failed with HTTP {response.status_code}."
                )
            return response.content

    def _generate_dev_image(self, *, prompt: str, reference_image: bytes | None = None) -> bytes:
        seed = hashlib.sha256(prompt.encode("utf-8")).digest()
        primary = (seed[0], seed[1], seed[2], 255)
        secondary = (min(seed[0] + 48, 255), min(seed[1] + 48, 255), min(seed[2] + 48, 255), 255)
        accent = (seed[3], seed[4], seed[5], 255)

        canvas = Image.new("RGBA", (1024, 1024), primary)
        draw = ImageDraw.Draw(canvas)

        for y in range(1024):
            ratio = y / 1023.0
            r = int(primary[0] * (1 - ratio) + secondary[0] * ratio)
            g = int(primary[1] * (1 - ratio) + secondary[1] * ratio)
            b = int(primary[2] * (1 - ratio) + secondary[2] * ratio)
            draw.line((0, y, 1023, y), fill=(r, g, b, 255))

        if reference_image:
            try:
                ref = Image.open(BytesIO(reference_image)).convert("RGBA")
                ref = ImageOps.fit(ref, (1024, 1024))
                overlay = Image.new("RGBA", (1024, 1024), (*accent[:3], 80))
                ref = Image.alpha_composite(ref, overlay)
                canvas = Image.blend(ref, canvas, 0.35)
            except Exception:
                pass

        overlay = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
        overlay_draw = ImageDraw.Draw(overlay)
        overlay_draw.ellipse((250, 120, 774, 644), fill=(*accent[:3], 38))
        overlay_draw.rounded_rectangle((290, 540, 734, 920), radius=180, fill=(255, 255, 255, 32))
        overlay_draw.rounded_rectangle((340, 680, 684, 860), radius=120, fill=(255, 255, 255, 48))
        overlay_draw.polygon([(512, 180), (560, 260), (464, 260)], fill=(255, 255, 255, 32))
        canvas = Image.alpha_composite(canvas, overlay)

        label_draw = ImageDraw.Draw(canvas)
        label = "DEV MODE"
        sublabel = prompt[:72]
        try:
            font_large = ImageFont.truetype("arial.ttf", 44)
            font_small = ImageFont.truetype("arial.ttf", 24)
        except Exception:
            font_large = None
            font_small = None

        label_draw.rounded_rectangle((48, 48, 976, 168), radius=28, fill=(0, 0, 0, 90))
        label_draw.text((76, 72), label, fill=(255, 255, 255, 255), font=font_large)
        label_draw.text((76, 124), sublabel, fill=(235, 240, 245, 220), font=font_small)

        canvas = canvas.filter(ImageFilter.SMOOTH)
        buffer = BytesIO()
        canvas.convert("RGBA").save(buffer, format="PNG")
        return buffer.getvalue()


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
            DEFAULT_COMPANION_ROLEPLAY_PROMPT,
            f"Character name: {name}.",
            f"Gender presentation: {gender}.",
            f"Age: {age}.",
            f"Art style: {art_style}.",
            f"Visual description: {visual_description}.",
            "Keep the same facial identity, age, hairstyle, hair color, eye color, body proportions, and art style.",
            "Use a clean character-focused composition with no text, watermark, or logo.",
        ]
    )


def _is_siliconflow_config(config: dict) -> bool:
    base_url = str(config.get("base_url", "")).lower()
    return "siliconflow" in base_url


def _build_data_url(content: bytes, content_type: str) -> str:
    media_type = content_type or "image/png"
    if media_type == "application/octet-stream":
        media_type = mimetypes.guess_type("image.png")[0] or "image/png"
    encoded = base64.b64encode(content).decode("ascii")
    return f"data:{media_type};base64,{encoded}"


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
