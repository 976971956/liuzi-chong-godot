extends SceneTree

const AI_PLAYER_SCRIPT = preload("res://scripts/ai_player.gd")

func _init() -> void:
	var ai = AI_PLAYER_SCRIPT.new()
	var board: Array[String] = []
	board.resize(20)
	board.fill("")

	# 空位会切断保护，远处无论是敌子还是己子都不影响吃子。
	board[0] = "blue"
	board[4] = "blue"
	board[8] = "red"
	board[16] = "red"
	assert(ai._capture_targets(board, 4, "blue") == [8])

	board[16] = "blue"
	assert(ai._capture_targets(board, 4, "blue") == [8])

	# 枪口敌子身后紧邻同色棋子时受到保护。
	board[12] = "red"
	board[16] = "blue"
	assert(ai._capture_targets(board, 4, "blue").is_empty())

	# 身后不是同色棋子时不构成保护。
	board[12] = "blue"
	assert(ai._capture_targets(board, 4, "blue") == [8])

	# 敌—己—己—敌可以向两端同时开枪，一次双吃。
	board.fill("")
	board[0] = "red"
	board[1] = "blue"
	board[2] = "blue"
	board[3] = "red"
	assert(ai._capture_targets(board, 2, "blue") == [0, 3])

	# 标准三子活枪可以吃掉枪口敌子。
	board.fill("")
	board[0] = "blue"
	board[4] = "blue"
	board[8] = "red"
	board[16] = ""
	assert(ai._capture_targets(board, 4, "blue") == [8])

	# 新开局中红方在下、蓝方在上，电脑必须能找到合法走法。
	board.fill("")
	for index in [12, 15, 16, 17, 18, 19]:
		board[index] = "red"
	for index in [0, 1, 2, 3, 4, 7]:
		board[index] = "blue"
	assert(not ai.find_best_move(board, 2).is_empty())
	print("规则与电脑走法测试通过")
	quit(0)
