extends Control

const ROWS := 4
const COLS := 4
const BOARD_VIEW_SCRIPT = preload("res://scripts/board_view.gd")
const SOUND_ENGINE_SCRIPT = preload("res://scripts/sound_engine.gd")
const AI_PLAYER_SCRIPT = preload("res://scripts/ai_player.gd")
const GAME_FONT = preload("res://assets/NotoSansSCGameV10.ttf")
const UI_BACKGROUND = preload("res://assets/generated_ui_background.png")
const BUTTON_PANEL_PAPER = preload("res://assets/generated_panel_paper.png")
const BUTTON_PANEL_JADE = preload("res://assets/generated_panel_jade.png")
const BUTTON_PANEL_CINNABAR = preload("res://assets/generated_panel_cinnabar.png")
const BUTTON_PANEL_ICON = preload("res://assets/generated_panel_jade.png")
const ICON_MUSIC = preload("res://assets/icons/generated_music.png")
const ICON_SETTINGS = preload("res://assets/icons/generated_settings.png")
const ICON_RULES = preload("res://assets/icons/generated_rules.png")
const ICON_UNDO = preload("res://assets/icons/generated_undo.png")
const ICON_RESTART = preload("res://assets/icons/generated_restart.png")
const ICON_CLOSE = preload("res://assets/icons/generated_close.png")

var board: Array[String] = []
var current := "red"
var selected := -1
var valid_moves: Array[int] = []
var winner := ""
var last_move := -1
var move_count := 0
var history: Array[Dictionary] = []
var board_skin := 0
var piece_skin := 0
var game_mode := "ai"
var ai_difficulty := 1
var ai_thinking := false
var ai_request_id := 0

var content_box: BoxContainer
var left_column: VBoxContainer
var settings_panel: PopupPanel
var header_margin: MarginContainer
var page_margin: MarginContainer
var action_layout: BoxContainer
var board_view: Control
var turn_label: Label
var step_label: Label
var headline: Label
var status_label: Label
var undo_button: Button
var music_toggle: CheckButton
var sfx_toggle: CheckButton
var track_select: OptionButton
var skin_buttons: Array[Button] = []
var piece_buttons: Array[Button] = []
var mode_buttons: Array[Button] = []
var difficulty_buttons: Array[Button] = []
var difficulty_section: VBoxContainer
var sound_engine: Node
var ai_player: RefCounted
var rules_dialog: PopupPanel

var board_skin_names := ["胡桃木", "青玉", "星河漆", "云纹纸"]
var piece_skin_names := ["玉扣", "漆雕", "铜章", "星环"]
var difficulty_names := ["入门", "进阶", "高手"]
var background_colors := [Color("dfe8e2"), Color("dbe9e3"), Color("111b2f"), Color("eee7da")]

func _ready() -> void:
	var game_theme := Theme.new()
	var game_font: Font = GAME_FONT.duplicate()
	game_font.fallbacks = [load("res://assets/NotoSansSC.ttf")]
	game_font.allow_system_fallback = true
	game_theme.default_font = game_font
	game_theme.default_font_size = 14
	theme = game_theme
	set_process_input(true)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	sound_engine = SOUND_ENGINE_SCRIPT.new()
	add_child(sound_engine)
	ai_player = AI_PLAYER_SCRIPT.new()
	_build_ui()
	_build_rules_dialog()
	_new_game(false)
	get_viewport().size_changed.connect(_update_responsive)
	_update_responsive()
	queue_redraw()

func _draw() -> void:
	var base: Color = background_colors[board_skin]
	draw_rect(Rect2(Vector2.ZERO, size), base)
	draw_texture_rect(UI_BACKGROUND, Rect2(Vector2.ZERO, size), false, Color(1, 1, 1, 0.74))
	var accent: Color = [Color("8eb3a5"), Color("9dc6b8"), Color("3b5577"), Color("c7a879")][board_skin]
	var ink: Color = [Color("31534d"), Color("47766c"), Color("0a1325"), Color("8a6049")][board_skin]
	draw_circle(Vector2(size.x * 0.08, size.y * 0.12), size.x * 0.75, Color(accent, 0.15))
	draw_circle(Vector2(size.x * 0.94, size.y * 0.78), size.x * 0.68, Color(ink, 0.09))
	draw_circle(Vector2(size.x * 0.44, size.y * 0.48), size.x * 0.78, Color(1, 1, 1, 0.08))
	for index in range(7):
		var y := size.y * (0.16 + float(index) * 0.14)
		draw_line(Vector2(-20, y), Vector2(size.x + 20, y + size.x * 0.06), Color(ink, 0.035), 1.0)

func _build_ui() -> void:
	var root_vbox := VBoxContainer.new()
	root_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_vbox.add_theme_constant_override("separation", 0)
	add_child(root_vbox)

	var header := PanelContainer.new()
	header.custom_minimum_size.y = 72
	header.add_theme_stylebox_override("panel", _style(Color("fbf8f1"), 0, Color("d8d0c2"), 1))
	root_vbox.add_child(header)
	header_margin = _margin(48, 48, 10, 10)
	header.add_child(header_margin)
	var header_row := HBoxContainer.new()
	header_row.alignment = BoxContainer.ALIGNMENT_CENTER
	header_row.add_theme_constant_override("separation", 8)
	header_margin.add_child(header_row)
	var brand_mark := Button.new()
	brand_mark.text = "六"
	brand_mark.tooltip_text = "重新开始"
	brand_mark.custom_minimum_size = Vector2(42, 42)
	brand_mark.add_theme_font_size_override("font_size", 20)
	brand_mark.add_theme_color_override("font_color", Color("fff7e8"))
	brand_mark.add_theme_stylebox_override("normal", _style(Color("203b31"), 12, Color("b78a45"), 1))
	brand_mark.add_theme_stylebox_override("hover", _style(Color("2b5142"), 12, Color("d3a75e"), 1))
	brand_mark.pressed.connect(func(): _new_game(true))
	header_row.add_child(brand_mark)
	var brand_stack := VBoxContainer.new()
	brand_stack.add_theme_constant_override("separation", -3)
	header_row.add_child(brand_stack)
	var brand_title := Label.new()
	brand_title.text = "六子冲"
	brand_title.add_theme_font_size_override("font_size", 18)
	brand_title.add_theme_color_override("font_color", Color("17281f"))
	brand_stack.add_child(brand_title)
	var brand_subtitle := Label.new()
	brand_subtitle.text = "LIUZI CHONG"
	brand_subtitle.add_theme_font_size_override("font_size", 9)
	brand_subtitle.add_theme_color_override("font_color", Color("8a7760"))
	brand_stack.add_child(brand_subtitle)
	var header_spacer := Control.new()
	header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(header_spacer)
	var music_button := Button.new()
	music_button.icon = ICON_MUSIC
	music_button.expand_icon = true
	music_button.tooltip_text = "开启或关闭背景音乐"
	_apply_premium_icon_button(music_button)
	music_button.pressed.connect(_toggle_music_from_header)
	header_row.add_child(music_button)
	var settings_button := Button.new()
	settings_button.icon = ICON_SETTINGS
	settings_button.expand_icon = true
	settings_button.tooltip_text = "棋盘、棋子与声音设置"
	_apply_premium_icon_button(settings_button)
	settings_button.pressed.connect(_show_settings)
	header_row.add_child(settings_button)
	var help_button := Button.new()
	help_button.icon = ICON_RULES
	help_button.expand_icon = true
	help_button.tooltip_text = "查看游戏规则"
	_apply_premium_icon_button(help_button)
	help_button.pressed.connect(_show_rules)
	header_row.add_child(help_button)

	var main_scroll := ScrollContainer.new()
	main_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_vbox.add_child(main_scroll)
	content_box = BoxContainer.new()
	content_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_box.add_theme_constant_override("separation", 0)
	main_scroll.add_child(content_box)

	left_column = VBoxContainer.new()
	left_column.custom_minimum_size.x = 1040
	left_column.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	left_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_column.add_theme_constant_override("separation", 12)
	page_margin = _margin(62, 62, 22, 20)
	page_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page_margin.add_child(left_column)
	content_box.add_child(page_margin)

	var hero_panel := PanelContainer.new()
	hero_panel.add_theme_stylebox_override("panel", _card_style(Color("f8f3e9", 0.96), 20, Color("d9cbb7", 0.90)))
	left_column.add_child(hero_panel)
	var hero_margin := _margin(18, 18, 13, 13)
	hero_panel.add_child(hero_margin)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 12)
	hero_margin.add_child(title_row)
	var title_stack := VBoxContainer.new()
	title_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_stack.add_theme_constant_override("separation", 3)
	title_row.add_child(title_stack)
	step_label = Label.new()
	step_label.text = "传统民间对弈 · 第 01 手"
	step_label.add_theme_font_size_override("font_size", 11)
	step_label.add_theme_color_override("font_color", Color("a65a43"))
	title_stack.add_child(step_label)
	headline = Label.new()
	headline.text = "双子成枪，只打孤子"
	headline.add_theme_font_size_override("font_size", 26)
	headline.add_theme_color_override("font_color", Color("17281f"))
	title_stack.add_child(headline)
	turn_label = Label.new()
	turn_label.text = "● 白方回合"
	turn_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turn_label.custom_minimum_size = Vector2(112, 38)
	turn_label.add_theme_stylebox_override("normal", _style(Color("fffaf1"), 12, Color("d8cbb9"), 1))
	turn_label.add_theme_font_size_override("font_size", 13)
	title_row.add_child(turn_label)

	board_view = BOARD_VIEW_SCRIPT.new()
	board_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_view.point_clicked.connect(_on_point_clicked)
	left_column.add_child(board_view)

	var action_panel := PanelContainer.new()
	action_panel.add_theme_stylebox_override("panel", _card_style(Color("f8f5ed", 0.98), 18, Color("d9d2c3", 0.90)))
	left_column.add_child(action_panel)
	var action_margin := _margin(18, 18, 14, 14)
	action_panel.add_child(action_margin)
	action_layout = BoxContainer.new()
	action_layout.add_theme_constant_override("separation", 14)
	action_margin.add_child(action_layout)
	status_label = Label.new()
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.custom_minimum_size.y = 44
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 14)
	status_label.add_theme_color_override("font_color", Color("33483e"))
	action_layout.add_child(status_label)

	var action_row := HBoxContainer.new()
	action_row.size_flags_horizontal = Control.SIZE_SHRINK_END
	action_row.add_theme_constant_override("separation", 10)
	action_layout.add_child(action_row)
	undo_button = _small_button("悔棋")
	undo_button.icon = ICON_UNDO
	undo_button.expand_icon = true
	undo_button.pressed.connect(_undo)
	action_row.add_child(undo_button)
	var reset_button := _primary_button("重新开局")
	reset_button.icon = ICON_RESTART
	reset_button.expand_icon = true
	reset_button.pressed.connect(func(): _new_game(true))
	action_row.add_child(reset_button)

	settings_panel = PopupPanel.new()
	settings_panel.title = "棋局设置"
	settings_panel.add_theme_stylebox_override("panel", _panel_surface(Color("f3f0e9"), 20, Color("c9d0c6")))
	add_child(settings_panel)
	var settings_shell := VBoxContainer.new()
	settings_shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	settings_shell.add_theme_constant_override("separation", 0)
	settings_shell.clip_contents = true
	settings_panel.add_child(settings_shell)
	var settings_header := PanelContainer.new()
	settings_header.add_theme_stylebox_override("panel", _style(Color("23483e"), 18))
	settings_shell.add_child(settings_header)
	var settings_header_margin := _margin(20, 16, 15, 15)
	settings_header.add_child(settings_header_margin)
	var settings_top := HBoxContainer.new()
	settings_top.add_theme_constant_override("separation", 12)
	settings_header_margin.add_child(settings_top)
	var settings_heading := VBoxContainer.new()
	settings_heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_heading.add_theme_constant_override("separation", 2)
	settings_top.add_child(settings_heading)
	var settings_eyebrow := _eyebrow("LIUZI CHONG  /  个性棋局")
	settings_eyebrow.add_theme_color_override("font_color", Color("bcd1c2"))
	settings_heading.add_child(settings_eyebrow)
	var settings_title := Label.new()
	settings_title.text = "棋局设置"
	settings_title.add_theme_font_size_override("font_size", 24)
	settings_title.add_theme_color_override("font_color", Color("fffaf0"))
	settings_heading.add_child(settings_title)
	var settings_close := Button.new()
	settings_close.text = "×"
	settings_close.tooltip_text = "关闭设置"
	settings_close.custom_minimum_size = Vector2(38, 38)
	settings_close.add_theme_font_size_override("font_size", 25)
	settings_close.add_theme_color_override("font_color", Color("fffaf0"))
	settings_close.add_theme_color_override("font_hover_color", Color.WHITE)
	settings_close.add_theme_stylebox_override("normal", _style(Color("41665a"), 12))
	settings_close.add_theme_stylebox_override("hover", _style(Color("5c7868"), 12))
	settings_close.pressed.connect(settings_panel.hide)
	settings_top.add_child(settings_close)

	var settings_scroll := ScrollContainer.new()
	settings_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	settings_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	settings_scroll.clip_contents = true
	settings_shell.add_child(settings_scroll)
	var settings_margin := _margin(18, 18, 16, 16)
	settings_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_scroll.add_child(settings_margin)
	var settings := VBoxContainer.new()
	settings.add_theme_constant_override("separation", 10)
	settings_margin.add_child(settings)
	var settings_copy := Label.new()
	settings_copy.text = "选择对战方式、难度与视觉风格，打造你的专属棋局。"
	settings_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	settings_copy.add_theme_font_size_override("font_size", 12)
	settings_copy.add_theme_color_override("font_color", Color("576960"))
	settings.add_child(settings_copy)

	var mode_group := _settings_group(settings, "对战模式", "01")
	var mode_grid := GridContainer.new()
	mode_grid.columns = 2
	mode_grid.add_theme_constant_override("h_separation", 8)
	mode_group.add_child(mode_grid)
	var mode_names := ["人机对战", "双人对抗"]
	var mode_copies := ["挑战电脑", "同屏轮流"]
	for i in range(mode_names.size()):
		var button := _mode_button(mode_names[i], mode_copies[i])
		button.pressed.connect(_select_game_mode.bind(i))
		mode_buttons.append(button)
		mode_grid.add_child(button)

	difficulty_section = _settings_group(settings, "电脑难度", "02")
	difficulty_section.add_theme_constant_override("separation", 8)
	var difficulty_grid := GridContainer.new()
	difficulty_grid.columns = 3
	difficulty_grid.add_theme_constant_override("h_separation", 7)
	difficulty_section.add_child(difficulty_grid)
	var difficulty_copies := ["轻松体验", "攻守兼备", "深度推演"]
	for i in range(difficulty_names.size()):
		var button := _difficulty_button(difficulty_names[i], difficulty_copies[i])
		button.pressed.connect(_select_ai_difficulty.bind(i))
		difficulty_buttons.append(button)
		difficulty_grid.add_child(button)

	var board_group := _settings_group(settings, "棋盘皮肤", "03")
	var skin_grid := GridContainer.new()
	skin_grid.columns = 2
	skin_grid.add_theme_constant_override("h_separation", 8)
	board_group.add_child(skin_grid)
	for i in range(board_skin_names.size()):
		var button := _skin_button(board_skin_names[i], i)
		button.pressed.connect(_select_board_skin.bind(i))
		skin_buttons.append(button)
		skin_grid.add_child(button)

	var piece_group := _settings_group(settings, "棋子样式", "04")
	var piece_grid := GridContainer.new()
	piece_grid.columns = 2
	piece_grid.add_theme_constant_override("h_separation", 8)
	piece_group.add_child(piece_grid)
	for i in range(piece_skin_names.size()):
		var button := _piece_button(piece_skin_names[i], i)
		button.pressed.connect(_select_piece_skin.bind(i))
		piece_buttons.append(button)
		piece_grid.add_child(button)

	var sound_group := _settings_group(settings, "声音氛围", "05")
	var music_row := HBoxContainer.new()
	sound_group.add_child(music_row)
	var music_copy := Label.new()
	music_copy.text = "背景音乐"
	music_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	music_copy.add_theme_font_size_override("font_size", 14)
	music_copy.add_theme_color_override("font_color", Color("33483d"))
	music_row.add_child(music_copy)
	music_toggle = CheckButton.new()
	music_toggle.text = "开启"
	music_toggle.custom_minimum_size = Vector2(82, 38)
	music_toggle.add_theme_color_override("font_color", Color("56645c"))
	music_toggle.add_theme_color_override("font_pressed_color", Color("fff8e9"))
	music_toggle.add_theme_stylebox_override("normal", _style(Color("f1eadf"), 14, Color("d7c7ad"), 1))
	music_toggle.add_theme_stylebox_override("hover", _style(Color("fffaf1"), 14, Color("b78a45"), 1))
	music_toggle.add_theme_stylebox_override("pressed", _style(Color("203b31"), 14, Color("b78a45"), 1))
	music_toggle.toggled.connect(_on_music_toggled)
	music_row.add_child(music_toggle)
	track_select = OptionButton.new()
	track_select.add_item("溪山清韵")
	track_select.add_item("竹窗夜雨")
	track_select.add_item("松间明月")
	track_select.custom_minimum_size.y = 44
	track_select.add_theme_color_override("font_color", Color("33483d"))
	track_select.add_theme_stylebox_override("normal", _option_style(Color("f9f5ec"), Color("d7c7ad")))
	track_select.add_theme_stylebox_override("hover", _option_style(Color("fffaf1"), Color("b78a45")))
	track_select.item_selected.connect(_on_track_selected)
	sound_group.add_child(track_select)
	var sfx_row := HBoxContainer.new()
	sound_group.add_child(sfx_row)
	var sfx_copy := Label.new()
	sfx_copy.text = "落子与吃子音效"
	sfx_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sfx_copy.add_theme_font_size_override("font_size", 14)
	sfx_copy.add_theme_color_override("font_color", Color("33483d"))
	sfx_row.add_child(sfx_copy)
	sfx_toggle = CheckButton.new()
	sfx_toggle.text = "开启"
	sfx_toggle.button_pressed = true
	sfx_toggle.custom_minimum_size = Vector2(82, 38)
	sfx_toggle.add_theme_color_override("font_color", Color("56645c"))
	sfx_toggle.add_theme_color_override("font_pressed_color", Color("fff8e9"))
	sfx_toggle.add_theme_stylebox_override("normal", _style(Color("f1eadf"), 14, Color("d7c7ad"), 1))
	sfx_toggle.add_theme_stylebox_override("hover", _style(Color("fffaf1"), 14, Color("b78a45"), 1))
	sfx_toggle.add_theme_stylebox_override("pressed", _style(Color("203b31"), 14, Color("b78a45"), 1))
	sfx_toggle.toggled.connect(_on_sfx_toggled)
	sfx_row.add_child(sfx_toggle)

	var settings_footer := PanelContainer.new()
	settings_footer.add_theme_stylebox_override("panel", _style(Color("ebe7dc"), 16, Color("d4d6cc"), 1))
	settings_shell.add_child(settings_footer)
	var footer_margin := _margin(18, 18, 12, 12)
	settings_footer.add_child(footer_margin)
	var footer_row := HBoxContainer.new()
	footer_row.add_theme_constant_override("separation", 8)
	footer_margin.add_child(footer_row)
	var new_game_button := _primary_button("开始新局  →")
	new_game_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	new_game_button.pressed.connect(_new_game_from_settings)
	footer_row.add_child(new_game_button)
	var rules_button := Button.new()
	rules_button.text = "规则"
	rules_button.custom_minimum_size = Vector2(98, 44)
	rules_button.add_theme_color_override("font_color", Color("5a6a61"))
	rules_button.add_theme_color_override("font_hover_color", Color("a7523f"))
	rules_button.add_theme_stylebox_override("normal", _style(Color("f1eadf"), 12, Color("d7c7ad"), 1))
	rules_button.add_theme_stylebox_override("hover", _style(Color("fffaf1"), 12, Color("b78a45"), 1))
	rules_button.pressed.connect(_show_rules)
	footer_row.add_child(rules_button)
	_update_mode_buttons()
	_update_skin_buttons()

func _build_rules_dialog() -> void:
	rules_dialog = PopupPanel.new()
	rules_dialog.add_theme_stylebox_override("panel", _panel_surface(Color("f7f3eb", 0.98), 24, Color("cdbda4", 0.92)))
	add_child(rules_dialog)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rules_dialog.add_child(scroll)
	var outer := _margin(20, 20, 18, 20)
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(outer)
	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 11)
	outer.add_child(stack)

	var top_row := HBoxContainer.new()
	stack.add_child(top_row)
	var eyebrow := _eyebrow("HOW TO PLAY · 民间六子冲规则")
	eyebrow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(eyebrow)
	var close_button := Button.new()
	close_button.icon = ICON_CLOSE
	close_button.expand_icon = true
	_apply_premium_icon_button(close_button, 34.0)
	close_button.pressed.connect(rules_dialog.hide)
	top_row.add_child(close_button)
	var rules_title := Label.new()
	rules_title.text = "只认二打一"
	rules_title.add_theme_font_size_override("font_size", 25)
	rules_title.add_theme_color_override("font_color", Color("17281f"))
	stack.add_child(rules_title)
	var rules_copy := Label.new()
	rules_copy.text = "两枚己棋相连形成枪身，只能打掉同一直线上的一枚孤立敌子。"
	rules_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rules_copy.add_theme_font_size_override("font_size", 12)
	rules_copy.add_theme_color_override("font_color", Color("718078"))
	stack.add_child(rules_copy)
	stack.add_child(_rule_card("01", "四线棋盘", "棋盘是横四线、竖四线的 4×4 交点，双方各有六枚棋子。白方从下方出发，黑方从上方出发。"))
	stack.add_child(_rule_card("02", "横竖走一格", "每回合移动一枚己方棋子，沿横线或竖线走到相邻空点，不能跳过棋子。"))
	stack.add_child(_rule_card("03", "只认二打一", "主动形成正好三子连线，且排列为“己—己—敌”或“敌—己—己”，即可吃掉这一枚敌子。"))
	stack.add_child(_rule_card("04", "四子不吃", "一条直线上若排满四枚棋子，不论怎样排列都不吃子；只有正好两己一敌的三子线有效。"))
	stack.add_child(_rule_card("05", "两种对战", "可选择人机对战并设置三档难度，也可选择本地双人对抗；把对方减到一枚或令其无路可走即胜。"))
	var start_button := _primary_button("明白了，开始对弈")
	start_button.custom_minimum_size.y = 48
	start_button.pressed.connect(rules_dialog.hide)
	stack.add_child(start_button)

func _new_game(with_sound: bool) -> void:
	ai_request_id += 1
	ai_thinking = false
	board.clear()
	board.resize(ROWS * COLS)
	board.fill("")
	# 红方玩家固定在棋盘下方，蓝方位于上方。
	for index in [8, 11, 12, 13, 14, 15]:
		board[index] = "red"
	for index in [0, 1, 2, 3, 4, 7]:
		board[index] = "blue"
	current = "red"
	selected = -1
	valid_moves.clear()
	winner = ""
	last_move = -1
	move_count = 0
	history.clear()
	_set_status("人机对战开始，你执白子" if game_mode == "ai" else "双人对抗开始，白方先行")
	if with_sound:
		sound_engine.play_sfx("move")
	_refresh()

func _on_point_clicked(index: int) -> void:
	if winner != "":
		return
	if ai_thinking or _is_ai_turn():
		_set_status("电脑正在思考，请稍候…")
		return
	var cell := board[index]
	if cell == current:
		selected = -1 if selected == index else index
		valid_moves = [] if selected == -1 else _valid_moves_for(selected, board)
		_set_status("请选择一枚棋子" if selected == -1 else "已选择%s方棋子，请走到亮起的横竖空位" % _player_name(current))
		sound_engine.play_sfx("select")
		_refresh()
		return
	if selected >= 0 and index in valid_moves:
		_move_piece(selected, index)
		return
	_set_status("现在是%s方回合" % _player_name(current) if cell != "" else "该位置不能到达，请选择亮起的空位")

func _move_piece(from: int, to: int) -> void:
	history.append({
		"board": board.duplicate(), "current": current, "winner": winner,
		"last_move": last_move, "move_count": move_count,
	})
	board[to] = current
	board[from] = ""
	var opponent := "blue" if current == "red" else "red"
	var captured := _capture_targets(board, to, current)
	for index in captured:
		board[index] = ""
	last_move = to
	move_count += 1
	selected = -1
	valid_moves.clear()
	if board.count(opponent) <= 1 or not _has_any_move(board, opponent):
		winner = current
		_set_status("%s方获胜！漂亮的一局" % _player_name(current))
		sound_engine.play_sfx("win")
	else:
		var moved_player := current
		current = opponent
		if captured.is_empty():
			_set_status("未形成二打一，%s方回合" % _player_name(current))
			sound_engine.play_sfx("move")
		else:
			_set_status("%s方完成吃子，拿走 %d 枚棋子" % [_player_name(moved_player), captured.size()])
			sound_engine.play_sfx("capture")
	_refresh()
	if not captured.is_empty():
		board_view.play_capture_effect(captured, opponent)
	if _is_ai_turn():
		_schedule_ai_turn()

func _undo() -> void:
	if history.is_empty():
		_set_status("当前没有可以悔棋的步骤")
		return
	ai_request_id += 1
	ai_thinking = false
	var undo_steps := 2 if game_mode == "ai" and current == "red" and history.size() >= 2 else 1
	var snapshot: Dictionary = {}
	for _step in range(undo_steps):
		if history.is_empty():
			break
		snapshot = history.pop_back()
	board.assign(snapshot.board)
	current = snapshot.current
	winner = snapshot.winner
	last_move = snapshot.last_move
	move_count = snapshot.move_count
	selected = -1
	valid_moves.clear()
	_set_status("已撤回双方一轮" if undo_steps == 2 else "已撤回上一步")
	sound_engine.play_sfx("select")
	_refresh()

func _valid_moves_for(index: int, target_board: Array[String]) -> Array[int]:
	var moves: Array[int] = []
	var row: int = int(index / COLS)
	var col: int = index % COLS
	var deltas: Array[Vector2i] = [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]
	for delta: Vector2i in deltas:
		var r: int = row + delta.x
		var c: int = col + delta.y
		if r < 0 or r >= ROWS or c < 0 or c >= COLS:
			continue
		var target: int = r * COLS + c
		if target_board[target] == "":
			moves.append(target)
	return moves

func _capture_targets(target_board: Array[String], moved_index: int, player: String) -> Array[int]:
	var opponent: String = "blue" if player == "red" else "red"
	var row: int = int(moved_index / COLS)
	var col: int = moved_index % COLS
	var row_line: Array[int] = []
	var col_line: Array[int] = []
	for c in range(COLS): row_line.append(row * COLS + c)
	for r in range(ROWS): col_line.append(r * COLS + col)
	var lines: Array = [row_line, col_line]
	var targets: Array[int] = []
	for line_variant in lines:
		var line: Array = line_variant
		# 唯一吃法：正好三子成直线，且两枚己棋相连，吃掉一枚敌棋。
		for start in range(line.size() - 2):
			var window: Array[int] = [int(line[start]), int(line[start + 1]), int(line[start + 2])]
			if moved_index not in window:
				continue
			var outside: int = int(line[3]) if start == 0 else int(line[0])
			if target_board[outside] != "":
				continue
			var values: Array[String] = [target_board[window[0]], target_board[window[1]], target_board[window[2]]]
			if values == [player, player, opponent] and int(window[2]) not in targets:
				targets.append(int(window[2]))
			elif values == [opponent, player, player] and int(window[0]) not in targets:
				targets.append(int(window[0]))
	return targets

func _has_any_move(target_board: Array[String], player: String) -> bool:
	for index in range(target_board.size()):
		if target_board[index] == player and not _valid_moves_for(index, target_board).is_empty():
			return true
	return false

func _refresh() -> void:
	board_view.set_state(board, selected, valid_moves, last_move, winner)
	board_view.set_skins(board_skin, piece_skin)
	step_label.text = "传统民间对弈 · %s · 第 %02d 手" % [_mode_label(), move_count + 1]
	step_label.add_theme_color_override("font_color", Color("a84735"))
	headline.text = "%s方胜出" % _player_name(winner) if winner != "" else ("你执白子，挑战电脑" if game_mode == "ai" else "双人轮流对战 · 二打一")
	headline.add_theme_color_override("font_color", Color("17281f"))
	turn_label.text = "棋局结束" if winner != "" else ("电脑思考中" if ai_thinking else "● %s方回合" % _player_name(current))
	turn_label.add_theme_color_override("font_color", Color("8e7755") if current == "red" else Color("20333a"))
	undo_button.disabled = history.is_empty()

func _set_status(text: String) -> void:
	if status_label:
		status_label.text = text

func _player_name(player: String) -> String:
	return "白" if player == "red" else "黑"

func _mode_label() -> String:
	return ("人机·%s" % difficulty_names[ai_difficulty]) if game_mode == "ai" else "双人对抗"

func _is_ai_turn() -> bool:
	return game_mode == "ai" and current == "blue" and winner == ""

func _schedule_ai_turn() -> void:
	if ai_thinking or not _is_ai_turn():
		return
	selected = -1
	valid_moves.clear()
	ai_thinking = true
	ai_request_id += 1
	var request := ai_request_id
	_set_status("电脑正在思考（%s难度）…" % difficulty_names[ai_difficulty])
	_refresh()
	_run_ai_turn(request)

func _run_ai_turn(request: int) -> void:
	await get_tree().create_timer(0.55).timeout
	if request != ai_request_id or not _is_ai_turn():
		return
	var move: Dictionary = ai_player.find_best_move(board.duplicate(), ai_difficulty)
	if request != ai_request_id:
		return
	ai_thinking = false
	if move.is_empty():
		winner = "red"
		_set_status("电脑无路可走，白方获胜！")
		_refresh()
		return
	_move_piece(int(move["from"]), int(move["to"]))

func _select_game_mode(index: int) -> void:
	game_mode = "ai" if index == 0 else "pvp"
	_update_mode_buttons()
	_new_game(false)

func _select_ai_difficulty(index: int) -> void:
	ai_difficulty = index
	_update_mode_buttons()
	_new_game(false)
	sound_engine.play_sfx("select")

func _update_mode_buttons() -> void:
	for i in range(mode_buttons.size()):
		mode_buttons[i].button_pressed = (i == 0 and game_mode == "ai") or (i == 1 and game_mode == "pvp")
	for i in range(difficulty_buttons.size()):
		difficulty_buttons[i].button_pressed = i == ai_difficulty
	if difficulty_section:
		difficulty_section.get_parent().visible = game_mode == "ai"

func _select_board_skin(index: int) -> void:
	board_skin = index
	_refresh()
	_update_skin_buttons()
	queue_redraw()

func _select_piece_skin(index: int) -> void:
	piece_skin = index
	board_view.set_skins(board_skin, piece_skin)
	_update_skin_buttons()
	sound_engine.play_sfx("select")

func _update_skin_buttons() -> void:
	for i in range(skin_buttons.size()):
		skin_buttons[i].button_pressed = i == board_skin
	for i in range(piece_buttons.size()):
		piece_buttons[i].button_pressed = i == piece_skin

func _on_music_toggled(enabled: bool) -> void:
	sound_engine.set_music_enabled(enabled)

func _toggle_music_from_header() -> void:
	music_toggle.button_pressed = not music_toggle.button_pressed

func _on_sfx_toggled(enabled: bool) -> void:
	sound_engine.sfx_enabled = enabled
	if enabled: sound_engine.play_sfx("select")

func _on_track_selected(index: int) -> void:
	sound_engine.set_track(index)

func _show_settings() -> void:
	var viewport_size := get_viewport_rect().size
	var popup_size := Vector2i(
		int(minf(430.0, viewport_size.x - 20.0)),
		int(minf(700.0, viewport_size.y - 40.0))
	)
	settings_panel.popup_centered(popup_size)

func _new_game_from_settings() -> void:
	settings_panel.hide()
	_new_game(true)

func _show_rules() -> void:
	if settings_panel.visible:
		settings_panel.hide()
	var viewport_size := get_viewport_rect().size
	rules_dialog.popup_centered(Vector2i(
		int(minf(540.0, viewport_size.x - 24.0)),
		int(minf(680.0, viewport_size.y - 24.0))
	))

func _update_responsive() -> void:
	if not content_box:
		return
	var width := get_viewport_rect().size.x
	var narrow := width < 700.0
	content_box.vertical = true
	if narrow:
		left_column.custom_minimum_size.x = 0
		board_view.custom_minimum_size = Vector2(maxf(280.0, width - 24.0), 430)
		action_layout.vertical = true
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		header_margin.add_theme_constant_override("margin_left", 12)
		header_margin.add_theme_constant_override("margin_right", 12)
		page_margin.add_theme_constant_override("margin_left", 12)
		page_margin.add_theme_constant_override("margin_right", 12)
		page_margin.add_theme_constant_override("margin_top", 12)
		headline.add_theme_font_size_override("font_size", 22)
		turn_label.custom_minimum_size.x = 96
	else:
		left_column.custom_minimum_size.x = minf(1040.0, width - 104.0)
		board_view.custom_minimum_size = Vector2(560, 640)
		action_layout.vertical = false
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		header_margin.add_theme_constant_override("margin_left", 48)
		header_margin.add_theme_constant_override("margin_right", 48)
		page_margin.add_theme_constant_override("margin_left", 52)
		page_margin.add_theme_constant_override("margin_right", 52)
		page_margin.add_theme_constant_override("margin_top", 24)
		headline.add_theme_font_size_override("font_size", 28)
		turn_label.custom_minimum_size.x = 112

func _margin(left: int, right: int, top: int, bottom: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_bottom", bottom)
	return margin

func _style(background: Color, radius: int, border_color := Color.TRANSPARENT, border_width := 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	if border_width > 0:
		style.border_color = border_color
		style.border_width_left = border_width
		style.border_width_right = border_width
		style.border_width_top = border_width
		style.border_width_bottom = border_width
	return style

func _panel_surface(background: Color, radius: int, border_color: Color) -> StyleBoxFlat:
	var style := _style(background, radius, border_color, 1)
	style.shadow_color = Color(0.05, 0.09, 0.08, 0.22)
	style.shadow_size = 14
	style.shadow_offset = Vector2(0, 5)
	return style

func _option_style(background: Color, border_color: Color) -> StyleBoxFlat:
	var style := _style(background, 15, border_color, 1)
	style.shadow_color = Color(0.06, 0.09, 0.08, 0.10)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	return style

func _card_style(background: Color, radius: int, border_color: Color) -> StyleBoxFlat:
	var style := _style(background, radius, border_color, 1)
	style.shadow_color = Color(0.08, 0.10, 0.08, 0.10)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 3)
	return style

func _premium_icon_style(background: Color, border_color: Color) -> StyleBoxFlat:
	var style := _style(background, 16, border_color, 1)
	style.shadow_color = Color(0.08, 0.10, 0.08, 0.14)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 2)
	return style

func _apply_premium_icon_button(button: Button, size := 46.0) -> void:
	button.custom_minimum_size = Vector2(size, size)
	button.add_theme_color_override("font_color", Color("33483d"))
	button.add_theme_color_override("font_hover_color", Color("17281f"))
	button.add_theme_color_override("icon_normal_color", Color("3d554b"))
	button.add_theme_color_override("icon_hover_color", Color("a7523f"))
	button.add_theme_color_override("icon_pressed_color", Color("fff7e8"))
	button.add_theme_stylebox_override("normal", _premium_icon_style(Color("f4eee3"), Color("d5c19d")))
	button.add_theme_stylebox_override("hover", _premium_icon_style(Color("fffaf1"), Color("b78a45")))
	button.add_theme_stylebox_override("pressed", _premium_icon_style(Color("203b31"), Color("b78a45")))

func _texture_button_style(texture: Texture2D, margin := 18.0, tint := Color.WHITE) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = margin
	style.texture_margin_right = margin
	style.texture_margin_top = minf(margin, 10.0)
	style.texture_margin_bottom = minf(margin, 10.0)
	# Keep the nine-slice bevel intact without letting its wide corner slices
	# squeeze icons and labels into the remaining center pixels on small screens.
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	style.modulate_color = tint
	return style

func _generated_panel_style(texture: Texture2D, margin := 32.0, tint := Color.WHITE) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = margin
	style.texture_margin_right = margin
	style.texture_margin_top = margin
	style.texture_margin_bottom = margin
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 14.0
	style.content_margin_bottom = 14.0
	style.modulate_color = tint
	return style

func _divider() -> HSeparator:
	var divider := HSeparator.new()
	divider.add_theme_constant_override("separation", 8)
	divider.add_theme_stylebox_override("separator", _style(Color("ded4c4"), 1))
	return divider

func _small_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(128, 44)
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", Color("33483d"))
	button.add_theme_color_override("font_disabled_color", Color("89918d"))
	button.add_theme_color_override("icon_normal_color", Color("405248"))
	button.add_theme_color_override("icon_hover_color", Color("a7523f"))
	button.add_theme_color_override("icon_disabled_color", Color("9b9f9c"))
	button.add_theme_stylebox_override("normal", _option_style(Color("fffdf8"), Color("c7cfc6")))
	button.add_theme_stylebox_override("hover", _option_style(Color("edf4ed"), Color("729785")))
	button.add_theme_stylebox_override("pressed", _option_style(Color("dceadd"), Color("729785")))
	button.add_theme_stylebox_override("disabled", _option_style(Color("e9e9e4"), Color("d2d7cf")))
	return button

func _primary_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(128, 44)
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", Color("fff8e9"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("icon_normal_color", Color("fff8e9"))
	button.add_theme_color_override("icon_hover_color", Color.WHITE)
	button.add_theme_color_override("icon_pressed_color", Color("fff8e9"))
	button.add_theme_stylebox_override("normal", _option_style(Color("234b3f"), Color("7da18c")))
	button.add_theme_stylebox_override("hover", _option_style(Color("30604e"), Color("a9c3a3")))
	button.add_theme_stylebox_override("pressed", _option_style(Color("193a32"), Color("7da18c")))
	return button

func _eyebrow(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color("a84735"))
	return label

func _section_title(text: String, count: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var marker := Label.new()
	marker.text = count
	marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	marker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	marker.custom_minimum_size = Vector2(32, 26)
	marker.add_theme_font_size_override("font_size", 10)
	marker.add_theme_color_override("font_color", Color("f3d9a2"))
	marker.add_theme_stylebox_override("normal", _style(Color("284c43"), 9, Color("b78a45", 0.72), 1))
	row.add_child(marker)
	var label := Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color("1e352d"))
	row.add_child(label)
	return row

func _settings_group(parent: VBoxContainer, title: String, count: String) -> VBoxContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _style(Color("fffdf8"), 15, Color("d9ddd3"), 1))
	parent.add_child(card)
	var inset := _margin(12, 12, 10, 12)
	card.add_child(inset)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 9)
	inset.add_child(stack)
	stack.add_child(_section_title(title, count))
	return stack

func _rule_card(number: String, title: String, copy: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _option_style(Color("fbf7ef"), Color("e0d4c1")))
	var margin := _margin(12, 12, 10, 10)
	card.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 11)
	margin.add_child(row)
	var badge := Label.new()
	badge.text = number
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.custom_minimum_size = Vector2(34, 34)
	badge.add_theme_font_size_override("font_size", 10)
	badge.add_theme_color_override("font_color", Color("fff7e8"))
	badge.add_theme_stylebox_override("normal", _style(Color("203b31"), 10))
	row.add_child(badge)
	var text_stack := VBoxContainer.new()
	text_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_stack.add_theme_constant_override("separation", 2)
	row.add_child(text_stack)
	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 14)
	title_label.add_theme_color_override("font_color", Color("20352b"))
	text_stack.add_child(title_label)
	var copy_label := Label.new()
	copy_label.text = copy
	copy_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy_label.add_theme_font_size_override("font_size", 11)
	copy_label.add_theme_color_override("font_color", Color("586960"))
	text_stack.add_child(copy_label)
	return card

func _mode_button(title: String, copy: String) -> Button:
	var button := Button.new()
	button.text = "%s\n%s" % [title, copy]
	button.toggle_mode = true
	button.custom_minimum_size = Vector2(118, 60)
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", Color("30463d"))
	button.add_theme_color_override("font_pressed_color", Color("fff8e9"))
	button.add_theme_stylebox_override("normal", _option_style(Color("f8f2e8"), Color("dacbb5")))
	button.add_theme_stylebox_override("pressed", _option_style(Color("23463b"), Color("b78a45")))
	button.add_theme_stylebox_override("hover", _option_style(Color("fffaf1"), Color("b78a45")))
	button.add_theme_stylebox_override("hover_pressed", _option_style(Color("2d5648"), Color("b78a45")))
	return button

func _difficulty_button(title: String, copy: String) -> Button:
	var button := Button.new()
	button.text = "%s\n%s" % [title, copy]
	button.toggle_mode = true
	button.custom_minimum_size = Vector2(82, 56)
	button.add_theme_font_size_override("font_size", 11)
	button.add_theme_color_override("font_color", Color("3c5048"))
	button.add_theme_color_override("font_pressed_color", Color("fff8e9"))
	button.add_theme_stylebox_override("normal", _option_style(Color("f8f2e8"), Color("dacbb5")))
	button.add_theme_stylebox_override("pressed", _option_style(Color("23463b"), Color("b78a45")))
	button.add_theme_stylebox_override("hover", _option_style(Color("fffaf1"), Color("b78a45")))
	button.add_theme_stylebox_override("hover_pressed", _option_style(Color("2d5648"), Color("b78a45")))
	return button

func _skin_button(text: String, index: int) -> Button:
	var colors := [Color("203d3d"), Color("3b6c65"), Color("1c2942"), Color("e9e1d2")]
	var button := Button.new()
	button.text = text
	button.toggle_mode = true
	button.custom_minimum_size = Vector2(118, 52)
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_color_override("font_color", Color("30463d"))
	button.add_theme_color_override("font_pressed_color", Color("fff8e9"))
	var tint: Color = colors[index].lerp(Color.WHITE, 0.72)
	button.add_theme_stylebox_override("normal", _option_style(tint, Color("d5c5ad")))
	button.add_theme_stylebox_override("pressed", _option_style(Color("23463b"), Color("b78a45")))
	button.add_theme_stylebox_override("hover", _option_style(Color("fffaf1"), Color("b78a45")))
	button.add_theme_stylebox_override("hover_pressed", _option_style(Color("2d5648"), Color("b78a45")))
	return button

func _piece_button(text: String, index: int) -> Button:
	var button := Button.new()
	button.text = text
	button.toggle_mode = true
	button.custom_minimum_size = Vector2(118, 52)
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_color_override("font_color", Color("30463d"))
	button.add_theme_color_override("font_pressed_color", Color("fff8e9"))
	button.add_theme_stylebox_override("normal", _option_style(Color("f8f2e8"), Color("dacbb5")))
	button.add_theme_stylebox_override("pressed", _option_style(Color("23463b"), Color("b78a45")))
	button.add_theme_stylebox_override("hover", _option_style(Color("fffaf1"), Color("b78a45")))
	button.add_theme_stylebox_override("hover_pressed", _option_style(Color("2d5648"), Color("b78a45")))
	return button
