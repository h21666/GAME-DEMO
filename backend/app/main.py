from contextlib import asynccontextmanager

import httpx
from fastapi import FastAPI, HTTPException

from app.config import get_settings
from app.database import get_connection, init_db, row_to_dict
from app.llm import LLMClient
from app.schemas import (
    CharacterCreate,
    CharacterRead,
    ChatRequest,
    ChatResponse,
    HealthResponse,
    MemoryCreate,
    MemoryRead,
    MessageRead,
)


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    yield


settings = get_settings()
app = FastAPI(title=settings.app_name, version="0.1.0", lifespan=lifespan)
llm_client = LLMClient(settings)


@app.get("/health", response_model=HealthResponse)
def health() -> HealthResponse:
    return HealthResponse(status="ok")


@app.post("/characters", response_model=CharacterRead, status_code=201)
def create_character(payload: CharacterCreate) -> dict:
    with get_connection() as connection:
        cursor = connection.execute(
            """
            INSERT INTO characters (name, personality, background, memory)
            VALUES (?, ?, ?, ?)
            """,
            (payload.name, payload.personality, payload.background, payload.memory),
        )
        character_id = cursor.lastrowid
        row = connection.execute(
            "SELECT * FROM characters WHERE id = ?",
            (character_id,),
        ).fetchone()

    character = row_to_dict(row)
    if character is None:
        raise HTTPException(status_code=500, detail="Failed to create character.")
    return character


@app.get("/characters", response_model=list[CharacterRead])
def list_characters() -> list[dict]:
    with get_connection() as connection:
        rows = connection.execute(
            "SELECT * FROM characters ORDER BY created_at DESC, id DESC"
        ).fetchall()
    return [dict(row) for row in rows]


@app.get("/characters/{character_id}", response_model=CharacterRead)
def get_character(character_id: int) -> dict:
    character = _get_character_or_404(character_id)
    return character


@app.post("/characters/{character_id}/chat", response_model=ChatResponse)
async def chat(character_id: int, payload: ChatRequest) -> ChatResponse:
    character = _get_character_or_404(character_id)
    recent_messages = _get_recent_messages(character_id, limit=12)
    memories = _get_memories(character_id, limit=8)

    try:
        result = await llm_client.generate_character_reply(
            character=character,
            recent_messages=recent_messages,
            memories=memories,
            user_message=payload.message,
        )
    except httpx.HTTPError as exc:
        raise HTTPException(status_code=502, detail=f"LLM API request failed: {exc}") from exc
    except (KeyError, IndexError, TypeError) as exc:
        raise HTTPException(status_code=502, detail="LLM API returned an unexpected response.") from exc

    with get_connection() as connection:
        connection.execute(
            """
            INSERT INTO messages (character_id, role, content)
            VALUES (?, 'user', ?)
            """,
            (character_id, payload.message),
        )
        connection.execute(
            """
            INSERT INTO messages (character_id, role, content)
            VALUES (?, 'assistant', ?)
            """,
            (character_id, result.reply),
        )

    return ChatResponse(
        character_id=character_id,
        user_message=payload.message,
        reply=result.reply,
        used_llm=result.used_llm,
    )


@app.get("/characters/{character_id}/messages", response_model=list[MessageRead])
def list_messages(character_id: int, limit: int = 50) -> list[dict]:
    _get_character_or_404(character_id)
    safe_limit = max(1, min(limit, 200))
    with get_connection() as connection:
        rows = connection.execute(
            """
            SELECT * FROM messages
            WHERE character_id = ?
            ORDER BY created_at DESC, id DESC
            LIMIT ?
            """,
            (character_id, safe_limit),
        ).fetchall()
    return [dict(row) for row in reversed(rows)]


@app.post("/characters/{character_id}/memories", response_model=MemoryRead, status_code=201)
def create_memory(character_id: int, payload: MemoryCreate) -> dict:
    _get_character_or_404(character_id)
    with get_connection() as connection:
        cursor = connection.execute(
            """
            INSERT INTO memories (character_id, type, content, importance)
            VALUES (?, ?, ?, ?)
            """,
            (character_id, payload.type, payload.content, payload.importance),
        )
        memory_id = cursor.lastrowid
        row = connection.execute(
            "SELECT * FROM memories WHERE id = ?",
            (memory_id,),
        ).fetchone()

    memory = row_to_dict(row)
    if memory is None:
        raise HTTPException(status_code=500, detail="Failed to create memory.")
    return memory


@app.get("/characters/{character_id}/memories", response_model=list[MemoryRead])
def list_memories(character_id: int, limit: int = 50) -> list[dict]:
    _get_character_or_404(character_id)
    return _get_memories(character_id, limit=max(1, min(limit, 200)))


def _get_character_or_404(character_id: int) -> dict:
    with get_connection() as connection:
        row = connection.execute(
            "SELECT * FROM characters WHERE id = ?",
            (character_id,),
        ).fetchone()
    character = row_to_dict(row)
    if character is None:
        raise HTTPException(status_code=404, detail="Character not found.")
    return character


def _get_recent_messages(character_id: int, limit: int) -> list[dict]:
    with get_connection() as connection:
        rows = connection.execute(
            """
            SELECT role, content FROM messages
            WHERE character_id = ?
            ORDER BY created_at DESC, id DESC
            LIMIT ?
            """,
            (character_id, limit),
        ).fetchall()
    return [dict(row) for row in reversed(rows)]


def _get_memories(character_id: int, limit: int) -> list[dict]:
    with get_connection() as connection:
        rows = connection.execute(
            """
            SELECT * FROM memories
            WHERE character_id = ?
            ORDER BY importance DESC, updated_at DESC, id DESC
            LIMIT ?
            """,
            (character_id, limit),
        ).fetchall()
    return [dict(row) for row in rows]

