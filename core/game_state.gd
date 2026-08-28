class_name GameState
extends RefCounted

## The source of truth for the match: the board, whose turn it is and how many
## rounds each player has won.
##
## It announces the two things the HUD cares about and nothing else. The board
## on screen is NOT driven by these signals: game.gd animates it by hand from
## the MoveResult, so that it can await one animation before starting the next.
## Two things must never both own the same fact.


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


# ---------------------------------------------------------------- plumbing


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


# ---------------------------------------------------------------- your work


## True when the current player may drop a mark in that cell.
##
##   nobody may play once the match is over
##   the cell has to be free
func can_play(index: int) -> bool:
	return board.is_free(index)


## Plays the current player's mark and reports what happened.
##
## WHAT IT SHOULD DO:
##   if the move is not allowed: answer a fresh MoveResult and change nothing
##       (a fresh one is already invalid, its index is -1)
##
##   remember which mark is being played
##   ask the board to place it, and keep the cell it emptied, if any
##   fill in the result: the cell played, the mark, the emptied cell
##
##   ask the rulebook whether that mark now owns a line
##   if it does:
##       put the line in the result
##       add one to the current player's score, then announce it with score_changed
##       stop there, the round is over
##   otherwise, if the rulebook calls the position a draw:
##       mark the result as a draw and stop there too
##   otherwise:
##       pass the turn to the other player and announce it with turn_changed
##
##   answer the result
##
## Two traps here:
##   - Do NOT pass the turn when the round ends. game.gd reads current_player
##     afterwards to know who just won, and start_round() decides who opens the
##     next round anyway.
##   - Emit score_changed AFTER the score has actually changed. Whoever listens
##     runs immediately, inside your emit() call, and a listener that reads a
##     half-updated state produces the kind of bug that looks like magic.
##
## Godot you may not know yet:
##   MoveResult.new()     a fresh result, invalid until you fill it in
##   my_signal.emit(a, b) fires the signal right there, synchronously
func play(index: int) -> MoveResult:
	if not can_play(index):
		return MoveResult.new()
	
	var mark := mark_for_player(index)
	var vanish := board.place(index, mark)
	var move := MoveResult.new()
	move.index = index
	move.mark = mark
	move.vanished_index = vanish
	
	var line := GameRules.winning_line(board, mark)
	if not line.is_empty():
		move.line = line
		scores[current_player] += 1
		score_changed.emit(current_player, scores[current_player])
		return move
	elif GameRules.is_draw(board):
		move.is_draw = true
		return move
	else:
		current_player += 1
		current_player = current_player % PLAYER_COUNT
		turn_changed.emit(current_player)
		return move


## Clears everything a round owns and hands the opening move to somebody.
##
##   empty the board (it knows how)
##   count one more round
##   set whose turn it is, and announce it with turn_changed
##
## Leave the scores alone: they belong to the match, not to the round. If you
## reset them here, the match can never end and game.gd will loop forever.
func start_round(starting_player: int) -> void:
	board = BoardState.new(config.max_marks())
	round_number += 1
	current_player = starting_player
	turn_changed.emit(starting_player)


## True once somebody has won enough rounds to take the match.
##
##   somebody's score has reached what the configuration asks for
func is_match_over() -> bool:
	return config.rounds_to_win == scores[current_player]
