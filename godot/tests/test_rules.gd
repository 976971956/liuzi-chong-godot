extends SceneTree

const AI_PLAYER_SCRIPT = preload("res://scripts/ai_player.gd")

func _init() -> void:
	var ai = AI_PLAYER_SCRIPT.new()
	var board: Array[String] = []
	board.resize(16)
	board.fill("")

	# 二打一：正好三子成线，两枚己棋相连，吃掉一枚敌子。
	board[0] = "blue"
	board[1] = "blue"
	board[2] = "red"
	assert(ai._capture_targets(board, 1, "blue") == [2])

	# 四子成线时不触发二打一，必须按二打二处理。
	board[3] = "red"
	assert(ai._capture_targets(board, 1, "blue") == [2, 3])

	# 二打一的另一种方向：敌—己—己，且线外必须为空。
	board.fill("")
	board[1] = "red"
	board[2] = "blue"
	board[3] = "blue"
	assert(ai._capture_targets(board, 2, "blue") == [1])

	# 只有最后一子时，可把自己插入敌—己—敌之间挑吃两子。
	board.fill("")
	board[0] = "red"
	board[1] = "blue"
	board[2] = "red"
	assert(ai._capture_targets(board, 1, "blue") == [0, 2])

	# 只有最后一子时可以沿直线滑行多格，但不能越过棋子。
	board.fill("")
	board[0] = "blue"
	board[5] = "red"
	var moves: Array[Dictionary] = ai._generate_moves(board, "blue")
	var slide_targets: Array[int] = []
	for move in moves:
		if int(move.from) == 0:
			slide_targets.append(int(move.to))
	assert(1 in slide_targets)
	assert(2 in slide_targets)
	assert(3 in slide_targets)
	assert(5 not in slide_targets)

	# 新开局中红方在下、蓝方在上，电脑必须能找到合法走法。
	board.fill("")
	for index in [8, 11, 12, 13, 14, 15]:
		board[index] = "red"
	for index in [0, 1, 2, 3, 4, 7]:
		board[index] = "blue"
	assert(not ai.find_best_move(board, 2).is_empty())
	print("民间六子冲规则与电脑走法测试通过")
	quit(0)
