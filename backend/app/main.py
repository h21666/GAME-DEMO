import json
from contextlib import asynccontextmanager
from pathlib import Path

import httpx
from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.staticfiles import StaticFiles

from app.action_templates import DEFAULT_ACTION_TEMPLATES
from app.config import get_settings
from app.database import get_connection, init_db, row_to_dict
from app.game_data import GIFT_CATALOG, ROOM_LEVELS, get_gift, get_room_level, relationship_stage
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
    CharacterProgressRead,
    ChatRequest,
    ChatResponse,
    GiftActionRequest,
    GiftActionResponse,
    GiftCatalogRead,
    HealthResponse,
    InventoryItemRead,
    MemoryCreate,
    MemoryRead,
    MessageRead,
    VisualProfileCreate,
    VisualProfileRead,
    ProviderConfigRead,
    ProviderConfigUpdate,
    ProgressActionRequest,
    ProgressActionResponse,
    ProgressUpdateRequest,
    ProgressUpdateResponse,
    RoomUpgradeResponse,
    SaveGameRead,
    SaveGameRequest,
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
        connection.execute(
            "INSERT OR IGNORE INTO character_progress (character_id) VALUES (?)",
            (character_id,),
        )
        row = connection.execute(
            "SELECT * FROM characters WHERE id = ?",
            (character_id,),
        ).fetchone()

    character = row_to_dict(row)
    if character is None:
        raise HTTPException(status_code=500, detail="Failed to create character.")
    return _get_character_or_404(int(character["id"]))


@app.get("/characters", response_model=list[CharacterRead])
def list_characters() -> list[dict]:
    with get_connection() as connection:
        rows = connection.execute(
            """
            SELECT characters.*, COALESCE(character_progress.relationship, 0) AS relationship
            FROM characters
            LEFT JOIN character_progress ON character_progress.character_id = characters.id
            ORDER BY characters.created_at DESC, characters.id DESC
            """
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

        delta = _relationship_delta_for_message(payload.message)
        connection.execute(
            """
            UPDATE character_progress
            SET relationship = MIN(100, MAX(0, relationship + ?)),
                updated_at = CURRENT_TIMESTAMP
            WHERE character_id = ?
            """,
            (delta, character_id),
        )

    progress = _get_progress_or_404(character_id)

    return ChatResponse(
        character_id=character_id,
        user_message=payload.message,
        reply=result.reply,
        used_llm=result.used_llm,
        relationship=progress["relationship"],
        relationship_stage=relationship_stage(progress["relationship"]),
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


@app.get("/gifts/catalog", response_model=list[GiftCatalogRead])
def gift_catalog() -> list[dict]:
    return GIFT_CATALOG


@app.get("/characters/{character_id}/progress", response_model=CharacterProgressRead)
def get_character_progress(character_id: int) -> dict:
    _get_character_or_404(character_id)
    return _serialize_progress(_get_progress_or_404(character_id))


@app.get("/characters/{character_id}/inventory", response_model=list[InventoryItemRead])
def get_inventory(character_id: int) -> list[dict]:
    _get_character_or_404(character_id)
    return _get_inventory(character_id)


@app.post("/characters/{character_id}/gifts/purchase", response_model=GiftActionResponse)
def purchase_gift(character_id: int, payload: GiftActionRequest) -> dict:
    _get_character_or_404(character_id)
    gift = get_gift(payload.gift_key)
    if gift is None:
        raise HTTPException(status_code=404, detail="Gift not found.")

    with get_connection() as connection:
        progress = connection.execute(
            "SELECT * FROM character_progress WHERE character_id = ?",
            (character_id,),
        ).fetchone()
        if progress is None or int(progress["money"]) < gift["price"]:
            raise HTTPException(status_code=400, detail="Not enough money for this gift.")
        connection.execute(
            """
            UPDATE character_progress
            SET money = money - ?, updated_at = CURRENT_TIMESTAMP
            WHERE character_id = ?
            """,
            (gift["price"], character_id),
        )
        connection.execute(
            """
            INSERT INTO gift_inventory (character_id, gift_key, quantity)
            VALUES (?, ?, 1)
            ON CONFLICT(character_id, gift_key) DO UPDATE SET
                quantity = quantity + 1,
                updated_at = CURRENT_TIMESTAMP
            """,
            (character_id, gift["gift_key"]),
        )

    return {
        "message": f"已买下{gift['name']}，可以回家送给她了。",
        "progress": _serialize_progress(_get_progress_or_404(character_id)),
        "inventory": _get_inventory(character_id),
    }


@app.post("/characters/{character_id}/gifts/use", response_model=GiftActionResponse)
def use_gift(character_id: int, payload: GiftActionRequest) -> dict:
    _get_character_or_404(character_id)
    gift = get_gift(payload.gift_key)
    if gift is None:
        raise HTTPException(status_code=404, detail="Gift not found.")

    with get_connection() as connection:
        item = connection.execute(
            "SELECT quantity FROM gift_inventory WHERE character_id = ? AND gift_key = ?",
            (character_id, payload.gift_key),
        ).fetchone()
        if item is None or int(item["quantity"]) <= 0:
            raise HTTPException(status_code=400, detail="This gift is not in the inventory.")
        connection.execute(
            """
            UPDATE gift_inventory
            SET quantity = quantity - 1, updated_at = CURRENT_TIMESTAMP
            WHERE character_id = ? AND gift_key = ?
            """,
            (character_id, payload.gift_key),
        )
        connection.execute(
            """
            UPDATE character_progress
            SET relationship = MIN(100, relationship + ?), updated_at = CURRENT_TIMESTAMP
            WHERE character_id = ?
            """,
            (gift["relationship_gain"], character_id),
        )
        connection.execute(
            """
            INSERT INTO memories (character_id, type, content, importance)
            VALUES (?, 'relationship', ?, 4)
            """,
            (character_id, f"主人送给她{gift['name']}，她感受到主人认真准备的心意。"),
        )

    return {
        "message": f"她收下了{gift['name']}，关系更近了一点。",
        "progress": _serialize_progress(_get_progress_or_404(character_id)),
        "inventory": _get_inventory(character_id),
    }


@app.post("/characters/{character_id}/room/upgrade", response_model=RoomUpgradeResponse)
def upgrade_room(character_id: int) -> dict:
    _get_character_or_404(character_id)
    progress = _get_progress_or_404(character_id)
    next_level = int(progress["room_level"]) + 1
    if next_level >= len(ROOM_LEVELS):
        raise HTTPException(status_code=400, detail="房间已经是最高等级。")
    room = get_room_level(next_level)
    if int(progress["money"]) < room["cost"]:
        raise HTTPException(status_code=400, detail=f"升级需要 {room['cost']} 金钱。")
    with get_connection() as connection:
        connection.execute(
            """
            UPDATE character_progress
            SET money = money - ?, room_level = ?, updated_at = CURRENT_TIMESTAMP
            WHERE character_id = ?
            """,
            (room["cost"], next_level, character_id),
        )
    return {
        "message": f"房间已升级为「{room['name']}」。",
        "progress": _serialize_progress(_get_progress_or_404(character_id)),
    }


@app.post("/characters/{character_id}/progress/action", response_model=ProgressActionResponse)
def apply_progress_action(character_id: int, payload: ProgressActionRequest) -> dict:
    _get_character_or_404(character_id)
    action_data = {
        "work": (35, 0, 0, "今天的打工让钱包稍微鼓了一点。"),
        "study": (-5, 1, 0, "主人学习了 AI 调参，希望把陪伴体验调得更好。"),
        "stroll": (-10, 0, 1, "主人今天去街上逛了逛，记住了一些适合一起散步的地方。"),
    }
    money_delta, study_delta, relationship_delta, memory_text = action_data[payload.action_key]
    with get_connection() as connection:
        connection.execute(
            """
            UPDATE character_progress
            SET money = MAX(0, money + ?),
                study_points = MAX(0, study_points + ?),
                relationship = MIN(100, MAX(0, relationship + ?)),
                updated_at = CURRENT_TIMESTAMP
            WHERE character_id = ?
            """,
            (money_delta, study_delta, relationship_delta, character_id),
        )
        memory_type = "user_preference" if payload.action_key == "study" else "important_conversation"
        connection.execute(
            """
            INSERT INTO memories (character_id, type, content, importance)
            VALUES (?, ?, ?, 2)
            """,
            (character_id, memory_type, memory_text),
        )
    return {
        "message": memory_text,
        "progress": _serialize_progress(_get_progress_or_404(character_id)),
    }


@app.put("/characters/{character_id}/progress", response_model=ProgressUpdateResponse)
def update_progress(character_id: int, payload: ProgressUpdateRequest) -> dict:
    _get_character_or_404(character_id)
    if payload.room_level >= len(ROOM_LEVELS):
        raise HTTPException(status_code=400, detail="Invalid room level.")
    with get_connection() as connection:
        connection.execute(
            """
            UPDATE character_progress
            SET money = ?,
                study_points = ?,
                relationship = ?,
                room_level = ?,
                updated_at = CURRENT_TIMESTAMP
            WHERE character_id = ?
            """,
            (payload.money, payload.study_points, payload.relationship, payload.room_level, character_id),
        )
    return {
        "message": "Progress updated.",
        "progress": _serialize_progress(_get_progress_or_404(character_id)),
    }


@app.get("/characters/{character_id}/saves", response_model=list[SaveGameRead])
def list_saves(character_id: int) -> list[dict]:
    _get_character_or_404(character_id)
    with get_connection() as connection:
        rows = connection.execute(
            "SELECT slot, state_json, updated_at FROM save_slots WHERE character_id = ? ORDER BY slot",
            (character_id,),
        ).fetchall()
    return [_deserialize_save(row) for row in rows]


@app.post("/characters/{character_id}/saves", response_model=SaveGameRead)
def save_game(character_id: int, payload: SaveGameRequest) -> dict:
    _get_character_or_404(character_id)
    with get_connection() as connection:
        connection.execute(
            """
            INSERT INTO save_slots (character_id, slot, state_json)
            VALUES (?, ?, ?)
            ON CONFLICT(character_id, slot) DO UPDATE SET
                state_json = excluded.state_json,
                updated_at = CURRENT_TIMESTAMP
            """,
            (character_id, payload.slot, json.dumps(payload.state, ensure_ascii=False)),
        )
        row = connection.execute(
            "SELECT slot, state_json, updated_at FROM save_slots WHERE character_id = ? AND slot = ?",
            (character_id, payload.slot),
        ).fetchone()
    return _deserialize_save(row)


@app.get("/characters/{character_id}/saves/{slot}", response_model=SaveGameRead)
def load_game(character_id: int, slot: int) -> dict:
    _get_character_or_404(character_id)
    if slot < 1 or slot > 5:
        raise HTTPException(status_code=400, detail="Save slot must be between 1 and 5.")
    with get_connection() as connection:
        row = connection.execute(
            "SELECT slot, state_json, updated_at FROM save_slots WHERE character_id = ? AND slot = ?",
            (character_id, slot),
        ).fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="Save slot is empty.")
    return _deserialize_save(row)


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
            """
            SELECT characters.*,
                   COALESCE(character_progress.relationship, 0) AS relationship,
                   COALESCE(character_progress.money, 120) AS money,
                   COALESCE(character_progress.study_points, 0) AS study_points,
                   COALESCE(character_progress.room_level, 0) AS room_level
            FROM characters
            LEFT JOIN character_progress ON character_progress.character_id = characters.id
            WHERE characters.id = ?
            """,
            (character_id,),
        ).fetchone()
    character = row_to_dict(row)
    if character is None:
        raise HTTPException(status_code=404, detail="Character not found.")
    room = get_room_level(int(character.get("room_level", 0)))
    character["room_name"] = room["name"]
    character["room_description"] = room["description"]
    return character


def _get_progress_or_404(character_id: int) -> dict:
    with get_connection() as connection:
        row = connection.execute(
            "SELECT * FROM character_progress WHERE character_id = ?",
            (character_id,),
        ).fetchone()
    progress = row_to_dict(row)
    if progress is None:
        raise HTTPException(status_code=404, detail="Character progress not found.")
    return progress


def _serialize_progress(progress: dict) -> dict:
    room = get_room_level(int(progress.get("room_level", 0)))
    next_level = int(progress.get("room_level", 0)) + 1
    next_room_cost = ROOM_LEVELS[next_level]["cost"] if next_level < len(ROOM_LEVELS) else None
    return {
        "character_id": int(progress["character_id"]),
        "relationship": int(progress["relationship"]),
        "relationship_stage": relationship_stage(int(progress["relationship"])),
        "money": int(progress["money"]),
        "study_points": int(progress["study_points"]),
        "room_level": int(progress["room_level"]),
        "room_name": room["name"],
        "room_description": room["description"],
        "next_room_cost": next_room_cost,
    }


def _get_inventory(character_id: int) -> list[dict]:
    with get_connection() as connection:
        rows = connection.execute(
            "SELECT gift_key, quantity FROM gift_inventory WHERE character_id = ? ORDER BY gift_key",
            (character_id,),
        ).fetchall()
    quantities = {str(row["gift_key"]): int(row["quantity"]) for row in rows}
    return [
        {**gift, "quantity": quantities.get(gift["gift_key"], 0)}
        for gift in GIFT_CATALOG
    ]


def _relationship_delta_for_message(message: str) -> int:
    positive_words = ("谢谢", "喜欢", "爱你", "想你", "开心", "可爱", "辛苦", "晚安", "早安", "陪我")
    negative_words = ("讨厌", "笨蛋", "闭嘴", "离开", "失望", "不想")
    delta = 1
    if any(word in message for word in positive_words):
        delta += 1
    if any(word in message for word in negative_words):
        delta -= 2
    return delta


def _deserialize_save(row) -> dict:
    try:
        state = json.loads(str(row["state_json"]))
    except (TypeError, json.JSONDecodeError):
        state = {}
    return {
        "slot": int(row["slot"]),
        "state": state if isinstance(state, dict) else {},
        "updated_at": row["updated_at"],
    }


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
