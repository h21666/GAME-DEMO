GIFT_CATALOG = [
    {
        "gift_key": "tea",
        "name": "晚安红茶",
        "description": "适合在出租屋的暖灯下慢慢分享。",
        "price": 25,
        "relationship_gain": 3,
    },
    {
        "gift_key": "book",
        "name": "旧书店的书",
        "description": "一本可以一起读很久的书。",
        "price": 45,
        "relationship_gain": 5,
    },
    {
        "gift_key": "flower",
        "name": "小束鲜花",
        "description": "让房间里多一点轻盈的颜色。",
        "price": 60,
        "relationship_gain": 7,
    },
    {
        "gift_key": "headphones",
        "name": "降噪耳机",
        "description": "一起听歌时，可以把城市的声音关在门外。",
        "price": 120,
        "relationship_gain": 10,
    },
]

ROOM_LEVELS = [
    {
        "level": 0,
        "name": "出租屋",
        "description": "一张床、一张书桌，还有刚刚开始的陪伴。",
        "cost": 0,
    },
    {
        "level": 1,
        "name": "温馨小屋",
        "description": "添置了柔和灯光和更舒服的双人空间。",
        "cost": 100,
    },
    {
        "level": 2,
        "name": "智能公寓",
        "description": "房间开始记住你们的习惯，生活变得更顺手。",
        "cost": 250,
    },
    {
        "level": 3,
        "name": "星光套房",
        "description": "窗边能看见整座城市，像给关系留了一盏长明灯。",
        "cost": 500,
    },
]


def get_gift(gift_key: str) -> dict | None:
    return next((gift for gift in GIFT_CATALOG if gift["gift_key"] == gift_key), None)


def get_room_level(level: int) -> dict:
    return ROOM_LEVELS[max(0, min(level, len(ROOM_LEVELS) - 1))]


def relationship_stage(value: int) -> str:
    if value < 20:
        return "初识"
    if value < 40:
        return "熟悉"
    if value < 60:
        return "信任"
    if value < 80:
        return "亲密"
    return "深爱"
