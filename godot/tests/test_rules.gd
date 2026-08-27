extends SceneTree

const AI_PLAYER_SCRIPT = preload("res://scripts/ai_player.gd")

func _init() -> void:
	var ai = AI_PLAYER_SCRIPT.new()
	var board: Array[String] = []
	board.resize(20)
	board.fill("")

	# 同一竖线上连续四子时，三子活枪被第四子封住。
	board[0] = "blue"
	board[4] = "blue"
	board[8] = "red"
	board[12] = "red"
	assert(ai._capture_targets(board, 4, "blue").is_empty())

	# 撤掉第四子后，恰好三子连线，可以吃掉枪口红子。
	board[12] = ""
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
