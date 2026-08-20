from functools import lru_cache

from pydantic import AliasChoices, Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "AIGC Interactive Character Simulator"
    database_url: str = "sqlite:///./aigc_character_simulator.db"

    deepseek_api_key: str = Field(
        default="",
        validation_alias=AliasChoices("DEEPSEEK_API_KEY", "OPENAI_API_KEY"),
    )
    deepseek_base_url: str = "https://api.deepseek.com"
    deepseek_model: str = "deepseek-v4-pro"
    deepseek_temperature: float = Field(default=0.8, ge=0.0, le=2.0)
    deepseek_max_tokens: int = Field(default=500, ge=1, le=4096)
    deepseek_thinking_enabled: bool = True
    deepseek_reasoning_effort: str = "high"

    media_dir: str = "./media"
    public_base_url: str = "http://127.0.0.1:8000"
    image_api_key: str = Field(
        default="",
        validation_alias=AliasChoices("IMAGE_API_KEY", "OPENAI_IMAGE_API_KEY"),
    )
    image_base_url: str = "https://api.openai.com/v1"
    image_model: str = "gpt-image-1"
    image_generation_path: str = "/images/generations"
    image_edit_path: str = "/images/edits"
    image_quality: str = "medium"
    image_size: str = "1024x1024"
    image_background: str = "opaque"
    image_input_fidelity: str = "high"

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")


@lru_cache
def get_settings() -> Settings:
    return Settings()
