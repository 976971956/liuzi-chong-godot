extends RefCounted

const ROWS := 4
const COLS := 4
const AI_SIDE := "blue"
const HUMAN_SIDE := "red"

var rng := RandomNumberGenerator.new()

func _init() -> void:
	rng.randomize()

func find_best_move(board: Array[String], difficulty: int) -> Dictionary:
	var moves := _generate_moves(board, AI_SIDE)
	if moves.is_empty():
		return {}
	_sort_captures_first(moves, board, AI_SIDE)
	if difficulty == 0:
		return _pick_beginner_move(board, moves)

	var depth := 2 if difficulty == 1 else 4
	var best_score := -1000000
	var best_moves: Array[Dictionary] = []
	for move in moves:
		var next_board := _apply_move(board, move, AI_SIDE)
		var score := _minimax(next_board, HUMAN_SIDE, depth - 1, -1000000, 1000000)
		if score > best_score:
			best_score = score
			best_moves = [move]
		elif score == best_score:
			best_moves.append(move)
	return best_moves[rng.randi_range(0, best_moves.size() - 1)]

func _pick_beginner_move(board: Array[String], moves: Array[Dictionary]) -> Dictionary:
	var good_moves: Array[Dictionary] = []
	for move in moves:
		var next_board := _apply_move(board, move, AI_SIDE)
		if next_board.count(HUMAN_SIDE) < board.count(HUMAN_SIDE):
			good_moves.append(move)
	# 入门电脑大多会吃眼前的子，但偶尔保留一点随机性。
	if not good_moves.is_empty() and rng.randf() < 0.78:
		return good_moves[rng.randi_range(0, good_moves.size() - 1)]
	return moves[rng.randi_range(0, moves.size() - 1)]

func _minimax(board: Array[String], player: String, depth: int, alpha_value: int, beta_value: int) -> int:
	var terminal := _terminal_score(board, depth)
	if terminal != 999999:
		return terminal
	if depth <= 0:
		return _evaluate(board)

	var moves := _generate_moves(board, player)
	if moves.is_empty():
		return -90000 - depth if player == AI_SIDE else 90000 + depth
	_sort_captures_first(moves, board, player)

	var alpha := alpha_value
	var beta := beta_value
	if player == AI_SIDE:
		var best := -1000000
		for move in moves:
			best = maxi(best, _minimax(_apply_move(board, move, player), HUMAN_SIDE, depth - 1, alpha, beta))
			alpha = maxi(alpha, best)
			if beta <= alpha:
				break
		return best
	else:
		var best := 1000000
		for move in moves:
			best = mini(best, _minimax(_apply_move(board, move, player), AI_SIDE, depth - 1, alpha, beta))
			beta = mini(beta, best)
			if beta <= alpha:
				break
		return best

func _terminal_score(board: Array[String], depth: int) -> int:
	if board.count(HUMAN_SIDE) <= 2:
		return 100000 + depth
	if board.count(AI_SIDE) <= 2:
		return -100000 - depth
	if _generate_moves(board, HUMAN_SIDE).is_empty():
		return 90000 + depth
	if _generate_moves(board, AI_SIDE).is_empty():
		return -90000 - depth
	return 999999

func _evaluate(board: Array[String]) -> int:
	var score := (board.count(AI_SIDE) - board.count(HUMAN_SIDE)) * 120
	score += (_generate_moves(board, AI_SIDE).size() - _generate_moves(board, HUMAN_SIDE).size()) * 7
	for index in range(board.size()):
		if board[index] == "":
			continue
		var row := int(index / COLS)
		var col := index % COLS
		var center_bonus := 5 if row in [1, 2, 3] and col in [1, 2] else 1
		score += center_bonus if board[index] == AI_SIDE else -center_bonus
		score += _friendly_neighbors(board, index, board[index]) * (3 if board[index] == AI_SIDE else -3)
	return score

func _friendly_neighbors(board: Array[String], index: int, side: String) -> int:
	var count := 0
	var row: int = int(index / COLS)
	var col: int = index % COLS
	for delta: Vector2i in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
		var next_row: int = row + delta.x
		var next_col: int = col + delta.y
		if next_row >= 0 and next_row < ROWS and next_col >= 0 and next_col < COLS:
			if board[next_row * COLS + next_col] == side:
				count += 1
	return count

func _sort_captures_first(moves: Array[Dictionary], board: Array[String], player: String) -> void:
	var opponent := HUMAN_SIDE if player == AI_SIDE else AI_SIDE
	moves.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_board := _apply_move(board, a, player)
		var b_board := _apply_move(board, b, player)
		return a_board.count(opponent) < b_board.count(opponent)
	)

func _generate_moves(board: Array[String], player: String) -> Array[Dictionary]:
	var moves: Array[Dictionary] = []
	for index in range(board.size()):
		if board[index] != player:
			continue
		var row: int = int(index / COLS)
		var col: int = index % COLS
		for delta: Vector2i in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
			var next_row: int = row + delta.x
			var next_col: int = col + delta.y
			if next_row < 0 or next_row >= ROWS or next_col < 0 or next_col >= COLS:
				continue
			var target: int = next_row * COLS + next_col
			if board[target] == "":
				moves.append({"from": index, "to": target, "kind": "step"})
			else:
				var jump_row: int = row + delta.x * 2
				var jump_col: int = col + delta.y * 2
				if jump_row >= 0 and jump_row < ROWS and jump_col >= 0 and jump_col < COLS:
					var jump_target := jump_row * COLS + jump_col
					if board[jump_target] == "":
						moves.append({"from": index, "to": jump_target, "kind": "jump"})
	return moves

func _apply_move(board: Array[String], move: Dictionary, player: String) -> Array[String]:
	var next_board: Array[String] = board.duplicate()
	next_board[int(move.to)] = player
	next_board[int(move.from)] = ""
	for target in _capture_targets(next_board, int(move.to), player):
		next_board[target] = ""
	return next_board

func _capture_targets(board: Array[String], moved_index: int, player: String) -> Array[int]:
	var opponent := HUMAN_SIDE if player == AI_SIDE else AI_SIDE
	var row := int(moved_index / COLS)
	var col := moved_index % COLS
	var row_line: Array[int] = []
	var col_line: Array[int] = []
	for c in range(COLS):
		row_line.append(row * COLS + c)
	for r in range(ROWS):
		col_line.append(r * COLS + col)
	var targets: Array[int] = []
	for line: Array[int] in [row_line, col_line]:
		# 只捕获被两枚己方棋子夹住的单子；敌—敌对子天然互相保护。
		for start in range(line.size() - 2):
			var window: Array[int] = [line[start], line[start + 1], line[start + 2]]
			if moved_index not in window:
				continue
			var values: Array[String] = [board[window[0]], board[window[1]], board[window[2]]]
			if values == [player, opponent, player] and window[1] not in targets:
				targets.append(window[1])
	return targets
