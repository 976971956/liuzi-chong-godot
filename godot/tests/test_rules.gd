extends SceneTree

const AI_PLAYER_SCRIPT = preload("res://scripts/ai_player.gd")

func _init() -> void:
	var ai = AI_PLAYER_SCRIPT.new()
	var board: Array[String] = []
	board.resize(20)
	board.fill("")

	# 己—己—敌之后即使隔着空点还有第四子，活枪也被封住。
	board[0] = "blue"
	board[4] = "blue"
	board[8] = "red"
	board[16] = "red"
	assert(ai._capture_targets(board, 4, "blue").is_empty())

	# 第四子无论敌我都封枪。
	board[16] = "blue"
	assert(ai._capture_targets(board, 4, "blue").is_empty())

	# 整条线上撤掉第四子后，只有己—己—敌，才可以吃掉枪口红子。
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
