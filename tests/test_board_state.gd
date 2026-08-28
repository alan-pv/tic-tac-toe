extends MiniTest

## Missions 2, 3 and 7.


func _classic() -> BoardState:
	return BoardState.new(0)


func _infinite(limit: int = 3) -> BoardState:
	return BoardState.new(limit)


# ---------------------------------------------------------------- mission 2


func test_a_new_board_is_empty() -> void:
	var board := _classic()
	eq(board.free_indices().size(), BoardState.CELL_COUNT, "free cells on a new board")
	eq(board.mark_at(0), Mark.Value.NONE, "the top-left cell")
	is_true(board.is_free(4), "the middle is free")
	is_false(board.is_full(), "a new board is not full")


func test_indices_outside_the_board_are_answered_calmly() -> void:
	var board := _classic()
	eq(board.mark_at(-1), Mark.Value.NONE, "cell -1")
	eq(board.mark_at(BoardState.CELL_COUNT), Mark.Value.NONE, "one past the last cell")
	is_false(board.is_free(-1), "cell -1 is not playable")
	is_false(board.is_free(99), "cell 99 is not playable")


func test_a_full_board_knows_it() -> void:
	var board := _classic()
	for i in BoardState.CELL_COUNT:
		board.place(i, Mark.Value.X)
	is_true(board.is_full(), "nine marks fill the board")
	eq(board.free_indices().size(), 0, "free cells on a full board")


# ---------------------------------------------------------------- mission 3


func test_placing_a_mark_puts_it_where_it_was_asked() -> void:
	var board := _classic()
	eq(board.place(4, Mark.Value.X), -1, "nothing should vanish in the classic game")
	eq(board.mark_at(4), Mark.Value.X, "the middle cell")
	is_false(board.is_free(4), "an occupied cell is not free")
	eq(board.free_indices().size(), BoardState.CELL_COUNT - 1, "free cells after one move")


func test_an_occupied_cell_refuses_a_second_mark() -> void:
	var board := _classic()
	board.place(0, Mark.Value.X)
	board.place(0, Mark.Value.O)
	eq(board.mark_at(0), Mark.Value.X, "the first mark stays")


func test_the_classic_game_never_removes_anything() -> void:
	var board := _classic()
	for i in [0, 1, 2, 3]:
		eq(board.place(i, Mark.Value.X), -1, "placing mark %d" % i)
	eq(board.order_for(Mark.Value.X).size(), 4, "four X on the board")


# ---------------------------------------------------------------- mission 7


func test_the_fourth_mark_pushes_the_first_one_off() -> void:
	var board := _infinite(3)
	board.place(0, Mark.Value.X)
	board.place(1, Mark.Value.X)
	board.place(2, Mark.Value.X)
	eq(board.place(5, Mark.Value.X), 0, "the oldest X should be the one to go")
	eq(board.mark_at(0), Mark.Value.NONE, "the oldest cell is empty now")
	eq(board.mark_at(5), Mark.Value.X, "and the new mark is on the board")
	eq(board.order_for(Mark.Value.X).size(), 3, "three X, never more")


## The bug this whole file exists for: evicting after placing makes a player at
## the limit throw away the mark they just played.
func test_the_mark_you_just_played_is_never_the_one_that_vanishes() -> void:
	var board := _infinite(3)
	for i in [0, 1, 2]:
		board.place(i, Mark.Value.X)
	var vanished := board.place(8, Mark.Value.X)
	is_false(vanished == 8, "the new mark must not evict itself")
	eq(board.mark_at(8), Mark.Value.X, "the new mark is still there")


func test_a_player_only_pushes_their_own_marks_off() -> void:
	var board := _infinite(3)
	board.place(0, Mark.Value.X)
	board.place(3, Mark.Value.O)
	board.place(1, Mark.Value.X)
	board.place(4, Mark.Value.O)
	board.place(2, Mark.Value.X)
	board.place(5, Mark.Value.O)
	eq(board.place(6, Mark.Value.X), 0, "X pushes its own oldest mark")
	eq(board.mark_at(3), Mark.Value.O, "the O at 3 has nothing to do with it")
	eq(board.order_for(Mark.Value.O).size(), 3, "O still has three marks")


func test_the_warning_points_at_the_oldest_mark() -> void:
	var board := _infinite(3)
	eq(board.next_to_vanish(Mark.Value.X), -1, "nothing to warn about on an empty board")
	board.place(0, Mark.Value.X)
	board.place(1, Mark.Value.X)
	eq(board.next_to_vanish(Mark.Value.X), -1, "still below the limit")
	board.place(2, Mark.Value.X)
	eq(board.next_to_vanish(Mark.Value.X), 0, "the oldest X is the one at risk")


func test_the_classic_game_warns_about_nothing() -> void:
	var board := _classic()
	for i in [0, 1, 2, 3, 4]:
		board.place(i, Mark.Value.X)
	eq(board.next_to_vanish(Mark.Value.X), -1, "no limit means no warning")


func test_a_clone_is_independent() -> void:
	var board := _infinite(3)
	board.place(0, Mark.Value.X)
	var copy := board.clone()
	copy.place(1, Mark.Value.X)
	eq(board.mark_at(1), Mark.Value.NONE, "the original must not move")
	eq(copy.mark_at(0), Mark.Value.X, "the copy carries the history over")
