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
var backend_url_edit: LineEdit
var connect_button: Button
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
var tab_container: TabContainer
var menu_home_button: Button
var menu_chat_button: Button
var menu_settings_button: Button
var menu_continue_story_button: Button
var character_count_label: Label
var chat_tab_index: int = 0
var home_tab_index: int = 0
var settings_tab_index: int = 0
var story_waiting_for_gameplay: bool = false


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
		_show_page(home_tab_index)
	)
	sidebar_box.add_child(menu_home_button)

	menu_chat_button = _make_menu_button("进入对话", func() -> void:
		await _open_selected_character_chat()
	)
	menu_chat_button.disabled = true
	sidebar_box.add_child(menu_chat_button)

	menu_settings_button = _make_menu_button("API 设置", func() -> void:
		_show_page(settings_tab_index)
	)
	sidebar_box.add_child(menu_settings_button)

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
	hero_copy.text = "主角攒够了钱，来到店里挑选属于自己的 AI 伴侣。先创建一个角色，再进入对话。"
	hero_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hero_copy.add_theme_font_size_override("font_size", 16)
	hero_copy.add_theme_color_override("font_color", Color(0.75, 0.82, 0.88, 1.0))
	hero_box.add_child(hero_copy)

	var split := HSplitContainer.new()
	split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.split_offset = 470
	parent.add_child(split)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 12)
	split.add_child(left)

	var backend_card := _make_card(left, "商店终端")
	backend_card.custom_minimum_size.y = 110
	backend_card.add_child(_make_help_text("确认后端在线后，就可以读取角色、保存 API 设置和进入聊天。"))

	var create_card := _make_card(left, "新建 AI 伴侣")
	character_name_edit = _make_line_edit("名字", "Mira")
	create_card.add_child(character_name_edit)
	character_personality_edit = _make_text_edit("性格", "warm, curious, playful")
	character_personality_edit.custom_minimum_size.y = 72
	create_card.add_child(character_personality_edit)
	character_background_edit = _make_text_edit("背景", "A virtual guide from a near-future city.")
	character_background_edit.custom_minimum_size.y = 88
	create_card.add_child(character_background_edit)
	character_memory_edit = _make_text_edit("初始记忆", "The user is building an AI character demo.")
	character_memory_edit.custom_minimum_size.y = 72
	create_card.add_child(character_memory_edit)

	var create_row := HBoxContainer.new()
	create_row.add_theme_constant_override("separation", 10)
	create_card.add_child(create_row)

	var create_button := _make_button("生成档案", func() -> void:
		await _create_character()
	)
	create_row.add_child(create_button)

	var demo_button := _make_button("示例填充", func() -> void:
		_fill_demo_character()
	)
	create_row.add_child(demo_button)

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

	var text_card := _make_card(split, "DeepSeek Text")
	deepseek_key_edit = _make_line_edit("API Key (blank keeps current)", "")
	deepseek_key_edit.secret = true
	text_card.add_child(deepseek_key_edit)
	deepseek_base_url_edit = _make_line_edit("Base URL", "https://api.deepseek.com")
	text_card.add_child(deepseek_base_url_edit)
	deepseek_model_edit = _make_line_edit("Model", "deepseek-v4-pro")
	text_card.add_child(deepseek_model_edit)
	deepseek_temperature_edit = _make_line_edit("Temperature", "0.7")
	text_card.add_child(deepseek_temperature_edit)
	deepseek_max_tokens_edit = _make_line_edit("Max Tokens", "1024")
	text_card.add_child(deepseek_max_tokens_edit)
	deepseek_reasoning_edit = _make_line_edit("Reasoning Effort", "medium")
	text_card.add_child(deepseek_reasoning_edit)

	var image_card := _make_card(split, "Image API")
	image_key_edit = _make_line_edit("API Key (blank keeps current)", "")
	image_key_edit.secret = true
	image_card.add_child(image_key_edit)
	image_base_url_edit = _make_line_edit("Base URL", "https://api.openai.com/v1")
	image_card.add_child(image_base_url_edit)
	image_model_edit = _make_line_edit("Model", "gpt-image-1")
	image_card.add_child(image_model_edit)
	image_generation_path_edit = _make_line_edit("Generation Path", "/images/generations")
	image_card.add_child(image_generation_path_edit)
	image_edit_path_edit = _make_line_edit("Edit Path", "/images/edits")
	image_card.add_child(image_edit_path_edit)
	image_size_edit = _make_line_edit("Size", "1024x1024")
	image_card.add_child(image_size_edit)
	image_quality_edit = _make_line_edit("Quality", "medium")
	image_card.add_child(image_quality_edit)
	image_background_edit = _make_line_edit("Background", "transparent")
	image_card.add_child(image_background_edit)
	image_input_fidelity_edit = _make_line_edit("Input Fidelity", "high")
	image_card.add_child(image_input_fidelity_edit)

	var save_button := _make_button("Save Settings", func() -> void:
		await _save_provider_settings()
	)
	image_card.add_child(save_button)

	var reload_button := _make_button("Reload Settings", func() -> void:
		await _load_provider_settings()
	)
	image_card.add_child(reload_button)

	var guide_card := _make_card(parent, "API 新手说明")
	guide_card.custom_minimum_size.y = 200
	guide_card.add_child(_make_help_text("API Key 就像门票，填进去才能让游戏调用你自己的 AI 服务。"))
	guide_card.add_child(_make_help_text("Base URL 是服务地址；Model 是你想用的模型名字。"))
	guide_card.add_child(_make_help_text("推荐测试图像模型先用 gpt-image-1-mini，省钱；正式质量可以切到 gpt-image-1。"))
	guide_card.add_child(_make_help_text("你可以先不填 Key，用后端的开发模式跑通流程，再换成真实 API。"))

	var guide_buttons := HBoxContainer.new()
	guide_buttons.add_theme_constant_override("separation", 10)
	guide_card.add_child(guide_buttons)

	var fill_recommended_button := _make_button("填入推荐测试值", func() -> void:
		_fill_recommended_image_settings()
	)
	guide_buttons.add_child(fill_recommended_button)


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

	var memory_card := _make_card(body, "Memories")
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
	_show_page(chat_tab_index)
	_set_status("已回到出租屋，可以开始互动。")


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
	_show_page(home_tab_index)
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
		_show_page(home_tab_index)
	elif focus == "settings":
		_show_page(settings_tab_index)
	elif focus == "chat":
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


func _show_page(index: int) -> void:
	if tab_container == null:
		return
	tab_container.current_tab = clamp(index, 0, tab_container.get_tab_count() - 1)


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


func _open_selected_character_chat() -> void:
	if selected_character.is_empty():
		_set_status("Choose a character first.")
		return

	var character_id := int(selected_character.get("id", 0))
	_set_status("Loading character chat...")

	var character_result := await _request_json(HTTPClient.METHOD_GET, "/characters/%d" % character_id)
	if not character_result.ok:
		_set_status("Load character failed: %s" % character_result.error)
		return

	selected_character = character_result.data if character_result.data is Dictionary else selected_character
	_render_selected_character()

	var messages_result := await _request_json(HTTPClient.METHOD_GET, "/characters/%d/messages?limit=100" % character_id)
	var memories_result := await _request_json(HTTPClient.METHOD_GET, "/characters/%d/memories?limit=50" % character_id)
	if not messages_result.ok:
		_set_status("Load messages failed: %s" % messages_result.error)
		return
	if not memories_result.ok:
		_set_status("Load memories failed: %s" % memories_result.error)
		return

	_render_memories(memories_result.data if memories_result.data is Array else [])
	_render_messages(messages_result.data if messages_result.data is Array else [])
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


func _create_character() -> void:
	var name := character_name_edit.text.strip_edges()
	var personality := character_personality_edit.text.strip_edges()
	var background := character_background_edit.text.strip_edges()
	var memory := character_memory_edit.text.strip_edges()

	if name.is_empty() or personality.is_empty() or background.is_empty():
		_set_status("Name, personality, and background are required.")
		return

	var payload := {
		"name": name,
		"personality": personality,
		"background": background,
		"memory": memory,
	}

	_set_status("Creating character...")
	var result := await _request_json(HTTPClient.METHOD_POST, "/characters", payload)
	if not result.ok:
		_set_status("Create failed: %s" % result.error)
		return

	await _refresh_characters()
	if result.data is Dictionary:
		var created_id := int(result.data.get("id", 0))
		var index := _find_character_index(created_id)
		if index >= 0:
			await _select_character_by_index(index, false)

	_set_status("Character created.")
	_update_story_continue_button()


func _fill_demo_character() -> void:
	character_name_edit.text = "Mira"
	character_personality_edit.text = "warm, curious, playful"
	character_background_edit.text = "A virtual guide from a near-future city."
	character_memory_edit.text = "The user is building an AI character demo."
	_set_status("Demo form filled.")


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


func _request_json(method: int, path: String, payload: Variant = null) -> Dictionary:
	var request := HTTPRequest.new()
	add_child(request)
	request.use_threads = true

	var headers := PackedStringArray(["Accept: application/json"])
	var body := ""
	if payload != null:
		headers.append("Content-Type: application/json")
		body = JSON.stringify(payload)

	var error := request.request(_build_url(path), headers, method, body)
	if error != OK:
		request.queue_free()
		return {"ok": false, "error": "HTTP request failed: %s" % error}

	var completed: Array = await request.request_completed
	request.queue_free()

	var response_code := int(completed[1])
	var response_body: PackedByteArray = completed[3]
	var response_text := response_body.get_string_from_utf8()

	if response_code < 200 or response_code >= 300:
		var reason := response_text if not response_text.is_empty() else "HTTP %d" % response_code
		return {"ok": false, "error": reason}

	var parsed: Variant = null
	if not response_text.is_empty():
		parsed = JSON.parse_string(response_text)
		if parsed == null and response_text != "null":
			return {"ok": false, "error": "Failed to parse backend response."}

	return {"ok": true, "data": parsed, "text": response_text}


func _escape_bbcode(text: String) -> String:
	return text.replace("[", "\\[").replace("]", "\\]")
