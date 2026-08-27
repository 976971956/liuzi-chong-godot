extends Control

const ROWS := 5
const COLS := 4
const BOARD_VIEW_SCRIPT = preload("res://scripts/board_view.gd")
const SOUND_ENGINE_SCRIPT = preload("res://scripts/sound_engine.gd")
const AI_PLAYER_SCRIPT = preload("res://scripts/ai_player.gd")
const GAME_FONT = preload("res://assets/NotoSansSCGameV6.ttf")

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
var capture_blocked_by_four := false

var content_box: BoxContainer
var left_column: VBoxContainer
var settings_panel: PopupPanel
var header_margin: MarginContainer
var page_margin: MarginContainer
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
var rules_dialog: AcceptDialog

var board_skin_names := ["胡桃木", "青玉", "星河漆", "云纹纸"]
var piece_skin_names := ["玉扣", "漆雕", "铜章", "星环"]
var difficulty_names := ["入门", "进阶", "高手"]
var background_colors := [Color("efe8dc"), Color("e5eee8"), Color("101a2b"), Color("f1ece3")]

func _ready() -> void:
	var game_theme := Theme.new()
	game_theme.default_font = GAME_FONT
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
	draw_rect(Rect2(Vector2.ZERO, size), background_colors[board_skin])
	var is_dark := board_skin == 2
	var haze := Color(0.36, 0.50, 0.68, 0.07) if is_dark else Color(1, 1, 1, 0.46)
	draw_circle(Vector2(size.x * 0.17, size.y * 0.18), minf(size.x, size.y) * 0.38, haze)
	for i in range(34):
		var y := float(i) * size.y / 33.0
		var line_color := Color(1, 1, 1, 0.018) if is_dark else Color(0.25, 0.20, 0.13, 0.018)
		draw_line(Vector2(0, y), Vector2(size.x, y + sin(float(i) * 1.7) * 4.0), line_color, 1.0)

func _build_ui() -> void:
	var root_vbox := VBoxContainer.new()
	root_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_vbox.add_theme_constant_override("separation", 0)
	add_child(root_vbox)

	var header := PanelContainer.new()
	header.custom_minimum_size.y = 76
	header.add_theme_stylebox_override("panel", _style(Color(0.98, 0.97, 0.94, 0.88), 0, Color(0.18, 0.23, 0.20, 0.12), 1))
	root_vbox.add_child(header)
	header_margin = _margin(54, 54, 0, 0)
	header.add_child(header_margin)
	var header_row := HBoxContainer.new()
	header_row.alignment = BoxContainer.ALIGNMENT_CENTER
	header_margin.add_child(header_row)
	var brand_button := Button.new()
	brand_button.flat = true
	brand_button.text = "▦  六子冲\n     LINE OF SIX"
	brand_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	brand_button.add_theme_font_size_override("font_size", 18)
	brand_button.add_theme_color_override("font_color", Color("17281f"))
	brand_button.pressed.connect(func(): _new_game(true))
	header_row.add_child(brand_button)
	var header_spacer := Control.new()
	header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(header_spacer)
	var music_button := Button.new()
	music_button.text = "音"
	music_button.tooltip_text = "开启或关闭背景音乐"
	music_button.custom_minimum_size = Vector2(42, 42)
	music_button.add_theme_color_override("font_color", Color("33483d"))
	music_button.add_theme_color_override("font_hover_color", Color("17281f"))
	music_button.add_theme_stylebox_override("normal", _style(Color(1, 1, 1, 0.42), 21, Color(0.15, 0.22, 0.18, 0.13), 1))
	music_button.add_theme_stylebox_override("hover", _style(Color("e9dfca"), 21))
	music_button.pressed.connect(_toggle_music_from_header)
	header_row.add_child(music_button)
	var settings_button := Button.new()
	settings_button.text = "设置"
	settings_button.tooltip_text = "棋盘、棋子与声音设置"
	settings_button.custom_minimum_size = Vector2(86, 42)
	settings_button.add_theme_color_override("font_color", Color("33483d"))
	settings_button.add_theme_color_override("font_hover_color", Color("17281f"))
	settings_button.add_theme_stylebox_override("normal", _style(Color(1, 1, 1, 0.42), 21, Color(0.15, 0.22, 0.18, 0.13), 1))
	settings_button.add_theme_stylebox_override("hover", _style(Color("e9dfca"), 21))
	settings_button.pressed.connect(_show_settings)
	header_row.add_child(settings_button)
	var help_button := Button.new()
	help_button.text = "?"
	help_button.custom_minimum_size = Vector2(42, 42)
	help_button.add_theme_color_override("font_color", Color("33483d"))
	help_button.add_theme_color_override("font_hover_color", Color("17281f"))
	help_button.add_theme_stylebox_override("normal", _style(Color(1, 1, 1, 0.42), 21, Color(0.15, 0.22, 0.18, 0.13), 1))
	help_button.add_theme_stylebox_override("hover", _style(Color("e9dfca"), 21))
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
	left_column.custom_minimum_size.x = 680
	left_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_column.add_theme_constant_override("separation", 10)
	page_margin = _margin(62, 62, 28, 22)
	page_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page_margin.add_child(left_column)
	content_box.add_child(page_margin)

	var title_row := HBoxContainer.new()
	left_column.add_child(title_row)
	var title_stack := VBoxContainer.new()
	title_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_stack.add_theme_constant_override("separation", 3)
	title_row.add_child(title_stack)
	step_label = Label.new()
	step_label.text = "传统民间对弈 · 第 01 手"
	step_label.add_theme_font_size_override("font_size", 11)
	step_label.add_theme_color_override("font_color", Color("a84735"))
	title_stack.add_child(step_label)
	headline = Label.new()
	headline.text = "双子成锋，一步制胜"
	headline.add_theme_font_size_override("font_size", 31)
	headline.add_theme_color_override("font_color", Color("17281f"))
	title_stack.add_child(headline)
	turn_label = Label.new()
	turn_label.text = "● 红方回合"
	turn_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turn_label.custom_minimum_size = Vector2(112, 38)
	turn_label.add_theme_stylebox_override("normal", _style(Color(1, 1, 1, 0.72), 19, Color(0.15, 0.22, 0.18, 0.12), 1))
	turn_label.add_theme_font_size_override("font_size", 13)
	title_row.add_child(turn_label)

	board_view = BOARD_VIEW_SCRIPT.new()
	board_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_view.point_clicked.connect(_on_point_clicked)
	left_column.add_child(board_view)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.custom_minimum_size.y = 42
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 13)
	status_label.add_theme_color_override("font_color", Color("415148"))
	status_label.add_theme_stylebox_override("normal", _style(Color(1, 1, 1, 0.88), 19, Color(0.15, 0.22, 0.18, 0.08), 1))
	left_column.add_child(status_label)

	var action_row := HBoxContainer.new()
	action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	action_row.add_theme_constant_override("separation", 10)
	left_column.add_child(action_row)
	undo_button = _small_button("悔棋")
	undo_button.pressed.connect(_undo)
	action_row.add_child(undo_button)
	var reset_button := _small_button("重新开局")
	reset_button.pressed.connect(func(): _new_game(true))
	action_row.add_child(reset_button)

	settings_panel = PopupPanel.new()
	settings_panel.title = "棋局设置"
	settings_panel.add_theme_stylebox_override("panel", _style(Color(0.98, 0.97, 0.94, 0.98), 18, Color(0.18, 0.23, 0.20, 0.12), 1))
	add_child(settings_panel)
	var settings_scroll := ScrollContainer.new()
	settings_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	settings_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	settings_panel.add_child(settings_scroll)
	var settings_margin := _margin(28, 28, 26, 24)
	settings_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_scroll.add_child(settings_margin)
	var settings := VBoxContainer.new()
	settings.add_theme_constant_override("separation", 14)
	settings_margin.add_child(settings)

	settings.add_child(_eyebrow("外观与声音"))
	var settings_title := Label.new()
	settings_title.text = "棋局设置"
	settings_title.add_theme_font_size_override("font_size", 27)
	settings_title.add_theme_color_override("font_color", Color("17281f"))
	settings.add_child(settings_title)
	var settings_copy := Label.new()
	settings_copy.text = "选择人机或双人对抗，再搭配喜欢的棋盘与棋子。"
	settings_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	settings_copy.add_theme_font_size_override("font_size", 13)
	settings_copy.add_theme_color_override("font_color", Color("718078"))
	settings.add_child(settings_copy)
	settings.add_child(HSeparator.new())

	settings.add_child(_section_title("对战模式", "02"))
	var mode_grid := GridContainer.new()
	mode_grid.columns = 2
	mode_grid.add_theme_constant_override("h_separation", 7)
	settings.add_child(mode_grid)
	var mode_names := ["人机对战", "双人对抗"]
	var mode_copies := ["挑战电脑", "同屏轮流"]
	for i in range(mode_names.size()):
		var button := _mode_button(mode_names[i], mode_copies[i])
		button.pressed.connect(_select_game_mode.bind(i))
		mode_buttons.append(button)
		mode_grid.add_child(button)

	difficulty_section = VBoxContainer.new()
	difficulty_section.add_theme_constant_override("separation", 8)
	settings.add_child(difficulty_section)
	difficulty_section.add_child(_section_title("电脑难度", "03"))
	var difficulty_grid := GridContainer.new()
	difficulty_grid.columns = 3
	difficulty_grid.add_theme_constant_override("h_separation", 6)
	difficulty_section.add_child(difficulty_grid)
	var difficulty_copies := ["轻松体验", "攻守兼备", "深度推演"]
	for i in range(difficulty_names.size()):
		var button := _difficulty_button(difficulty_names[i], difficulty_copies[i])
		button.pressed.connect(_select_ai_difficulty.bind(i))
		difficulty_buttons.append(button)
		difficulty_grid.add_child(button)

	settings.add_child(HSeparator.new())

	settings.add_child(_section_title("棋盘皮肤", "04"))
	var skin_grid := GridContainer.new()
	skin_grid.columns = 2
	skin_grid.add_theme_constant_override("h_separation", 7)
	settings.add_child(skin_grid)
	for i in range(board_skin_names.size()):
		var button := _skin_button(board_skin_names[i], i)
		button.pressed.connect(_select_board_skin.bind(i))
		skin_buttons.append(button)
		skin_grid.add_child(button)

	settings.add_child(HSeparator.new())
	settings.add_child(_section_title("棋子样式", "04"))
	var piece_grid := GridContainer.new()
	piece_grid.columns = 2
	piece_grid.add_theme_constant_override("h_separation", 7)
	settings.add_child(piece_grid)
	for i in range(piece_skin_names.size()):
		var button := _piece_button(piece_skin_names[i], i)
		button.pressed.connect(_select_piece_skin.bind(i))
		piece_buttons.append(button)
		piece_grid.add_child(button)

	settings.add_child(HSeparator.new())
	var music_row := HBoxContainer.new()
	settings.add_child(music_row)
	var music_copy := Label.new()
	music_copy.text = "背景音乐"
	music_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	music_copy.add_theme_font_size_override("font_size", 14)
	music_row.add_child(music_copy)
	music_toggle = CheckButton.new()
	music_toggle.text = "开启"
	music_toggle.toggled.connect(_on_music_toggled)
	music_row.add_child(music_toggle)
	track_select = OptionButton.new()
	track_select.add_item("溪山清韵")
	track_select.add_item("竹窗夜雨")
	track_select.add_item("松间明月")
	track_select.item_selected.connect(_on_track_selected)
	settings.add_child(track_select)
	var sfx_row := HBoxContainer.new()
	settings.add_child(sfx_row)
	var sfx_copy := Label.new()
	sfx_copy.text = "落子与吃子音效"
	sfx_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sfx_copy.add_theme_font_size_override("font_size", 14)
	sfx_row.add_child(sfx_copy)
	sfx_toggle = CheckButton.new()
	sfx_toggle.text = "开启"
	sfx_toggle.button_pressed = true
	sfx_toggle.toggled.connect(_on_sfx_toggled)
	sfx_row.add_child(sfx_toggle)

	var settings_spacer := Control.new()
	settings_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	settings.add_child(settings_spacer)
	var new_game_button := Button.new()
	new_game_button.text = "开始新局   →"
	new_game_button.custom_minimum_size.y = 48
	new_game_button.add_theme_font_size_override("font_size", 15)
	new_game_button.add_theme_color_override("font_color", Color.WHITE)
	new_game_button.add_theme_stylebox_override("normal", _style(Color("17281f"), 9))
	new_game_button.add_theme_stylebox_override("hover", _style(Color("294438"), 9))
	new_game_button.pressed.connect(_new_game_from_settings)
	settings.add_child(new_game_button)
	var rules_button := Button.new()
	rules_button.flat = true
	rules_button.text = "查看完整规则  ↗"
	rules_button.add_theme_color_override("font_color", Color("7f8a84"))
	rules_button.pressed.connect(_show_rules)
	settings.add_child(rules_button)
	_update_mode_buttons()
	_update_skin_buttons()

func _build_rules_dialog() -> void:
	rules_dialog = AcceptDialog.new()
	rules_dialog.title = "六子冲 · 活枪规则"
	rules_dialog.dialog_text = "① 走一步\n每回合选择一枚己方棋子，沿横线或竖线移动到相邻空点，不能跳跃或斜走。\n\n② 二打一\n本步主动形成连续的“己—己—敌”，恰好三子连成一线，便可吃掉枪口的敌子。\n\n③ 四子封枪\n若同一直线上连续出现第四枚棋子，活枪即被封住，不能吃子。\n\n④ 定胜负\n把对方吃到只剩一枚，或让对方完全无路可走，即获得胜利。"
	rules_dialog.ok_button_text = "明白了，开始对弈"
	rules_dialog.min_size = Vector2i(330, 400)
	add_child(rules_dialog)

func _new_game(with_sound: bool) -> void:
	ai_request_id += 1
	ai_thinking = false
	board.clear()
	board.resize(ROWS * COLS)
	board.fill("")
	# 红方玩家固定在棋盘下方，蓝方位于上方。
	for index in [12, 15, 16, 17, 18, 19]:
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
	_set_status("人机对战开始，你执红子" if game_mode == "ai" else "双人对抗开始，红方先行")
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
		_set_status("请选择一枚棋子" if selected == -1 else "已选择%s方棋子，请走到亮起的相邻空位" % _player_name(current))
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
			_set_status("四子同线，活枪被封，%s方回合" % _player_name(current) if capture_blocked_by_four else "%s方回合，请选择棋子" % _player_name(current))
			sound_engine.play_sfx("move")
		else:
			_set_status("%s方形成活枪，吃掉 %d 枚棋子" % [_player_name(moved_player), captured.size()])
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
		if r >= 0 and r < ROWS and c >= 0 and c < COLS:
			var target: int = r * COLS + c
			if target_board[target] == "":
				moves.append(target)
	return moves

func _capture_targets(target_board: Array[String], moved_index: int, player: String) -> Array[int]:
	capture_blocked_by_four = false
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
		for start in range(line.size() - 2):
			var window: Array[int] = [int(line[start]), int(line[start + 1]), int(line[start + 2])]
			if moved_index not in window:
				continue
			var values: Array[String] = [target_board[window[0]], target_board[window[1]], target_board[window[2]]]
			var forward: bool = values == [player, player, opponent]
			var backward: bool = values == [opponent, player, player]
			if not forward and not backward:
				continue
			var before: int = int(line[start - 1]) if start > 0 else -1
			var after: int = int(line[start + 3]) if start + 3 < line.size() else -1
			var clean_before: bool = before == -1 or target_board[before] == ""
			var clean_after: bool = after == -1 or target_board[after] == ""
			if clean_before and clean_after:
				var target: int = window[2] if forward else window[0]
				if target not in targets:
					targets.append(target)
			else:
				capture_blocked_by_four = true
	return targets

func _has_any_move(target_board: Array[String], player: String) -> bool:
	for index in range(target_board.size()):
		if target_board[index] == player and not _valid_moves_for(index, target_board).is_empty():
			return true
	return false

func _refresh() -> void:
	board_view.set_state(board, selected, valid_moves, last_move, winner)
	board_view.set_skins(board_skin, piece_skin)
	var dark_board := board_skin == 2
	step_label.text = "传统民间对弈 · %s · 第 %02d 手" % [_mode_label(), move_count + 1]
	step_label.add_theme_color_override("font_color", Color("e3bb73") if dark_board else Color("a84735"))
	headline.text = "%s方胜出" % _player_name(winner) if winner != "" else ("你执红子，挑战电脑" if game_mode == "ai" else "双子成锋，一步制胜")
	headline.add_theme_color_override("font_color", Color("f3e7cf") if dark_board else Color("17281f"))
	turn_label.text = "棋局结束" if winner != "" else ("电脑思考中" if ai_thinking else "● %s方回合" % _player_name(current))
	turn_label.add_theme_color_override("font_color", Color("a84735") if current == "red" else Color("294b6b"))
	undo_button.disabled = history.is_empty()

func _set_status(text: String) -> void:
	if status_label:
		status_label.text = text

func _player_name(player: String) -> String:
	return "红" if player == "red" else "蓝"

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
		_set_status("电脑无路可走，红方获胜！")
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
		difficulty_section.visible = game_mode == "ai"

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
		int(minf(760.0, viewport_size.y - 20.0))
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
		int(minf(440.0, viewport_size.y - 24.0))
	))

func _update_responsive() -> void:
	if not content_box:
		return
	var width := get_viewport_rect().size.x
	var narrow := width < 700.0
	content_box.vertical = true
	if narrow:
		left_column.custom_minimum_size.x = 0
		board_view.custom_minimum_size = Vector2(340, 470)
		header_margin.add_theme_constant_override("margin_left", 14)
		header_margin.add_theme_constant_override("margin_right", 14)
		page_margin.add_theme_constant_override("margin_left", 12)
		page_margin.add_theme_constant_override("margin_right", 12)
		page_margin.add_theme_constant_override("margin_top", 16)
		headline.add_theme_font_size_override("font_size", 24)
		turn_label.custom_minimum_size.x = 102
	else:
		left_column.custom_minimum_size.x = 620
		board_view.custom_minimum_size = Vector2(560, 660)
		header_margin.add_theme_constant_override("margin_left", 48)
		header_margin.add_theme_constant_override("margin_right", 48)
		page_margin.add_theme_constant_override("margin_left", 52)
		page_margin.add_theme_constant_override("margin_right", 52)
		page_margin.add_theme_constant_override("margin_top", 24)
		headline.add_theme_font_size_override("font_size", 31)
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

func _small_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(128, 42)
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_color_override("font_color", Color("33483d"))
	button.add_theme_color_override("font_disabled_color", Color("89918d"))
	button.add_theme_stylebox_override("normal", _style(Color(1, 1, 1, 0.82), 17, Color(0.15, 0.22, 0.18, 0.09), 1))
	button.add_theme_stylebox_override("hover", _style(Color(1, 1, 1, 0.86), 17, Color("bd8f46"), 1))
	return button

func _eyebrow(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color("a84735"))
	return label

func _section_title(text: String, count: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 14)
	row.add_child(label)
	var count_label := Label.new()
	count_label.text = count
	count_label.add_theme_font_size_override("font_size", 10)
	count_label.add_theme_color_override("font_color", Color("a5a69f"))
	row.add_child(count_label)
	return row

func _mode_button(title: String, copy: String) -> Button:
	var button := Button.new()
	button.text = "%s\n%s" % [title, copy]
	button.toggle_mode = true
	button.custom_minimum_size = Vector2(142, 64)
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", Color("5f6962"))
	button.add_theme_color_override("font_pressed_color", Color("17281f"))
	button.add_theme_stylebox_override("normal", _style(Color(1, 1, 1, 0.42), 10, Color(0.15, 0.22, 0.18, 0.10), 1))
	button.add_theme_stylebox_override("pressed", _style(Color("e7dfcf"), 10, Color("a84735"), 2))
	button.add_theme_stylebox_override("hover", _style(Color(1, 1, 1, 0.72), 10, Color("bd8f46"), 1))
	return button

func _difficulty_button(title: String, copy: String) -> Button:
	var button := Button.new()
	button.text = "%s\n%s" % [title, copy]
	button.toggle_mode = true
	button.custom_minimum_size = Vector2(92, 58)
	button.add_theme_font_size_override("font_size", 11)
	button.add_theme_color_override("font_color", Color("657068"))
	button.add_theme_color_override("font_pressed_color", Color("17281f"))
	button.add_theme_stylebox_override("normal", _style(Color(1, 1, 1, 0.34), 9, Color(0.15, 0.22, 0.18, 0.08), 1))
	button.add_theme_stylebox_override("pressed", _style(Color("e3eadf"), 9, Color("356652"), 2))
	button.add_theme_stylebox_override("hover", _style(Color(1, 1, 1, 0.68), 9, Color("bd8f46"), 1))
	return button

func _skin_button(text: String, index: int) -> Button:
	var colors := [Color("d5a462"), Color("8ea99a"), Color("25334b"), Color("e9dfc9")]
	var button := Button.new()
	button.text = "▦   " + text
	button.toggle_mode = true
	button.custom_minimum_size = Vector2(142, 64)
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_color_override("font_color", Color("5f6962"))
	button.add_theme_color_override("font_pressed_color", Color("5f6962"))
	button.add_theme_stylebox_override("normal", _style(Color(colors[index], 0.38), 10, Color(0.15, 0.22, 0.18, 0.10), 1))
	button.add_theme_stylebox_override("pressed", _style(Color(colors[index], 0.58), 10, Color("a84735"), 2))
	button.add_theme_stylebox_override("hover", _style(Color(colors[index], 0.52), 10, Color("bd8f46"), 1))
	return button

func _piece_button(text: String, index: int) -> Button:
	var icons := ["◉", "◎", "●", "⊙"]
	var button := Button.new()
	button.text = "%s   %s" % [icons[index], text]
	button.toggle_mode = true
	button.custom_minimum_size = Vector2(142, 64)
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_color_override("font_color", Color("5f6962"))
	button.add_theme_color_override("font_pressed_color", Color("5f6962"))
	button.add_theme_stylebox_override("normal", _style(Color(1, 1, 1, 0.38), 10, Color(0.15, 0.22, 0.18, 0.10), 1))
	button.add_theme_stylebox_override("pressed", _style(Color(1, 1, 1, 0.82), 10, Color("a84735"), 2))
	button.add_theme_stylebox_override("hover", _style(Color(1, 1, 1, 0.66), 10, Color("bd8f46"), 1))
	return button
