extends MiniTest

## The rulebook: the eight lines, and what ends a round.
##
## These write straight into board.cells instead of calling place(), so a bug in
## BoardState cannot make the rulebook look broken.


func _board_from(layout: Array) -> BoardState:
	var board := BoardState.new(0)
	for i in layout.size():
		board.cells[i] = layout[i]
	return board


func _has_line(lines: Array[PackedInt32Array], wanted: Array) -> bool:
	var want := wanted.duplicate()
	want.sort()
	for line in lines:
		var got := Array(line)
		got.sort()
		if got == want:
			return true
	return false


const _N := Mark.Value.NONE
const _X := Mark.Value.X
const _O := Mark.Value.O


# ---------------------------------------------------------------- the lines


func test_there_are_eight_ways_to_win() -> void:
	eq(GameRules.all_lines().size(), 8, "rows, columns and both diagonals")


func test_every_line_is_three_cells_of_the_board() -> void:
	for line in GameRules.all_lines():
		eq(line.size(), BoardState.SIZE, "a line is as long as the board is wide")
		for index in line:
			is_true(BoardState.is_inside(index), "cell %d is off the board" % index)


func test_the_rows_the_columns_and_the_diagonals_are_all_there() -> void:
	var lines := GameRules.all_lines()
	is_true(_has_line(lines, [0, 1, 2]), "the top row")
	is_true(_has_line(lines, [6, 7, 8]), "the bottom row")
	is_true(_has_line(lines, [1, 4, 7]), "the middle column")
	is_true(_has_line(lines, [0, 4, 8]), "the main diagonal")
	is_true(_has_line(lines, [2, 4, 6]), "the other diagonal")


func test_nobody_wins_on_an_empty_board() -> void:
	var board := BoardState.new(0)
	is_true(GameRules.winning_line(board, _X).is_empty(), "X has no line")
	is_true(GameRules.winning_line(board, _O).is_empty(), "O has no line")


func test_a_row_wins_and_reports_its_cells() -> void:
	var board := _board_from([_X, _X, _X, _O, _O, _N, _N, _N, _N])
	var line := Array(GameRules.winning_line(board, _X))
	line.sort()
	eq(line, [0, 1, 2], "the winning row")
	is_true(GameRules.winning_line(board, _O).is_empty(), "O has not won")


func test_a_diagonal_wins() -> void:
	var board := _board_from([_O, _X, _N, _X, _O, _N, _N, _N, _O])
	var line := Array(GameRules.winning_line(board, _O))
	line.sort()
	eq(line, [0, 4, 8], "the main diagonal")


func test_a_line_of_two_marks_and_a_gap_wins_nothing() -> void:
	var board := _board_from([_X, _X, _N, _N, _N, _N, _N, _N, _N])
	is_true(GameRules.winning_line(board, _X).is_empty(), "two in a row is not three")


func test_a_line_shared_between_players_wins_nothing() -> void:
	var board := _board_from([_X, _X, _O, _N, _N, _N, _N, _N, _N])
	is_true(GameRules.winning_line(board, _X).is_empty(), "X does not own that row")
	is_true(GameRules.winning_line(board, _O).is_empty(), "neither does O")


# ---------------------------------------------------------------- outcomes


func test_a_full_board_with_no_line_is_a_draw() -> void:
	var board := _board_from([_X, _O, _X, _X, _O, _O, _O, _X, _X])
	is_true(GameRules.is_draw(board), "nine marks and nobody won")


func test_a_full_board_with_a_winner_is_not_a_draw() -> void:
	var board := _board_from([_X, _X, _X, _O, _O, _X, _O, _X, _O])
	is_false(GameRules.is_draw(board), "X owns the top row")


func test_an_unfinished_board_is_not_a_draw() -> void:
	var board := _board_from([_X, _O, _N, _N, _N, _N, _N, _N, _N])
	is_false(GameRules.is_draw(board), "there is still room to play")
