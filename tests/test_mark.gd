extends MiniTest

## The three things a cell can hold.


func test_opponent_swaps_the_two_marks() -> void:
	eq(Mark.opponent(Mark.Value.X), Mark.Value.O, "the rival of X")
	eq(Mark.opponent(Mark.Value.O), Mark.Value.X, "the rival of O")


func test_an_empty_cell_has_no_rival() -> void:
	eq(Mark.opponent(Mark.Value.NONE), Mark.Value.NONE, "the rival of nothing")


func test_symbols() -> void:
	eq(Mark.to_symbol(Mark.Value.X), "X")
	eq(Mark.to_symbol(Mark.Value.O), "O")
	eq(Mark.to_symbol(Mark.Value.NONE), "")
