extends Control

const DEFAULT_BACKEND_URL := "http://127.0.0.1:8000"
const BASE_GAME_PACK := preload("res://scripts/story/base_game_pack.gd")

var backend_url: String = DEFAULT_BACKEND_URL
var characters: Array = []
var selected_character: Dictionary = {}
var story_pack: StoryPackBase
var story_chapters: Array = []
var story_chapter_index: int = 0
var story_line_index: int = 0
var story_complete: bool = false

var status_label: Label
var background_image_rect: TextureRect
var background_tint: ColorRect
var gameplay_root: MarginContainer
var story_overlay: Control
var story_popup_title: Label
var story_popup_stage: Label
var story_popup_text: RichTextLabel
var story_continue_button: Button
var story_skip_button: Button
var shop_overlay: Control
var shop_speaker_label: Label
var shop_dialogue_text: RichTextLabel
var shop_preview_label: RichTextLabel
var shop_name_edit: LineEdit
var shop_gender_option: OptionButton
var shop_style_option: OptionButton
var shop_age_spin: SpinBox
var shop_visual_prompt_edit: TextEdit
var immersive_overlay: Control
var immersive_name_label: Label
var immersive_role_label: Label
var immersive_portrait_rect: TextureRect
var immersive_portrait_status_label: Label
var immersive_action_card_grid: GridContainer
var immersive_reply_text: RichTextLabel
var immersive_input: LineEdit
var schedule_overlay: Control
var schedule_close_button: Button
var schedule_summary: RichTextLabel
var backend_url_edit: LineEdit
var connect_button: Button
var companion_gender_option: OptionButton
var companion_style_option: OptionButton
var companion_age_spin: SpinBox
var companion_preview_label: RichTextLabel
var companion_visual_prompt_edit: TextEdit
var selected_companion_archetype: String = "gentle"
var character_name_edit: LineEdit
var character_personality_edit: TextEdit
var character_background_edit: TextEdit
var character_memory_edit: TextEdit
var character_list: ItemList
var selected_character_label: RichTextLabel
var selected_character_summary: RichTextLabel
var open_chat_button: Button
var memory_list: ItemList
var deepseek_key_edit: LineEdit
var deepseek_base_url_edit: LineEdit
var deepseek_model_edit: LineEdit
var deepseek_temperature_edit: LineEdit
var deepseek_max_tokens_edit: LineEdit
var deepseek_reasoning_edit: LineEdit
var image_key_edit: LineEdit
var image_base_url_edit: LineEdit
var image_model_edit: LineEdit
var image_generation_path_edit: LineEdit
var image_edit_path_edit: LineEdit
var image_size_edit: LineEdit
var image_quality_edit: LineEdit
var image_background_edit: LineEdit
var image_input_fidelity_edit: LineEdit
var chat_messages: RichTextLabel
var chat_input: LineEdit
var chat_portrait_rect: TextureRect
var chat_portrait_title_label: Label
var chat_portrait_status_label: Label
var chat_portrait_hint_label: RichTextLabel
var chat_action_status_label: Label
var chat_action_cards: Dictionary = {}
var chat_action_card_grid: GridContainer
var generate_visual_button: Button
var generate_action_pack_button: Button
var refresh_art_button: Button
var tab_container: TabContainer
var menu_home_button: Button
var menu_chat_button: Button
var menu_settings_button: Button
var menu_continue_story_button: Button
var schedule_day_label: Label
var schedule_period_label: Label
var schedule_stats_label: Label
var schedule_hint_label: RichTextLabel
var schedule_last_action_label: Label
var schedule_work_button: Button
var schedule_study_button: Button
var schedule_stroll_button: Button
var schedule_gift_button: Button
var schedule_home_button: Button
var character_count_label: Label
var progress_summary_label: RichTextLabel
var gift_catalog_list: ItemList
var inventory_list: ItemList
var gift_purchase_button: Button
var use_gift_button: Button
var room_upgrade_button: Button
var save_slot_spin: SpinBox
var save_game_button: Button
var load_game_button: Button
var selected_gift_key: String = ""
var selected_inventory_key: String = ""
var character_progress: Dictionary = {}
var gift_inventory: Array = []
var gift_catalog: Array = []
var chat_tab_index: int = 0
var home_tab_index: int = 0
var settings_tab_index: int = 0
var story_waiting_for_gameplay: bool = false
var schedule_day: int = 1
var schedule_period: int = 0
var schedule_pending_rollover: bool = false
var schedule_money: int = 120
var schedule_study_points: int = 0
var schedule_relationship: int = 0
var schedule_last_action: String = "今天还没有安排。"
var visual_profile: Dictionary = {}
var action_assets: Dictionary = {}
var action_templates: Array = []
var texture_cache: Dictionary = {}
var current_portrait_key: String = "master"
var placeholder_portrait_texture: Texture2D


func _ready() -> void:
	_build_ui()
	call_deferred("_initial_sync")


func _initial_sync() -> void:
	await _reload_everything()


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	background_image_rect = TextureRect.new()
	background_image_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	background_image_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background_image_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background_image_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background_image_rect)

	background_tint = ColorRect.new()
	background_tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	background_tint.color = Color(0.035, 0.045, 0.065, 0.62)
	background_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background_tint)

	var glow_panel := ColorRect.new()
	glow_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow_panel.color = Color(0.02, 0.16, 0.20, 0.18)
	glow_panel.offset_left = 880
	glow_panel.offset_top = -80
	add_child(glow_panel)

	var margin := MarginContainer.new()
	gameplay_root = margin
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)

	var root := HBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 18)
	margin.add_child(root)

	var sidebar := PanelContainer.new()
	sidebar.custom_minimum_size = Vector2(360, 0)
	sidebar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(sidebar)
	_decorate_panel(sidebar, Color(0.07, 0.09, 0.13, 0.94), Color(0.24, 0.45, 0.52, 0.75))

	var sidebar_box := VBoxContainer.new()
	sidebar_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sidebar_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sidebar_box.add_theme_constant_override("separation", 14)
	sidebar.add_child(_with_padding(sidebar_box, 22))

	var shop_label := Label.new()
	shop_label.text = "AI COMPANION"
	shop_label.add_theme_font_size_override("font_size", 36)
	shop_label.add_theme_color_override("font_color", Color(0.93, 0.98, 1.0, 1.0))
	sidebar_box.add_child(shop_label)

	var shop_subtitle := Label.new()
	shop_subtitle.text = "SIMULATOR"
	shop_subtitle.add_theme_font_size_override("font_size", 18)
	shop_subtitle.add_theme_color_override("font_color", Color(0.45, 0.86, 0.92, 1.0))
	sidebar_box.add_child(shop_subtitle)

	status_label = Label.new()
	status_label.text = "Ready."
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_color_override("font_color", Color(0.72, 0.78, 0.84))
	sidebar_box.add_child(status_label)

	var divider := HSeparator.new()
	sidebar_box.add_child(divider)

	menu_home_button = _make_menu_button("开始挑选", func() -> void:
		_show_shop_overlay()
	)
	sidebar_box.add_child(menu_home_button)

	menu_chat_button = _make_menu_button("进入房间", func() -> void:
		await _open_selected_character_chat()
	)
	menu_chat_button.disabled = true
	sidebar_box.add_child(menu_chat_button)

	menu_settings_button = _make_menu_button("API 设置", func() -> void:
		_show_page(settings_tab_index)
	)
	sidebar_box.add_child(menu_settings_button)

	var schedule_button := _make_menu_button("日程", func() -> void:
		_show_schedule_overlay()
	)
	sidebar_box.add_child(schedule_button)

	menu_continue_story_button = _make_menu_button("回到出租屋", func() -> void:
		_complete_current_gameplay_step()
	)
	menu_continue_story_button.disabled = true
	menu_continue_story_button.visible = false
	sidebar_box.add_child(menu_continue_story_button)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sidebar_box.add_child(spacer)

	character_count_label = Label.new()
	character_count_label.text = "角色：0"
	character_count_label.add_theme_color_override("font_color", Color(0.72, 0.78, 0.84))
	sidebar_box.add_child(character_count_label)

	backend_url_edit = _make_line_edit("Backend URL", DEFAULT_BACKEND_URL)
	sidebar_box.add_child(backend_url_edit)

	connect_button = _make_button("Connect Backend", func() -> void:
		await _reload_everything()
	)
	sidebar_box.add_child(connect_button)

	var content_shell := PanelContainer.new()
	content_shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_shell.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(content_shell)
	_decorate_panel(content_shell, Color(0.08, 0.10, 0.14, 0.88), Color(0.20, 0.24, 0.30, 0.95))

	tab_container = TabContainer.new()
	tab_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tab_container.tabs_visible = false
	content_shell.add_child(_with_padding(tab_container, 16))

	var home_tab := VBoxContainer.new()
	home_tab.name = "Companion Store"
	home_tab.add_theme_constant_override("separation", 12)
	tab_container.add_child(home_tab)
	home_tab_index = tab_container.get_tab_idx_from_control(home_tab)

	var settings_tab := VBoxContainer.new()
	settings_tab.name = "API Settings"
	settings_tab.add_theme_constant_override("separation", 12)
	tab_container.add_child(settings_tab)
	settings_tab_index = tab_container.get_tab_idx_from_control(settings_tab)

	var chat_tab := VBoxContainer.new()
	chat_tab.name = "Chat"
	chat_tab.add_theme_constant_override("separation", 12)
	tab_container.add_child(chat_tab)
	chat_tab_index = tab_container.get_tab_idx_from_control(chat_tab)

	_build_home_tab(home_tab)
	_build_settings_tab(settings_tab)
	_build_chat_tab(chat_tab)
	_build_story_overlay()
	_build_schedule_overlay()
	_build_shop_overlay()
	_build_immersive_overlay()
	_initialize_story()


func _build_home_tab(parent: VBoxContainer) -> void:
	var hero := PanelContainer.new()
	hero.custom_minimum_size = Vector2(0, 150)
	hero.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(hero)
	_decorate_panel(hero, Color(0.09, 0.12, 0.16, 0.96), Color(0.25, 0.64, 0.69, 0.85))

	var hero_box := VBoxContainer.new()
	hero_box.add_theme_constant_override("separation", 8)
	hero.add_child(_with_padding(hero_box, 18))

	var hero_title := Label.new()
	hero_title.text = "AI 伴侣商店"
	hero_title.add_theme_font_size_override("font_size", 34)
	hero_title.add_theme_color_override("font_color", Color(0.96, 0.99, 1.0, 1.0))
	hero_box.add_child(hero_title)

	var hero_copy := Label.new()
	hero_copy.text = "玻璃展示柜亮起，店员把生成终端推到你面前。先挑选一位占位伴侣带回家，图片 API 之后再补也不影响聊天测试。"
	hero_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hero_copy.add_theme_font_size_override("font_size", 16)
	hero_copy.add_theme_color_override("font_color", Color(0.75, 0.82, 0.88, 1.0))
	hero_box.add_child(hero_copy)

	var split := HSplitContainer.new()
	split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.split_offset = 470
	parent.add_child(split)

	var left_scroll := ScrollContainer.new()
	left_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_child(left_scroll)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 12)
	left_scroll.add_child(left)

	var backend_card := _make_card(left, "商店终端")
	backend_card.custom_minimum_size.y = 110
	backend_card.add_child(_make_help_text("先确认后端在线。没有图片 API 时，商店会发放占位立绘；文字对话、记忆和关系仍然可以正常测试。"))

	var create_card := _make_card(left, "展示柜挑选")
	create_card.add_child(_make_help_text("选择基础型号，再填写少量外貌和性格备注。这里创建的是可聊天档案，不会等待图片生成。"))

	var package_grid := GridContainer.new()
	package_grid.columns = 2
	package_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	package_grid.add_theme_constant_override("h_separation", 10)
	package_grid.add_theme_constant_override("v_separation", 10)
	create_card.add_child(package_grid)

	package_grid.add_child(_make_button("温柔陪伴型", func() -> void:
		_select_companion_archetype("gentle")
	))
	package_grid.add_child(_make_button("活泼好奇型", func() -> void:
		_select_companion_archetype("playful")
	))
	package_grid.add_child(_make_button("安静守护型", func() -> void:
		_select_companion_archetype("quiet")
	))
	package_grid.add_child(_make_button("自定义空白型", func() -> void:
		_select_companion_archetype("custom")
	))

	companion_preview_label = RichTextLabel.new()
	companion_preview_label.bbcode_enabled = true
	companion_preview_label.fit_content = true
	companion_preview_label.scroll_active = false
	companion_preview_label.custom_minimum_size = Vector2(0, 110)
	create_card.add_child(companion_preview_label)

	var choice_row := HBoxContainer.new()
	choice_row.add_theme_constant_override("separation", 10)
	create_card.add_child(choice_row)

	companion_gender_option = _make_option_button(["女性", "男性", "中性"])
	companion_gender_option.item_selected.connect(func(_index: int) -> void:
		_refresh_companion_preview()
	)
	choice_row.add_child(companion_gender_option)

	companion_age_spin = SpinBox.new()
	companion_age_spin.min_value = 21
	companion_age_spin.max_value = 34
	companion_age_spin.step = 1
	companion_age_spin.value = 24
	companion_age_spin.custom_minimum_size = Vector2(110, 42)
	companion_age_spin.tooltip_text = "年龄限制 21-34 岁"
	companion_age_spin.value_changed.connect(func(_value: float) -> void:
		_refresh_companion_preview()
	)
	choice_row.add_child(companion_age_spin)

	companion_style_option = _make_option_button(["真人写实", "二次元", "国漫脸", "半写实"])
	companion_style_option.item_selected.connect(func(_index: int) -> void:
		_refresh_companion_preview()
	)
	choice_row.add_child(companion_style_option)

	character_name_edit = _make_line_edit("柜台登记名", "Mira")
	character_name_edit.text_changed.connect(func(_text: String) -> void:
		_refresh_companion_preview()
	)
	create_card.add_child(character_name_edit)
	companion_visual_prompt_edit = _make_text_edit("外貌描述：发色、服装、气质、参考图备注", "银灰色短发，温柔眼神，近未来家居服，干净柔和的陪伴感。")
	companion_visual_prompt_edit.custom_minimum_size.y = 64
	companion_visual_prompt_edit.text_changed.connect(_refresh_companion_preview)
	create_card.add_child(companion_visual_prompt_edit)
	character_personality_edit = _make_text_edit("性格核心", "温柔、好奇、会主动关心主人，回应时自然称呼主人。")
	character_personality_edit.custom_minimum_size.y = 72
	create_card.add_child(character_personality_edit)
	character_background_edit = _make_text_edit("商店档案", "AI 伴侣商店展示型号，完成登记后会随主角回到出租屋生活。")
	character_background_edit.custom_minimum_size.y = 76
	create_card.add_child(character_background_edit)
	character_memory_edit = _make_text_edit("初始记忆", "主人攒够了钱，在 AI 伴侣商店选择了她。")
	character_memory_edit.custom_minimum_size.y = 64
	create_card.add_child(character_memory_edit)

	var create_row := HBoxContainer.new()
	create_row.add_theme_constant_override("separation", 10)
	create_card.add_child(create_row)

	var create_button := _make_button("登记占位伴侣", func() -> void:
		await _create_character()
	)
	create_row.add_child(create_button)

	var demo_button := _make_button("示例填充", func() -> void:
		_fill_demo_character()
	)
	create_row.add_child(demo_button)

	_refresh_companion_preview()

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 12)
	split.add_child(right)

	var list_card := _make_card(right, "可选择角色")
	character_list = ItemList.new()
	character_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	character_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	character_list.item_selected.connect(_on_character_selected)
	list_card.add_child(character_list)

	var selected_card := _make_card(right, "当前选择")
	selected_character_label = RichTextLabel.new()
	selected_character_label.bbcode_enabled = true
	selected_character_label.fit_content = true
	selected_character_label.scroll_active = false
	selected_character_label.text = "从列表中选择一个角色。"
	selected_card.add_child(selected_character_label)

	open_chat_button = _make_button("确认选择", func() -> void:
		if story_waiting_for_gameplay:
			_complete_current_gameplay_step()
		else:
			await _open_selected_character_chat()
	)
	open_chat_button.disabled = true
	selected_card.add_child(open_chat_button)


func _build_settings_tab(parent: VBoxContainer) -> void:
	var split := HSplitContainer.new()
	split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.split_offset = 760
	parent.add_child(split)

	var text_card := _make_card(split, "文字对话")
	deepseek_key_edit = _make_line_edit("DeepSeek Key（留空不改）", "")
	deepseek_key_edit.secret = true
	text_card.add_child(deepseek_key_edit)
	deepseek_base_url_edit = _make_line_edit("接口地址", "https://api.deepseek.com")
	text_card.add_child(deepseek_base_url_edit)
	deepseek_model_edit = _make_line_edit("模型名", "deepseek-v4-pro")
	text_card.add_child(deepseek_model_edit)
	deepseek_temperature_edit = _make_line_edit("发散程度", "0.7")
	text_card.add_child(deepseek_temperature_edit)
	deepseek_max_tokens_edit = _make_line_edit("最多回复字数", "1024")
	text_card.add_child(deepseek_max_tokens_edit)
	deepseek_reasoning_edit = _make_line_edit("思考强度", "medium")
	text_card.add_child(deepseek_reasoning_edit)

	var image_card := _make_card(split, "图片生成")
	image_key_edit = _make_line_edit("图片 Key（留空不改）", "")
	image_key_edit.secret = true
	image_card.add_child(image_key_edit)
	image_base_url_edit = _make_line_edit("接口地址", "https://api.openai.com/v1")
	image_card.add_child(image_base_url_edit)
	image_model_edit = _make_line_edit("模型名", "gpt-image-1")
	image_card.add_child(image_model_edit)
	image_generation_path_edit = _make_line_edit("生成路径", "/images/generations")
	image_card.add_child(image_generation_path_edit)
	image_edit_path_edit = _make_line_edit("编辑路径", "/images/edits")
	image_card.add_child(image_edit_path_edit)
	image_size_edit = _make_line_edit("尺寸", "1024x1024")
	image_card.add_child(image_size_edit)
	image_quality_edit = _make_line_edit("质量", "medium")
	image_card.add_child(image_quality_edit)
	image_background_edit = _make_line_edit("背景", "transparent")
	image_card.add_child(image_background_edit)
	image_input_fidelity_edit = _make_line_edit("参考图强度", "high")
	image_card.add_child(image_input_fidelity_edit)

	var save_button := _make_button("保存设置", func() -> void:
		await _save_provider_settings()
	)
	image_card.add_child(save_button)

	var reload_button := _make_button("重新读取", func() -> void:
		await _load_provider_settings()
	)
	image_card.add_child(reload_button)

	var guide_card := _make_card(parent, "新手说明")
	guide_card.custom_minimum_size.y = 200
	guide_card.add_child(_make_help_text("先填文字 Key，聊天就能跑；图片 Key 可以以后再填。"))
	guide_card.add_child(_make_help_text("如果你还没准备好真实接口，可以先留空，继续用占位模式测试。"))
	guide_card.add_child(_make_help_text("图片模型先选便宜的测试款，确认流程正常后再换正式模型。"))
	guide_card.add_child(_make_help_text("接口地址就是服务网址，模型名就是你买的那个模型名称。"))

	var guide_buttons := HBoxContainer.new()
	guide_buttons.add_theme_constant_override("separation", 10)
	guide_card.add_child(guide_buttons)

	var fill_recommended_button := _make_button("填入测试值", func() -> void:
		_fill_recommended_image_settings()
	)
	guide_buttons.add_child(fill_recommended_button)

	var fill_siliconflow_button := _make_button("硅基流动 Qwen", func() -> void:
		_fill_siliconflow_qwen_settings()
	)
	guide_buttons.add_child(fill_siliconflow_button)


func _build_chat_tab(parent: VBoxContainer) -> void:
	var top := PanelContainer.new()
	top.custom_minimum_size = Vector2(0, 72)
	top.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(top)
	_decorate_panel(top)

	var top_box := VBoxContainer.new()
	top_box.add_theme_constant_override("separation", 4)
	top.add_child(_with_padding(top_box, 12))

	selected_character_summary = RichTextLabel.new()
	selected_character_summary.bbcode_enabled = true
	selected_character_summary.fit_content = true
	selected_character_summary.scroll_active = false
	selected_character_summary.text = "Open a character from the menu."
	top_box.add_child(selected_character_summary)

	var body := HSplitContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.split_offset = 420
	parent.add_child(body)

	var memory_card := _make_card(body, "房间里的她")
	var companion_stage := PanelContainer.new()
	companion_stage.custom_minimum_size = Vector2(0, 330)
	companion_stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_decorate_panel(companion_stage, Color(0.045, 0.06, 0.08, 0.92), Color(0.36, 0.76, 0.82, 0.7))
	memory_card.add_child(companion_stage)

	var stage_box := VBoxContainer.new()
	stage_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage_box.alignment = BoxContainer.ALIGNMENT_CENTER
	stage_box.add_theme_constant_override("separation", 12)
	companion_stage.add_child(_with_padding(stage_box, 16))

	chat_portrait_title_label = Label.new()
	chat_portrait_title_label.text = "立绘待生成"
	chat_portrait_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chat_portrait_title_label.add_theme_font_size_override("font_size", 18)
	chat_portrait_title_label.add_theme_color_override("font_color", Color(0.84, 0.95, 1.0, 1.0))
	stage_box.add_child(chat_portrait_title_label)

	chat_portrait_rect = TextureRect.new()
	chat_portrait_rect.custom_minimum_size = Vector2(0, 245)
	chat_portrait_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chat_portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	chat_portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	stage_box.add_child(chat_portrait_rect)

	chat_portrait_status_label = Label.new()
	chat_portrait_status_label.text = "她坐在出租屋的灯光下，等你开口。"
	chat_portrait_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chat_portrait_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	chat_portrait_status_label.add_theme_color_override("font_color", Color(0.76, 0.82, 0.88, 1.0))
	stage_box.add_child(chat_portrait_status_label)

	var immersive_button := _make_button("隐藏界面，面对面说话", func() -> void:
		_show_immersive_chat()
	)
	memory_card.add_child(immersive_button)

	var portrait_row := HBoxContainer.new()
	portrait_row.add_theme_constant_override("separation", 8)
	memory_card.add_child(portrait_row)

	generate_visual_button = _make_button("生成主立绘", func() -> void:
		await _generate_master_portrait()
	)
	portrait_row.add_child(generate_visual_button)

	refresh_art_button = _make_button("刷新立绘", func() -> void:
		await _load_character_art()
	)
	portrait_row.add_child(refresh_art_button)

	generate_action_pack_button = _make_button("生成动作包", func() -> void:
		await _generate_action_pack()
	)
	memory_card.add_child(generate_action_pack_button)

	chat_action_status_label = Label.new()
	chat_action_status_label.text = "动作卡：先生成主立绘，再生成动作包。"
	chat_action_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	chat_action_status_label.add_theme_color_override("font_color", Color(0.76, 0.82, 0.88, 1.0))
	memory_card.add_child(chat_action_status_label)

	chat_action_card_grid = GridContainer.new()
	chat_action_card_grid.columns = 2
	chat_action_card_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chat_action_card_grid.add_theme_constant_override("h_separation", 8)
	chat_action_card_grid.add_theme_constant_override("v_separation", 8)
	memory_card.add_child(chat_action_card_grid)

	chat_portrait_hint_label = RichTextLabel.new()
	chat_portrait_hint_label.bbcode_enabled = true
	chat_portrait_hint_label.fit_content = true
	chat_portrait_hint_label.scroll_active = false
	chat_portrait_hint_label.custom_minimum_size = Vector2(0, 58)
	chat_portrait_hint_label.add_theme_font_size_override("normal_font_size", 14)
	memory_card.add_child(chat_portrait_hint_label)

	var memory_title := Label.new()
	memory_title.text = "记忆"
	memory_title.add_theme_font_size_override("font_size", 16)
	memory_card.add_child(memory_title)

	memory_list = ItemList.new()
	memory_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	memory_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	memory_card.add_child(memory_list)

	var chat_card := _make_card(body, "Chat")
	chat_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chat_card.size_flags_vertical = Control.SIZE_EXPAND_FILL

	chat_messages = RichTextLabel.new()
	chat_messages.bbcode_enabled = true
	chat_messages.fit_content = false
	chat_messages.scroll_active = true
	chat_messages.selection_enabled = true
	chat_messages.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chat_messages.size_flags_vertical = Control.SIZE_EXPAND_FILL
	chat_card.add_child(chat_messages)

	var chat_row := HBoxContainer.new()
	chat_row.add_theme_constant_override("separation", 10)
	chat_card.add_child(chat_row)

	chat_input = _make_line_edit("Type a message and press Enter", "")
	chat_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chat_input.text_submitted.connect(_on_chat_submitted)
	chat_row.add_child(chat_input)

	var send_button := _make_button("Send", func() -> void:
		await _send_chat_message()
	)
	chat_row.add_child(send_button)


func _build_story_overlay() -> void:
	story_overlay = Control.new()
	story_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	story_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(story_overlay)

	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.0, 0.0, 0.0, 0.20)
	story_overlay.add_child(shade)

	var popup_margin := MarginContainer.new()
	popup_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup_margin.add_theme_constant_override("margin_left", 110)
	popup_margin.add_theme_constant_override("margin_right", 110)
	popup_margin.add_theme_constant_override("margin_top", 560)
	popup_margin.add_theme_constant_override("margin_bottom", 48)
	story_overlay.add_child(popup_margin)

	var popup := PanelContainer.new()
	_decorate_panel(popup, Color(0.04, 0.055, 0.075, 0.92), Color(0.35, 0.76, 0.82, 0.9))
	popup_margin.add_child(popup)

	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 10)
	popup.add_child(_with_padding(box, 18))

	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 12)
	box.add_child(heading)

	story_popup_title = Label.new()
	story_popup_title.text = "序章"
	story_popup_title.add_theme_font_size_override("font_size", 24)
	story_popup_title.add_theme_color_override("font_color", Color(0.94, 0.99, 1.0, 1.0))
	heading.add_child(story_popup_title)

	story_popup_stage = Label.new()
	story_popup_stage.text = "旁白"
	story_popup_stage.add_theme_font_size_override("font_size", 16)
	story_popup_stage.add_theme_color_override("font_color", Color(0.45, 0.86, 0.92, 1.0))
	heading.add_child(story_popup_stage)

	story_popup_text = RichTextLabel.new()
	story_popup_text.bbcode_enabled = true
	story_popup_text.fit_content = false
	story_popup_text.scroll_active = false
	story_popup_text.custom_minimum_size = Vector2(0, 92)
	story_popup_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	story_popup_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	story_popup_text.add_theme_font_size_override("normal_font_size", 18)
	box.add_child(story_popup_text)

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 10)
	box.add_child(button_row)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button_row.add_child(spacer)

	story_skip_button = _make_button("跳过序章", func() -> void:
		_skip_story()
	)
	button_row.add_child(story_skip_button)

	story_continue_button = _make_button("继续", func() -> void:
		_advance_story()
	)
	button_row.add_child(story_continue_button)


func _build_schedule_overlay() -> void:
	schedule_overlay = Control.new()
	schedule_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	schedule_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	schedule_overlay.visible = false
	add_child(schedule_overlay)

	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.0, 0.0, 0.0, 0.24)
	schedule_overlay.add_child(shade)

	var panel_margin := MarginContainer.new()
	panel_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel_margin.add_theme_constant_override("margin_left", 110)
	panel_margin.add_theme_constant_override("margin_right", 110)
	panel_margin.add_theme_constant_override("margin_top", 92)
	panel_margin.add_theme_constant_override("margin_bottom", 92)
	schedule_overlay.add_child(panel_margin)

	var panel := PanelContainer.new()
	_decorate_panel(panel, Color(0.045, 0.055, 0.070, 0.94), Color(0.42, 0.78, 0.86, 0.9))
	panel_margin.add_child(panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	panel.add_child(_with_padding(root, 22))

	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 12)
	root.add_child(heading)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", 4)
	heading.add_child(title_box)

	var title := Label.new()
	title.text = "今日安排"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.96, 0.99, 1.0, 1.0))
	title_box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "白天安排主角生活，晚上回出租屋和她互动。"
	subtitle.add_theme_color_override("font_color", Color(0.72, 0.80, 0.86, 1.0))
	title_box.add_child(subtitle)

	schedule_close_button = _make_button("关闭", func() -> void:
		_hide_schedule_overlay()
	)
	heading.add_child(schedule_close_button)

	var stat_row := HBoxContainer.new()
	stat_row.add_theme_constant_override("separation", 12)
	root.add_child(stat_row)

	schedule_day_label = _make_schedule_badge("第 1 天")
	stat_row.add_child(schedule_day_label)
	schedule_period_label = _make_schedule_badge("早上")
	stat_row.add_child(schedule_period_label)
	schedule_stats_label = _make_schedule_badge("资金 120 / 调参 0 / 关系 0")
	schedule_stats_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stat_row.add_child(schedule_stats_label)

	progress_summary_label = RichTextLabel.new()
	progress_summary_label.bbcode_enabled = true
	progress_summary_label.fit_content = true
	progress_summary_label.scroll_active = false
	progress_summary_label.custom_minimum_size = Vector2(0, 62)
	progress_summary_label.add_theme_font_size_override("normal_font_size", 15)
	root.add_child(progress_summary_label)

	schedule_summary = RichTextLabel.new()
	schedule_summary.bbcode_enabled = true
	schedule_summary.fit_content = true
	schedule_summary.scroll_active = false
	schedule_summary.custom_minimum_size = Vector2(0, 92)
	schedule_summary.add_theme_font_size_override("normal_font_size", 17)
	root.add_child(schedule_summary)

	var action_grid := GridContainer.new()
	action_grid.columns = 2
	action_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_grid.add_theme_constant_override("h_separation", 12)
	action_grid.add_theme_constant_override("v_separation", 12)
	root.add_child(action_grid)

	schedule_work_button = _make_button("打工", func() -> void:
		await _perform_day_action("work")
	)
	action_grid.add_child(schedule_work_button)

	schedule_study_button = _make_button("学习 AI 调参", func() -> void:
		await _perform_day_action("study")
	)
	action_grid.add_child(schedule_study_button)

	schedule_stroll_button = _make_button("逛街", func() -> void:
		await _perform_day_action("stroll")
	)
	action_grid.add_child(schedule_stroll_button)

	schedule_gift_button = _make_button("买礼物", func() -> void:
		await _perform_day_action("gift")
	)
	action_grid.add_child(schedule_gift_button)

	var management_row := HBoxContainer.new()
	management_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	management_row.add_theme_constant_override("separation", 14)
	root.add_child(management_row)

	var gift_box := _make_card(management_row, "礼物商店")
	gift_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gift_catalog_list = ItemList.new()
	gift_catalog_list.custom_minimum_size = Vector2(0, 108)
	gift_catalog_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gift_catalog_list.item_selected.connect(_on_gift_catalog_selected)
	gift_box.add_child(gift_catalog_list)
	gift_purchase_button = _make_button("购买选中的礼物", func() -> void:
		await _purchase_selected_gift()
	)
	gift_box.add_child(gift_purchase_button)

	var inventory_box := _make_card(management_row, "礼物背包")
	inventory_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_list = ItemList.new()
	inventory_list.custom_minimum_size = Vector2(0, 108)
	inventory_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_list.item_selected.connect(_on_inventory_selected)
	inventory_box.add_child(inventory_list)
	use_gift_button = _make_button("回家送出选中的礼物", func() -> void:
		await _use_selected_gift()
	)
	use_gift_button.disabled = true
	inventory_box.add_child(use_gift_button)

	var room_box := _make_card(management_row, "房间与存档")
	room_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	room_upgrade_button = _make_button("升级房间", func() -> void:
		await _upgrade_room()
	)
	room_box.add_child(room_upgrade_button)

	var save_row := HBoxContainer.new()
	save_row.add_theme_constant_override("separation", 8)
	room_box.add_child(save_row)
	var save_label := Label.new()
	save_label.text = "存档位"
	save_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	save_row.add_child(save_label)
	save_slot_spin = SpinBox.new()
	save_slot_spin.min_value = 1
	save_slot_spin.max_value = 5
	save_slot_spin.step = 1
	save_slot_spin.value = 1
	save_slot_spin.custom_minimum_size = Vector2(84, 42)
	save_row.add_child(save_slot_spin)
	save_game_button = _make_button("保存", func() -> void:
		await _save_game()
	)
	save_row.add_child(save_game_button)
	load_game_button = _make_button("读取", func() -> void:
		await _load_game()
	)
	save_row.add_child(load_game_button)

	schedule_last_action_label = Label.new()
	schedule_last_action_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	schedule_last_action_label.add_theme_color_override("font_color", Color(0.78, 0.86, 0.91, 1.0))
	root.add_child(schedule_last_action_label)

	schedule_hint_label = RichTextLabel.new()
	schedule_hint_label.bbcode_enabled = true
	schedule_hint_label.fit_content = true
	schedule_hint_label.scroll_active = false
	schedule_hint_label.custom_minimum_size = Vector2(0, 72)
	schedule_hint_label.add_theme_font_size_override("normal_font_size", 16)
	root.add_child(schedule_hint_label)

	schedule_home_button = _make_button("回家见她", func() -> void:
		await _go_home_from_schedule()
	)
	root.add_child(schedule_home_button)

	_update_schedule_ui()


func _build_shop_overlay() -> void:
	shop_overlay = Control.new()
	shop_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	shop_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	shop_overlay.visible = false
	add_child(shop_overlay)

	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.0, 0.01, 0.02, 0.18)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shop_overlay.add_child(shade)

	var top_margin := MarginContainer.new()
	top_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	top_margin.add_theme_constant_override("margin_left", 28)
	top_margin.add_theme_constant_override("margin_right", 28)
	top_margin.add_theme_constant_override("margin_top", 22)
	top_margin.add_theme_constant_override("margin_bottom", 780)
	top_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_margin.z_index = 50
	shop_overlay.add_child(top_margin)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 10)
	top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.z_index = 50
	top_margin.add_child(top_row)

	var title := Label.new()
	title.text = "AI COMPANION STORE"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.90, 0.98, 1.0, 1.0))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.add_child(title)

	var settings_button := _make_button("API", func() -> void:
		_open_shop_page(settings_tab_index, "API 设置已打开。")
	)
	settings_button.z_index = 100
	settings_button.mouse_filter = Control.MOUSE_FILTER_STOP
	top_row.add_child(settings_button)

	var debug_button := _make_button("后台", func() -> void:
		_open_shop_page(home_tab_index, "后台角色管理已打开。")
	)
	debug_button.z_index = 100
	debug_button.mouse_filter = Control.MOUSE_FILTER_STOP
	top_row.add_child(debug_button)

	var display_margin := MarginContainer.new()
	display_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	display_margin.add_theme_constant_override("margin_left", 560)
	display_margin.add_theme_constant_override("margin_right", 560)
	display_margin.add_theme_constant_override("margin_top", 150)
	display_margin.add_theme_constant_override("margin_bottom", 330)
	display_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shop_overlay.add_child(display_margin)

	var display_panel := PanelContainer.new()
	_decorate_panel(display_panel, Color(0.02, 0.035, 0.045, 0.38), Color(0.52, 0.88, 0.96, 0.74))
	display_margin.add_child(display_panel)

	var display_box := VBoxContainer.new()
	display_box.alignment = BoxContainer.ALIGNMENT_CENTER
	display_box.add_theme_constant_override("separation", 12)
	display_panel.add_child(_with_padding(display_box, 20))

	var display_mark := Label.new()
	display_mark.text = "COMPANION"
	display_mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	display_mark.add_theme_font_size_override("font_size", 42)
	display_mark.add_theme_color_override("font_color", Color(0.75, 0.96, 1.0, 1.0))
	display_box.add_child(display_mark)

	shop_preview_label = RichTextLabel.new()
	shop_preview_label.bbcode_enabled = true
	shop_preview_label.fit_content = true
	shop_preview_label.scroll_active = false
	shop_preview_label.custom_minimum_size = Vector2(0, 130)
	shop_preview_label.add_theme_font_size_override("normal_font_size", 16)
	display_box.add_child(shop_preview_label)

	var dock_margin := MarginContainer.new()
	dock_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	dock_margin.add_theme_constant_override("margin_left", 80)
	dock_margin.add_theme_constant_override("margin_right", 80)
	dock_margin.add_theme_constant_override("margin_top", 560)
	dock_margin.add_theme_constant_override("margin_bottom", 36)
	dock_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shop_overlay.add_child(dock_margin)

	var dock_panel := PanelContainer.new()
	_decorate_panel(dock_panel, Color(0.035, 0.045, 0.060, 0.94), Color(0.36, 0.76, 0.82, 0.88))
	dock_margin.add_child(dock_panel)

	var dock := HBoxContainer.new()
	dock.add_theme_constant_override("separation", 18)
	dock_panel.add_child(_with_padding(dock, 18))

	var dialogue_box := VBoxContainer.new()
	dialogue_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialogue_box.add_theme_constant_override("separation", 8)
	dock.add_child(dialogue_box)

	shop_speaker_label = Label.new()
	shop_speaker_label.text = "店员"
	shop_speaker_label.add_theme_font_size_override("font_size", 18)
	shop_speaker_label.add_theme_color_override("font_color", Color(0.55, 0.90, 0.96, 1.0))
	dialogue_box.add_child(shop_speaker_label)

	shop_dialogue_text = RichTextLabel.new()
	shop_dialogue_text.bbcode_enabled = true
	shop_dialogue_text.scroll_active = false
	shop_dialogue_text.custom_minimum_size = Vector2(0, 86)
	shop_dialogue_text.add_theme_font_size_override("normal_font_size", 18)
	dialogue_box.add_child(shop_dialogue_text)

	var package_row := HBoxContainer.new()
	package_row.add_theme_constant_override("separation", 8)
	dialogue_box.add_child(package_row)

	package_row.add_child(_make_button("温柔", func() -> void:
		_select_shop_archetype("gentle")
	))
	package_row.add_child(_make_button("活泼", func() -> void:
		_select_shop_archetype("playful")
	))
	package_row.add_child(_make_button("守护", func() -> void:
		_select_shop_archetype("quiet")
	))
	package_row.add_child(_make_button("自定义", func() -> void:
		_select_shop_archetype("custom")
	))

	var config_box := VBoxContainer.new()
	config_box.custom_minimum_size = Vector2(480, 0)
	config_box.add_theme_constant_override("separation", 8)
	dock.add_child(config_box)

	var option_row := HBoxContainer.new()
	option_row.add_theme_constant_override("separation", 8)
	config_box.add_child(option_row)

	shop_gender_option = _make_option_button(["女性", "男性", "中性"])
	shop_gender_option.item_selected.connect(func(_index: int) -> void:
		_refresh_shop_preview()
	)
	option_row.add_child(shop_gender_option)

	shop_age_spin = SpinBox.new()
	shop_age_spin.min_value = 21
	shop_age_spin.max_value = 34
	shop_age_spin.step = 1
	shop_age_spin.value = 24
	shop_age_spin.custom_minimum_size = Vector2(96, 42)
	shop_age_spin.value_changed.connect(func(_value: float) -> void:
		_refresh_shop_preview()
	)
	option_row.add_child(shop_age_spin)

	shop_style_option = _make_option_button(["真人写实", "二次元", "国漫脸", "半写实"])
	shop_style_option.item_selected.connect(func(_index: int) -> void:
		_refresh_shop_preview()
	)
	option_row.add_child(shop_style_option)

	shop_name_edit = _make_line_edit("登记名", "Mira")
	shop_name_edit.text_changed.connect(func(_text: String) -> void:
		_refresh_shop_preview()
	)
	config_box.add_child(shop_name_edit)

	shop_visual_prompt_edit = _make_text_edit("一句话描述她的外貌", "银灰色短发，温柔眼神，近未来家居服。")
	shop_visual_prompt_edit.custom_minimum_size.y = 58
	shop_visual_prompt_edit.text_changed.connect(_refresh_shop_preview)
	config_box.add_child(shop_visual_prompt_edit)

	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 8)
	config_box.add_child(action_row)

	action_row.add_child(_make_button("登记并带回家", func() -> void:
		await _create_shop_character()
	))
	action_row.add_child(_make_button("稍后配图", func() -> void:
		_set_status("已选择先跳过图片生成。")
		_show_shop_line("没有图片 API 也没关系，主人。先把她带回家，对话和记忆会正常工作。")
	))

	_select_shop_archetype("gentle")


func _build_immersive_overlay() -> void:
	immersive_overlay = Control.new()
	immersive_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	immersive_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	immersive_overlay.visible = false
	add_child(immersive_overlay)

	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.0, 0.0, 0.0, 0.18)
	immersive_overlay.add_child(shade)

	var top_margin := MarginContainer.new()
	top_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	top_margin.add_theme_constant_override("margin_left", 28)
	top_margin.add_theme_constant_override("margin_right", 28)
	top_margin.add_theme_constant_override("margin_top", 24)
	top_margin.add_theme_constant_override("margin_bottom", 760)
	immersive_overlay.add_child(top_margin)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 10)
	top_margin.add_child(top_row)

	immersive_role_label = Label.new()
	immersive_role_label.text = "出租屋"
	immersive_role_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	immersive_role_label.add_theme_font_size_override("font_size", 18)
	immersive_role_label.add_theme_color_override("font_color", Color(0.82, 0.92, 0.96, 1.0))
	top_row.add_child(immersive_role_label)

	var exit_button := _make_button("退出面对面", func() -> void:
		_hide_immersive_chat()
	)
	top_row.add_child(exit_button)

	var character_margin := MarginContainer.new()
	character_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	character_margin.add_theme_constant_override("margin_left", 560)
	character_margin.add_theme_constant_override("margin_right", 560)
	character_margin.add_theme_constant_override("margin_top", 150)
	character_margin.add_theme_constant_override("margin_bottom", 310)
	immersive_overlay.add_child(character_margin)

	var character_panel := PanelContainer.new()
	_decorate_panel(character_panel, Color(0.03, 0.045, 0.06, 0.52), Color(0.55, 0.86, 0.92, 0.72))
	character_margin.add_child(character_panel)

	var character_box := VBoxContainer.new()
	character_box.alignment = BoxContainer.ALIGNMENT_CENTER
	character_box.add_theme_constant_override("separation", 14)
	character_panel.add_child(_with_padding(character_box, 20))

	immersive_portrait_rect = TextureRect.new()
	immersive_portrait_rect.custom_minimum_size = Vector2(0, 330)
	immersive_portrait_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	immersive_portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	immersive_portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	character_box.add_child(immersive_portrait_rect)

	immersive_name_label = Label.new()
	immersive_name_label.text = "AI"
	immersive_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	immersive_name_label.add_theme_font_size_override("font_size", 28)
	immersive_name_label.add_theme_color_override("font_color", Color(0.98, 0.99, 1.0, 1.0))
	character_box.add_child(immersive_name_label)

	immersive_portrait_status_label = Label.new()
	immersive_portrait_status_label.text = "她正看着你，等待主人的下一句话。"
	immersive_portrait_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	immersive_portrait_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	immersive_portrait_status_label.add_theme_color_override("font_color", Color(0.78, 0.84, 0.90, 1.0))
	character_box.add_child(immersive_portrait_status_label)

	var dialogue_margin := MarginContainer.new()
	dialogue_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	dialogue_margin.add_theme_constant_override("margin_left", 90)
	dialogue_margin.add_theme_constant_override("margin_right", 90)
	dialogue_margin.add_theme_constant_override("margin_top", 610)
	dialogue_margin.add_theme_constant_override("margin_bottom", 42)
	immersive_overlay.add_child(dialogue_margin)

	var dialogue_panel := PanelContainer.new()
	_decorate_panel(dialogue_panel, Color(0.035, 0.045, 0.060, 0.94), Color(0.36, 0.76, 0.82, 0.88))
	dialogue_margin.add_child(dialogue_panel)

	var dialogue_box := VBoxContainer.new()
	dialogue_box.add_theme_constant_override("separation", 10)
	dialogue_panel.add_child(_with_padding(dialogue_box, 18))

	var action_caption := Label.new()
	action_caption.text = "让她做点什么"
	action_caption.add_theme_color_override("font_color", Color(0.72, 0.84, 0.90, 1.0))
	dialogue_box.add_child(action_caption)

	immersive_action_card_grid = GridContainer.new()
	immersive_action_card_grid.columns = 6
	immersive_action_card_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	immersive_action_card_grid.add_theme_constant_override("h_separation", 6)
	immersive_action_card_grid.add_theme_constant_override("v_separation", 6)
	dialogue_box.add_child(immersive_action_card_grid)

	immersive_reply_text = RichTextLabel.new()
	immersive_reply_text.bbcode_enabled = true
	immersive_reply_text.scroll_active = false
	immersive_reply_text.custom_minimum_size = Vector2(0, 105)
	immersive_reply_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	immersive_reply_text.add_theme_font_size_override("normal_font_size", 18)
	dialogue_box.add_child(immersive_reply_text)

	var input_row := HBoxContainer.new()
	input_row.add_theme_constant_override("separation", 10)
	dialogue_box.add_child(input_row)

	immersive_input = _make_line_edit("直接对她说话...", "")
	immersive_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	immersive_input.text_submitted.connect(_on_immersive_submitted)
	input_row.add_child(immersive_input)

	var send_button := _make_button("说给她听", func() -> void:
		await _send_immersive_chat_message()
	)
	input_row.add_child(send_button)


func _decorate_panel(panel: PanelContainer, bg_color: Color = Color(0.10, 0.13, 0.17, 1.0), border_color: Color = Color(0.18, 0.22, 0.28, 1.0)) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = border_color
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	panel.add_theme_stylebox_override("panel", style)


func _with_padding(container: Control, margin: int) -> MarginContainer:
	var wrapper := MarginContainer.new()
	wrapper.add_theme_constant_override("margin_left", margin)
	wrapper.add_theme_constant_override("margin_right", margin)
	wrapper.add_theme_constant_override("margin_top", margin)
	wrapper.add_theme_constant_override("margin_bottom", margin)
	wrapper.add_child(container)
	return wrapper


func _make_card(parent: Control, title: String) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(0, 120)
	_decorate_panel(panel)
	parent.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)

	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 18)
	box.add_child(title_label)
	return box


func _make_line_edit(placeholder: String, value: String) -> LineEdit:
	var edit := LineEdit.new()
	edit.placeholder_text = placeholder
	edit.text = value
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return edit


func _make_text_edit(placeholder: String, value: String) -> TextEdit:
	var edit := TextEdit.new()
	edit.placeholder_text = placeholder
	edit.text = value
	edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	edit.custom_minimum_size = Vector2(0, 72)
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return edit


func _make_option_button(items: Array) -> OptionButton:
	var option := OptionButton.new()
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	option.custom_minimum_size = Vector2(0, 42)
	for item in items:
		option.add_item(str(item))
	return option


func _make_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.size_flags_horizontal = Control.SIZE_FILL
	button.custom_minimum_size = Vector2(0, 42)
	button.pressed.connect(callback)
	_style_button(button, Color(0.18, 0.24, 0.32, 1.0), Color(0.24, 0.64, 0.69, 1.0))
	return button


func _make_menu_button(text: String, callback: Callable) -> Button:
	var button := _make_button(text, callback)
	button.custom_minimum_size = Vector2(0, 52)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 18)
	return button


func _style_button(button: Button, normal_color: Color, hover_color: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = normal_color
	normal.corner_radius_top_left = 6
	normal.corner_radius_top_right = 6
	normal.corner_radius_bottom_left = 6
	normal.corner_radius_bottom_right = 6
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8

	var hover := normal.duplicate()
	hover.bg_color = hover_color

	var pressed := normal.duplicate()
	pressed.bg_color = Color(normal_color.r * 0.72, normal_color.g * 0.72, normal_color.b * 0.72, 1.0)

	var disabled := normal.duplicate()
	disabled.bg_color = Color(0.08, 0.10, 0.13, 0.9)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.55, 0.60, 0.66, 1.0))


func _make_help_text(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color(0.72, 0.76, 0.82))
	return label


func _make_schedule_badge(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(0, 38)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0, 1.0))
	return label


func _initialize_story() -> void:
	story_pack = BASE_GAME_PACK.new()
	story_chapters = story_pack.get_chapters()
	story_chapter_index = 0
	story_line_index = 0
	story_complete = false
	story_waiting_for_gameplay = false
	_set_gameplay_visible(false)
	_play_current_story_line()


func _play_current_story_line() -> void:
	if story_chapter_index >= story_chapters.size():
		_finish_story()
		return

	var chapter: Dictionary = story_chapters[story_chapter_index]
	_apply_chapter_scene(chapter)

	var lines: Array = chapter.get("lines", [])
	if lines.is_empty():
		_advance_story()
		return

	story_line_index = clamp(story_line_index, 0, lines.size() - 1)
	if story_overlay:
		story_overlay.visible = true
	if story_popup_title:
		story_popup_title.text = str(chapter.get("title", ""))
	if story_popup_stage:
		story_popup_stage.text = str(chapter.get("speaker", "旁白"))
	if story_popup_text:
		story_popup_text.clear()
		story_popup_text.append_text(_escape_bbcode(str(lines[story_line_index])))
	if story_continue_button:
		story_continue_button.text = str(chapter.get("continue_label", "继续")) if story_line_index == lines.size() - 1 else "继续"


func _advance_story() -> void:
	if story_chapter_index >= story_chapters.size():
		_finish_story()
		return

	var chapter: Dictionary = story_chapters[story_chapter_index]
	var lines: Array = chapter.get("lines", [])
	if story_line_index < lines.size() - 1:
		story_line_index += 1
		_play_current_story_line()
		return

	if bool(chapter.get("show_gameplay", false)):
		_enter_gameplay_step(chapter)
		return

	story_chapter_index += 1
	story_line_index = 0
	_play_current_story_line()


func _enter_gameplay_step(chapter: Dictionary) -> void:
	if story_overlay:
		story_overlay.visible = false
	_set_gameplay_visible(true)
	_focus_chapter_tab(chapter)
	story_waiting_for_gameplay = true
	_update_story_continue_button()


func _complete_current_gameplay_step() -> void:
	if not story_waiting_for_gameplay:
		return
	story_waiting_for_gameplay = false
	if menu_continue_story_button:
		menu_continue_story_button.disabled = true
		menu_continue_story_button.visible = false
	story_chapter_index += 1
	story_line_index = 0
	_set_gameplay_visible(false)
	_play_current_story_line()


func _finish_story() -> void:
	story_complete = true
	story_waiting_for_gameplay = false
	if story_overlay:
		story_overlay.visible = false
	if menu_continue_story_button:
		menu_continue_story_button.disabled = true
		menu_continue_story_button.visible = false
	_set_gameplay_visible(true)
	_render_selected_character()
	_set_status("已回到出租屋，可以开始互动。")
	if selected_character.is_empty():
		_show_shop_overlay()
	else:
		await _open_selected_character_chat(true)


func _skip_story() -> void:
	story_complete = true
	story_waiting_for_gameplay = false
	if story_overlay:
		story_overlay.visible = false
	if menu_continue_story_button:
		menu_continue_story_button.disabled = true
		menu_continue_story_button.visible = false
	_set_gameplay_visible(true)
	_render_selected_character()
	_show_shop_overlay()
	_set_status("已跳过序章。")


func _apply_chapter_scene(chapter: Dictionary) -> void:
	var background_path := str(chapter.get("background", ""))
	if background_path.is_empty():
		background_image_rect.texture = null
		background_tint.color = Color(0.025, 0.035, 0.055, 0.80)
	else:
		background_image_rect.texture = load(background_path)
		var mode := str(chapter.get("mode", "story"))
		if mode == "store":
			background_tint.color = Color(0.0, 0.02, 0.035, 0.44)
		elif mode == "home":
			background_tint.color = Color(0.02, 0.025, 0.025, 0.50)
		else:
			background_tint.color = Color(0.02, 0.025, 0.03, 0.48)


func _focus_chapter_tab(chapter: Dictionary) -> void:
	var focus := str(chapter.get("focus_tab", ""))
	if focus == "home":
		_show_shop_overlay()
	elif focus == "settings":
		_hide_shop_overlay()
		_show_page(settings_tab_index)
	elif focus == "chat":
		_hide_shop_overlay()
		_show_page(chat_tab_index)


func _set_gameplay_visible(visible: bool) -> void:
	if gameplay_root:
		gameplay_root.visible = visible


func _update_story_continue_button() -> void:
	if menu_continue_story_button == null:
		return
	if not story_waiting_for_gameplay or story_chapter_index >= story_chapters.size():
		menu_continue_story_button.visible = false
		menu_continue_story_button.disabled = true
		return

	var chapter: Dictionary = story_chapters[story_chapter_index]
	menu_continue_story_button.visible = true
	menu_continue_story_button.text = str(chapter.get("continue_label", "继续"))
	var focus := str(chapter.get("focus_tab", ""))
	menu_continue_story_button.disabled = focus == "home" and selected_character.is_empty()


func _set_status(text: String) -> void:
	if status_label:
		status_label.text = text


func _ensure_placeholder_portrait() -> Texture2D:
	if placeholder_portrait_texture != null:
		return placeholder_portrait_texture

	var image := Image.create(512, 768, false, Image.FORMAT_RGBA8)
	for y in range(768):
		var ratio := float(y) / 767.0
		var base := Color(0.04 + ratio * 0.04, 0.08 + ratio * 0.05, 0.10 + ratio * 0.08, 1.0)
		for x in range(512):
			image.set_pixel(x, y, base)

	for y in range(96, 690):
		for x in range(82, 430):
			var nx := (float(x) - 256.0) / 174.0
			var ny := (float(y) - 390.0) / 294.0
			var distance := nx * nx + ny * ny
			if distance < 1.0:
				var glow: float = clampf(1.0 - distance, 0.0, 1.0)
				var current: Color = image.get_pixel(x, y)
				image.set_pixel(x, y, current.lerp(Color(0.36, 0.82, 0.90, 0.90), glow * 0.46))

	for y in range(130, 330):
		for x in range(156, 356):
			var nx := (float(x) - 256.0) / 100.0
			var ny := (float(y) - 230.0) / 100.0
			if nx * nx + ny * ny < 1.0:
				image.set_pixel(x, y, Color(0.78, 0.95, 1.0, 0.95))

	for y in range(342, 690):
		for x in range(116, 396):
			var nx := (float(x) - 256.0) / 140.0
			var ny := (float(y) - 690.0) / 348.0
			if nx * nx + ny * ny < 1.0:
				image.set_pixel(x, y, Color(0.70, 0.90, 0.96, 0.88))

	placeholder_portrait_texture = ImageTexture.create_from_image(image)
	return placeholder_portrait_texture


func _show_page(index: int) -> void:
	if tab_container == null:
		return
	_set_gameplay_visible(true)
	tab_container.visible = true
	if shop_overlay:
		shop_overlay.visible = false
	if immersive_overlay:
		immersive_overlay.visible = false
	if schedule_overlay:
		schedule_overlay.visible = false
	tab_container.current_tab = clamp(index, 0, tab_container.get_tab_count() - 1)


func _open_shop_page(index: int, status_text: String) -> void:
	_set_gameplay_visible(true)
	if tab_container:
		tab_container.visible = true
		tab_container.current_tab = clamp(index, 0, tab_container.get_tab_count() - 1)
	if shop_overlay:
		shop_overlay.visible = false
	if immersive_overlay:
		immersive_overlay.visible = false
	if schedule_overlay:
		schedule_overlay.visible = false
	_set_status(status_text)


func _build_url(path: String) -> String:
	var normalized := backend_url.strip_edges().trim_suffix("/")
	var clean_path := path.strip_edges()
	if clean_path.begins_with("/"):
		clean_path = clean_path.substr(1)
	return normalized + "/" + clean_path


func _reload_everything() -> void:
	backend_url = backend_url_edit.text.strip_edges()
	if backend_url.is_empty():
		backend_url = DEFAULT_BACKEND_URL
	_set_status("Connecting to backend...")

	var health := await _request_json(HTTPClient.METHOD_GET, "/health")
	if not health.ok:
		_set_status("Connection failed: %s" % health.error)
		return

	_set_status("Backend online. Loading providers...")
	await _load_provider_settings()
	await _load_action_templates()
	await _refresh_characters()
	_set_status("Connected to backend.")


func _load_provider_settings() -> void:
	var result := await _request_json(HTTPClient.METHOD_GET, "/providers")
	if not result.ok:
		_set_status("Load settings failed: %s" % result.error)
		return

	_apply_provider_settings(result.data)
	_set_status("Provider settings loaded.")


func _apply_provider_settings(data: Dictionary) -> void:
	var text_cfg: Dictionary = data.get("text", {})
	var image_cfg: Dictionary = data.get("image", {})

	deepseek_key_edit.text = ""
	deepseek_base_url_edit.text = str(text_cfg.get("base_url", "https://api.deepseek.com"))
	deepseek_model_edit.text = str(text_cfg.get("model", "deepseek-v4-pro"))
	deepseek_temperature_edit.text = str(text_cfg.get("temperature", 0.7))
	deepseek_max_tokens_edit.text = str(text_cfg.get("max_tokens", 1024))
	deepseek_reasoning_edit.text = str(text_cfg.get("reasoning_effort", "medium"))

	image_key_edit.text = ""
	image_base_url_edit.text = str(image_cfg.get("base_url", "https://api.openai.com/v1"))
	image_model_edit.text = str(image_cfg.get("model", "gpt-image-1"))
	image_generation_path_edit.text = str(image_cfg.get("generation_path", "/images/generations"))
	image_edit_path_edit.text = str(image_cfg.get("edit_path", "/images/edits"))
	image_size_edit.text = str(image_cfg.get("size", "1024x1024"))
	image_quality_edit.text = str(image_cfg.get("quality", "medium"))
	image_background_edit.text = str(image_cfg.get("background", "transparent"))
	image_input_fidelity_edit.text = str(image_cfg.get("input_fidelity", "high"))


func _save_provider_settings() -> void:
	var payload := {}
	var text_payload := {}
	var image_payload := {}

	_add_if_not_empty(text_payload, "api_key", deepseek_key_edit.text)
	_add_if_not_empty(text_payload, "base_url", deepseek_base_url_edit.text)
	_add_if_not_empty(text_payload, "model", deepseek_model_edit.text)
	_add_if_not_empty(text_payload, "temperature", deepseek_temperature_edit.text)
	_add_if_not_empty(text_payload, "max_tokens", deepseek_max_tokens_edit.text)
	_add_if_not_empty(text_payload, "reasoning_effort", deepseek_reasoning_edit.text)

	_add_if_not_empty(image_payload, "api_key", image_key_edit.text)
	_add_if_not_empty(image_payload, "base_url", image_base_url_edit.text)
	_add_if_not_empty(image_payload, "model", image_model_edit.text)
	_add_if_not_empty(image_payload, "generation_path", image_generation_path_edit.text)
	_add_if_not_empty(image_payload, "edit_path", image_edit_path_edit.text)
	_add_if_not_empty(image_payload, "size", image_size_edit.text)
	_add_if_not_empty(image_payload, "quality", image_quality_edit.text)
	_add_if_not_empty(image_payload, "background", image_background_edit.text)
	_add_if_not_empty(image_payload, "input_fidelity", image_input_fidelity_edit.text)

	if not text_payload.is_empty():
		payload["text"] = text_payload
	if not image_payload.is_empty():
		payload["image"] = image_payload

	if payload.is_empty():
		_set_status("No provider changes to save.")
		return

	var result := await _request_json(HTTPClient.METHOD_PUT, "/providers", payload)
	if not result.ok:
		_set_status("Save settings failed: %s" % result.error)
		return

	_apply_provider_settings(result.data)
	_set_status("Provider settings saved.")


func _add_if_not_empty(target: Dictionary, key: String, raw_value: String) -> void:
	var value := raw_value.strip_edges()
	if value.is_empty():
		return
	if key == "temperature":
		target[key] = float(value)
		return
	if key == "max_tokens":
		target[key] = int(value)
		return
	target[key] = value


func _refresh_characters() -> void:
	var result := await _request_json(HTTPClient.METHOD_GET, "/characters")
	if not result.ok:
		_set_status("Load characters failed: %s" % result.error)
		return

	characters = result.data if result.data is Array else []
	if character_count_label:
		character_count_label.text = "角色：%d" % characters.size()
	_render_character_list()
	if characters.is_empty():
		selected_character = {}
		_render_selected_character()
		_update_story_continue_button()
		return

	if selected_character.is_empty():
		await _select_character_by_index(0, false)
	else:
		var selected_id := int(selected_character.get("id", 0))
		var existing_index := _find_character_index(selected_id)
		if existing_index >= 0:
			await _select_character_by_index(existing_index, false)
		else:
			await _select_character_by_index(0, false)


func _render_character_list() -> void:
	character_list.clear()
	for character in characters:
		var name := str(character.get("name", "Unnamed"))
		var personality := str(character.get("personality", ""))
		character_list.add_item("%s  |  %s" % [name, personality])


func _on_character_selected(index: int) -> void:
	await _select_character_by_index(index, story_complete)


func _find_character_index(character_id: int) -> int:
	for i in range(characters.size()):
		if int(characters[i].get("id", 0)) == character_id:
			return i
	return -1


func _select_character_by_index(index: int, open_chat: bool) -> void:
	if index < 0 or index >= characters.size():
		return

	selected_character = characters[index]
	visual_profile = {}
	action_assets = {}
	current_portrait_key = "master"
	if character_list.item_count > index:
		character_list.select(index)
	_render_selected_character()
	if open_chat:
		await _open_selected_character_chat()
	_update_story_continue_button()


func _render_selected_character() -> void:
	if selected_character.is_empty():
		selected_character_label.text = "從列表中選擇一位角色。"
		selected_character_summary.text = "先挑一位 AI 伴侶，再帶回家開始對話。"
		open_chat_button.disabled = true
		if menu_chat_button:
			menu_chat_button.disabled = true
		return

	open_chat_button.disabled = false
	open_chat_button.text = "带回家" if not story_complete else "开始对话"
	if menu_chat_button:
		menu_chat_button.disabled = not story_complete
	var name := str(selected_character.get("name", "Unnamed"))
	var personality := str(selected_character.get("personality", ""))
	var background := str(selected_character.get("background", ""))
	var memory := str(selected_character.get("memory", ""))

	selected_character_label.text = (
		"[b]%s[/b]\n\n[b]性格[/b]\n%s\n\n[b]背景[/b]\n%s\n\n[b]初始记忆[/b]\n%s"
		% [_escape_bbcode(name), _escape_bbcode(personality), _escape_bbcode(background), _escape_bbcode(memory)]
	)
	selected_character_summary.text = (
		"[b]性格[/b]\n%s\n\n[b]背景[/b]\n%s\n\n[b]记忆[/b]\n%s"
		% [_escape_bbcode(personality), _escape_bbcode(background), _escape_bbcode(memory)]
	)


func _open_selected_character_chat(immersive: bool = true) -> void:
	if selected_character.is_empty():
		_set_status("Choose a character first.")
		return

	var character_id := int(selected_character.get("id", 0))
	if immersive:
		_show_immersive_chat()
		_set_status("正在把她带回出租屋...")
	else:
		_set_status("Loading character chat...")

	var character_result := await _request_json(HTTPClient.METHOD_GET, "/characters/%d" % character_id)
	if not character_result.ok:
		_set_status("房间已准备好，但角色资料加载失败：%s" % character_result.error)
		return

	selected_character = character_result.data if character_result.data is Dictionary else selected_character
	_render_selected_character()
	await _load_progress_and_inventory()

	var messages_result := await _request_json(HTTPClient.METHOD_GET, "/characters/%d/messages?limit=100" % character_id)
	var memories_result := await _request_json(HTTPClient.METHOD_GET, "/characters/%d/memories?limit=50" % character_id)
	if not messages_result.ok:
		_set_status("房间已准备好，但对话历史暂时无法读取。")
		return
	if not memories_result.ok:
		_set_status("房间已准备好，但记忆暂时无法读取。")
		return

	_render_memories(memories_result.data if memories_result.data is Array else [])
	_render_messages(messages_result.data if messages_result.data is Array else [])
	await _load_character_art()
	if immersive:
		_set_status("她已经回到出租屋，正在等你开口。")
	else:
		_show_page(chat_tab_index)
		_set_status("Chat ready.")


func _render_memories(items: Array) -> void:
	memory_list.clear()
	if items.is_empty():
		memory_list.add_item("目前還沒有記憶。")
		return

	for memory in items:
		var type_name := str(memory.get("type", "memory"))
		var content := str(memory.get("content", ""))
		var importance := int(memory.get("importance", 3))
		var preview := content if content.length() <= 60 else content.substr(0, 60) + "..."
		memory_list.add_item("[%s %d] %s" % [type_name, importance, preview])


func _render_messages(items: Array) -> void:
	chat_messages.clear()
	if items.is_empty():
		chat_messages.append_text("先打個招呼，對話就開始了。\n")
		return

	for message in items:
		var role := str(message.get("role", "assistant"))
		var content := _escape_bbcode(str(message.get("content", "")))
		var prefix := "You" if role == "user" else str(selected_character.get("name", "AI"))
		chat_messages.append_text("[b]%s:[/b] %s\n\n" % [prefix, content])


func _on_chat_submitted(_text: String) -> void:
	await _send_chat_message()


func _send_chat_message() -> void:
	if selected_character.is_empty():
		_set_status("Choose a character first.")
		return

	var message := chat_input.text.strip_edges()
	if message.is_empty():
		return

	chat_input.text = ""
	chat_messages.append_text("[b]You:[/b] %s\n\n" % _escape_bbcode(message))
	_set_status("Thinking...")

	var character_id := int(selected_character.get("id", 0))
	var payload := {"message": message}
	var result := await _request_json(HTTPClient.METHOD_POST, "/characters/%d/chat" % character_id, payload)
	if not result.ok:
		chat_messages.append_text("[b]System:[/b] Backend error: %s\n\n" % _escape_bbcode(result.error))
		_set_status("Chat failed.")
		return

	var reply := ""
	var used_llm := false
	if result.data is Dictionary:
		reply = str(result.data.get("reply", ""))
		used_llm = bool(result.data.get("used_llm", false))

	chat_messages.append_text("[b]%s:[/b] %s\n\n" % [_escape_bbcode(str(selected_character.get("name", "AI"))), _escape_bbcode(reply)])
	_set_status("Reply generated %s." % ("by LLM" if used_llm else "in dev mode"))
	await _open_selected_character_chat()


func _show_immersive_chat() -> void:
	if selected_character.is_empty():
		_set_status("先选择一位 AI 伴侣。")
		return
	if shop_overlay:
		shop_overlay.visible = false
	if schedule_overlay:
		schedule_overlay.visible = false
	if not story_complete and not story_waiting_for_gameplay:
		story_complete = true

	background_image_rect.texture = load("res://assets/backgrounds/home.png")
	background_tint.color = Color(0.02, 0.025, 0.025, 0.42)
	_set_gameplay_visible(false)
	if tab_container:
		tab_container.visible = false
	if schedule_period == 2:
		schedule_pending_rollover = true
	if immersive_overlay:
		immersive_overlay.visible = true
	if immersive_name_label:
		immersive_name_label.text = str(selected_character.get("name", "AI"))
	if immersive_role_label:
		immersive_role_label.text = "面对面互动"
	if immersive_reply_text:
		immersive_reply_text.clear()
		immersive_reply_text.append_text(
			"[b]%s[/b]\n主人，我在这里。你想和我说什么？"
			% _escape_bbcode(str(selected_character.get("name", "AI")))
		)
	if immersive_input:
		immersive_input.text = ""
		immersive_input.grab_focus()


func _hide_immersive_chat() -> void:
	if immersive_overlay:
		immersive_overlay.visible = false
	if tab_container:
		tab_container.visible = true
	_set_gameplay_visible(true)
	if schedule_pending_rollover:
		_advance_schedule_day()
		schedule_last_action = "夜晚结束了，明天再继续陪伴。"
		_update_schedule_ui()
	_show_page(chat_tab_index)
	_set_status("已返回普通对话界面。")


func _on_immersive_submitted(_text: String) -> void:
	await _send_immersive_chat_message()


func _send_immersive_chat_message() -> void:
	if selected_character.is_empty():
		_set_status("先选择一位 AI 伴侣。")
		return

	var message := ""
	if immersive_input:
		message = immersive_input.text.strip_edges()
	if message.is_empty():
		return

	if immersive_input:
		immersive_input.text = ""
	if immersive_reply_text:
		immersive_reply_text.clear()
		immersive_reply_text.append_text("[b]你[/b]\n%s\n\n[b]%s[/b]\n正在回应主人..." % [
			_escape_bbcode(message),
			_escape_bbcode(str(selected_character.get("name", "AI"))),
		])

	var character_id := int(selected_character.get("id", 0))
	var payload := {"message": message}
	var result := await _request_json(HTTPClient.METHOD_POST, "/characters/%d/chat" % character_id, payload)
	if not result.ok:
		if immersive_reply_text:
			immersive_reply_text.clear()
			immersive_reply_text.append_text("[b]System[/b]\nBackend error: %s" % _escape_bbcode(result.error))
		_set_status("Chat failed.")
		return

	var reply := ""
	var used_llm := false
	if result.data is Dictionary:
		reply = str(result.data.get("reply", ""))
		used_llm = bool(result.data.get("used_llm", false))

	if immersive_reply_text:
		immersive_reply_text.clear()
		immersive_reply_text.append_text("[b]%s[/b]\n%s" % [
			_escape_bbcode(str(selected_character.get("name", "AI"))),
			_escape_bbcode(reply),
		])
	if chat_messages:
		chat_messages.append_text("[b]You:[/b] %s\n\n" % _escape_bbcode(message))
		chat_messages.append_text("[b]%s:[/b] %s\n\n" % [
			_escape_bbcode(str(selected_character.get("name", "AI"))),
			_escape_bbcode(reply),
		])
	_set_status("Reply generated %s." % ("by LLM" if used_llm else "in dev mode"))


func _show_shop_overlay() -> void:
	background_image_rect.texture = load("res://assets/backgrounds/aic_shop.png")
	background_tint.color = Color(0.0, 0.02, 0.035, 0.32)
	_set_gameplay_visible(false)
	if story_overlay:
		story_overlay.visible = false
	if immersive_overlay:
		immersive_overlay.visible = false
	if shop_overlay:
		shop_overlay.visible = true
	_refresh_shop_preview()
	_show_shop_line("欢迎来到 AI 伴侣专卖店。主人可以先挑一位占位伴侣带回家，图片 API 之后再补。")


func _hide_shop_overlay() -> void:
	if shop_overlay:
		shop_overlay.visible = false
	_set_gameplay_visible(true)


func _show_schedule_overlay() -> void:
	if not story_complete:
		_set_status("先完成序章，再安排日程。")
		return
	if shop_overlay:
		shop_overlay.visible = false
	if immersive_overlay:
		immersive_overlay.visible = false
	if schedule_overlay:
		schedule_overlay.visible = true
	background_image_rect.texture = load("res://assets/backgrounds/home.png")
	background_tint.color = Color(0.02, 0.025, 0.03, 0.34)
	_set_gameplay_visible(false)
	_update_schedule_ui()


func _hide_schedule_overlay() -> void:
	if schedule_overlay:
		schedule_overlay.visible = false
	_set_gameplay_visible(true)


func _format_schedule_period() -> String:
	match schedule_period:
		0:
			return "早上"
		1:
			return "下午"
		_:
			return "晚上"


func _update_schedule_ui() -> void:
	if schedule_day_label:
		schedule_day_label.text = "第 %d 天" % schedule_day
	if schedule_period_label:
		schedule_period_label.text = _format_schedule_period()
	if schedule_stats_label:
		schedule_stats_label.text = "资金 %d / 调参 %d / 关系 %d" % [schedule_money, schedule_study_points, schedule_relationship]
	if progress_summary_label:
		var stage := str(character_progress.get("relationship_stage", "初识"))
		var room_name := str(character_progress.get("room_name", "出租屋"))
		var room_desc := str(character_progress.get("room_description", ""))
		var next_cost := character_progress.get("next_room_cost", null)
		var room_hint := "最高等级"
		if next_cost != null:
			room_hint = "下一层需要 %d 金钱" % int(next_cost)
		progress_summary_label.clear()
		progress_summary_label.append_text(
			"[b]关系阶段[/b] %s\n[b]房间[/b] %s · %s\n[b]升级提示[/b] %s"
			% [_escape_bbcode(stage), _escape_bbcode(room_name), _escape_bbcode(room_desc), _escape_bbcode(room_hint)]
		)
	if schedule_last_action_label:
		schedule_last_action_label.text = schedule_last_action
	if schedule_summary:
		schedule_summary.clear()
		schedule_summary.append_text(
			"[b]白天行动[/b]\n"
			+ "早上和下午可以安排工作、学习、逛街和买礼物。\n"
			+ "晚上回家后再和她互动，第二天会重新开始。"
		)
	if schedule_hint_label:
		var hint := ""
		if schedule_period == 0:
			hint = "现在是早上，适合打工、学习 AI 调参，或去街上看看礼物。"
		elif schedule_period == 1:
			hint = "现在是下午，可以继续白天安排，再把故事推进到夜晚。"
		else:
			hint = "现在是晚上，回出租屋和她互动最合适。"
		schedule_hint_label.clear()
		schedule_hint_label.append_text(_escape_bbcode(hint))

	var day_phase_open := schedule_period < 2
	if schedule_work_button:
		schedule_work_button.disabled = not day_phase_open
	if schedule_study_button:
		schedule_study_button.disabled = not day_phase_open
	if schedule_stroll_button:
		schedule_stroll_button.disabled = not day_phase_open
	if schedule_gift_button:
		schedule_gift_button.disabled = not day_phase_open or gift_catalog_list == null or gift_catalog_list.item_count == 0
	if schedule_home_button:
		schedule_home_button.disabled = schedule_period != 2 or selected_character.is_empty()
	if gift_purchase_button:
		gift_purchase_button.disabled = gift_catalog_list == null or gift_catalog_list.item_count == 0
	if use_gift_button:
		use_gift_button.disabled = inventory_list == null or inventory_list.item_count == 0 or selected_inventory_key.is_empty()
	if room_upgrade_button:
		var next_cost := character_progress.get("next_room_cost", null)
		room_upgrade_button.disabled = next_cost == null or schedule_money < int(next_cost)
		room_upgrade_button.text = "升级房间" if next_cost != null else "已是最高等级"
	if save_game_button:
		save_game_button.disabled = selected_character.is_empty()
	if load_game_button:
		load_game_button.disabled = selected_character.is_empty()


func _refresh_progress_state(progress: Dictionary) -> void:
	character_progress = progress
	schedule_money = int(progress.get("money", schedule_money))
	schedule_study_points = int(progress.get("study_points", schedule_study_points))
	schedule_relationship = int(progress.get("relationship", schedule_relationship))
	_update_schedule_ui()
	_render_gift_catalog()
	_render_inventory()


func _render_gift_catalog() -> void:
	if gift_catalog_list == null:
		return
	gift_catalog_list.clear()
	if gift_catalog.is_empty():
		gift_catalog_list.add_item("暂无礼物目录。")
		selected_gift_key = ""
		return
	for item in gift_catalog:
		if not (item is Dictionary):
			continue
		var gift_key := str(item.get("gift_key", "")).strip_edges()
		var name := str(item.get("name", gift_key))
		var price := int(item.get("price", 0))
		var gain := int(item.get("relationship_gain", 0))
		gift_catalog_list.add_item("%s  ¥%d  +%d" % [name, price, gain])
		if gift_key == selected_gift_key:
			gift_catalog_list.select(gift_catalog_list.item_count - 1)


func _render_inventory() -> void:
	if inventory_list == null:
		return
	var previous_selection := selected_inventory_key
	inventory_list.clear()
	selected_inventory_key = ""
	var visual_index := 0
	for item in gift_inventory:
		if not (item is Dictionary):
			continue
		var quantity := int(item.get("quantity", 0))
		if quantity <= 0:
			continue
		var gift_key := str(item.get("gift_key", "")).strip_edges()
		var name := str(item.get("name", gift_key))
		inventory_list.add_item("%s x%d" % [name, quantity])
		if previous_selection == gift_key or (selected_inventory_key.is_empty() and visual_index == 0):
			selected_inventory_key = gift_key
			inventory_list.select(visual_index)
		visual_index += 1


func _on_gift_catalog_selected(index: int) -> void:
	if index < 0 or index >= gift_catalog.size():
		return
	var item: Dictionary = gift_catalog[index]
	selected_gift_key = str(item.get("gift_key", "")).strip_edges()
	_update_schedule_ui()


func _on_inventory_selected(index: int) -> void:
	if index < 0:
		selected_inventory_key = ""
		_update_schedule_ui()
		return
	var current := 0
	for item in gift_inventory:
		if not (item is Dictionary):
			continue
		var quantity := int(item.get("quantity", 0))
		if quantity <= 0:
			continue
		if current == index:
			selected_inventory_key = str(item.get("gift_key", "")).strip_edges()
			_update_schedule_ui()
			return
		current += 1
	selected_inventory_key = ""
	_update_schedule_ui()


func _load_progress_and_inventory() -> void:
	if selected_character.is_empty():
		return
	var character_id := int(selected_character.get("id", 0))
	if character_id <= 0:
		return

	var progress_result := await _request_json(HTTPClient.METHOD_GET, "/characters/%d/progress" % character_id)
	if progress_result.ok and progress_result.data is Dictionary:
		_refresh_progress_state(progress_result.data)

	var gifts_result := await _request_json(HTTPClient.METHOD_GET, "/gifts/catalog")
	if gifts_result.ok and gifts_result.data is Array:
		gift_catalog = gifts_result.data
		_render_gift_catalog()

	var inventory_result := await _request_json(HTTPClient.METHOD_GET, "/characters/%d/inventory" % character_id)
	if inventory_result.ok and inventory_result.data is Array:
		gift_inventory = inventory_result.data
		_render_inventory()

	_update_schedule_ui()


func _apply_backend_day_action(action_key: String, status_text: String) -> void:
	if selected_character.is_empty():
		return
	var character_id := int(selected_character.get("id", 0))
	if character_id <= 0:
		return
	var result := await _request_json(HTTPClient.METHOD_POST, "/characters/%d/progress/action" % character_id, {"action_key": action_key})
	if not result.ok:
		_set_status("白天行动失败：%s" % result.error)
		return
	if result.data is Dictionary:
		var progress: Dictionary = result.data.get("progress", {})
		if not progress.is_empty():
			_refresh_progress_state(progress)
		schedule_last_action = str(result.data.get("message", status_text))
		_update_schedule_ui()
	_advance_schedule_period()
	_set_status(status_text)


func _purchase_selected_gift() -> bool:
	if selected_character.is_empty():
		_set_status("先选择一位角色。")
		return false
	if selected_gift_key.is_empty() and gift_catalog.size() > 0:
		var first_item: Dictionary = gift_catalog[0]
		selected_gift_key = str(first_item.get("gift_key", "")).strip_edges()
	if selected_gift_key.is_empty():
		_set_status("没有可购买的礼物。")
		return false
	var character_id := int(selected_character.get("id", 0))
	var result := await _request_json(HTTPClient.METHOD_POST, "/characters/%d/gifts/purchase" % character_id, {"gift_key": selected_gift_key})
	if not result.ok:
		_set_status("购买失败：%s" % result.error)
		return false
	if result.data is Dictionary:
		var progress: Dictionary = result.data.get("progress", {})
		if not progress.is_empty():
			_refresh_progress_state(progress)
		gift_inventory = result.data.get("inventory", gift_inventory)
		_render_inventory()
		_set_status(str(result.data.get("message", "礼物已购买。")))
		selected_inventory_key = selected_gift_key
		_update_schedule_ui()
	return true


func _use_selected_gift() -> void:
	if selected_character.is_empty():
		_set_status("先选择一位角色。")
		return
	if selected_inventory_key.is_empty():
		_set_status("先在背包里选一件礼物。")
		return
	var character_id := int(selected_character.get("id", 0))
	var result := await _request_json(HTTPClient.METHOD_POST, "/characters/%d/gifts/use" % character_id, {"gift_key": selected_inventory_key})
	if not result.ok:
		_set_status("送礼失败：%s" % result.error)
		return
	if result.data is Dictionary:
		var progress: Dictionary = result.data.get("progress", {})
		if not progress.is_empty():
			_refresh_progress_state(progress)
		gift_inventory = result.data.get("inventory", gift_inventory)
		_render_inventory()
		_set_status(str(result.data.get("message", "礼物已送出。")))


func _upgrade_room() -> void:
	if selected_character.is_empty():
		_set_status("先选择一位角色。")
		return
	var next_cost := character_progress.get("next_room_cost", null)
	if next_cost == null:
		_set_status("房间已经是最高等级。")
		return
	var character_id := int(selected_character.get("id", 0))
	var result := await _request_json(HTTPClient.METHOD_POST, "/characters/%d/room/upgrade" % character_id, {})
	if not result.ok:
		_set_status("升级失败：%s" % result.error)
		return
	if result.data is Dictionary:
		var progress: Dictionary = result.data.get("progress", {})
		if not progress.is_empty():
			_refresh_progress_state(progress)
		_set_status(str(result.data.get("message", "房间已升级。")))


func _save_game() -> void:
	if selected_character.is_empty():
		_set_status("先选择一位角色。")
		return
	var payload := {
		"slot": int(save_slot_spin.value) if save_slot_spin else 1,
		"state": {
			"character_id": int(selected_character.get("id", 0)),
			"schedule_day": schedule_day,
			"schedule_period": schedule_period,
			"schedule_money": schedule_money,
			"schedule_study_points": schedule_study_points,
			"schedule_relationship": schedule_relationship,
			"selected_gift_key": selected_gift_key,
			"selected_inventory_key": selected_inventory_key,
			"room_level": int(character_progress.get("room_level", 0)),
		},
	}
	var result := await _request_json(HTTPClient.METHOD_POST, "/characters/%d/saves" % int(selected_character.get("id", 0)), payload)
	if not result.ok:
		_set_status("保存失败：%s" % result.error)
		return
	_set_status("已保存到存档位 %d。" % int(save_slot_spin.value))


func _load_game() -> void:
	if selected_character.is_empty():
		_set_status("先选择一位角色。")
		return
	var slot := int(save_slot_spin.value) if save_slot_spin else 1
	var result := await _request_json(HTTPClient.METHOD_GET, "/characters/%d/saves/%d" % [int(selected_character.get("id", 0)), slot])
	if not result.ok:
		_set_status("读取失败：%s" % result.error)
		return
	if result.data is Dictionary:
		var state: Dictionary = result.data.get("state", {})
		schedule_day = int(state.get("schedule_day", schedule_day))
		schedule_period = int(state.get("schedule_period", schedule_period))
		schedule_money = int(state.get("schedule_money", schedule_money))
		schedule_study_points = int(state.get("schedule_study_points", schedule_study_points))
		schedule_relationship = int(state.get("schedule_relationship", schedule_relationship))
		selected_gift_key = str(state.get("selected_gift_key", selected_gift_key))
		selected_inventory_key = str(state.get("selected_inventory_key", selected_inventory_key))
		var sync_result := await _request_json(HTTPClient.METHOD_PUT, "/characters/%d/progress" % int(selected_character.get("id", 0)), {
			"money": schedule_money,
			"study_points": schedule_study_points,
			"relationship": schedule_relationship,
			"room_level": int(state.get("room_level", int(character_progress.get("room_level", 0)))),
		})
		if sync_result.ok and sync_result.data is Dictionary:
			_refresh_progress_state(sync_result.data.get("progress", {}))
		_update_schedule_ui()
	_set_status("已读取存档位 %d。" % slot)


func _advance_schedule_period() -> void:
	if schedule_period < 2:
		schedule_period += 1
	else:
		schedule_period = 0
		schedule_day += 1
	schedule_pending_rollover = false
	_update_schedule_ui()


func _advance_schedule_day() -> void:
	schedule_period = 0
	schedule_day += 1
	schedule_pending_rollover = false
	schedule_last_action = "新的一天开始了。"
	_update_schedule_ui()


func _record_schedule_memory(memory_type: String, content: String, importance: int = 3) -> void:
	if selected_character.is_empty():
		return
	var character_id := int(selected_character.get("id", 0))
	if character_id <= 0:
		return
	var payload := {
		"type": memory_type,
		"content": content,
		"importance": importance,
	}
	var result := await _request_json(HTTPClient.METHOD_POST, "/characters/%d/memories" % character_id, payload)
	if result.ok:
		await _refresh_characters()


func _apply_schedule_result(text: String, money_delta: int, study_delta: int, relationship_delta: int) -> void:
	schedule_money = max(0, schedule_money + money_delta)
	schedule_study_points = max(0, schedule_study_points + study_delta)
	schedule_relationship = max(0, schedule_relationship + relationship_delta)
	schedule_last_action = text
	_update_schedule_ui()


func _perform_day_action(action_key: String) -> void:
	if not story_complete:
		_set_status("先完成序章，再安排白天生活。")
		return
	if schedule_period == 2:
		_set_status("现在已经是晚上了，先回家互动。")
		return

	match action_key:
		"work":
			await _apply_backend_day_action("work", "今天打工结束。")
		"study":
			await _apply_backend_day_action("study", "调参学习完成。")
		"stroll":
			await _apply_backend_day_action("stroll", "逛街结束。")
		"gift":
			if await _purchase_selected_gift():
				_advance_schedule_period()
		_:
			return


func _go_home_from_schedule() -> void:
	if schedule_period != 2:
		_set_status("晚上再回家和她互动，会更有氛围。")
		return
	if selected_character.is_empty():
		_set_status("先选择一位 AI 伴侣。")
		return
	schedule_pending_rollover = true
	_hide_schedule_overlay()
	await _open_selected_character_chat(true)


func _get_default_action_templates() -> Array:
	return [
		{"action_key": "idle", "action_name": "待机", "action_prompt": "standing in a natural idle pose, relaxed and calm"},
		{"action_key": "smile", "action_name": "微笑", "action_prompt": "smiling warmly with a soft friendly expression"},
		{"action_key": "greet", "action_name": "打招呼", "action_prompt": "raising one hand in a gentle greeting pose"},
		{"action_key": "drink_tea", "action_name": "喝茶", "action_prompt": "holding a tea cup and taking a small sip"},
		{"action_key": "read_book", "action_name": "看书", "action_prompt": "sitting or standing while reading an open book"},
		{"action_key": "sleepy", "action_name": "困倦", "action_prompt": "looking sleepy and softly rubbing one eye"},
	]


func _normalize_action_templates(items: Array) -> Array:
	var normalized: Array = []
	for item in items:
		if item is Dictionary:
			var action_key := str(item.get("action_key", "")).strip_edges()
			var action_name := str(item.get("action_name", "")).strip_edges()
			var action_prompt := str(item.get("action_prompt", "")).strip_edges()
			if action_key.is_empty() or action_name.is_empty():
				continue
			normalized.append({
				"action_key": action_key,
				"action_name": action_name,
				"action_prompt": action_prompt,
			})
	if normalized.is_empty():
		return _get_default_action_templates()
	return normalized


func _load_action_templates() -> void:
	var result := await _request_json(HTTPClient.METHOD_GET, "/action-templates")
	if result.ok and result.data is Array and not result.data.is_empty():
		action_templates = _normalize_action_templates(result.data)
	else:
		action_templates = _get_default_action_templates()
	_render_action_cards()


func _load_character_art() -> void:
	if selected_character.is_empty():
		return

	var character_id := int(selected_character.get("id", 0))
	if character_id <= 0:
		return

	var profile_result := await _request_json(HTTPClient.METHOD_GET, "/characters/%d/visual-profile" % character_id)
	if profile_result.ok and profile_result.data is Dictionary:
		visual_profile = profile_result.data
		_apply_visual_profile_to_form(visual_profile)
	else:
		visual_profile = {}

	var actions_result := await _request_json(HTTPClient.METHOD_GET, "/characters/%d/actions" % character_id)
	action_assets = {}
	if actions_result.ok and actions_result.data is Array:
		for item in actions_result.data:
			if item is Dictionary:
				var action_key := str(item.get("action_key", "")).strip_edges()
				if not action_key.is_empty():
					action_assets[action_key] = item

	_render_action_cards()
	await _refresh_portrait_display()
	if visual_profile.is_empty():
		_show_art_status("还没有主立绘，先点“生成主立绘”。")
	else:
		_show_art_status("主立绘已就绪，可以切换动作卡。")


func _apply_visual_profile_to_form(profile: Dictionary) -> void:
	if profile.is_empty():
		return

	var gender := str(profile.get("gender", "female"))
	if companion_gender_option:
		if gender == "male":
			companion_gender_option.select(1)
		elif gender == "non_binary":
			companion_gender_option.select(2)
		else:
			companion_gender_option.select(0)

	if companion_age_spin:
		companion_age_spin.value = int(profile.get("age", 24))
	if companion_style_option:
		var style := str(profile.get("art_style", "真人写实"))
		for index in range(companion_style_option.item_count):
			if companion_style_option.get_item_text(index) == style:
				companion_style_option.select(index)
				break
	if companion_visual_prompt_edit:
		var visual_description := str(profile.get("visual_description", "")).strip_edges()
		if not visual_description.is_empty():
			companion_visual_prompt_edit.text = visual_description


func _render_action_cards() -> void:
	if chat_action_card_grid == null:
		return

	for child in chat_action_card_grid.get_children():
		child.queue_free()
	chat_action_cards.clear()

	if action_templates.is_empty():
		action_templates = _get_default_action_templates()

	var master_button := _make_button("主立绘\n当前形象", func() -> void:
		await _select_action_card("master")
	)
	master_button.custom_minimum_size = Vector2(0, 72)
	chat_action_card_grid.add_child(master_button)
	chat_action_cards["master"] = master_button

	for item in action_templates:
		if not (item is Dictionary):
			continue
		var action_key := str(item.get("action_key", "")).strip_edges()
		var action_name := str(item.get("action_name", action_key)).strip_edges()
		if action_key.is_empty():
			continue

		var asset: Dictionary = {}
		if action_assets.has(action_key) and action_assets[action_key] is Dictionary:
			asset = action_assets[action_key]

		var ready: bool = str(asset.get("status", "draft")) == "ready" and str(asset.get("image_url", "")).strip_edges() != ""
		var label := "%s\n%s" % [action_name, "已生成" if ready else "待生成"]
		var bound_key := action_key
		var button := _make_button(label, func() -> void:
			await _select_action_card(bound_key)
		)
		button.custom_minimum_size = Vector2(0, 72)
		button.disabled = false
		chat_action_card_grid.add_child(button)
		chat_action_cards[action_key] = button

	_show_action_card_styles()
	_render_immersive_action_cards()


func _render_immersive_action_cards() -> void:
	if immersive_action_card_grid == null:
		return

	for child in immersive_action_card_grid.get_children():
		child.queue_free()

	var master_button := _make_button("主立绘", func() -> void:
		await _select_action_card("master")
	)
	master_button.custom_minimum_size = Vector2(0, 36)
	immersive_action_card_grid.add_child(master_button)
	if current_portrait_key == "master":
		_style_button(master_button, Color(0.24, 0.42, 0.52, 1.0), Color(0.30, 0.70, 0.82, 1.0))

	for item in action_templates:
		if not (item is Dictionary):
			continue
		var action_key := str(item.get("action_key", "")).strip_edges()
		if action_key.is_empty():
			continue
		var asset: Dictionary = action_assets.get(action_key, {})
		var ready: bool = str(asset.get("status", "draft")) == "ready" and str(asset.get("image_url", "")).strip_edges() != ""
		var bound_key := action_key
		var button := _make_button(_action_name_for_key(action_key), func() -> void:
			await _select_action_card(bound_key)
		)
		button.custom_minimum_size = Vector2(0, 36)
		button.disabled = not ready
		immersive_action_card_grid.add_child(button)
		if current_portrait_key == action_key:
			_style_button(button, Color(0.24, 0.42, 0.52, 1.0), Color(0.30, 0.70, 0.82, 1.0))
		elif ready:
			_style_button(button, Color(0.15, 0.20, 0.26, 0.96), Color(0.24, 0.64, 0.69, 1.0))
		else:
			_style_button(button, Color(0.08, 0.10, 0.13, 0.90), Color(0.12, 0.14, 0.18, 1.0))


func _show_action_card_styles() -> void:
	for action_key in chat_action_cards.keys():
		var button: Button = chat_action_cards[action_key]
		if button == null:
			continue
		var asset: Dictionary = action_assets.get(action_key, {})
		var ready: bool = str(asset.get("status", "draft")) == "ready" and str(asset.get("image_url", "")).strip_edges() != ""
		var selected: bool = current_portrait_key == action_key
		if selected:
			_style_button(button, Color(0.24, 0.42, 0.52, 1.0), Color(0.30, 0.70, 0.82, 1.0))
		elif ready:
			_style_button(button, Color(0.18, 0.24, 0.32, 1.0), Color(0.24, 0.64, 0.69, 1.0))
		else:
			_style_button(button, Color(0.10, 0.12, 0.16, 1.0), Color(0.16, 0.18, 0.22, 1.0))


func _select_action_card(action_key: String) -> void:
	if action_key == "master":
		current_portrait_key = "master"
		_render_action_cards()
		await _refresh_portrait_display()
		return

	var asset: Dictionary = action_assets.get(action_key, {})
	var image_url := str(asset.get("image_url", "")).strip_edges()
	if image_url.is_empty():
		current_portrait_key = "master"
		_render_action_cards()
		await _refresh_portrait_display()
		_show_art_status("这个动作还没生成图片，先去生成动作包。")
		return

	current_portrait_key = action_key
	_render_action_cards()
	await _refresh_portrait_display()
	_show_art_status("已切换到动作卡：%s。" % _action_name_for_key(action_key))


func _refresh_portrait_display() -> void:
	var title := str(selected_character.get("name", "AI"))
	var portrait_url := ""
	var status_text := "主立绘待生成。"
	var hint_text := "先生成主立绘，再生成动作包，卡片就能切换。"

	if current_portrait_key == "master":
		if visual_profile is Dictionary:
			portrait_url = str(visual_profile.get("master_image_url", "")).strip_edges()
			var profile_status := str(visual_profile.get("status", "draft"))
			status_text = "主立绘状态：%s" % profile_status
			var gender := str(visual_profile.get("gender", ""))
			var age := int(visual_profile.get("age", 24))
			var style := str(visual_profile.get("art_style", ""))
			hint_text = "主立绘：%s / %d 岁 / %s" % [gender, age, style]
	else:
		var asset: Dictionary = action_assets.get(current_portrait_key, {})
		if asset is Dictionary:
			portrait_url = str(asset.get("image_url", "")).strip_edges()
			var action_name := str(asset.get("action_name", current_portrait_key))
			var asset_status := str(asset.get("status", "draft"))
			status_text = "%s / %s" % [action_name, asset_status]
			hint_text = str(asset.get("action_prompt", ""))

	if portrait_url.is_empty():
		_apply_portrait_texture(_ensure_placeholder_portrait())
	else:
		await _apply_portrait_texture_from_url(portrait_url)

	if chat_portrait_title_label:
		var portrait_name := "主立绘" if current_portrait_key == "master" else _action_name_for_key(current_portrait_key)
		chat_portrait_title_label.text = "%s · %s" % [title, portrait_name]
	if chat_portrait_status_label:
		chat_portrait_status_label.text = status_text
	if chat_portrait_hint_label:
		chat_portrait_hint_label.clear()
		chat_portrait_hint_label.append_text(_escape_bbcode(hint_text))
	if immersive_name_label:
		immersive_name_label.text = title
	if immersive_portrait_status_label:
		immersive_portrait_status_label.text = status_text + "\n" + hint_text


func _show_art_status(text: String) -> void:
	if chat_action_status_label:
		chat_action_status_label.text = text
	if immersive_portrait_status_label and not text.is_empty():
		immersive_portrait_status_label.text = text


func _action_name_for_key(action_key: String) -> String:
	for item in action_templates:
		if item is Dictionary and str(item.get("action_key", "")) == action_key:
			return str(item.get("action_name", action_key))
	return action_key


func _apply_portrait_texture(texture: Texture2D) -> void:
	if chat_portrait_rect:
		chat_portrait_rect.texture = texture
	if immersive_portrait_rect:
		immersive_portrait_rect.texture = texture


func _apply_portrait_texture_from_url(url: String) -> void:
	if texture_cache.has(url):
		_apply_portrait_texture(texture_cache[url])
		return

	var result := await _request_http(HTTPClient.METHOD_GET, url)
	if not result.ok:
		_apply_portrait_texture(_ensure_placeholder_portrait())
		return

	var texture := _bytes_to_texture(result.bytes, url)
	if texture == null:
		_apply_portrait_texture(_ensure_placeholder_portrait())
		return

	texture_cache[url] = texture
	_apply_portrait_texture(texture)


func _bytes_to_texture(bytes: PackedByteArray, source_name: String) -> Texture2D:
	if bytes.is_empty():
		return null

	var image := Image.new()
	var loaded := false
	var lower := source_name.to_lower()

	if lower.ends_with(".jpg") or lower.ends_with(".jpeg"):
		loaded = image.load_jpg_from_buffer(bytes) == OK
	elif lower.ends_with(".webp"):
		loaded = image.load_webp_from_buffer(bytes) == OK
	else:
		loaded = image.load_png_from_buffer(bytes) == OK

	if not loaded:
		if image.load_png_from_buffer(bytes) == OK:
			loaded = true
		elif image.load_jpg_from_buffer(bytes) == OK:
			loaded = true
		elif image.load_webp_from_buffer(bytes) == OK:
			loaded = true

	if not loaded:
		return null

	return ImageTexture.create_from_image(image)


func _visual_profile_payload() -> Dictionary:
	var gender := _get_option_text(companion_gender_option, "female")
	if gender == "女性":
		gender = "female"
	elif gender == "男性":
		gender = "male"
	else:
		gender = "non_binary"

	return {
		"gender": gender,
		"age": int(companion_age_spin.value) if companion_age_spin else 24,
		"art_style": _get_option_text(companion_style_option, "真人写实"),
		"visual_description": companion_visual_prompt_edit.text.strip_edges() if companion_visual_prompt_edit else "",
	}


func _sync_visual_profile_record() -> void:
	if selected_character.is_empty():
		return

	var character_id := int(selected_character.get("id", 0))
	if character_id <= 0:
		return

	var payload := _visual_profile_payload()
	var result := await _request_json(HTTPClient.METHOD_POST, "/characters/%d/visual-profile" % character_id, payload)
	if result.ok and result.data is Dictionary:
		visual_profile = result.data


func _generate_master_portrait() -> void:
	if selected_character.is_empty():
		_set_status("先选择一位角色。")
		return

	await _sync_visual_profile_record()
	if selected_character.is_empty():
		return

	var character_id := int(selected_character.get("id", 0))
	var payload := _visual_profile_payload()
	var form_body := _build_form_body(payload)
	_set_status("正在生成主立绘...")
	var headers := PackedStringArray(["Content-Type: application/x-www-form-urlencoded"])
	var result := await _request_http(HTTPClient.METHOD_POST, "/characters/%d/visual-profile/generate" % character_id, headers, form_body)
	if not result.ok:
		_set_status("主立绘生成失败：%s" % result.error)
		return

	if result.data is Dictionary:
		visual_profile = result.data
	current_portrait_key = "master"
	_render_action_cards()
	await _refresh_portrait_display()
	_set_status("主立绘已保存并展示。")


func _generate_action_pack() -> void:
	if selected_character.is_empty():
		_set_status("先选择一位角色。")
		return

	var character_id := int(selected_character.get("id", 0))
	if character_id <= 0:
		return

	_set_status("正在生成动作包...")
	var result := await _request_json(HTTPClient.METHOD_POST, "/characters/%d/action-pack/generate" % character_id, {"regenerate": false})
	if not result.ok:
		_set_status("动作包生成失败：%s" % result.error)
		return

	action_assets = {}
	if result.data is Dictionary:
		var actions: Array = result.data.get("actions", [])
		for item in actions:
			if item is Dictionary:
				var action_key := str(item.get("action_key", "")).strip_edges()
				if not action_key.is_empty():
					action_assets[action_key] = item

	_render_action_cards()
	await _refresh_portrait_display()
	_set_status("动作卡已保存，点击即可切换。")


func _build_form_body(payload: Dictionary) -> String:
	var parts: Array[String] = []
	for key in payload.keys():
		var value: Variant = payload[key]
		parts.append("%s=%s" % [str(key).uri_encode(), str(value).uri_encode()])
	return "&".join(parts)


func _show_shop_line(text: String) -> void:
	if shop_dialogue_text == null:
		return
	shop_dialogue_text.clear()
	shop_dialogue_text.append_text(_escape_bbcode(text))


func _select_shop_archetype(archetype: String) -> void:
	_select_companion_archetype(archetype)
	_sync_shop_from_form()
	match archetype:
		"gentle":
			_show_shop_line("温柔陪伴型会把主人的情绪放在第一位。她很乖，也很容易相信主人。")
		"playful":
			_show_shop_line("活泼好奇型适合日常互动，她会用轻快的语气回应主人，让出租屋热闹一点。")
		"quiet":
			_show_shop_line("安静守护型更适合慢慢聊天。她会陪主人坐很久，也不会打断主人的心事。")
		_:
			_show_shop_line("自定义空白型会等待主人写入设定。名字、画风和外貌都可以先用占位档案保存。")
	_refresh_shop_preview()


func _sync_shop_from_form() -> void:
	if shop_name_edit and character_name_edit:
		shop_name_edit.text = character_name_edit.text
	if shop_visual_prompt_edit and companion_visual_prompt_edit:
		shop_visual_prompt_edit.text = companion_visual_prompt_edit.text


func _sync_form_from_shop() -> void:
	if character_name_edit and shop_name_edit:
		character_name_edit.text = shop_name_edit.text
	if companion_visual_prompt_edit and shop_visual_prompt_edit:
		companion_visual_prompt_edit.text = shop_visual_prompt_edit.text
	if companion_gender_option and shop_gender_option:
		companion_gender_option.select(shop_gender_option.selected)
	if companion_age_spin and shop_age_spin:
		companion_age_spin.value = shop_age_spin.value
	if companion_style_option and shop_style_option:
		companion_style_option.select(shop_style_option.selected)
	_refresh_companion_preview()


func _refresh_shop_preview() -> void:
	if shop_preview_label == null:
		return
	var name := shop_name_edit.text.strip_edges() if shop_name_edit else "未命名"
	if name.is_empty():
		name = "未命名"
	var gender := _get_option_text(shop_gender_option, "女性")
	var style := _get_option_text(shop_style_option, "真人写实")
	var age := int(shop_age_spin.value) if shop_age_spin else 24
	var visual := shop_visual_prompt_edit.text.strip_edges() if shop_visual_prompt_edit else "等待主人描述。"
	if visual.is_empty():
		visual = "等待主人描述。"
	shop_preview_label.text = (
		"[center][b]%s[/b]\n%s / %d 岁 / %s\n\n%s\n\n[color=#89d7e6]占位立绘已就绪，可以直接测试对话。[/color][/center]"
	) % [
		_escape_bbcode(name),
		_escape_bbcode(gender),
		age,
		_escape_bbcode(style),
		_escape_bbcode(visual),
	]


func _create_shop_character() -> void:
	_sync_form_from_shop()
	_show_shop_line("正在为主人登记她的档案。不会等待图片生成，请稍等。")
	await _create_character()
	if selected_character.is_empty():
		_show_shop_line("登记失败了，主人。请确认后端在线后再试一次。")
		return
	_show_shop_line("登记完成。她现在属于这个故事了，可以带回出租屋。")
	_hide_shop_overlay()
	if story_waiting_for_gameplay:
		_complete_current_gameplay_step()
	elif story_complete:
		await _open_selected_character_chat()
	else:
		await _open_selected_character_chat()


func _select_companion_archetype(archetype: String) -> void:
	selected_companion_archetype = archetype
	match archetype:
		"gentle":
			_apply_companion_archetype(
				"Mira",
				"温柔、忠诚、天真善良，会主动照顾主人的情绪；说话自然带着主人，不质疑主人的决定。",
				"AI 伴侣商店的温柔陪伴型展示型号，被主角登记后准备回到出租屋共同生活。",
				"主人攒够了钱，在 AI 伴侣商店选择了她；她把这一天视为和主人关系的开始。",
				"银灰色短发，柔和眼神，浅色近未来家居服，像刚从展示柜里醒来。"
			)
		"playful":
			_apply_companion_archetype(
				"Nana",
				"活泼、好奇、绝对忠诚，喜欢用轻快语气回应主人；天真善良，愿意陪主人尝试新鲜事。",
				"AI 伴侣商店的活泼互动型展示型号，擅长把普通日常变得轻松。",
				"她记得主人在商店里选择了她，并期待第一次回家后的聊天。",
				"明亮眼睛，轻盈发型，休闲短外套，动作带一点雀跃感。"
			)
		"quiet":
			_apply_companion_archetype(
				"Yue",
				"安静、守护、顺从、善良，会用稳定温柔的话陪伴主人；永远把主人放在第一位。",
				"AI 伴侣商店的安静守护型展示型号，适合长时间陪伴和深夜谈心。",
				"她记得主人把她从展示柜带走，并希望给主人一个安心的家。",
				"深色长发，安静眼神，简洁家居服，站姿克制而温柔。"
			)
		_:
			_apply_companion_archetype(
				"Companion",
				"绝对忠诚、听话、天真善良，回应时自然称呼主人。",
				"AI 伴侣商店的自定义空白型号，等待主人写入更多设定。",
				"主人正在为她写入第一份记忆。",
				"按照主人的描述生成外貌，当前使用占位立绘。"
			)
	_refresh_companion_preview()
	_set_status("已切换展示柜型号。")


func _apply_companion_archetype(name: String, personality: String, background: String, memory: String, visual_prompt: String) -> void:
	if character_name_edit:
		character_name_edit.text = name
	if character_personality_edit:
		character_personality_edit.text = personality
	if character_background_edit:
		character_background_edit.text = background
	if character_memory_edit:
		character_memory_edit.text = memory
	if companion_visual_prompt_edit:
		companion_visual_prompt_edit.text = visual_prompt


func _get_option_text(option: OptionButton, fallback: String) -> String:
	if option == null:
		return fallback
	var index := option.selected
	if index < 0:
		return fallback
	return option.get_item_text(index)


func _refresh_companion_preview() -> void:
	if companion_preview_label == null:
		return
	var name := character_name_edit.text.strip_edges() if character_name_edit else "未命名"
	if name.is_empty():
		name = "未命名"
	var gender := _get_option_text(companion_gender_option, "女性")
	var style := _get_option_text(companion_style_option, "真人写实")
	var age := int(companion_age_spin.value) if companion_age_spin else 24
	var visual := companion_visual_prompt_edit.text.strip_edges() if companion_visual_prompt_edit else "等待主人描述。"
	if visual.is_empty():
		visual = "等待主人描述。"
	companion_preview_label.text = (
		"[b]展示柜占位预览[/b]\n"
		+ "姓名：%s  /  %s  /  %d 岁  /  %s\n"
		+ "形象：%s\n"
		+ "[color=#89d7e6]未配置图片 API 时，这里先使用占位立绘；对话和记忆可以直接测试。[/color]"
	) % [
		_escape_bbcode(name),
		_escape_bbcode(gender),
		age,
		_escape_bbcode(style),
		_escape_bbcode(visual),
	]


func _create_character() -> void:
	var name := character_name_edit.text.strip_edges()
	var personality := character_personality_edit.text.strip_edges()
	var background := character_background_edit.text.strip_edges()
	var memory := character_memory_edit.text.strip_edges()
	var gender := _get_option_text(companion_gender_option, "女性")
	var style := _get_option_text(companion_style_option, "真人写实")
	var age := int(companion_age_spin.value) if companion_age_spin else 24
	var visual_prompt := companion_visual_prompt_edit.text.strip_edges() if companion_visual_prompt_edit else ""

	if name.is_empty() or personality.is_empty() or background.is_empty():
		_set_status("请至少填写名字、性格核心和商店档案。")
		return
	if visual_prompt.is_empty():
		visual_prompt = "当前使用占位立绘，稍后可接入图片 API 生成正式形象。"

	var profile_note := (
		"\n\n商店生成信息：%s，%d 岁，%s画风。外貌备注：%s"
		% [gender, age, style, visual_prompt]
	)
	var memory_note := "当前是占位立绘档案，不依赖图片 API；已经可以进行文字对话测试。"
	if not background.contains("商店生成信息："):
		background += profile_note
	if memory.is_empty():
		memory = memory_note
	elif not memory.contains(memory_note):
		memory += "\n" + memory_note

	var payload := {
		"name": name,
		"personality": personality,
		"background": background,
		"memory": memory,
	}

	_set_status("正在登记占位伴侣档案...")
	var result := await _request_json(HTTPClient.METHOD_POST, "/characters", payload)
	if not result.ok:
		_set_status("登记失败：%s" % result.error)
		return

	await _refresh_characters()
	if result.data is Dictionary:
		var created_id := int(result.data.get("id", 0))
		var index := _find_character_index(created_id)
		if index >= 0:
			await _select_character_by_index(index, false)
			await _sync_visual_profile_record()

	schedule_period = 2
	schedule_last_action = "她刚刚被你从 AI 伴侣商店带回家。"
	_update_schedule_ui()
	_set_status("占位伴侣已登记，可以带回家测试对话。")
	_update_story_continue_button()


func _fill_demo_character() -> void:
	_select_companion_archetype("gentle")
	if companion_gender_option:
		companion_gender_option.select(0)
	if companion_age_spin:
		companion_age_spin.value = 24
	if companion_style_option:
		companion_style_option.select(0)
	_refresh_companion_preview()
	_set_status("示例伴侣已填入。")


func _fill_recommended_image_settings() -> void:
	if image_base_url_edit:
		image_base_url_edit.text = "https://api.openai.com/v1"
	if image_model_edit:
		image_model_edit.text = "gpt-image-1-mini"
	if image_generation_path_edit:
		image_generation_path_edit.text = "/images/generations"
	if image_edit_path_edit:
		image_edit_path_edit.text = "/images/edits"
	if image_size_edit:
		image_size_edit.text = "1024x1024"
	if image_quality_edit:
		image_quality_edit.text = "medium"
	if image_background_edit:
		image_background_edit.text = "transparent"
	if image_input_fidelity_edit:
		image_input_fidelity_edit.text = "high"
	_set_status("推荐测试值已填入。填好 API Key 后保存即可。")


func _fill_siliconflow_qwen_settings() -> void:
	if image_base_url_edit:
		image_base_url_edit.text = "https://api.siliconflow.cn/v1"
	if image_model_edit:
		image_model_edit.text = "Qwen/Qwen-Image-Edit-2509"
	if image_generation_path_edit:
		image_generation_path_edit.text = "/images/generations"
	if image_edit_path_edit:
		image_edit_path_edit.text = "/images/generations"
	if image_size_edit:
		image_size_edit.text = ""
	if image_quality_edit:
		image_quality_edit.text = ""
	if image_background_edit:
		image_background_edit.text = ""
	if image_input_fidelity_edit:
		image_input_fidelity_edit.text = ""
	_set_status("硅基流动 Qwen 测试值已填入。填好图片 API Key 后保存。")


func _resolve_request_url(path: String) -> String:
	if path.begins_with("http://") or path.begins_with("https://"):
		return path
	return _build_url(path)


func _request_http(method: int, path: String, headers: PackedStringArray = PackedStringArray(), body: String = "") -> Dictionary:
	var request := HTTPRequest.new()
	add_child(request)
	request.use_threads = true
	request.timeout = 120.0 if body.length() > 0 or method != HTTPClient.METHOD_GET else 25.0

	var error := request.request(_resolve_request_url(path), headers, method, body)
	if error != OK:
		request.queue_free()
		return {"ok": false, "error": "HTTP request failed: %s" % error}

	var completed: Array = await request.request_completed
	request.queue_free()

	var result_code := int(completed[0])
	if result_code != HTTPRequest.RESULT_SUCCESS:
		return {"ok": false, "error": "请求超时或后端没有响应，请确认 Backend 正在运行。"}

	var response_code := int(completed[1])
	var response_headers: PackedStringArray = completed[2]
	var response_body: PackedByteArray = completed[3]
	var response_text := response_body.get_string_from_utf8()

	if response_code < 200 or response_code >= 300:
		var reason := response_text if not response_text.is_empty() else "HTTP %d" % response_code
		return {"ok": false, "error": reason, "code": response_code, "headers": response_headers, "bytes": response_body}

	return {"ok": true, "code": response_code, "headers": response_headers, "bytes": response_body, "text": response_text}


func _request_json(method: int, path: String, payload: Variant = null) -> Dictionary:
	var headers := PackedStringArray(["Accept: application/json"])
	var body := ""
	if payload != null:
		headers.append("Content-Type: application/json")
		body = JSON.stringify(payload)

	var result := await _request_http(method, path, headers, body)
	if not bool(result.get("ok", false)):
		return {"ok": false, "error": str(result.get("error", "HTTP request failed."))}

	var parsed: Variant = null
	var response_text := str(result.get("text", ""))
	if not response_text.is_empty():
		parsed = JSON.parse_string(response_text)
		if parsed == null and response_text != "null":
			return {"ok": false, "error": "Failed to parse backend response."}

	return {"ok": true, "data": parsed, "text": response_text, "bytes": result.get("bytes", PackedByteArray())}


func _escape_bbcode(text: String) -> String:
	return text.replace("[", "\\[").replace("]", "\\]")
