from contextlib import asynccontextmanager
from pathlib import Path

import httpx
from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.staticfiles import StaticFiles

from app.action_templates import DEFAULT_ACTION_TEMPLATES
from app.config import get_settings
from app.database import get_connection, init_db, row_to_dict
from app.image_generation import (
    ImageGenerationClient,
    ImageGenerationError,
    build_identity_prompt,
    media_root,
    public_media_url,
    save_media,
)
from app.llm import LLMClient
from app.provider_store import get_provider_settings_payload, save_provider_config
from app.schemas import (
    ActionAssetCreate,
    ActionAssetRead,
    ActionPackGenerateRequest,
    ActionPackGenerateResponse,
    ActionTemplateRead,
    CharacterCreate,
    CharacterRead,
    ChatRequest,
    ChatResponse,
    HealthResponse,
    MemoryCreate,
    MemoryRead,
    MessageRead,
    VisualProfileCreate,
    VisualProfileRead,
    ProviderConfigRead,
    ProviderConfigUpdate,
)


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    media_root(settings)
    yield


settings = get_settings()
app = FastAPI(title=settings.app_name, version="0.1.0", lifespan=lifespan)
app.mount("/media", StaticFiles(directory=media_root(settings)), name="media")
llm_client = LLMClient()
image_client = ImageGenerationClient()


@app.get("/health", response_model=HealthResponse)
def health() -> HealthResponse:
    return HealthResponse(status="ok")


@app.get("/")
def root() -> dict:
    return {
        "status": "ok",
        "message": "AIGC Interactive Character Simulator Backend is running.",
        "docs": "/docs",
        "health": "/health",
    }


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


@app.get("/providers", response_model=ProviderConfigRead)
def get_providers() -> dict:
    return get_provider_settings_payload()


@app.put("/providers", response_model=ProviderConfigRead)
def update_providers(payload: ProviderConfigUpdate) -> dict:
    if payload.text is not None:
        save_provider_config("text", payload.text.model_dump(exclude_none=True))
    if payload.image is not None:
        save_provider_config("image", payload.image.model_dump(exclude_none=True))
    return get_provider_settings_payload()


@app.post("/characters/{character_id}/visual-profile", response_model=VisualProfileRead)
def create_visual_profile(character_id: int, payload: VisualProfileCreate) -> dict:
    character = _get_character_or_404(character_id)
    identity_prompt = build_identity_prompt(
        name=character["name"],
        gender=payload.gender,
        age=payload.age,
        art_style=payload.art_style,
        visual_description=payload.visual_description,
    )

    with get_connection() as connection:
        connection.execute(
            """
            INSERT INTO character_visual_profiles (
                character_id, gender, age, art_style, visual_description, identity_prompt, status
            )
            VALUES (?, ?, ?, ?, ?, ?, 'draft')
            ON CONFLICT(character_id) DO UPDATE SET
                gender = excluded.gender,
                age = excluded.age,
                art_style = excluded.art_style,
                visual_description = excluded.visual_description,
                identity_prompt = excluded.identity_prompt,
                master_image_path = NULL,
                status = 'draft',
                updated_at = CURRENT_TIMESTAMP
            """,
            (
                character_id,
                payload.gender,
                payload.age,
                payload.art_style,
                payload.visual_description,
                identity_prompt,
            ),
        )
        row = connection.execute(
            "SELECT * FROM character_visual_profiles WHERE character_id = ?",
            (character_id,),
        ).fetchone()
        connection.execute(
            "DELETE FROM character_actions WHERE character_id = ?",
            (character_id,),
        )

    profile = row_to_dict(row)
    if profile is None:
        raise HTTPException(status_code=500, detail="Failed to save visual profile.")
    return _serialize_visual_profile(profile)


@app.get("/characters/{character_id}/visual-profile", response_model=VisualProfileRead)
def get_visual_profile(character_id: int) -> dict:
    _get_character_or_404(character_id)
    profile = _get_visual_profile_or_404(character_id)
    return _serialize_visual_profile(profile)


@app.post("/characters/{character_id}/visual-profile/generate", response_model=VisualProfileRead)
async def generate_visual_profile(
    character_id: int,
    gender: str = Form(...),
    age: int = Form(...),
    art_style: str = Form(...),
    visual_description: str = Form(...),
    reference_image: UploadFile | None = File(default=None),
) -> dict:
    payload = VisualProfileCreate(
        gender=gender,
        age=age,
        art_style=art_style,
        visual_description=visual_description,
    )
    character = _get_character_or_404(character_id)
    identity_prompt = build_identity_prompt(
        name=character["name"],
        gender=payload.gender,
        age=payload.age,
        art_style=payload.art_style,
        visual_description=payload.visual_description,
    )

    reference_bytes = None
    reference_path = None
    reference_content_type = "image/png"
    reference_filename = "reference.png"

    if reference_image is not None:
        _validate_image_upload(reference_image)
        reference_bytes = await reference_image.read(10 * 1024 * 1024 + 1)
        if not reference_bytes:
            raise HTTPException(status_code=400, detail="Reference image is empty.")
        if len(reference_bytes) > 10 * 1024 * 1024:
            raise HTTPException(status_code=413, detail="Reference image must be 10 MB or smaller.")
        reference_filename = Path(reference_image.filename or reference_filename).name
        reference_content_type = reference_image.content_type or reference_content_type
        reference_path = save_media(
            relative_path=f"characters/{character_id}/reference_{reference_filename}",
            content=reference_bytes,
        )

    _upsert_visual_profile(
        character_id=character_id,
        payload=payload,
        identity_prompt=identity_prompt,
        reference_path=reference_path,
        status="generating",
    )

    try:
        generated_image = await image_client.generate(
            prompt=identity_prompt,
            reference_image=reference_bytes,
            reference_filename=reference_filename,
            reference_content_type=reference_content_type,
        )
        master_path = save_media(
            relative_path=f"characters/{character_id}/master.png",
            content=generated_image,
        )
    except ImageGenerationError as exc:
        _set_visual_profile_status(character_id, "failed")
        raise HTTPException(status_code=502, detail=str(exc)) from exc

    _update_visual_profile_master(character_id, master_path)
    profile = _get_visual_profile_or_404(character_id)
    return _serialize_visual_profile(profile)


@app.post("/characters/{character_id}/actions", response_model=ActionAssetRead)
async def generate_action_asset(
    character_id: int,
    payload: ActionAssetCreate,
) -> dict:
    _get_character_or_404(character_id)
    profile = _get_visual_profile_or_404(character_id)
    reference_path = profile.get("master_image_path") or profile.get("reference_image_path")
    if not reference_path:
        raise HTTPException(
            status_code=409,
            detail="Generate a master character image before generating actions.",
        )

    reference_file = media_root(settings) / reference_path
    if not reference_file.exists():
        raise HTTPException(status_code=404, detail="Character reference image file not found.")

    identity_prompt = profile["identity_prompt"]
    action_prompt = "\n".join(
        [
            identity_prompt,
            f"Action: {payload.action_prompt}.",
            "Preserve the exact same character identity and visual style.",
            "Generate one clear full-body or medium-shot action pose.",
        ]
    )
    _upsert_action_asset(character_id, payload, status="generating")

    try:
        generated_image = await image_client.generate(
            prompt=action_prompt,
            reference_image=reference_file.read_bytes(),
            reference_filename=Path(reference_path).name,
        )
        image_path = save_media(
            relative_path=f"characters/{character_id}/actions/{payload.action_key}.png",
            content=generated_image,
        )
    except ImageGenerationError as exc:
        _set_action_status(character_id, payload.action_key, "failed")
        raise HTTPException(status_code=502, detail=str(exc)) from exc

    _update_action_asset(character_id, payload.action_key, image_path)
    action = _get_action_or_404(character_id, payload.action_key)
    return _serialize_action_asset(action)


@app.get("/action-templates", response_model=list[ActionTemplateRead])
def list_action_templates() -> list[ActionTemplateRead]:
    return [
        ActionTemplateRead(
            action_key=item.action_key,
            action_name=item.action_name,
            action_prompt=item.action_prompt,
        )
        for item in DEFAULT_ACTION_TEMPLATES
    ]


@app.post("/characters/{character_id}/action-pack/generate", response_model=ActionPackGenerateResponse)
async def generate_action_pack(
    character_id: int,
    payload: ActionPackGenerateRequest | None = None,
) -> dict:
    _get_character_or_404(character_id)
    profile = _get_visual_profile_or_404(character_id)
    reference_path = profile.get("master_image_path") or profile.get("reference_image_path")
    if not reference_path:
        raise HTTPException(
            status_code=409,
            detail="Generate a master character image before generating an action pack.",
        )

    reference_file = media_root(settings) / reference_path
    if not reference_file.exists():
        raise HTTPException(status_code=404, detail="Character reference image file not found.")

    regenerate = bool(payload.regenerate) if payload is not None else False
    results: list[dict] = []

    for template in DEFAULT_ACTION_TEMPLATES:
        existing = _get_action_if_exists(character_id, template.action_key)
        if existing is not None and not regenerate and existing.get("status") == "ready":
            results.append(_serialize_action_asset(existing))
            continue

        action_payload = ActionAssetCreate(
            action_key=template.action_key,
            action_prompt=template.action_prompt,
        )
        _upsert_action_asset(character_id, action_payload, status="generating")

        action_prompt = build_action_prompt(profile["identity_prompt"], template.action_prompt)

        try:
            generated_image = await image_client.generate(
                prompt=action_prompt,
                reference_image=reference_file.read_bytes(),
                reference_filename=Path(reference_path).name,
            )
            image_path = save_media(
                relative_path=f"characters/{character_id}/actions/{template.action_key}.png",
                content=generated_image,
            )
        except ImageGenerationError as exc:
            _set_action_status(character_id, template.action_key, "failed")
            raise HTTPException(status_code=502, detail=f"{template.action_key}: {exc}") from exc

        _update_action_asset(character_id, template.action_key, image_path)
        action = _get_action_or_404(character_id, template.action_key)
        results.append(_serialize_action_asset(action))

    return ActionPackGenerateResponse(character_id=character_id, actions=results)


@app.get("/characters/{character_id}/actions", response_model=list[ActionAssetRead])
def list_action_assets(character_id: int) -> list[dict]:
    _get_character_or_404(character_id)
    with get_connection() as connection:
        rows = connection.execute(
            """
            SELECT * FROM character_actions
            WHERE character_id = ?
            ORDER BY updated_at DESC, id DESC
            """,
            (character_id,),
        ).fetchall()
    return [_serialize_action_asset(dict(row)) for row in rows]


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


def _validate_image_upload(upload: UploadFile) -> None:
    if not upload.content_type or not upload.content_type.startswith("image/"):
        raise HTTPException(status_code=415, detail="reference_image must be an image file.")


def _get_visual_profile_or_404(character_id: int) -> dict:
    with get_connection() as connection:
        row = connection.execute(
            "SELECT * FROM character_visual_profiles WHERE character_id = ?",
            (character_id,),
        ).fetchone()
    profile = row_to_dict(row)
    if profile is None:
        raise HTTPException(status_code=404, detail="Visual profile not found.")
    return profile


def _upsert_visual_profile(
    *,
    character_id: int,
    payload: VisualProfileCreate,
    identity_prompt: str,
    reference_path: str | None,
    status: str,
) -> None:
    with get_connection() as connection:
        connection.execute(
            """
            INSERT INTO character_visual_profiles (
                character_id, gender, age, art_style, visual_description,
                identity_prompt, reference_image_path, status
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(character_id) DO UPDATE SET
                gender = excluded.gender,
                age = excluded.age,
                art_style = excluded.art_style,
                visual_description = excluded.visual_description,
                identity_prompt = excluded.identity_prompt,
                reference_image_path = COALESCE(excluded.reference_image_path, reference_image_path),
                master_image_path = NULL,
                status = excluded.status,
                updated_at = CURRENT_TIMESTAMP
            """,
            (
                character_id,
                payload.gender,
                payload.age,
                payload.art_style,
                payload.visual_description,
                identity_prompt,
                reference_path,
                status,
            ),
        )
        connection.execute(
            "DELETE FROM character_actions WHERE character_id = ?",
            (character_id,),
        )


def _set_visual_profile_status(character_id: int, status: str) -> None:
    with get_connection() as connection:
        connection.execute(
            """
            UPDATE character_visual_profiles
            SET status = ?, updated_at = CURRENT_TIMESTAMP
            WHERE character_id = ?
            """,
            (status, character_id),
        )


def _update_visual_profile_master(character_id: int, master_path: str) -> None:
    with get_connection() as connection:
        connection.execute(
            """
            UPDATE character_visual_profiles
            SET master_image_path = ?, status = 'ready', updated_at = CURRENT_TIMESTAMP
            WHERE character_id = ?
            """,
            (master_path, character_id),
        )


def _serialize_visual_profile(profile: dict) -> dict:
    profile["reference_image_url"] = public_media_url(profile.get("reference_image_path"))
    profile["master_image_url"] = public_media_url(profile.get("master_image_path"))
    return profile


def _upsert_action_asset(character_id: int, payload: ActionAssetCreate, status: str) -> None:
    with get_connection() as connection:
        connection.execute(
            """
            INSERT INTO character_actions (character_id, action_key, action_prompt, status)
            VALUES (?, ?, ?, ?)
            ON CONFLICT(character_id, action_key) DO UPDATE SET
                action_prompt = excluded.action_prompt,
                status = excluded.status,
                updated_at = CURRENT_TIMESTAMP
            """,
            (character_id, payload.action_key, payload.action_prompt, status),
        )


def _set_action_status(character_id: int, action_key: str, status: str) -> None:
    with get_connection() as connection:
        connection.execute(
            """
            UPDATE character_actions
            SET status = ?, updated_at = CURRENT_TIMESTAMP
            WHERE character_id = ? AND action_key = ?
            """,
            (status, character_id, action_key),
        )


def _update_action_asset(character_id: int, action_key: str, image_path: str) -> None:
    with get_connection() as connection:
        connection.execute(
            """
            UPDATE character_actions
            SET image_path = ?, status = 'ready', updated_at = CURRENT_TIMESTAMP
            WHERE character_id = ? AND action_key = ?
            """,
            (image_path, character_id, action_key),
        )


def _get_action_or_404(character_id: int, action_key: str) -> dict:
    with get_connection() as connection:
        row = connection.execute(
            """
            SELECT * FROM character_actions
            WHERE character_id = ? AND action_key = ?
            """,
            (character_id, action_key),
        ).fetchone()
    action = row_to_dict(row)
    if action is None:
        raise HTTPException(status_code=404, detail="Action asset not found.")
    return action


def _serialize_action_asset(action: dict) -> dict:
    action["image_url"] = public_media_url(action.get("image_path"))
    return action


def _get_action_if_exists(character_id: int, action_key: str) -> dict | None:
    with get_connection() as connection:
        row = connection.execute(
            """
            SELECT * FROM character_actions
            WHERE character_id = ? AND action_key = ?
            """,
            (character_id, action_key),
        ).fetchone()
    return row_to_dict(row)


def build_action_prompt(identity_prompt: str, action_prompt: str) -> str:
    return "\n".join(
        [
            identity_prompt,
            f"Action: {action_prompt}.",
            "Preserve the same facial identity, hairstyle, body shape, art style, and outfit language.",
            "Keep the character adult, consistent, and clearly recognizable.",
            "Compose a polished single-character image with no text, watermark, or logo.",
        ]
    )
