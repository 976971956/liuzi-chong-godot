extends Control

signal point_clicked(index: int)

const ROWS := 4
const COLS := 4
const GAME_FONT = preload("res://assets/NotoSansSCGameV10.ttf")
const GENERATED_BOARD_PATH := "res://assets/generated_board_surface_v2.png"
const GENERATED_STONES_PATH := "res://assets/generated_go_stones_v2.png"

const GO_BLACK_SOURCE := Rect2(110, 100, 700, 700)
const GO_WHITE_SOURCE := Rect2(964, 100, 700, 700)

var board: Array[String] = []
var selected := -1
var valid_moves: Array[int] = []
var last_move := -1
var board_skin := 0
var piece_skin := 0
var winner := ""
var capture_effects: Array[Dictionary] = []
var generated_board: Texture2D
var generated_stones: Texture2D

var skin_data := [
	{"board": Color("203d3d"), "glow": Color("6d9b91"), "line": Color("d9bd7c"), "line_shadow": Color("0c2225"), "accent": Color("f4dca0"), "frame": Color("122b2e"), "edge": Color("bd9758"), "shadow": Color(0.03, 0.06, 0.06, 0.34)},
	{"board": Color("3b6c65"), "glow": Color("b9ded0"), "line": Color("e6d39b"), "line_shadow": Color("173d3a"), "accent": Color("f6e5b0"), "frame": Color("244b48"), "edge": Color("d5b979"), "shadow": Color(0.02, 0.10, 0.09, 0.28)},
	{"board": Color("1c2942"), "glow": Color("476285"), "line": Color("d8b66c"), "line_shadow": Color("0a1224"), "accent": Color("ffe5a1"), "frame": Color("101b31"), "edge": Color("c9a35d"), "shadow": Color(0.01, 0.02, 0.07, 0.42)},
	{"board": Color("e9e1d2"), "glow": Color("fffaf0"), "line": Color("9b604b"), "line_shadow": Color("fdf7e9"), "accent": Color("b98351"), "frame": Color("c8b59a"), "edge": Color("a77d57"), "shadow": Color(0.12, 0.08, 0.05, 0.22)},
]

func _ready() -> void:
	custom_minimum_size = Vector2(340, 430)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	resized.connect(queue_redraw)
	generated_board = load(GENERATED_BOARD_PATH) as Texture2D
	generated_stones = load(GENERATED_STONES_PATH) as Texture2D
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
	var frame_width := minf(available.x, available.y)
	var frame_height := frame_width
	var frame := Rect2((size - Vector2(frame_width, frame_height)) * 0.5, Vector2(frame_width, frame_height))
	var inset_x := clampf(frame_width * 0.135, 40.0, 72.0)
	var inset_y := clampf(frame_height * 0.135, 40.0, 72.0)
	return {"frame": frame, "grid": Rect2(frame.position + Vector2(inset_x, inset_y), frame.size - Vector2(inset_x * 2.0, inset_y * 2.0))}

func _draw() -> void:
	var geometry := _get_geometry()
	var frame: Rect2 = geometry.frame
	var grid: Rect2 = geometry.grid
	var skin: Dictionary = skin_data[board_skin]

	draw_style_box(_style(skin.shadow, 28.0), Rect2(frame.position + Vector2(0, 14), frame.size).grow(4.0))
	draw_style_box(_style(skin.frame, 28.0, skin.edge, 2.0), frame.grow(6.0))
	draw_style_box(_style(skin.board, 24.0, Color(skin.edge, 0.48), 2.0), frame)
	if board_skin == 0 and generated_board:
		draw_texture_rect(generated_board, frame, false, Color(1, 1, 1, 0.78))
		draw_rect(frame, Color(skin.board, 0.18))
	draw_circle(frame.position + Vector2(frame.size.x * 0.18, frame.size.y * 0.16), frame.size.x * 0.72, Color(skin.glow, 0.08))
	draw_circle(frame.position + Vector2(frame.size.x * 0.86, frame.size.y * 0.84), frame.size.x * 0.56, Color(skin.line_shadow, 0.10))
	draw_style_box(_style(Color(1, 1, 1, 0.035), 21.0, Color(skin.edge, 0.58), 2.0), frame.grow(-8.0))
	draw_style_box(_style(Color.TRANSPARENT, 18.0, Color(skin.line_shadow, 0.34), 1.0), frame.grow(-14.0))
	_draw_corners(frame, skin.accent)

	for row in range(ROWS):
		var y := grid.position.y + grid.size.y * float(row) / float(ROWS - 1)
		draw_line(Vector2(grid.position.x, y + 2.0), Vector2(grid.end.x, y + 2.0), Color(skin.line_shadow, 0.42), 4.2, true)
		draw_line(Vector2(grid.position.x, y), Vector2(grid.end.x, y), skin.line, 2.2, true)
	for col in range(COLS):
		var x := grid.position.x + grid.size.x * float(col) / float(COLS - 1)
		draw_line(Vector2(x + 2.0, grid.position.y), Vector2(x + 2.0, grid.end.y), Color(skin.line_shadow, 0.42), 4.2, true)
		draw_line(Vector2(x, grid.position.y), Vector2(x, grid.end.y), skin.line, 2.2, true)

	if board.is_empty():
		return
	for index in range(board.size()):
		var point := _point_position(index, grid)
		if board[index] == "":
			if index in valid_moves:
				draw_circle(point, 15.0, Color(skin.accent, 0.14))
				draw_arc(point, 10.0, 0, TAU, 32, Color(skin.accent, 0.92), 2.0, true)
				draw_circle(point, 3.2, skin.accent)
			else:
				draw_circle(point, 3.2, Color(skin.line, 0.76))
		else:
			_draw_piece(point, board[index], index == selected, index == last_move, grid)

	_draw_capture_effects(grid)
	_draw_count_tag(Vector2(frame.position.x + 12, frame.position.y + 13), "黑", board.count("blue"), Color("1c282d"))
	_draw_count_tag(Vector2(frame.end.x - 12, frame.end.y - 13), "白", board.count("red"), Color("e8dfcf"), true)
	if winner != "":
		_draw_winner_seal(frame.get_center())

func _draw_piece(center: Vector2, side: String, is_selected: bool, is_last: bool, grid: Rect2) -> void:
	var step_x := grid.size.x / float(COLS - 1)
	var step_y := grid.size.y / float(ROWS - 1)
	var radius := clampf(minf(step_x, step_y) * 0.275, 21.0, 35.0)
	var white_stone := side == "red"
	var stone_top := Color("f2eee4") if white_stone else Color("303b41")
	var stone_mid := Color("d5cdbd") if white_stone else Color("1b252b")
	var stone_edge := Color("aaa291") if white_stone else Color("0b1318")
	var stone_highlight := Color("fffdf5") if white_stone else Color("aabcc2")
	var stone_shadow := Color(0.01, 0.025, 0.03, 0.44)
	var shine_strength := 0.52
	var bevel_width := 2.4
	match piece_skin:
		1:
			stone_top = Color("f9f7f0") if white_stone else Color("3b5962")
			stone_mid = Color("d8e0db") if white_stone else Color("142b34")
			shine_strength = 0.72
			bevel_width = 2.0
		2:
			stone_top = Color("d9d0c0") if white_stone else Color("343a3c")
			stone_mid = Color("b5aa99") if white_stone else Color("22282a")
			stone_highlight = Color("fff5dc") if white_stone else Color("899092")
			shine_strength = 0.22
			bevel_width = 3.0
		_:
			shine_strength = 0.36

	if is_selected:
		draw_arc(center, radius + 9.0, 0, TAU, 56, Color("e9c777"), 3.0, true)
		draw_circle(center, radius + 5.0, Color(0.02, 0.06, 0.06, 0.26))
		center.y -= 2.5

	if piece_skin == 0 and generated_stones:
		var source := GO_WHITE_SOURCE if white_stone else GO_BLACK_SOURCE
		var target := Rect2(center - Vector2(radius * 1.05, radius * 0.93), Vector2(radius * 2.10, radius * 1.86))
		draw_texture_rect_region(generated_stones, target, source, Color(1, 1, 1, 0.98))
		if is_last:
			draw_circle(center + Vector2(radius * 0.72, -radius * 0.72), 5.5, Color("172328", 0.88))
			draw_circle(center + Vector2(radius * 0.72, -radius * 0.72), 3.0, Color("f0d38b"))
		return

	# A Go-style stone is built in depth layers: contact shadow, side wall, bevel, cap, and gloss.
	_draw_ellipse(center + Vector2(0, radius * 0.58), radius * 1.12, 0.34, stone_shadow)
	for depth in range(6, 0, -1):
		var depth_ratio := float(depth) / 6.0
		draw_circle(center + Vector2(0, depth_ratio * radius * 0.18), radius + 1.2, Color(stone_edge, 0.92))
	draw_circle(center, radius + 0.3, stone_edge)
	draw_circle(center - Vector2(0, 1.4), radius - 1.8, stone_mid)
	draw_circle(center - Vector2(0, 2.7), radius - 3.4, stone_top)
	draw_circle(center - Vector2(radius * 0.18, radius * 0.22), radius * 0.70, Color(stone_highlight, shine_strength * 0.22))
	_draw_ellipse(center - Vector2(radius * 0.31, radius * 0.38), radius * 0.25, 0.12, Color(stone_highlight, shine_strength))
	draw_arc(center - Vector2(0, 2.0), radius - 4.0, PI * 1.08, PI * 1.84, 36, Color(stone_highlight, shine_strength * 0.54), bevel_width, true)
	draw_arc(center + Vector2(0, 1.5), radius - 3.2, PI * 0.16, PI * 0.92, 32, Color(0.01, 0.02, 0.02, 0.24), bevel_width, true)
	if piece_skin == 1:
		draw_arc(center - Vector2(0, 1.5), radius - 5.0, 0, TAU, 56, Color("f0d38b", 0.54), 1.2, true)

	if is_last:
		draw_circle(center + Vector2(radius * 0.72, -radius * 0.72), 5.5, Color("172328", 0.88))
		draw_circle(center + Vector2(radius * 0.72, -radius * 0.72), 3.0, Color("f0d38b"))

func _draw_ellipse(center: Vector2, radius: float, vertical_scale: float, color: Color) -> void:
	draw_set_transform(center, 0.0, Vector2(radius, radius * vertical_scale))
	draw_circle(Vector2.ZERO, 1.0, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

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
	var seal_color := Color("e4dac8") if winner == "red" else Color("1b2a31")
	var seal_text := Color("2b3836") if winner == "red" else Color("f3eadb")
	draw_circle(center + Vector2(0, 10), 76.0, Color(0.02, 0.01, 0.01, 0.42))
	draw_circle(center, 72.0, Color(seal_color, 0.98))
	draw_arc(center, 64.0, 0, TAU, 64, Color("f4d69a"), 3.0, true)
	draw_string(GAME_FONT, center + Vector2(-48, -17), "胜者", HORIZONTAL_ALIGNMENT_CENTER, 96, 14, seal_text)
	draw_string(GAME_FONT, center + Vector2(-48, 34), "白" if winner == "red" else "黑", HORIZONTAL_ALIGNMENT_CENTER, 96, 48, seal_text)

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
