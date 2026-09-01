class_name BotPlayer
extends Player

## The machine: a depth-limited minimax with alpha-beta pruning, blunted by
## `skill` so the easy presets feel careless rather than slow.


## Classic tic tac toe never runs past nine plies, so this only ever bites in
## infinite mode, where marks vanish and no position is ever final.
const MAX_DEPTH := 6

## Far enough above any heuristic score that a win is never traded for shape.
const WIN_SCORE := 1000.0

## Cells in the order they are worth trying: the centre, then the corners, then
## the sides. Alpha-beta prunes on the strength of the first move it looks at,
## and a search that opens in the middle finishes several times sooner.
const SEARCH_ORDER := [4, 0, 2, 6, 8, 1, 3, 5, 7]

## Every opening on an empty board is a reflection of another, so there is
## nothing there to search. These are the strongest of them.
const OPENINGS := [4, 0, 2, 6, 8]

var think_time: float = 0.45

## 0.0 = play at random, 1.0 = play as well as it can.
var skill: float = 0.8

## Bumped on every request and on every cancel. A pick that comes back from its
## await holding an old token knows the world moved on and stays quiet.
var _pick_token: int = 0


func setup(p_index: int, p_name: String, p_mark: int, config: GameConfig) -> void:
	super.setup(p_index, p_name, p_mark, config)
	is_human = false
	if config != null:
		think_time = config.bot_think_time
		skill = config.bot_skill


func request_pick(state: GameState) -> void:
	_pick_token += 1
	var token := _pick_token

	if think_time > 0.0:
		await get_tree().create_timer(think_time).timeout
	if token != _pick_token:
		return

	var index := choose_move(state.board, mark)
	if not state.can_play(index):
		index = _random_free_cell(state.board)
	if index < 0:
		push_error("The bot found nowhere to play. Is the board full?")
		return
	picked.emit(index)


func cancel_pick() -> void:
	_pick_token += 1


## Picks the cell to play, or -1 when there is nowhere left.
##
## Ties are broken at random so the bot stops opening every game the same way,
## and a bot below full skill simply declines to think some of the time.
func choose_move(board: BoardState, my_mark: int) -> int:
	var free := board.free_indices()
	if free.is_empty():
		return -1
	if randf() > skill:
		return free.pick_random()
	if free.size() == BoardState.CELL_COUNT:
		return OPENINGS.pick_random()

	free.shuffle()
	var depth := _depth_for(board)
	var best := free[0]
	var best_score := -INF

	for index in free:
		var next := board.clone()
		next.place(index, my_mark)
		var score := _search(next, my_mark, Mark.opponent(my_mark), depth - 1, -INF, INF)
		if score > best_score:
			best_score = score
			best = index

	return best


## Classic play is short enough to solve outright. Infinite mode has no final
## position at all, so it is looked at a fixed distance ahead and judged there,
## less far the more careless the preset is.
func _depth_for(board: BoardState) -> int:
	if board.max_marks_per_player == 0:
		return BoardState.CELL_COUNT
	return maxi(2, roundi(MAX_DEPTH * skill))


## The value of a position for `me`, with `turn` to move. Wins are scored with
## the depth left over, so the bot takes the quickest win and the slowest loss.
func _search(board: BoardState, me: int, turn: int, depth: int, alpha: float, beta: float) -> float:
	var winner := GameRules.winner(board)
	if winner != Mark.Value.NONE:
		return (WIN_SCORE + depth) if winner == me else (-WIN_SCORE - depth)
	if board.is_full():
		return 0.0
	if depth <= 0:
		return _evaluate(board, me)

	var maximising := turn == me
	var best := -INF if maximising else INF

	for index in _ordered_free(board):
		var next := board.clone()
		next.place(index, turn)
		var score := _search(next, me, Mark.opponent(turn), depth - 1, alpha, beta)
		if maximising:
			best = maxf(best, score)
			alpha = maxf(alpha, best)
		else:
			best = minf(best, score)
			beta = minf(beta, best)
		if beta <= alpha:
			break

	return best


## How promising a position looks when there is no more depth to spend: lines
## still open to one side are worth more the closer they are to being three.
func _evaluate(board: BoardState, me: int) -> float:
	var rival := Mark.opponent(me)
	var score := 0.0

	for line in GameRules.all_lines():
		var mine := 0
		var theirs := 0
		for index in line:
			var cell := board.cells[index]
			if cell == me:
				mine += 1
			elif cell == rival:
				theirs += 1
		if theirs == 0:
			score += mine * mine
		if mine == 0:
			score -= theirs * theirs

	return score


## The free cells, most promising first.
func _ordered_free(board: BoardState) -> Array:
	var free: Array = []
	for index in SEARCH_ORDER:
		if board.is_free(index):
			free.append(index)
	return free


func _random_free_cell(board: BoardState) -> int:
	var free := board.free_indices()
	return free.pick_random() if not free.is_empty() else -1
