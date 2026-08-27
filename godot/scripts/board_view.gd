extends Control

signal point_clicked(index: int)

const ROWS := 5
const COLS := 4
const GAME_FONT = preload("res://assets/NotoSansSCGameV9.ttf")
const BOARD_TEXTURES = preload("res://assets/board_texture_atlas.png")

var board: Array[String] = []
var selected := -1
var valid_moves: Array[int] = []
var last_move := -1
var board_skin := 0
var piece_skin := 0
var winner := ""
var capture_effects: Array[Dictionary] = []

var skin_data := [
	{"line": Color("e8c98e"), "line_shadow": Color("2b1208"), "accent": Color("f7dfaa"), "wash": Color(0.12, 0.04, 0.01, 0.10)},
	{"line": Color("214f45"), "line_shadow": Color("dce9d9"), "accent": Color("f2e6bd"), "wash": Color(0.02, 0.20, 0.15, 0.06)},
	{"line": Color("e7be6b"), "line_shadow": Color("050c22"), "accent": Color("fff0ba"), "wash": Color(0.02, 0.03, 0.13, 0.10)},
	{"line": Color("8c3d31"), "line_shadow": Color("f7eedc"), "accent": Color("c38a45"), "wash": Color(0.25, 0.16, 0.05, 0.04)},
]

func _ready() -> void:
	custom_minimum_size = Vector2(340, 470)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	resized.connect(queue_redraw)
	set_process(false)

func set_state(new_board: Array[String], new_selected: int, new_valid: Array[int], new_last: int, new_winner: String) -> void:
	board = new_board
	selected = new_selected
	valid_moves = new_valid
	last_move = new_last
	winner = new_winner
	queue_redraw()

func set_skins(new_board_skin: int, new_piece_skin: int) -> void:
	board_skin = new_board_skin
	piece_skin = new_piece_skin
	queue_redraw()

func play_capture_effect(indices: Array[int], side: String) -> void:
	for index in indices:
		capture_effects.append({"index": index, "side": side, "time": 0.0, "duration": 0.82})
	set_process(not capture_effects.is_empty())
	queue_redraw()

func _process(delta: float) -> void:
	for i in range(capture_effects.size() - 1, -1, -1):
		capture_effects[i]["time"] = float(capture_effects[i]["time"]) + delta
		if float(capture_effects[i]["time"]) >= float(capture_effects[i]["duration"]):
			capture_effects.remove_at(i)
	set_process(not capture_effects.is_empty())
	queue_redraw()

func _get_geometry() -> Dictionary:
	var horizontal_gap := clampf(size.x * 0.035, 10.0, 26.0)
	var available := size - Vector2(horizontal_gap * 2.0, 12.0)
	var frame_width := minf(available.x, available.y / 1.20)
	var frame_height := frame_width * 1.20
	var frame := Rect2((size - Vector2(frame_width, frame_height)) * 0.5, Vector2(frame_width, frame_height))
	var inset_x := clampf(frame_width * 0.135, 42.0, 72.0)
	var inset_y := clampf(frame_height * 0.125, 48.0, 78.0)
	return {"frame": frame, "grid": Rect2(frame.position + Vector2(inset_x, inset_y), frame.size - Vector2(inset_x * 2.0, inset_y * 2.0))}

func _draw() -> void:
	var geometry := _get_geometry()
	var frame: Rect2 = geometry.frame
	var grid: Rect2 = geometry.grid
	var skin: Dictionary = skin_data[board_skin]

	draw_style_box(_style(Color(0.035, 0.025, 0.02, 0.30), 30.0), Rect2(frame.position + Vector2(0, 14), frame.size))
	draw_style_box(_style(Color("5c3a21"), 29.0), frame.grow(4.0))
	var half := BOARD_TEXTURES.get_size() * 0.5
	var source := Rect2(Vector2(float(board_skin % 2) * half.x, float(board_skin / 2) * half.y), half)
	draw_texture_rect_region(BOARD_TEXTURES, frame, source)
	draw_rect(frame, skin.wash)
	draw_style_box(_style(Color(1, 1, 1, 0.025), 26.0, Color(1, 0.88, 0.61, 0.34), 2.0), frame.grow(-7.0))
	draw_style_box(_style(Color.TRANSPARENT, 22.0, Color(0.08, 0.05, 0.03, 0.26), 1.0), frame.grow(-13.0))
	_draw_corners(frame, skin.accent)

	for row in range(ROWS):
		var y := grid.position.y + grid.size.y * float(row) / float(ROWS - 1)
		draw_line(Vector2(grid.position.x, y + 2.0), Vector2(grid.end.x, y + 2.0), Color(skin.line_shadow, 0.34), 5.5, true)
		draw_line(Vector2(grid.position.x, y), Vector2(grid.end.x, y), skin.line, 3.2, true)
	for col in range(COLS):
		var x := grid.position.x + grid.size.x * float(col) / float(COLS - 1)
		draw_line(Vector2(x + 2.0, grid.position.y), Vector2(x + 2.0, grid.end.y), Color(skin.line_shadow, 0.34), 5.5, true)
		draw_line(Vector2(x, grid.position.y), Vector2(x, grid.end.y), skin.line, 3.2, true)

	if board.is_empty():
		return
	for index in range(board.size()):
		var point := _point_position(index, grid)
		if board[index] == "":
			if index in valid_moves:
				draw_circle(point, 18.0, Color(skin.accent, 0.18))
				draw_arc(point, 11.5, 0, TAU, 32, Color(skin.accent, 0.92), 2.2, true)
				draw_circle(point, 3.8, skin.accent)
			else:
				draw_circle(point, 4.0, Color(skin.line, 0.86))
		else:
			_draw_piece(point, board[index], index == selected, index == last_move, grid)

	_draw_capture_effects(grid)
	_draw_count_tag(Vector2(frame.position.x + 12, frame.position.y + 13), "蓝", board.count("blue"), Color("35648f"))
	_draw_count_tag(Vector2(frame.end.x - 12, frame.end.y - 13), "红", board.count("red"), Color("c64b3b"), true)
	if winner != "":
		_draw_winner_seal(frame.get_center())

func _draw_piece(center: Vector2, side: String, is_selected: bool, is_last: bool, grid: Rect2) -> void:
	var step_x := grid.size.x / float(COLS - 1)
	var step_y := grid.size.y / float(ROWS - 1)
	var radius := clampf(minf(step_x, step_y) * 0.31, 22.0, 38.0)
	var red := side == "red"
	var primary := Color("bd4638") if red else Color("315f88")
	var deep := Color("651f1d") if red else Color("132f4a")
	var bright := Color("f3826a") if red else Color("73a2c5")
	var ivory := Color("fff0d1")

	if is_selected:
		draw_circle(center, radius + 11.0, Color("ffe8a7"))
		draw_circle(center, radius + 7.0, Color(0.06, 0.04, 0.03, 0.72))
		center.y -= 4.0

	draw_circle(center + Vector2(0, radius * 0.24), radius + 1.5, Color(0.02, 0.015, 0.01, 0.34))
	match piece_skin:
		0:
			draw_circle(center, radius, deep)
			draw_circle(center, radius - 2.5, primary)
			draw_circle(center - Vector2(radius * 0.16, radius * 0.19), radius * 0.73, bright)
			draw_circle(center + Vector2(radius * 0.09, radius * 0.08), radius * 0.73, primary)
			draw_arc(center, radius * 0.75, 0, TAU, 48, Color(1, 0.88, 0.68, 0.52), 1.8, true)
			_draw_glyph(center, radius, "冲" if red else "守", ivory)
		1:
			draw_circle(center, radius, Color("211814"))
			draw_circle(center, radius - 3.0, deep)
			draw_arc(center, radius - 6.0, 0, TAU, 56, Color("e9bd68"), 2.3, true)
			draw_arc(center, radius * 0.58, 0, TAU, 48, Color(primary, 0.86), radius * 0.25, true)
			_draw_glyph(center, radius, "六", Color("f8db9b"))
		2:
			draw_circle(center, radius, Color("49321f"))
			draw_circle(center, radius - 2.0, Color("c9954f"))
			draw_circle(center, radius - 6.5, Color("72502e"))
			draw_circle(center, radius - 9.0, primary)
			for angle in [0.0, PI * 0.5, PI, PI * 1.5]:
				draw_circle(center + Vector2(cos(angle), sin(angle)) * (radius - 4.2), 2.0, Color("f5d28c"))
			_draw_glyph(center, radius, "锋" if red else "垒", ivory)
		_:
			draw_circle(center, radius, Color("0b1420"))
			draw_circle(center, radius - 3.0, Color(primary, 0.96))
			draw_circle(center, radius * 0.62, Color("101a28"))
			draw_arc(center, radius * 0.76, -0.55, 2.25, 42, Color("ffe29a"), 2.6, true)
			draw_circle(center + Vector2(radius * 0.56, -radius * 0.51), 3.2, Color("fff1b3"))
			draw_circle(center, radius * 0.15, bright)

	if is_last:
		draw_circle(center + Vector2(radius * 0.72, -radius * 0.72), 6.0, Color("24170f"))
		draw_circle(center + Vector2(radius * 0.72, -radius * 0.72), 3.6, Color("ffe092"))

func _draw_glyph(center: Vector2, radius: float, glyph: String, color: Color) -> void:
	var font_size := int(radius * 0.70)
	draw_string(GAME_FONT, center + Vector2(-radius, float(font_size) * 0.36), glyph, HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, font_size, color)

func _draw_capture_effects(grid: Rect2) -> void:
	for effect in capture_effects:
		var progress := clampf(float(effect["time"]) / float(effect["duration"]), 0.0, 1.0)
		var fade := 1.0 - progress
		var center := _point_position(int(effect["index"]), grid)
		var side_color := Color("dc5a48") if String(effect["side"]) == "red" else Color("4f88b8")
		var gold := Color("ffe19a")
		var ghost_radius := 24.0 * (1.0 - progress * 0.35)
		draw_circle(center, ghost_radius, Color(side_color, fade * 0.38))
		draw_circle(center, 10.0 + progress * 24.0, Color(gold, fade * 0.16))
		draw_circle(center, maxf(2.0, 9.0 * fade), Color(gold, fade * 0.92))
		var ring_radius := 13.0 + progress * 48.0
		draw_arc(center, ring_radius, 0, TAU, 56, Color(gold, minf(1.0, fade * 1.25)), 4.0 * fade + 1.0, true)
		draw_arc(center, ring_radius * 0.72, 0, TAU, 48, Color(side_color, fade * 0.72), 2.0, true)
		for shard in range(16):
			var angle := TAU * float(shard) / 16.0 + float(int(effect["index"]) % 5) * 0.13
			var distance := 10.0 + progress * (32.0 + float(shard % 3) * 7.0)
			var direction := Vector2(cos(angle), sin(angle))
			var start := center + direction * distance
			var finish := start + direction * (12.0 + float(shard % 2) * 7.0) * fade
			var shard_color := gold if shard % 2 == 0 else side_color
			draw_line(start, finish, Color(shard_color, minf(1.0, fade * 1.18)), 3.4 * fade + 0.8, true)
			draw_circle(finish, 2.6 * fade + 0.8, Color(shard_color, fade))

func _draw_count_tag(anchor: Vector2, label: String, count: int, color: Color, right_align := false) -> void:
	var tag_size := Vector2(78, 30)
	var rect := Rect2(anchor - (Vector2(tag_size.x, tag_size.y) if right_align else Vector2.ZERO), tag_size)
	draw_style_box(_style(Color(0.06, 0.045, 0.035, 0.72), 15.0, Color(1, 0.9, 0.68, 0.18), 1.0), rect)
	draw_circle(rect.position + Vector2(16, 15), 7.0, color)
	draw_string(GAME_FONT, rect.position + Vector2(28, 20), "%s · %d" % [label, count], HORIZONTAL_ALIGNMENT_LEFT, 46, 12, Color("fff3db"))

func _draw_winner_seal(center: Vector2) -> void:
	var seal_color := Color("9e352e") if winner == "red" else Color("24547a")
	draw_circle(center + Vector2(0, 10), 76.0, Color(0.02, 0.01, 0.01, 0.42))
	draw_circle(center, 72.0, Color(seal_color, 0.98))
	draw_arc(center, 64.0, 0, TAU, 64, Color("f4d69a"), 3.0, true)
	draw_string(GAME_FONT, center + Vector2(-48, -17), "胜者", HORIZONTAL_ALIGNMENT_CENTER, 96, 14, Color("f7dfaf"))
	draw_string(GAME_FONT, center + Vector2(-48, 34), "红" if winner == "red" else "蓝", HORIZONTAL_ALIGNMENT_CENTER, 96, 48, Color("fff3d9"))

func _draw_corners(frame: Rect2, color: Color) -> void:
	var margin := 22.0
	var length := 21.0
	var points := [
		[frame.position + Vector2(margin, margin), Vector2(1, 1)],
		[Vector2(frame.end.x - margin, frame.position.y + margin), Vector2(-1, 1)],
		[Vector2(frame.position.x + margin, frame.end.y - margin), Vector2(1, -1)],
		[frame.end - Vector2(margin, margin), Vector2(-1, -1)],
	]
	for item in points:
		var origin: Vector2 = item[0]
		var direction: Vector2 = item[1]
		draw_line(origin, origin + Vector2(direction.x * length, 0), Color(color, 0.74), 2.0)
		draw_line(origin, origin + Vector2(0, direction.y * length), Color(color, 0.74), 2.0)

func _point_position(index: int, grid: Rect2) -> Vector2:
	var row: int = int(index / COLS)
	var col: int = index % COLS
	return Vector2(
		grid.position.x + grid.size.x * float(col) / float(COLS - 1),
		grid.position.y + grid.size.y * float(row) / float(ROWS - 1)
	)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var grid: Rect2 = _get_geometry().grid
		var nearest := -1
		var nearest_distance := 9999.0
		for index in range(ROWS * COLS):
			var distance: float = event.position.distance_to(_point_position(index, grid))
			if distance < nearest_distance:
				nearest_distance = distance
				nearest = index
		if nearest >= 0 and nearest_distance <= 46.0:
			point_clicked.emit(nearest)

func _style(background: Color, radius: float, border_color := Color.TRANSPARENT, border_width := 0.0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.corner_radius_top_left = int(radius)
	style.corner_radius_top_right = int(radius)
	style.corner_radius_bottom_left = int(radius)
	style.corner_radius_bottom_right = int(radius)
	if border_width > 0.0:
		style.border_color = border_color
		style.border_width_left = int(border_width)
		style.border_width_right = int(border_width)
		style.border_width_top = int(border_width)
		style.border_width_bottom = int(border_width)
	return style
