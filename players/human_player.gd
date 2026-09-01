class_name HumanPlayer
extends Player

## A person: waits for a legal click on the board. Clicks that arrive out of
## turn, or on a cell the rules refuse, are ignored.


var _waiting: bool = false
var _state: GameState = null


func request_pick(state: GameState) -> void:
	_state = state
	_waiting = true


func on_cell_clicked(index: int) -> void:
	if not _waiting:
		return
	if _state == null or not _state.can_play(index):
		return
	_waiting = false
	picked.emit(index)


func cancel_pick() -> void:
	_waiting = false
