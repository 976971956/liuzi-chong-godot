extends SceneTree

const AI_PLAYER_SCRIPT = preload("res://scripts/ai_player.gd")

func _init() -> void:
	var ai = AI_PLAYER_SCRIPT.new()
	var board: Array[String] = []
	board.resize(16)
	board.fill("")

	# 唯一吃法：二打一，正好三子成线。
	board[0] = "blue"
	board[1] = "blue"
	board[2] = "red"
	assert(ai._capture_targets(board, 1, "blue") == [2])

	# 四子排满时不吃子，即使前三子看起来像二打一。
	board[3] = "red"
	assert(ai._capture_targets(board, 1, "blue").is_empty())

	# 反向排列“敌—己—己”同样可以二打一，线外必须为空。
	board.fill("")
	board[1] = "red"
	board[2] = "blue"
	board[3] = "blue"
	assert(ai._capture_targets(board, 2, "blue") == [1])
	board[0] = "red"
	assert(ai._capture_targets(board, 2, "blue").is_empty())

	# 普通棋子只能横竖移动一格，不能跳跃或滑行。
	board.fill("")
	board[0] = "blue"
	board[1] = "red"
	var moves: Array[Dictionary] = ai._generate_moves(board, "blue")
	var targets: Array[int] = []
	for move in moves:
		if int(move.from) == 0:
			targets.append(int(move.to))
	assert(0 not in targets)
	assert(2 not in targets)
	assert(4 in targets)

	# 人机对战开局中蓝方必须能找到合法走法。
	board.fill("")
	for index in [8, 11, 12, 13, 14, 15]:
		board[index] = "red"
	for index in [0, 1, 2, 3, 4, 7]:
		board[index] = "blue"
	assert(not ai.find_best_move(board, 2).is_empty())
	print("二打一规则与电脑走法测试通过")
	quit(0)
