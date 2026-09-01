class_name GameState
extends RefCounted

## The source of truth for the match: the board, whose turn it is and how many
## rounds each player has won.
##
## It announces the two things the HUD cares about and nothing else. The board
## on screen is not driven by these signals: game.gd animates it from the
## MoveResult, so it can await one animation before starting the next.


signal turn_changed(player_index: int)

signal score_changed(player_index: int, score: int)

const PLAYER_COUNT := 2

var config: GameConfig

var board: BoardState

## Rounds won, one entry per player.
var scores: Array[int] = []

var current_player: int = 0

## 0 before the first round starts.
var round_number: int = 0


func setup(p_config: GameConfig) -> void:
	config = p_config
	board = BoardState.new(config.max_marks())
	scores = []
	scores.resize(PLAYER_COUNT)
	scores.fill(0)
	current_player = 0
	round_number = 0


func mark_for_player(player_index: int) -> int:
	return Mark.Value.X if player_index == 0 else Mark.Value.O


func player_for_mark(mark: int) -> int:
	return 0 if mark == Mark.Value.X else 1


func current_mark() -> int:
	return mark_for_player(current_player)


func opponent_of(player_index: int) -> int:
	return (player_index + 1) % PLAYER_COUNT


## Who is ahead once the match is over. -1 when the scores are level.
func match_winner() -> int:
	if scores[0] > scores[1]:
		return 0
	if scores[1] > scores[0]:
		return 1
	return -1


## True when the current player may drop a mark in that cell.
func can_play(index: int) -> bool:
	return not is_match_over() and board.is_free(index)


## Plays the current player's mark and reports what happened.
##
## The turn is not handed over when the round ends: game.gd reads
## current_player afterwards to know who just won, and start_round() decides
## who opens the next one.
func play(index: int) -> MoveResult:
	var move := MoveResult.new()
	if not can_play(index):
		return move

	var mark := current_mark()
	move.index = index
	move.mark = mark
	move.vanished_index = board.place(index, mark)

	var line := GameRules.winning_line(board, mark)
	if not line.is_empty():
		move.line = line
		scores[current_player] += 1
		score_changed.emit(current_player, scores[current_player])
		return move

	if GameRules.is_draw(board):
		move.is_draw = true
		return move

	current_player = opponent_of(current_player)
	turn_changed.emit(current_player)
	return move


## Clears everything a round owns and hands the opening move to somebody. The
## scores belong to the match, not to the round, so they are left alone.
func start_round(starting_player: int) -> void:
	board = BoardState.new(config.max_marks())
	round_number += 1
	current_player = starting_player
	turn_changed.emit(starting_player)


## True once somebody has won enough rounds to take the match.
func is_match_over() -> bool:
	if config == null:
		return false
	for score in scores:
		if score >= config.rounds_to_win:
			return true
	return false
