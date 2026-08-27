extends SceneTree

const AI_PLAYER_SCRIPT = preload("res://scripts/ai_player.gd")
const GAME_COUNT := 80
const TURN_LIMIT := 120

var rng := RandomNumberGenerator.new()

func _init() -> void:
	rng.seed = 20260827
	var ai = AI_PLAYER_SCRIPT.new()
	var games_with_capture := 0
	var finished_games := 0
	var total_captures := 0
	for game_index in range(GAME_COUNT):
		var board := _initial_board()
		var side := "red" if game_index % 2 == 0 else "blue"
		var game_captures := 0
		var seen: Dictionary = {}
		for _turn in range(TURN_LIMIT):
			var moves: Array[Dictionary] = ai._generate_moves(board, side)
			if moves.is_empty():
				finished_games += 1
				break
			var opponent := "blue" if side == "red" else "red"
			var capture_moves: Array[Dictionary] = []
			for move in moves:
				var result: Array[String] = ai._apply_move(board, move, side)
				if result.count(opponent) < board.count(opponent):
					capture_moves.append(move)
			var choices := capture_moves if not capture_moves.is_empty() else moves
			var chosen: Dictionary = choices[rng.randi_range(0, choices.size() - 1)]
			var next_board: Array[String] = ai._apply_move(board, chosen, side)
			game_captures += board.count(opponent) - next_board.count(opponent)
			board = next_board
			if board.count(opponent) <= 1:
				finished_games += 1
				break
			side = opponent
			var key := _board_key(board, side)
			seen[key] = int(seen.get(key, 0)) + 1
			if seen[key] >= 3:
				break
		if game_captures > 0:
			games_with_capture += 1
		total_captures += game_captures

	assert(games_with_capture >= 60)
	assert(total_captures >= 160)
	print("可玩性模拟通过：%d/%d 局发生吃子，%d 局决出胜负，共吃掉 %d 子" % [games_with_capture, GAME_COUNT, finished_games, total_captures])
	quit(0)

func _initial_board() -> Array[String]:
	var board: Array[String] = []
	board.resize(20)
	board.fill("")
	for index in [12, 15, 16, 17, 18, 19]:
		board[index] = "red"
	for index in [0, 1, 2, 3, 4, 7]:
		board[index] = "blue"
	return board

func _board_key(board: Array[String], side: String) -> String:
	var key := side.left(1)
	for cell in board:
		key += "." if cell == "" else cell.left(1)
	return key
