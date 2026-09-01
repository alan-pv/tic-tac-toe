class_name GameRules
extends RefCounted

## The rulebook: which cells win and when a round is dead. Static and pure, so
## it can be tested without opening a scene.


## Built once and reused: the eight lines never change.
static var _lines: Array[PackedInt32Array] = []


## Every line that wins a round: the rows, the columns and the two diagonals.
static func all_lines() -> Array[PackedInt32Array]:
	if _lines.is_empty():
		_lines = _build_lines()
	return _lines


## The line that `mark` has completed, or an empty array if it has not. The
## cells come back so the board can light them up.
static func winning_line(board: BoardState, mark: int) -> PackedInt32Array:
	if mark == Mark.Value.NONE:
		return PackedInt32Array()
	for line in all_lines():
		var complete := true
		for index in line:
			if board.cells[index] != mark:
				complete = false
				break
		if complete:
			return line
	return PackedInt32Array()


## True when the board is full and nobody owns a line. Never happens in
## infinite mode, which is the point of the mode.
static func is_draw(board: BoardState) -> bool:
	return board.is_full() and winner(board) == Mark.Value.NONE


## Whoever owns a line right now, or NONE.
static func winner(board: BoardState) -> int:
	if not winning_line(board, Mark.Value.X).is_empty():
		return Mark.Value.X
	if not winning_line(board, Mark.Value.O).is_empty():
		return Mark.Value.O
	return Mark.Value.NONE


## True when nothing more can happen in this round.
static func is_round_over(board: BoardState) -> bool:
	return winner(board) != Mark.Value.NONE or is_draw(board)


static func _build_lines() -> Array[PackedInt32Array]:
	var lines: Array[PackedInt32Array] = []

	for row in BoardState.SIZE:
		var across := PackedInt32Array()
		for column in BoardState.SIZE:
			across.append(BoardState.index_of(row, column))
		lines.append(across)

	for column in BoardState.SIZE:
		var down := PackedInt32Array()
		for row in BoardState.SIZE:
			down.append(BoardState.index_of(row, column))
		lines.append(down)

	var falling := PackedInt32Array()
	var rising := PackedInt32Array()
	for i in BoardState.SIZE:
		falling.append(BoardState.index_of(i, i))
		rising.append(BoardState.index_of(i, BoardState.SIZE - 1 - i))
	lines.append(falling)
	lines.append(rising)

	return lines
