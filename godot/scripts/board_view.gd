extends Control

signal point_clicked(index: int)

const ROWS := 5
const COLS := 4
const GAME_FONT = preload("res://assets/NotoSansSC.ttf")

var board: Array[String] = []
var selected := -1
var valid_moves: Array[int] = []
var last_move := -1
var board_skin := 0
var piece_skin := 0
var winner := ""

var skin_data := [
	{"board": Color("d39a55"), "board_2": Color("e2b873"), "line": Color("6f431f"), "glow": Color("f5d58f")},
	{"board": Color("719584"), "board_2": Color("a9c5b5"), "line": Color("244e42"), "glow": Color("dcebdc")},
	{"board": Color("1d3049"), "board_2": Color("40536d"), "line": Color("d3ad68"), "glow": Color("f2d9a2")},
	{"board": Color("e2d5bb"), "board_2": Color("f1e9d7"), "line": Color("8f3d32"), "glow": Color("e4bb78")},
]

func _ready() -> void:
	custom_minimum_size = Vector2(500, 590)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	resized.connect(queue_redraw)

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

func _get_geometry() -> Dictionary:
	var available := size - Vector2(90, 60)
	var frame_height := minf(available.y, available.x * 1.16)
	var frame_width := frame_height / 1.16
	if frame_width > available.x:
		frame_width = available.x
		frame_height = frame_width * 1.16
	var frame := Rect2((size - Vector2(frame_width, frame_height)) * 0.5, Vector2(frame_width, frame_height))
	var inset := clampf(frame_width * 0.13, 42.0, 66.0)
	return {"frame": frame, "grid": frame.grow(-inset)}

func _draw() -> void:
	var geometry := _get_geometry()
	var frame: Rect2 = geometry.frame
	var grid: Rect2 = geometry.grid
	var skin: Dictionary = skin_data[board_skin]

	draw_style_box(_style(Color(0.08, 0.06, 0.04, 0.22), 30.0), Rect2(frame.position + Vector2(0, 18), frame.size))
	draw_style_box(_style(skin.board, 27.0, skin.board_2, 3.0), frame)
	draw_style_box(_style(Color(1, 1, 1, 0.035), 20.0, Color(1, 1, 1, 0.12), 1.0), frame.grow(-9.0))

	for i in range(18):
		var y := frame.position.y + 18.0 + float(i) * (frame.size.y - 36.0) / 17.0
		draw_line(Vector2(frame.position.x + 18, y), Vector2(frame.end.x - 18, y + sin(float(i)) * 2.0), Color(0.18, 0.10, 0.04, 0.045), 1.0)
	_draw_corners(frame, skin.line)

	for row in range(ROWS):
		var y := grid.position.y + grid.size.y * float(row) / float(ROWS - 1)
		draw_line(Vector2(grid.position.x, y + 1), Vector2(grid.end.x, y + 1), Color(1, 0.9, 0.68, 0.18), 4.0, true)
		draw_line(Vector2(grid.position.x, y), Vector2(grid.end.x, y), skin.line, 3.0, true)
	for col in range(COLS):
		var x := grid.position.x + grid.size.x * float(col) / float(COLS - 1)
		draw_line(Vector2(x + 1, grid.position.y), Vector2(x + 1, grid.end.y), Color(1, 0.9, 0.68, 0.18), 4.0, true)
		draw_line(Vector2(x, grid.position.y), Vector2(x, grid.end.y), skin.line, 3.0, true)

	if board.is_empty():
		return
	for index in range(board.size()):
		var point := _point_position(index, grid)
		if board[index] == "":
			var dot_radius := 8.0 if index in valid_moves else 4.5
			var dot_color: Color = skin.glow if index in valid_moves else skin.line
			if index in valid_moves:
				draw_circle(point, 17.0, Color(dot_color, 0.17))
			draw_circle(point, dot_radius, dot_color)
		else:
			_draw_piece(point, board[index], index == selected, index == last_move)

	_draw_count_tag(Vector2(frame.position.x - 3, frame.position.y + 8), "红方", board.count("red"), Color("a84735"), false)
	_draw_count_tag(Vector2(frame.end.x + 3, frame.end.y - 8), "蓝方", board.count("blue"), Color("213f62"), true)
	if winner != "":
		_draw_winner_seal(frame.get_center())

func _draw_piece(center: Vector2, side: String, is_selected: bool, is_last: bool) -> void:
	var radius := clampf(size.x / 18.0, 24.0, 34.0)
	if is_selected:
		draw_circle(center, radius + 9.0, Color("f4d78f"))
		draw_circle(center, radius + 6.0, Color(0.18, 0.12, 0.06, 0.55))
		center.y -= 4.0
	var primary := Color("ae4635") if side == "red" else Color("294b6b")
	var light := Color("df7962") if side == "red" else Color("5c7d99")
	if piece_skin == 1:
		light = Color("f09a84") if side == "red" else Color("87abc3")
	if piece_skin == 2:
		primary = primary.lerp(Color("4d4d48"), 0.35)
		light = light.lerp(Color("aaa69d"), 0.38)
	draw_circle(center + Vector2(0, 7), radius, Color(0.06, 0.04, 0.03, 0.28))
	draw_circle(center, radius, primary)
	if piece_skin != 3:
		draw_circle(center - Vector2(radius * 0.22, radius * 0.22), radius * 0.69, light)
		draw_circle(center, radius * 0.7, primary)
		draw_arc(center, radius * 0.73, 0, TAU, 48, Color(1, 0.91, 0.76, 0.46), 1.2, true)
		var glyph := "冲" if side == "red" else "守"
		draw_string(GAME_FONT, center + Vector2(-radius, 8.0), glyph, HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, int(radius * 0.74), Color("f7e5c7"))
	else:
		draw_arc(center, radius - 4, 0, TAU, 48, Color("efd3ae") if side == "red" else Color("d8e2df"), 3.0, true)
	if is_last:
		draw_circle(center + Vector2(radius * 0.72, -radius * 0.72), 4.5, Color("f4d78f"))

func _draw_count_tag(anchor: Vector2, label: String, count: int, color: Color, right_align: bool) -> void:
	var tag_size := Vector2(105, 34)
	var rect := Rect2(anchor - (Vector2(tag_size.x, tag_size.y) if right_align else Vector2.ZERO), tag_size)
	draw_style_box(_style(Color(0.98, 0.97, 0.93, 0.88), 17.0, Color(0.15, 0.20, 0.17, 0.11), 1.0), rect)
	draw_circle(rect.position + Vector2(18, 17), 8.0, color)
	draw_string(GAME_FONT, rect.position + Vector2(32, 22), "%s  %d" % [label, count], HORIZONTAL_ALIGNMENT_LEFT, 66, 13, Color("47534c"))

func _draw_winner_seal(center: Vector2) -> void:
	var seal_color := Color("963b2f") if winner == "red" else Color("264f70")
	draw_circle(center + Vector2(0, 9), 82.0, Color(0.05, 0.03, 0.02, 0.26))
	draw_circle(center, 78.0, seal_color)
	draw_arc(center, 69.0, 0, TAU, 64, Color("f0d4a5"), 3.0, true)
	draw_arc(center, 61.0, 0, TAU, 64, Color(1, 0.91, 0.74, 0.4), 1.0, true)
	draw_string(GAME_FONT, center + Vector2(-50, -19), "胜者", HORIZONTAL_ALIGNMENT_CENTER, 100, 14, Color("f3d9af"))
	draw_string(GAME_FONT, center + Vector2(-50, 38), "红" if winner == "red" else "蓝", HORIZONTAL_ALIGNMENT_CENTER, 100, 54, Color("fff1d4"))

func _draw_corners(frame: Rect2, color: Color) -> void:
	var margin := 24.0
	var length := 19.0
	var points := [
		[frame.position + Vector2(margin, margin), Vector2(1, 1)],
		[Vector2(frame.end.x - margin, frame.position.y + margin), Vector2(-1, 1)],
		[Vector2(frame.position.x + margin, frame.end.y - margin), Vector2(1, -1)],
		[frame.end - Vector2(margin, margin), Vector2(-1, -1)],
	]
	for item in points:
		var origin: Vector2 = item[0]
		var direction: Vector2 = item[1]
		draw_line(origin, origin + Vector2(direction.x * length, 0), Color(color, 0.55), 2.0)
		draw_line(origin, origin + Vector2(0, direction.y * length), Color(color, 0.55), 2.0)

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
		if nearest >= 0 and nearest_distance <= 40.0:
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
