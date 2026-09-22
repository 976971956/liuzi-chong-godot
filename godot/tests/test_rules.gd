extends SceneTree

const AI_PLAYER_SCRIPT = preload("res://scripts/ai_player.gd")

func _init() -> void:
	var ai = AI_PLAYER_SCRIPT.new()
	var board: Array[String] = []
	board.resize(16)
	board.fill("")

	# 新规则：己—敌—己夹击，吃掉中间单子。
	board[0] = "blue"
	board[1] = "red"
	board[2] = "blue"
	assert(ai._capture_targets(board, 2, "blue") == [1])

	# 敌—敌对子互相保护，不会被夹击拆开。
	board.fill("")
	board[0] = "blue"
	board[1] = "red"
	board[2] = "red"
	board[3] = "blue"
	assert(ai._capture_targets(board, 3, "blue").is_empty())

	# 横竖两个方向同时形成夹击，可以双吃。
	board.fill("")
	board[1] = "red"
	board[4] = "red"
	board[5] = "red"
	board[6] = "blue"
	board[7] = "red"
	board[9] = "blue"
	board[13] = "red"
	assert(ai._capture_targets(board, 5, "red") == [6, 9])

	# 跃过一枚棋子到两格外的空点。
	board.fill("")
	board[0] = "blue"
	board[1] = "red"
	var moves: Array[Dictionary] = ai._generate_moves(board, "blue")
	var found_jump := false
	for move in moves:
		if int(move.from) == 0 and int(move.to) == 2:
			found_jump = true
	assert(found_jump)

	# 新开局中红方在下、蓝方在上，电脑必须能找到合法走法。
	board.fill("")
	for index in [8, 11, 12, 13, 14, 15]:
		board[index] = "red"
	for index in [0, 1, 2, 3, 4, 7]:
		board[index] = "blue"
	assert(not ai.find_best_move(board, 2).is_empty())
	print("四线夹击规则与电脑走法测试通过")
	quit(0)
