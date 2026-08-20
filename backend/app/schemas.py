from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field


MemoryType = Literal["important_conversation", "user_preference", "relationship"]


class CharacterCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=80)
    personality: str = Field(..., min_length=1, max_length=1200)
    background: str = Field(..., min_length=1, max_length=2000)
    memory: str = Field(default="", max_length=4000)


class CharacterRead(CharacterCreate):
    id: int
    created_at: datetime


class ChatRequest(BaseModel):
    message: str = Field(..., min_length=1, max_length=4000)


class ChatResponse(BaseModel):
    character_id: int
    user_message: str
    reply: str
    used_llm: bool


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

