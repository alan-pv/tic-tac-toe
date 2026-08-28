extends MiniTest

## Missions 4 and 6.
##
## This suite leans on BoardState and GameRules, so it is the last one to go
## green. If it fails while the other three pass, the bug is here.


func _config(rounds_to_win: int = 3, infinite: bool = false) -> GameConfig:
	var config := GameConfig.new()
	config.rounds_to_win = rounds_to_win
	config.infinite_mode = infinite
	config.max_marks_per_player = 3
	return config


func _fresh(rounds_to_win: int = 3, infinite: bool = false) -> GameState:
	var state := GameState.new()
	state.setup(_config(rounds_to_win, infinite))
	return state


# ---------------------------------------------------------------- mission 4


func test_a_new_match_starts_level() -> void:
	var state := _fresh()
	eq(state.scores, [0, 0], "the scoreboard")
	eq(state.current_player, 0, "player one opens")
	eq(state.current_mark(), Mark.Value.X, "player one plays X")


func test_a_free_cell_can_be_played_and_a_silly_one_cannot() -> void:
	var state := _fresh()
	is_true(state.can_play(0), "the top-left corner is free")
	is_false(state.can_play(-1), "cell -1 does not exist")
	is_false(state.can_play(BoardState.CELL_COUNT), "one past the last cell")


func test_playing_puts_a_mark_down_and_passes_the_turn() -> void:
	var state := _fresh()
	var result := state.play(4)
	is_true(result.is_valid(), "the move should be accepted")
	eq(result.index, 4, "where the mark landed")
	eq(result.mark, Mark.Value.X, "whose mark it was")
	eq(state.board.mark_at(4), Mark.Value.X, "the board agrees")
	eq(state.current_player, 1, "the turn moves on")


func test_an_occupied_cell_is_refused() -> void:
	var state := _fresh()
	state.play(4)
	var result := state.play(4)
	is_false(result.is_valid(), "the second move on the same cell")
	eq(state.current_player, 1, "a refused move does not pass the turn")


func test_three_in_a_row_wins_the_round() -> void:
	var state := _fresh()
	state.play(0)  # X
	state.play(3)  # O
	state.play(1)  # X
	state.play(4)  # O
	var result := state.play(2)  # X completes the top row

	is_true(result.is_win(), "X owns the top row")
	var line := Array(result.line)
	line.sort()
	eq(line, [0, 1, 2], "the winning line travels back in the result")
	eq(state.scores, [1, 0], "the round is scored")
	eq(state.current_player, 0, "the winner is still the current player")


func test_a_new_round_clears_the_board_but_not_the_score() -> void:
	var state := _fresh()
	state.play(0)
	state.scores[0] = 1

	state.start_round(1)
	eq(state.board.free_indices().size(), BoardState.CELL_COUNT, "a clean board")
	eq(state.current_player, 1, "the other player opens")
	is_true(state.round_number >= 1, "the round counter moved")
	eq(state.scores, [1, 0], "the match score survives the round")


# ---------------------------------------------------------------- mission 6


func test_the_match_ends_when_somebody_reaches_the_target() -> void:
	var state := _fresh(2)
	is_false(state.is_match_over(), "nothing has happened yet")
	state.scores[0] = 1
	is_false(state.is_match_over(), "one round short")
	state.scores[0] = 2
	is_true(state.is_match_over(), "two rounds is the whole match")


func test_infinite_mode_keeps_the_board_from_filling_up() -> void:
	var state := _fresh(3, true)
	for turn in 20:
		var free := state.board.free_indices()
		if free.is_empty():
			break
		state.play(free[0])

	is_false(state.board.is_full(), "with three marks each the board cannot fill up")
	is_true(state.board.order_for(Mark.Value.X).size() <= 3, "X never keeps a fourth mark")
	is_true(state.board.order_for(Mark.Value.O).size() <= 3, "O never keeps a fourth mark")
