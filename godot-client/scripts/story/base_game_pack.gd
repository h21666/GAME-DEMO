extends StoryPackBase
class_name BaseGamePack

func get_pack_id() -> String:
	return "base_game"

func get_chapters() -> Array:
	return [
		{
			"id": "home_intro",
			"title": "出租屋",
			"background": "res://assets/backgrounds/home.png",
			"mode": "story",
			"show_gameplay": false,
			"focus_tab": "",
			"speaker": "旁白",
			"lines": [
				"他住在一间不大的出租屋里，房间不豪华，但足够安静。",
				"白天写代码，晚上攒钱，目标很简单: 去街上的 AI 伴侣商店看看。"
			],
			"continue_label": "出门去街上",
		},
		{
			"id": "street_walk",
			"title": "街道",
			"background": "",
			"mode": "street",
			"show_gameplay": false,
			"focus_tab": "",
			"speaker": "旁白",
			"lines": [
				"夜色压下来，霓虹灯把街道染成冷蓝色。",
				"他把积攒的预算握在手里，沿着街走向那家店。"
			],
			"continue_label": "进入商店",
		},
		{
			"id": "shop_intro",
			"title": "AI 伴侣商店",
			"background": "res://assets/backgrounds/aic_shop.png",
			"mode": "store",
			"show_gameplay": true,
			"focus_tab": "home",
			"speaker": "店内广播",
			"lines": [
				"欢迎来到 AI 伴侣商店。",
				"先选择基础设定，再进入生成与配置界面，打造属于你的角色。"
			],
			"continue_label": "开始生成",
		},
		{
			"id": "return_home",
			"title": "回到出租屋",
			"background": "res://assets/backgrounds/home.png",
			"mode": "home",
			"show_gameplay": true,
			"focus_tab": "chat",
			"speaker": "旁白",
			"lines": [
				"他把生成好的 AI 带回出租屋。",
				"现在，真正的互动开始了。"
			],
			"continue_label": "开始互动",
		},
	]
