import json
from copy import deepcopy

from app.config import get_settings
from app.database import get_connection

TEXT_PROVIDER_KIND = "text"
IMAGE_PROVIDER_KIND = "image"


def _default_text_config() -> dict:
    settings = get_settings()
    return {
        "provider_name": "deepseek",
        "api_key": settings.deepseek_api_key,
        "base_url": settings.deepseek_base_url,
        "model": settings.deepseek_model,
        "temperature": settings.deepseek_temperature,
        "max_tokens": settings.deepseek_max_tokens,
        "thinking_enabled": settings.deepseek_thinking_enabled,
        "reasoning_effort": settings.deepseek_reasoning_effort,
    }


def _default_image_config() -> dict:
    settings = get_settings()
    return {
        "provider_name": "openai_compatible",
        "api_key": settings.image_api_key,
        "base_url": settings.image_base_url,
        "model": settings.image_model,
        "generation_path": settings.image_generation_path,
        "edit_path": settings.image_edit_path,
        "quality": settings.image_quality,
        "size": settings.image_size,
        "background": settings.image_background,
        "input_fidelity": settings.image_input_fidelity,
    }


def get_provider_config(provider_kind: str) -> dict:
    if provider_kind == TEXT_PROVIDER_KIND:
        default_config = _default_text_config()
    elif provider_kind == IMAGE_PROVIDER_KIND:
        default_config = _default_image_config()
    else:
        raise ValueError(f"Unsupported provider kind: {provider_kind}")

    with get_connection() as connection:
        row = connection.execute(
            "SELECT config_json FROM provider_configs WHERE provider_kind = ?",
            (provider_kind,),
        ).fetchone()

    if row is None:
        return deepcopy(default_config)

    stored_config = json.loads(row["config_json"])
    merged = deepcopy(default_config)
    merged.update(stored_config)
    return merged


def save_provider_config(provider_kind: str, updates: dict) -> dict:
    current = get_provider_config(provider_kind)
    clean_updates = {key: value for key, value in updates.items() if value is not None}
    current.update(clean_updates)

    with get_connection() as connection:
        connection.execute(
            """
            INSERT INTO provider_configs (provider_kind, config_json)
            VALUES (?, ?)
            ON CONFLICT(provider_kind) DO UPDATE SET
                config_json = excluded.config_json,
                updated_at = CURRENT_TIMESTAMP
            """,
            (provider_kind, json.dumps(current, ensure_ascii=False)),
        )

    return current


def get_provider_settings_payload() -> dict:
    text = get_provider_config(TEXT_PROVIDER_KIND)
    image = get_provider_config(IMAGE_PROVIDER_KIND)
    return {
        "text": {
            "provider_name": text["provider_name"],
            "api_key_present": bool(text.get("api_key")),
            "base_url": text["base_url"],
            "model": text["model"],
            "temperature": text["temperature"],
            "max_tokens": text["max_tokens"],
            "thinking_enabled": bool(text["thinking_enabled"]),
            "reasoning_effort": text["reasoning_effort"],
        },
        "image": {
            "provider_name": image["provider_name"],
            "api_key_present": bool(image.get("api_key")),
            "base_url": image["base_url"],
            "model": image["model"],
            "generation_path": image["generation_path"],
            "edit_path": image["edit_path"],
            "quality": image["quality"],
            "size": image["size"],
            "background": image["background"],
            "input_fidelity": image["input_fidelity"],
        },
    }
