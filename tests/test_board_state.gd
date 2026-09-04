extends MiniTest

## The grid: reading it, placing on it, and the infinite mode eviction.


func _classic() -> BoardState:
	return BoardState.new(0)


func _infinite(limit: int = 3) -> BoardState:
	return BoardState.new(limit)


# ---------------------------------------------------------------- reading


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


# ---------------------------------------------------------------- placing


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


# ---------------------------------------------------------------- infinite mode


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


func test_a_full_quota_counts_down_from_the_oldest_mark() -> void:
	var board := _infinite(3)
	for i in [0, 1, 2]:
		board.place(i, Mark.Value.X)
	eq(board.moves_until_vanish(0), 1, "the oldest X goes on the next X move")
	eq(board.moves_until_vanish(1), 2, "the next one after that")
	eq(board.moves_until_vanish(2), 3, "the mark just played has the whole quota")


## Below the limit a placement evicts nothing, so everything is one move safer
## for every slot still free.
func test_marks_below_the_limit_get_a_reprieve() -> void:
	var board := _infinite(3)
	board.place(0, Mark.Value.X)
	eq(board.moves_until_vanish(0), 3, "two more X can be placed before it goes")
	board.place(1, Mark.Value.X)
	eq(board.moves_until_vanish(0), 2, "one more now")
	eq(board.moves_until_vanish(1), 3, "and the newer one is still untouchable")


func test_each_player_is_counted_on_their_own() -> void:
	var board := _infinite(2)
	board.place(0, Mark.Value.X)
	board.place(4, Mark.Value.O)
	board.place(1, Mark.Value.X)
	eq(board.moves_until_vanish(0), 1, "X is at the limit, so its oldest is next")
	eq(board.moves_until_vanish(4), 2, "O has placed once and is in no danger")


func test_nothing_ever_vanishes_in_the_classic_game() -> void:
	var board := _classic()
	for i in [0, 1, 2, 3, 4]:
		board.place(i, Mark.Value.X)
	eq(board.moves_until_vanish(0), 0, "no limit means nothing is ever pushed off")


func test_an_empty_cell_is_waiting_for_nothing() -> void:
	var board := _infinite(3)
	board.place(0, Mark.Value.X)
	eq(board.moves_until_vanish(7), 0, "there is no mark there to lose")
	eq(board.moves_until_vanish(-1), 0, "and nothing outside the board either")


func test_a_clone_is_independent() -> void:
	var board := _infinite(3)
	board.place(0, Mark.Value.X)
	var copy := board.clone()
	copy.place(1, Mark.Value.X)
	eq(board.mark_at(1), Mark.Value.NONE, "the original must not move")
	eq(copy.mark_at(0), Mark.Value.X, "the copy carries the history over")
