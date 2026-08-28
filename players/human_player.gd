class_name HumanPlayer
extends Player

## A person: waits for a legal click on the board.
##
## Nothing to implement here. It only turns "a cell was clicked" into "this is
## my move", and ignores clicks that arrive when it is not this player's turn or
## that land on a cell the rules refuse.


var _waiting: bool = false
var _state: GameState = null


func request_pick(state: GameState) -> void:
	_state = state
	_waiting = true


## game.gd routes every board click to every human. Only the one that is
## currently waiting answers.
func on_cell_clicked(index: int) -> void:
	if not _waiting:
		return
	if _state == null or not _state.can_play(index):
		return
	_waiting = false
	picked.emit(index)


func cancel_pick() -> void:
	_waiting = false
