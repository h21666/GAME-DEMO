from datetime import datetime
from typing import Any, Literal

from pydantic import BaseModel, Field


MemoryType = Literal["important_conversation", "user_preference", "relationship"]
Gender = Literal["female", "male", "non_binary"]


class CharacterCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=80)
    personality: str = Field(..., min_length=1, max_length=1200)
    background: str = Field(..., min_length=1, max_length=2000)
    memory: str = Field(default="", max_length=4000)


class CharacterRead(CharacterCreate):
    id: int
    relationship: int = Field(default=0, ge=0, le=100)
    created_at: datetime


class ChatRequest(BaseModel):
    message: str = Field(..., min_length=1, max_length=4000)


class ChatResponse(BaseModel):
    character_id: int
    user_message: str
    reply: str
    used_llm: bool
    relationship: int = Field(default=0, ge=0, le=100)
    relationship_stage: str = "初识"


class MessageRead(BaseModel):
    id: int
    character_id: int
    role: Literal["user", "assistant"]
    content: str
    created_at: datetime


class MemoryCreate(BaseModel):
    type: MemoryType
    content: str = Field(..., min_length=1, max_length=2000)
    importance: int = Field(default=3, ge=1, le=5)


class MemoryRead(MemoryCreate):
    id: int
    character_id: int
    created_at: datetime
    updated_at: datetime


class HealthResponse(BaseModel):
    status: str


class VisualProfileCreate(BaseModel):
    gender: Gender
    age: int = Field(..., ge=21, le=34)
    art_style: str = Field(..., min_length=1, max_length=120)
    visual_description: str = Field(..., min_length=1, max_length=3000)


class VisualProfileRead(VisualProfileCreate):
    id: int
    character_id: int
    identity_prompt: str
    reference_image_url: str | None = None
    master_image_url: str | None = None
    status: Literal["draft", "generating", "ready", "failed"]
    created_at: datetime
    updated_at: datetime


class ActionAssetCreate(BaseModel):
    action_key: str = Field(..., min_length=1, max_length=80, pattern=r"^[a-zA-Z0-9_-]+$")
    action_prompt: str = Field(..., min_length=1, max_length=1000)


class ActionAssetRead(ActionAssetCreate):
    id: int
    character_id: int
    image_url: str | None = None
    status: Literal["draft", "generating", "ready", "failed"]
    created_at: datetime
    updated_at: datetime


class ActionTemplateRead(BaseModel):
    action_key: str
    action_name: str
    action_prompt: str


class ActionPackGenerateRequest(BaseModel):
    regenerate: bool = False


class ActionPackGenerateResponse(BaseModel):
    character_id: int
    actions: list[ActionAssetRead]


class TextProviderConfigUpdate(BaseModel):
    api_key: str | None = None
    base_url: str | None = None
    model: str | None = None
    temperature: float | None = Field(default=None, ge=0.0, le=2.0)
    max_tokens: int | None = Field(default=None, ge=1, le=4096)
    thinking_enabled: bool | None = None
    reasoning_effort: str | None = None


class ImageProviderConfigUpdate(BaseModel):
    api_key: str | None = None
    base_url: str | None = None
    model: str | None = None
    generation_path: str | None = None
    edit_path: str | None = None
    quality: str | None = None
    size: str | None = None
    background: str | None = None
    input_fidelity: str | None = None


class ProviderConfigUpdate(BaseModel):
    text: TextProviderConfigUpdate | None = None
    image: ImageProviderConfigUpdate | None = None


class TextProviderConfigRead(BaseModel):
    provider_name: str
    api_key_present: bool
    base_url: str
    model: str
    temperature: float
    max_tokens: int
    thinking_enabled: bool
    reasoning_effort: str


class ImageProviderConfigRead(BaseModel):
    provider_name: str
    api_key_present: bool
    base_url: str
    model: str
    generation_path: str
    edit_path: str
    quality: str
    size: str
    background: str
    input_fidelity: str


class ProviderConfigRead(BaseModel):
    text: TextProviderConfigRead
    image: ImageProviderConfigRead


class CharacterProgressRead(BaseModel):
    character_id: int
    relationship: int = Field(ge=0, le=100)
    relationship_stage: str
    money: int = Field(ge=0)
    study_points: int = Field(ge=0)
    room_level: int = Field(ge=0)
    room_name: str
    room_description: str
    next_room_cost: int | None = Field(default=None, ge=0)


class GiftCatalogRead(BaseModel):
    gift_key: str
    name: str
    description: str
    price: int = Field(ge=0)
    relationship_gain: int = Field(ge=0)


class InventoryItemRead(GiftCatalogRead):
    quantity: int = Field(ge=0)


class GiftActionRequest(BaseModel):
    gift_key: str = Field(..., min_length=1, max_length=80)


class GiftActionResponse(BaseModel):
    message: str
    progress: CharacterProgressRead
    inventory: list[InventoryItemRead]


class RoomUpgradeResponse(BaseModel):
    message: str
    progress: CharacterProgressRead


class ProgressActionRequest(BaseModel):
    action_key: Literal["work", "study", "stroll"]


class ProgressActionResponse(BaseModel):
    message: str
    progress: CharacterProgressRead


class ProgressUpdateRequest(BaseModel):
    money: int = Field(..., ge=0)
    study_points: int = Field(..., ge=0)
    relationship: int = Field(..., ge=0, le=100)
    room_level: int = Field(..., ge=0)


class ProgressUpdateResponse(BaseModel):
    message: str
    progress: CharacterProgressRead


class SaveGameRequest(BaseModel):
    slot: int = Field(..., ge=1, le=5)
    state: dict[str, Any]


class SaveGameRead(BaseModel):
    slot: int
    state: dict[str, Any]
    updated_at: datetime
