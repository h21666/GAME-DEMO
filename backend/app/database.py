import sqlite3
from contextlib import contextmanager
from pathlib import Path
from typing import Iterator

from app.config import get_settings


def _database_path() -> Path:
    database_url = get_settings().database_url
    if not database_url.startswith("sqlite:///"):
        raise ValueError("Only sqlite:/// DATABASE_URL is supported in this demo backend.")
    return Path(database_url.replace("sqlite:///", "", 1))


@contextmanager
def get_connection() -> Iterator[sqlite3.Connection]:
    path = _database_path()
    path.parent.mkdir(parents=True, exist_ok=True)
    connection = sqlite3.connect(path)
    connection.row_factory = sqlite3.Row
    try:
        yield connection
        connection.commit()
    finally:
        connection.close()


def init_db() -> None:
    with get_connection() as connection:
        connection.executescript(
            """
            CREATE TABLE IF NOT EXISTS characters (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                personality TEXT NOT NULL,
                background TEXT NOT NULL,
                memory TEXT NOT NULL DEFAULT '',
                created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
            );

            CREATE TABLE IF NOT EXISTS messages (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                character_id INTEGER NOT NULL,
                role TEXT NOT NULL CHECK(role IN ('user', 'assistant')),
                content TEXT NOT NULL,
                created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY(character_id) REFERENCES characters(id) ON DELETE CASCADE
            );

            CREATE TABLE IF NOT EXISTS memories (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                character_id INTEGER NOT NULL,
                type TEXT NOT NULL CHECK(type IN ('important_conversation', 'user_preference', 'relationship')),
                content TEXT NOT NULL,
                importance INTEGER NOT NULL DEFAULT 3 CHECK(importance BETWEEN 1 AND 5),
                created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY(character_id) REFERENCES characters(id) ON DELETE CASCADE
            );

            CREATE TABLE IF NOT EXISTS character_visual_profiles (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                character_id INTEGER NOT NULL UNIQUE,
                gender TEXT NOT NULL CHECK(gender IN ('female', 'male', 'non_binary')),
                age INTEGER NOT NULL CHECK(age BETWEEN 21 AND 34),
                art_style TEXT NOT NULL,
                visual_description TEXT NOT NULL,
                identity_prompt TEXT NOT NULL,
                reference_image_path TEXT,
                master_image_path TEXT,
                status TEXT NOT NULL DEFAULT 'draft'
                    CHECK(status IN ('draft', 'generating', 'ready', 'failed')),
                created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY(character_id) REFERENCES characters(id) ON DELETE CASCADE
            );

            CREATE TABLE IF NOT EXISTS character_actions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                character_id INTEGER NOT NULL,
                action_key TEXT NOT NULL,
                action_prompt TEXT NOT NULL,
                image_path TEXT,
                status TEXT NOT NULL DEFAULT 'draft'
                    CHECK(status IN ('draft', 'generating', 'ready', 'failed')),
                created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(character_id, action_key),
                FOREIGN KEY(character_id) REFERENCES characters(id) ON DELETE CASCADE
            );

            CREATE TABLE IF NOT EXISTS provider_configs (
                provider_kind TEXT PRIMARY KEY CHECK(provider_kind IN ('text', 'image')),
                config_json TEXT NOT NULL,
                created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
            );

            CREATE TABLE IF NOT EXISTS character_progress (
                character_id INTEGER PRIMARY KEY,
                relationship INTEGER NOT NULL DEFAULT 0 CHECK(relationship BETWEEN 0 AND 100),
                money INTEGER NOT NULL DEFAULT 120 CHECK(money >= 0),
                study_points INTEGER NOT NULL DEFAULT 0 CHECK(study_points >= 0),
                room_level INTEGER NOT NULL DEFAULT 0 CHECK(room_level >= 0),
                updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY(character_id) REFERENCES characters(id) ON DELETE CASCADE
            );

            CREATE TABLE IF NOT EXISTS gift_inventory (
                character_id INTEGER NOT NULL,
                gift_key TEXT NOT NULL,
                quantity INTEGER NOT NULL DEFAULT 0 CHECK(quantity >= 0),
                updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                PRIMARY KEY(character_id, gift_key),
                FOREIGN KEY(character_id) REFERENCES characters(id) ON DELETE CASCADE
            );

            CREATE TABLE IF NOT EXISTS save_slots (
                character_id INTEGER NOT NULL,
                slot INTEGER NOT NULL CHECK(slot BETWEEN 1 AND 5),
                state_json TEXT NOT NULL,
                updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                PRIMARY KEY(character_id, slot),
                FOREIGN KEY(character_id) REFERENCES characters(id) ON DELETE CASCADE
            );

            CREATE INDEX IF NOT EXISTS idx_messages_character_created
                ON messages(character_id, created_at);

            CREATE INDEX IF NOT EXISTS idx_memories_character_importance
                ON memories(character_id, importance DESC, updated_at DESC);

            CREATE INDEX IF NOT EXISTS idx_actions_character
                ON character_actions(character_id, updated_at DESC);

            CREATE INDEX IF NOT EXISTS idx_inventory_character
                ON gift_inventory(character_id, updated_at DESC);
            """
        )
        connection.execute(
            """
            INSERT OR IGNORE INTO character_progress (character_id)
            SELECT id FROM characters
            """
        )


def row_to_dict(row: sqlite3.Row | None) -> dict | None:
    if row is None:
        return None
    return dict(row)
